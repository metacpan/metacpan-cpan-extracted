package Memcached::Client;
BEGIN {
  $Memcached::Client::VERSION = '2.01';
}
# ABSTRACT: All-singing, all-dancing Perl client for Memcached

use strict;
use warnings;
use AnyEvent qw{};
use AnyEvent::Handle qw{};
use Memcached::Client::Connection qw{};
use Memcached::Client::Log qw{DEBUG LOG};
use Memcached::Client::Request qw{};
use Module::Load qw{load};


sub new {
    my ($class, @args) = @_;
    my %args = 1 == scalar @args ? %{$args[0]} : @args;

    my $self = bless {}, $class;

    $self->log ("new: %s", \%args) if DEBUG;

    # Get all of our objects instantiated
    $self->{compressor} = $self->__class_loader (Compressor => $args{compressor} || 'Gzip')->new;
    $self->{selector} = $self->__class_loader (Selector => $args{selector} || 'Traditional')->new;
    $self->{serializer} = $self->__class_loader (Serializer => $args{serializer} || 'Storable')->new;
    $self->{protocol} = $self->__class_loader (Protocol => $args{protocol} || 'Text')->new (compressor => $self->{compressor}, serializer => $self->{serializer});

    $self->compress_threshold ($args{compress_threshold} || 10000);
    $self->hash_namespace ($args{hash_namespace} || 1);
    $self->namespace ($args{namespace} || "");
    $self->set_servers ($args{servers});
    $self->set_preprocessor ($args{preprocessor});

    $self->log ("new: done") if DEBUG;

    $self;
}


sub log {
    my ($self, $format, @args) = @_;
    LOG ("Client> " . $format, @args);
}

# This manages class loading for the sub-classes
sub __class_loader {
    my ($self, $prefix, $class) = @_;
    # Add our prefixes if the class name isn't called out as absolute
    $class = join ('::', 'Memcached::Client', $prefix, $class) if ($class !~ s/^\+//);
    # Sanitize our class name
    $class =~ s/[^\w:_]//g;
    $self->log ("loading %s", $class) if DEBUG;
    load $class;
    $class;
}


sub compress_threshold {
    my ($self, $new) = @_;
    $self->log ("compress threshold: %d", $new) if DEBUG;
    $self->{compressor}->compress_threshold ($new);
}


sub namespace {
    my ($self, $new) = @_;
    my $ret = $self->{namespace};
    $self->log ("namespace: %s", $new) if DEBUG;
    $self->{namespace} = $new if (defined $new);
    return $ret;
}


sub hash_namespace {
    my ($self, $new) = @_;
    my $ret = $self->{hash_namespace};
    $self->log ("hash namespace: %s", $new) if DEBUG;
    $self->{hash_namespace} = !!$new if (defined $new);
    return $ret;
}


sub set_preprocessor {
    my ($self, $new) = @_;
    $self->{preprocessor} = $new if (ref $new eq "CODE");
    return 1;
}


sub set_servers {
    my ($self, $servers) = @_;

    # Give the selector the list of servers first
    $self->{selector}->set_servers ($servers);

    # Shut down the servers that are no longer part of the list
    my $list = {map {(ref $_ ? $_->[0] : $_), {}} @{$servers}};
    for my $server (keys %{$self->{servers} || {}}) {
        next if (delete $list->{$server});
        $self->log ("disconnecting %s", $server) if DEBUG;
        my $connection = delete $self->{servers}->{$server};
        $connection->disconnect;
    }

    # Spawn connection handlers for all the others
    for my $server (sort keys %{$list}) {
        $self->log ("creating connection for %s", $server) if DEBUG;
        $self->{servers}->{$server} ||= Memcached::Client::Connection->new ($server, $self->{protocol});
    }

    return 1;
}


sub disconnect {
    my ($self) = @_;

    $self->log ("disconnecting all") if DEBUG;
    for my $server (keys %{$self->{servers}}) {
        next unless defined $self->{servers}->{$server};
        $self->log ("disconnecting %s", $server) if DEBUG;
        $self->{servers}->{$server}->disconnect;
    }
}

# When the object leaves scope, be sure to run C<disconnect()> to make
# certain that we shut everything down.
sub DESTROY {
    my $self = shift;
    $self->disconnect;
}


# This is really where all the action happens---where actual requests
# are submitted and handled.
#
# The routine iterates over the requests its given.  It serializes and
# compresses any data in the request as necessary.  If the request has
# a key, then it follows the keyed-submission process, preprocessing
# the key as necessary, checking its validity, mapping it to a server,
# adding a namespace, and finally submitting it.
#
# If the request has no key, it is assumed to be a broadcast request,
# so we call the ->server method on the request for each of our
# servers, to create the appropriate number of requests, and we queue
# each of them.

sub __submit {
    my ($self, @requests) = @_;
    $self->log ("Submitting request(s)") if DEBUG;
    for my $request (@requests) {
        $self->log ("Request is %s", $request) if DEBUG;
        if (defined $request->{key}) {
            if ($self->{preprocessor}) {
                if (ref $request->{key}) {
                    $request->{key}->[1] = $self->{preprocessor}->($request->{key}->[1]);
                } else {
                    $request->{key} = $self->{preprocessor}->($request->{key});
                }
            }
            if (ref $request->{key} # Pre-hashed
                ? ($request->{key}->[0] =~ m/^\d+$/ and # Hash is a decimal #
                   length $request->{key}->[1] > 0 and # Real key has a length
                   length $request->{key}->[1] <= 250 and # Real key is shorter than 250 chars
                   -1 == index $request->{key}->[1], " ") # Key contains no spaces
                : (length $request->{key} > 0 and # Real key has a length
                   length $request->{key} <= 250 and # Real key is shorter than 250 chars
                   -1 == index $request->{key}, " ") # Key contains no spaces
               ) {
                $self->log ("Finding server for key %s", $request->{key}) if DEBUG;
                my $server = $self->{selector}->get_server ($request->{key}, $self->{hash_namespace} ? $self->{namespace} : "");
                $request->{key} = ref $request->{key} ? $request->{key}->[1] : $request->{key};
                $request->{nskey} = $self->{namespace} . $request->{key};
                $self->{servers}->{$server}->enqueue ($request);
            } else {
                $self->log ("Key is invalid") if DEBUG;
                $request->result;
            }
        } else {
            $self->log ("Sending request to all servers") if DEBUG;
            for my $server (keys %{$self->{servers}} ) {
                $self->log ("Queueing for %s", $server) if DEBUG;
                $self->{servers}->{$server}->enqueue ($request->server ($server));
            }
        }
    }
}


1;

__END__
=pod

=head1 NAME

Memcached::Client - All-singing, all-dancing Perl client for Memcached

=head1 VERSION

version 2.01

=head1 SYNOPSIS

  use Memcached::Client;
  my $client = Memcached::Client->new ({servers => ['127.0.0.1:11211']});

  # Synchronous interface
  my $value = $client->get ($key);

  # Asynchronous-ish interface (using your own condvar)
  use AnyEvent;
  my $cv = AnyEvent->cv;
  $client->get ($key, $cv);
  my $value = $cv->recv;

  # Asynchronous (AnyEvent) interface (using callback)
  use AnyEvent;
  $client->get ($key, sub {
    my ($value) = @_;
    warn "got $value for $key";
  });

  # You have to have an event loop running.
  my $loop = AnyEvent->cv;
  $loop->recv;

  # Done
  $client->disconnect();

=head1 DESCRIPTION

Memcached::Client attempts to be a versatile Perl client for the
memcached protocol.

It is built to be usable in a synchronous style by most Perl code,
while also being capable of being used as an entirely asynchronous
library running under AnyEvent.

In theory, being based on AnyEvent means that it can be integrated in
asynchrous programs running under EV, Event, POE, Glib, IO::Async,
etc., though it has only really been tested using AnyEvent's pure-Perl
and EV back-ends.

It allows for pluggable implementations of hashing, protcol,
serialization and compression---it currently implements the
traditional Cache::Memcached hashing, both text and binary protocols,
serialization using Storable or JSON, and compression using gzip.

=head1 METHODS

=head2 new

C<new> takes a hash or a hashref containing any or all of the
following parameters, to define various aspects of the behavior of the
client.

=head3 parameters

=over 4

=item C<compress_threshold> => C<10_000>

Don't consider compressing items whose length is smaller than this
number.

=item C<compressor> => C<Gzip>

You may provide the name of the class to be instantiated by
L<Memcached::Client> to handle compressing data for the servers.

If the C<$classname> is prefixed by a C<+>, it will be used verbatim.
If it is not prefixed by a C<+>, we will look for the name under
L<Memcached::Client::Compressor>.

C<compressor> defaults to C<Gzip>, so a protocol object of the
L<Memcached::Client::Compressor::Gzip> type will be created by
default.  This is intended to be compatible with the behavior of
C<Cache::Memcached>.

=item C<namespace> => C<"">

This string will be used to prefix all keys stored or retrieved by
this client.

=item C<hash_namespace> => C<1>

If hash_namespace is true, any namespace prefix will be added to the
key B<before> hashing.  If it is false, any namespace prefix will be
added to the key B<after> hashing.

=item C<no_rehash> => C<1>

This parameter is only made available for compatiblity with
Cache::Memcached, and is ignored.  Memcached::Client will never
rehash.

=item C<preprocessor> => C<undef>

This allows you to set a preprocessor routine to normalize all keys
before they're sent to the server.  Expects a coderef that will
transform its first argument and then return it.  The identity
preprocessor would be:

 sub {
     return $_[0];
 }

This can be useful for mapping keys to a consistent case or encoding
them as to allow spaces in keys or the like.

=item C<procotol> => C<Text>

You may provide the name of the class to be instantiated by
L<Memcached::Client> to handle encoding details.

If the $classname is prefixed by a +, it will be used verbatim.  If it
is not prefixed by a +, we will look for the name under
L<Memcached::Client::Protocol>.

C<protocol> defaults to C<Text>, so a protocol object of the
L<Memcached::Client::Protocol::Text> type will be created by default.
This is intended to be compatible with the behavior of
C<Cache::Memcached>

=item C<readonly> => C<0>

This parameter is only made available for compatiblity with
Cache::Memcached, and is, for the moment, ignored.  Memcached::Client
does not currently have a readonly mode.

=item C<selector> => C<Traditional>

You may provide the name of the class to be instantiated by
L<Memcached::Client> to handle mapping keys to servers.

If the C<$classname> is prefixed by a C<+>, it will be used verbatim.
If it is not prefixed by a C<+>, we will look for the name under
L<Memcached::Client::Selector>.

C<selector> defaults to C<Traditional>, so a protocol object of the
L<Memcached::Client::Selector::Traditional> type will be created by
default.  This is intended to be compatible with the behavior of
C<Cache::Memcached>

=item C<serializer> => C<Storable>

You may provide the name of theclass to be instantiated by
L<Memcached::Client> to handle serializing data for the servers.

If the C<$classname> is prefixed by a C<+>, it will be used verbatim.
If it is not prefixed by a C<+>, we will look for the name under
L<Memcached::Client::Serializer>.

C<serializer> defaults to C<Storable>, so a protocol object of the
L<Memcached::Client::Serializer::Storable> type will be created by
default.  This is intended to be compatible with the behavior of
C<Cache::Memcached>.

=item C<servers> => \@servers

A reference to an array of servers to use.

Each item can either be a plain string in the form C<hostname:port>,
or an array reference of the form C<['hostname:port' =E<gt> weight]>.  In
the absence of a weight specification, it is assumed to be C<1>.

=back

=head2 log

Log with an appropriate prefix.

=head2 compress_threshold

This routine returns the current compress_threshold, and sets it to
the new value if it's handed one.

=head2 namespace

This routine returns the current namespace, and sets it to the new
value if it's handed one.

=head2 hash_namespace

Whether to prepend the namespace to the key before hashing, or after

This routine returns the current setting, and sets it to the new value
if it's handed one.

=head2 set_preprocessor

Sets a routine to preprocess keys before they are transmitted.

If you want to do some transformation to all keys before they hit the
wire, give this a subroutine reference and it will be run across all
keys.

=head2 set_servers()

Change the list of servers to the listref handed to the function.

=head2 connect()

Immediately initate connections to all servers.

While connections are implicitly made upon first need, and thus are
invisible to the user, it is sometimes helpful to go ahead and start
connections to all servers at once.  Calling C<connect()> will do
this.

=head2 disconnect()

Immediately disconnect from all handles and shutdown everything.

While connections are implicitly made upon first need, and thus are
invisible to the user, there are circumstances where it can be
important to call C<disconnect()> explicitly.

=head2 add

[$rc = ] add ($key, $value[, $exptime, $cb-E<gt>($rc) || $cv])

If the specified key does not already exist in the cache, it will be
set to the specified value.  If an expiration is included, it will
determine the lifetime of the object on the server.

If the add succeeds, 1 will be returned, if it fails, 0 will be
returned.

=head2 add_multi

[$rc = ] add_multi (@([$key, $value, $exptime]), [$cb-E<gt>($rc) || $cv])

Given an array of [key, value, $exptime] tuples, iterate over them and
if the specified key does not already exist in the cache, it will be
set to the specified value.  If an expiration is included, it will
determine the lifetime of the object on the server.

Returns a hashref of {key, boolean} pairs, where 1 means the add
succeeded, 0 means it failed.

=head2 append

[$rc = ] append ($key, $value[, $cb-E<gt>($rc) || $cv])

If the specified key already exists in the cache, it will have the
specified content appended to it.

If the append succeeds, 1 will be returned, if it fails, 0 will be
returned.

=head2 append_multi

[$rc = ] append_multi (@([$key, $value]), [$cb-E<gt>($rc) || $cv])

Given an array of [key, value] tuples, iterate over them and if the
specified key already exists in the cache, it will have the the
specified value appended to it.

Returns a hashref of {key, boolean} pairs, where 1 means the add
succeeded, 0 means it failed.

=head2 decr

[$value = ] decr ($key, [$delta (= 1), $initial, $cb-E<gt>($value) || $cv])

If the specified key already exists in the cache, it will be
decremented by the specified delta value, or 1 if no delta is
specified.

If the value does not exist in the cache, and an initial value is
supplied, the key will be set to that value.

If the decr succeeds, the resulting value will be returned, otherwise
undef will be the result.

=head2 decr_multi

[$value = ] decr_multi (@($key, [$delta (= 1), $initial]), $cb-E<gt>($value) || $cv])

Given an array of either keys, [key, delta] tuples, or [key, delta,
initial] tuples, iterate over them and if the specified key already
exists in the cache, it will be decremented by the specified delta, or
1 if no delta is specified.  If the value does not exist in the cache,
and an initial value is supplied, the key will be set to that value.

Returns a hashref of {key, value} pairs, giving the new values of each
key.

=head2 delete

[$rc = ] delete ($key, [$cb-E<gt>($rc) || $cv])

If the specified key exists in the cache, it will be deleted.

If the delete succeeds, 1 will be returned, otherwise 0 will be the
result.

=head2 delete_multi

[\%keys = ] delete_multi (@keys, [$cb-E<gt>($rc) || $cv])

For each key specified, if the specified key exists in the cache, it
will be deleted.

If the delete succeeds, 1 will be returned, otherwise 0 will be the
result.

=head2 flush_all

[\%servers = ] flush_all ([$cb-E<gt>(\%servers) || $cv])

Clears the keys on each memcached server.

Returns a hashref indicating which servers the flush succeeded on.

=head2 get

[$value = ] get ($key, [$cb-E<gt>($value) || $cv])

Retrieves the specified key from the cache, otherwise returning undef.

=head2 get_multi

[\%values = ] get_multi (@values, [$cb-E<gt>(\%values) || $cv])

Retrieves the specified keys from the cache, returning a hashref of
key => value pairs.

=head2 incr

[$value = ] incr ($key, [$delta (= 1), $initial, $cb-E<gt>($value) || $cv])

If the specified key already exists in the cache, it will be
incremented by the specified delta value, or 1 if no delta is
specified.

If the value does not exist in the cache, and an initial value is
supplied, the key will be set to that value.

If the incr succeeds, the resulting value will be returned, otherwise
undef will be the result.

=head2 incr_multi

[$value = ] incr_multi (\@($key, [$delta (= 1), $initial]), $cb-E<gt>($value) || $cv])

Given an array of either keys, [key, delta] tuples, or [key, delta,
initial] tuples, iterate over them and if the specified key already
exists in the cache, it will be incremented by the specified delta, or
1 if no delta is specified.  If the value does not exist in the cache,
and an initial value is supplied, the key will be set to that value.

Returns a hashref of {key, value} pairs, giving the new values of each
key.

=head2 prepend($key, $value, $cb->($rc));

[$rc = ] append ($key, $value[, $cb-E<gt>($rc) || $cv])

If the specified key already exists in the cache, it will have the
specified content prepended to it.

If the prepend succeeds, 1 will be returned, if it fails, 0 will be
returned.

=head2 prepend_multi

[$rc = ] prepend_multi (@([$key, $value]), [$cb-E<gt>($rc) || $cv])

Given an array of [key, value] tuples, iterate over them and if the
specified key already exists in the cache, it will have the the
specified value prepended to it.

Returns a hashref of {key, boolean} pairs, where 1 means the add
succeeded, 0 means it failed.

=head2 remove

Alias to delete

=head2 replace

[$rc = ] replace ($key, $value[, $exptime, $cb-E<gt>($rc) || $cv])

If the specified key already exists in the cache, it will be replaced
by the specified value.  If it doesn't already exist, nothing will
happen.  If an expiration is included, it will determine the lifetime
of the object on the server.

If the replace succeeds, 1 will be returned, if it fails, 0 will be
returned.

=head2 replace_multi

[$rc = ] replace_multi (@([$key, $value, $exptime]), [$cb-E<gt>($rc) || $cv])

Given an array of [key, value, $exptime] tuples, iterate over them and
if the specified key already exists in the cache, it will be set to
the specified value.  If an expiration is included, it will determine
the lifetime of the object on the server.

Returns a hashref of {key, boolean} pairs, where 1 means the replace
succeeded, 0 means it failed.

=head2 set()

[$rc = ] set ($key, $value[, $exptime, $cb-E<gt>($rc) || $cv])

Set the specified key to the specified value.  If an expiration is
included, it will determine the lifetime of the object on the server.

If the set succeeds, 1 will be returned, if it fails, 0 will be
returned.

=head2 set_multi

[$rc = ] set_multi (@([$key, $value, $exptime]), [$cb-E<gt>($rc) || $cv])

Given an array of [key, value, $exptime] tuples, iterate over them and
set the specified key to the specified value.  If an expiration is
included, it will determine the lifetime of the object on the server.

Returns a hashref of {key, boolean} pairs, where 1 means the set
succeeded, 0 means it failed.

=head2 stats ()

[\%stats = ] stats ([$name, $cb-E<gt>(\%stats) || $cv])

Retrieves stats from all memcached servers.

Returns a hashref of hashrefs with the named stats.

=head2 version()

[\%versions = ] stats ([$cb-E<gt>(\%versions) || $cv])

Retrieves the version number from all memcached servers.

Returns a hashref of server => version pairs.

=head1 METHODS (INTERACTION)

All methods are intended to be called in either a synchronous or
asynchronous fashion.

A method is considered to have been called in a synchronous fashion if
it is does not have a callback (or AnyEvent::CondVar) as its last
parameter.  Because of the way the synchronous mode is implemented, it
B<must not> be used with programs that will call an event loop on
their own (often by calling C<-E<gt>recv> on a condvar)---you will
likely get an error:

	AnyEvent::CondVar: recursive blocking wait detected

A method is considered to have been called in an asynchronous fashion
if it is called with a callback as its last parameter.  If you make a
call in asynchronous mode, your program is responsible for making sure
that an event loop is run...otherwise your program will probably just
exit.

When, in discussing the methods below, the documentation says a value
will be returned, it means that in synchronous mode, the result will
be returned from the function, or in asynchronous mode, the result
will be passed to the callback when it is invoked.

=head1 RATIONALE

Like the world needs another Memcached client for Perl.  Well, I hope
this one is worth inflicting on the world.

First there was L<Cache::Memcached>, the original implementation.

Then there was L<Cache::Memcached::Managed>, which was a layer on top
of L<Cache::Memcached> providing additional capablities.  Then people
tried to do it in XS, spawning L<Cache::Memcached::XS> and then
L<Cache::Memcached::Fast> and finally L<Memcached::libmemcached>,
based on the libmemcached C-library.  Then people tried to do it
asynchronously, spawning L<AnyEvent::Memcached> and
L<Cache::Memcached::AnyEvent>.  There are probably some I missed.

I have used all of them except for L<Cache::Memcached::Managed>
(because I didn't need its additional capabilities) and
L<Cache::Memcached::XS>, which never seems to have really gotten off
the ground, and L<Memcached::libmemcached> which went through long
periods of stagnation.  In fact, I've often worked with more than one
at a time, because my day job has both synchronous and asynchronous
memcached clients.

Diasuke Maki created the basics of a nice asynchronous implementation
of the memcached protocol as L<Cache::Memcached::AnyEvent>, and I
contributed some fixes to it, but it became clear to me that our
attitudes diverged on some things, and decided to fork the project
(for at its base I thought was some excellent code) to produce a
client that could support goals.

My intention with Memcached::Client is to create a reliable,
well-tested, well-documented, richly featured and fast Memcached
client library that can be used idiomatically in both synchronous and
asynchronous code, and should be configurabe to interoperate with
other clients.

I owe a great debt of gratitude to Diasuke Maki, as I used his
L<Cache::Memcached::AnyEvent> as the basis for this implementation,
though the code has basically been rewritten from the groune
up---which is to say, all bugs are mine.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

