package IO::Stream;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.2';

use Scalar::Util qw( weaken );


use IO::Stream::const;
use IO::Stream::EV;


#
# Export constants.
#
# Usage: use IO::Stream qw( :ALL :DEFAULT :Event :Error IN EINBUFLIMIT ... )
#
sub import {
    my %tags = (
        Event   => [ qw( RESOLVED CONNECTED IN OUT EOF SENT ) ],
        Error   => [ qw(
            EINBUFLIMIT 
            ETORESOLVE ETOCONNECT ETOWRITE
            EDNS EDNSNXDOMAIN EDNSNODATA
            EREQINBUFLIMIT EREQINEOF
        ) ],
    );
    $tags{ALL} = $tags{DEFAULT} = [ map { @{$_} } values %tags ];
    my %known = map { $_ => 1 } @{ $tags{ALL} };

    my (undef, @p) = @_;
    if (!@p) {
        @p = (':DEFAULT');
    }
    @p = map { /\A:(\w+)\z/xms ? @{ $tags{$1} || [] } : $_ } @p;
    my $pkg = caller;
    no strict 'refs';
    for my $const (@p) {
        next if !$known{$const};
        *{"${pkg}::$const"} = \&{$const};
    }
    return;
}


my @Active;


sub new {
    my (undef, $opt) = @_;
    croak 'usage: IO::Stream->new({ cb=>, wait_for=>, [fh=>, | host=>, port=>,] ... })'
        if ref $opt ne 'HASH'
        || !$opt->{cb}
        || !($opt->{fh} xor $opt->{host})
        || ($opt->{host} xor $opt->{port});

    my $self = bless {
        # no default values for these:
        cb          => undef,
        wait_for    => undef,
        fh          => undef,
        host        => undef,
        port        => undef,
        # default values:
        method      => 'IO',
        in_buf_limit=> undef,
        out_buf     => q{},                 # modified on: OUT
        out_pos     => undef,               # modified on: OUT
        # user shouldn't provide values for these, but it's ok if he want:
        out_bytes   => 0,                   # modified on: OUT
        in_buf      => q{},                 # modified on: IN
        in_bytes    => 0,                   # modified on: IN
        ip          => undef,               # modified on: RESOLVED
        is_eof      => undef,               # modified on: EOF
        # load user values:
        %{$opt},
        # we'll setup these below:
        plugin      => {},
        _master     => undef,
        _slave      => undef,
        _id         => undef,
    }, __PACKAGE__;

    # Create socket if needed.
    if (!$self->{fh}) {
        # Maybe it have sense instead or croak just send event to user?
        # (Most probable reason: error in socket because there no more fd.)
        socket $self->{fh}, AF_INET, SOCK_STREAM, PROTO_TCP
                                                        or croak "socket: $!";
      if (!WIN32) {
        fcntl $self->{fh}, F_SETFL, O_NONBLOCK          or croak "fcntl: $!";
      } else {
        my $nb=1; ioctl $self->{fh}, FIONBIO, \$nb      or croak "ioctl: $!";
      }
    }

    # Keep this object alive, even if user doesn't keep it himself.
    $self->{_id} = fileno $self->{fh};
    if (!$self->{_id}) {
        croak q{can't get file descriptor};
    } elsif ($Active[ $self->{_id} ]) {
        croak q{can't create second object for same fh};
    } else {
        $Active[ $self->{_id} ] = $self;
    }

    # Connect plugins into chain and setup {plugin}.
    my $master = $self;
    if ($opt->{plugin}) {
        while (my ($name, $plugin) = splice @{ $opt->{plugin} }, 0, 2) {
            $self->{plugin}{$name}  = $plugin;
            $master->{_slave}       = $plugin;
            $plugin->{_master}      = $master;
            weaken($plugin->{_master});
            $master                 = $plugin;
        }
    }
    my $plugin          = IO::Stream::EV->new();
    $master->{_slave}   = $plugin;
    $plugin->{_master}  = $master;
    weaken($plugin->{_master});

    # Ask plugin chain to continue with initialization:
    $self->{_slave}->PREPARE($self->{fh}, $self->{host}, $self->{port});

    # Shortcuts for typical operations after creating new I/O object:
    if (length $self->{out_buf}) {
        $self->write();
    }

    return $self;
}

#
# Push user data down the stream, optionally adding new data to {out_buf}.
#
sub write {     ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $data) = @_;
    if ($#_ > 0) {
        $self->{out_buf} .= $data;
    }
    $self->{_slave}->WRITE();
    return;
}

#
# Free fh and Stream object.
#
sub close {     ## no critic (ProhibitBuiltinHomonyms ProhibitAmbiguousNames)
    my ($self) = @_;
    undef $Active[ $self->{_id} ];
    return close $self->{fh};
}

#
# Filter and deliver to user events (received from top plugin in the chain).
#
sub EVENT {
    my ($self, $e, $err) = @_;
    my $w = $self->{wait_for};
    if ($e & IN && !($w & IN)) {
        # override $err in case of wrong config
        if (!($w & EOF)) {
            $err = EREQINEOF;
        }
        elsif (!defined $self->{in_buf_limit}) {
            $err = EREQINBUFLIMIT;
        }
    }
    if (!$err && $e & IN && !($w & IN)) {
        my $l = $self->{in_buf_limit};
        if ($l > 0 && length $self->{in_buf} > $l) {
            $err = EINBUFLIMIT;
        }
    }
    $e &= $w;
    if ($e || $err) {
        if (ref $self->{cb} eq 'CODE') {
            $self->{cb}->($self, $e, $err);
        } else {
            my $method = $self->{method};
            $self->{cb}->$method($self, $e, $err);
        }
    }
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=for stopwords ip EREQINEOF EREQINBUFLIMIT EINBUFLIMIT

=head1 NAME

IO::Stream - ease non-blocking I/O streams based on EV


=head1 VERSION

This document describes IO::Stream version v2.0.2


=head1 SYNOPSIS

    use EV;
    use IO::Stream;

    IO::Stream->new({
        host        => 'google.com',
        port        => 80,
        cb          => \&client,
        wait_for    => SENT|EOF,
        in_buf_limit=> 102400,
        out_buf     => "GET / HTTP/1.0\nHost: google.com\n\n",
    });

    $EV::DIED = sub { warn $@; EV::unloop };
    EV::loop;

    sub client {
        my ($io, $e, $err) = @_;
        if ($err) {
            $io->close();
            die $err;
        }
        if ($e & SENT) {
            print "request sent, waiting for reply...\n";
        }
        if ($e & EOF) {
            print "server reply:\n", $io->{in_buf};
            $io->close();
            EV::unloop;         # ALL DONE
        }
    }


=head1 DESCRIPTION

Non-blocking event-based low-level I/O is hard to get right. Code usually
error-prone and complex... and it very similar in all applications. Things
become much worse when you need to alter I/O stream in some way - use
proxies, encryption, SSL, etc.

This module designed to give user ability to work with I/O streams on
higher level, using input/output buffers (just scalars) and high-level
events like CONNECTED, SENT or EOF. As same time it doesn't hide low-level
things, and user still able to work on low-level without any limitations.

=head2 PLUGINS

Architecture of this module make it ease to write plugins, which will alter
I/O stream in any way - route it through proxies, encrypt, log, etc.

Here are few available plugins, you may find more on CPAN:
L<IO::Stream::Crypt::RC4>,
L<IO::Stream::Proxy::HTTPS>,
L<IO::Stream::MatrixSSL::Client>,
L<IO::Stream::MatrixSSL::Server>.

If you interested in writing own plugin, check source for "skeleton"
plugins: L<IO::Stream::Noop> and L<IO::Stream::NoopAlias>.


=head1 EXPORTS

This modules doesn't export any functions/methods/variables, but it exports
a lot of constants. There two groups of constants: events and errors
(which can be imported using tags ':Event' and ':Error').
By default all constants are exported.

Events:

    RESOLVED CONNECTED IN OUT EOF SENT

Errors:

    EINBUFLIMIT
    ETORESOLVE ETOCONNECT ETOWRITE
    EDNS EDNSNXDOMAIN EDNSNODATA
    EREQINBUFLIMIT EREQINEOF

Errors are similar to $! - they're dualvars, having both textual and numeric
values.

B<NOTE:> Since v2.0.0 C<ETORESOLVE>, C<EDNSNXDOMAIN> and C<EDNSNODATA> are
not used anymore (C<EDNS> is used instead), but they're still exported for
compatibility.


=head1 OVERVIEW

You can create IO::Stream object using any "stream" fh
(file, TTY, UNIX socket, TCP socket, pipe, FIFO).
Or, if you need TCP socket, you can create IO::Stream object using host+port
instead of fh (in this case IO::Stream will do non-blocking host resolving,
create TCP socket and do non-blocking connect).

After you created IO::Stream object, it will handle read/write on this fh,
and deliver only high-level events you asked for into your callback, where
you will be able to operate with in/out buffers instead of doing
sysread()/syswrite() manually.

There no limitations on what you can do with fh after you've created
IO::Stream object - you can even do sysread()/syswrite() (but there no
reasons for you to do this anymore).

B<IMPORTANT!> When you want to close this fh,
B<you MUST use $io-E<gt>close() method for closing fh> instead of
doing close($fh). This is because IO::Stream doesn't require from you to
keep object returned by new(), and without call to $io->close()
IO::Stream object will continue to exists and may receive/generate some
events, which is not what you expect after closing fh. Also, if you keep
object returned by IO::Stream->new() somewhere in your variables, you
should either undef all such variables after you called $io->close(),
or you should use Scalar::Util::weaken() on these variables after storing
IO::Stream object. (The same is applicable for all plugin objects too.)


=head2 EVENTS

=over

=item RESOLVED

If you created IO::Stream object using {host}+{port} instead of {fh},
this event will be generated after resolving {host}. Resolved IP address
will be stored in {ip}.

=item CONNECTED

If you created IO::Stream object using {host}+{port} instead of {fh},
this event will be generated after connecting socket to {ip}:{port}.

=item IN

Generated after each successful read. IO::Stream may execute several
sysread() at once before generating IN event for optimization.
Read data will be stored in {in_buf}, and {in_bytes} counter will be
incremented by amount of bytes read.

=item EOF

Generated only B<ONCE> when EOF reached (sysread() return 0).
Also will set {is_eof} to true.

=item OUT

Generated when some data from {out_buf} was written. Written bytes either
removed from {out_buf} or just increment {out_pos} by amount of bytes written
(see documentation about these fields below for more details).
Also increment {out_bytes} counter by amount of bytes written.

Here 'written' may be somewhat virtual, while {out_buf}/{out_pos} changes,
the real data still can be in plugin buffers (if you use plugins) and real
syswrite() may not be called yet. To detect when all data is B<really>
written you should use SENT event, not OUT.

=item SENT

Generated when all data from {out_buf} was written. It's usual and safe to
call $io->close() on SENT event.

=back


=head2 TIMEOUTS

IO::Stream has 30-second timeouts for connect and write,
to timeout DNS resolve it use default AnyEvent::DNS timeout.
If you need to timeout other operations, you have to create own timers
using EV::timer().

Current version doesn't allow you to change these timeouts.


=head2 SERVER

If you need to run TCP/UNIX-server socket, then you should handle that socket
manually. But you can create IO::Stream object for accept()'ed socket:

    my ($host, $port) = ('0.0.0.0', 1234);
    socket  my $srv_sock, AF_INET, SOCK_STREAM, 0;
    setsockopt $srv_sock, SOL_SOCKET, SO_REUSEADDR, 1;
    bind       $srv_sock, sockaddr_in($port, inet_aton($host));
    listen     $srv_sock, SOMAXCONN;
    fcntl      $srv_sock, F_SETFL, O_NONBLOCK;
    $srv_w = EV::io($srv_sock, EV::READ, sub {
        if (accept my $sock, $srv_sock) {
            IO::Stream->new({
                fh          => $sock,
                cb          => \&server,
                wait_for    => IN,
            });
        }
        elsif ($! != EAGAIN) {
            die "accept: $!";
        }
    });


=head1 INTERFACE 

IO::Stream provide only three public methods: new(), write() and close().
new() will create new object, close() will destroy it and write() must be
called when you want to modify (or just modified) output buffer.

All other operations are done using IO::Stream object fields - for
simplicity and performance reasons. Moreover, you can keep your own data
in it. There convention on field names, to avoid conflicts:

=over

=item /^_/

Fields with names started with underscore are for internal use by
IO::Stream, you shouldn't touch them or create your own field with such
names.

=item /^[a-z]/

Fields with names started with lower-case letter are part of IO::Stream
public interface - you allowed to read/write these fields, but you should
not store incorrect values in these fields. Check L<PUBLIC FIELDS> below
for description of available fields and their format.

=item /^[A-Z]/

You can store your own data in IO::Stream object using field names started
with upper-case letter. IO::Stream will not touch these fields.

=back

When some event arise which you're waited for, your callback will be
called with 3 parameters: IO::Stream object, event mask, and error (if any):

    sub callback {
        my ($io, $e, $err) = @_;
    }


=head1 METHODS

=head2 new

    IO::Stream->new( \%opt );

Create and return IO::Stream object. You may not keep returned object - you
will get it in your callback (in first parameter) when some interesting
for your event happens, and will exists until to call method close().
See L<OVERVIEW> for more details.

Fields of %opt become fields of created IO::Stream object. There only few
fields required, but you can set any other fields too, and can also set
your custom fields (with names starting from upper-case letter).

Only required fields in %opt are {cb} and either {fh} or {host}+{port}.
The {wait_for} field also highly recommended to set when creating object.

If {out_buf} will be set, then new() will automatically call write() after
creating object.

    IO::Stream->new({
        fh          => \*STDIN,
        cb          => \&console,
        wait_for    => IN,
    });

=head2 write

    $io->write();
    $io->write($data);

Method write() B<MUST> be called after any modifications of {out_buf} field,
to ensure data in {out_buf} will be written to {fh} as soon as it will be
possible.

If {fh} available for writing when calling write(), then it will write
(may be partially) {out_buf} and may immediately call your callback function
delivering OUT|SENT events there. So, if you call write() from that callback
(as it usually happens), keep in mind it may be called again while executing
write(), and object state may significantly change (it even may be close()'d)
after it return from write() into your callback.

The write($data) is just a shortcut for:

    $io->{out_buf} .= $data;
    $io->write();

=head2 close

    $io->close()

Method close() will close {fh} and destroy IO::Stream object.
See L<OVERVIEW> for more details.


=head1 PUBLIC FIELDS

If field marked *RO* that mean field is read-only and shouldn't be changed.

Some field have default values (shown after equal sign).

Some field modified on events.

=over

=item cb

=item method ='IO'

User callback which will be called when some listed in {wait_for} events
arise or error happens.

Field {cb} should be either CODE ref or object or class name. In last two
cases method named {method} will be called. Field {method} should be string.

=item wait_for

Bitmask of events interesting for user. Can be changed at any time.
For example:

    $io->{wait_for} = RESOLVED|CONNECTED|IN|EOF|OUT|SENT;

When some data will be read from {fh}, {wait_for} must contain IN and/or EOF,
or error EREQINEOF will be generated. So, it's better to always have
IN and/or EOF in {wait_for}.

If {wait_for} contain EOF and doesn't contain IN then {in_buf_limit} must
be defined or error EREQINBUFLIMIT will be generated.

=item fh *RO*

File handle for doing I/O. It's either provided by user to new(), or created
by new() (when user provided {host}+{port} instead).

=item host *RO*

=item port *RO*

If user doesn't provide {fh} to new(), he should provide {host} and {port}
instead. This way new() will create new TCP socket in {fh} and resolve
{host} and connect this {fh} to resolved {ip} and {port}. Both resolving
and connecting happens in non-blocking way, and will result in delivering
RESOLVED and CONNECTED events into user callback (if user {wait_for} these
events).

=item in_buf_limit =undef

Used to avoid DoS attach when user doesn't handle IN events and want his
callback called only on EOF event. Must be defined if user have EOF without
IN in {wait_for}.

Any value >0 will defined amount of bytes which can be read into {in_buf}
before EOF happens. When size of {in_buf} become larger than {in_buf_limit},
error EINBUFLIMIT will be delivered to user callback. In this case user can
either remove some data from {in_buf} to make it smaller than {in_buf_limit}
or increase {in_buf_limit}, and continue reading data.

B<NOT RECOMMENDED!> Value 0 will switch off DoS protection, so there will
be no limit on amount of data to read into {in_buf} until EOF happens.

=item out_buf =q{}          # modified on: OUT

=item out_pos =undef        # modified on: OUT

Data from {out_buf} will be written to {fh}.

If {out_pos} not defined, then data will be written from beginning of
{out_buf}, and after successful write written bytes will be removed from
beginning of {out_buf}.

If {out_pos} defined, it should be >= 0. In this case data will be written
from {out_pos} position in {out_buf}, and after successful write {out_pos}
will be incremented by amount of bytes written. {out_buf} will not be changed!

=item out_bytes =0          # modified on: OUT

Each successful write will increment {out_bytes} by amount of written bytes.
You can change {out_bytes} in any way, but it should always be a number.

=item in_buf =q{}           # modified on: IN

Each successful read will concatenate read bytes to {in_buf}.
You can change {in_buf} in any way, but it should always be a string.

=item in_bytes =0           # modified on: IN

Each successful read will increment {in_bytes} by amount of read bytes.
You can change {in_bytes} in any way, but it should always be a number.

=item ip *RO* =undef        # modified on: RESOLVED

When you call new() with {host}+{port} instead of {fh} then IP address
resolved from {host} will be stored in {ip}, and event RESOLVED will be
generated.

=item is_eof *RO* =undef    # modified on: EOF

When EOF event happens {is_eof} will be set to true value.
This allow you to detect is EOF already happens at any time, even if
you doesn't have EOF in {wait_for}.

=item plugin *RO* ={}

Allow you to set list of plugins when creating object with new(),
and later access these plugins.

This field is somewhat special, because when you call new() you should
set plugin to ARRAY ref, but in IO::Stream object {plugin} is HASH ref:

    my $io = IO::Stream->new({
        host        => 'www.google.com',
        port        => 443,
        cb          => \&google,
        wait_for    => EOF,
        in_buf_limit=> 102400,
        out_buf     => "GET / HTTP/1.0\nHost: www.google.com\n\n",
        plugin      => [    # <------ it's ARRAY, but looks like HASH
            ssl         => IO::Stream::MatrixSSL::Client->new(),
            proxy       => IO::Stream::Proxy::HTTPS->new({
                host        => 'my.proxy.com',
                port        => 3218,
                user        => 'me',
                pass        => 'my pass',
            }),
        ],
        MyField1    => 'my data1',
        MyField2    => \%mydata2,
    });

    # access the "proxy" plugin:
    $io->{plugin}{proxy};

This is because when calling new() it's important to keep plugins in order,
but later it's easier to access them using names.

=back


=head1 DIAGNOSTICS

Exceptions may be thrown only in new(). All other errors will be delivered
to user's callback in last parameter.

=over

=item C<< usage: IO::Stream->new({ cb=>, wait_for=>, [fh=>, | host=>, port=>,] ... }) >>

You called new() with wrong parameters.

=item C<< socket: %s >>

=item C<< fcntl: %s >>

Error happens while creating new socket. Usually this happens because you
run out of file descriptors.

=item C<< can't get file descriptor >>

Failed to get fileno() for your fh. Either fh doesn't open, or this fh
type is not supported (directory handle), or fh is not file handle at all.

=item C<< can't create second object for same fh >>

You can't have more than one IO::Stream object for same fh.

IO::Stream keep all objects created by new() until $io->close() will be
called. Probably you've closed fh in some way without calling
$io->close(), then new fh was created with same file descriptor
number, and you've tried to create IO::Stream object using new fh.

=back


=head1 SEE ALSO

L<AnyEvent::Handle>


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-IO-Stream/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-IO-Stream>

    git clone https://github.com/powerman/perl-IO-Stream.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=IO-Stream>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/IO-Stream>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Stream>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=IO-Stream>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/IO-Stream>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
