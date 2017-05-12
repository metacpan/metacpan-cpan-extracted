package Memcached::Client::Request;
BEGIN {
  $Memcached::Client::Request::VERSION = '2.01';
}
# ABSTRACT: Base class for Memcached::Client request drivers

use strict;
use warnings;
use AnyEvent qw{};
use Memcached::Client::Log qw{DEBUG LOG};


sub generate {
    my ($class, $command) = @_;

    $class->log ("Class is %s, Command is %s", $class, $command) if DEBUG;
    return sub {
        my ($client, @args) = @_;

        my $request = bless {command => $command}, $class;
        $class->log ("Request is %s", $request) if DEBUG;

        $class->log ("Checking for condvar/callback") if DEBUG;
        if (ref $args[-1] eq 'AnyEvent::CondVar' or ref $args[-1] eq 'CODE') {
            $class->log ("Found condvar/callback") if DEBUG;
            $request->{cb} = pop @args;
        } else {
            $class->log ("Making own condvar") if DEBUG;
            $request->{cb} = AE::cv;
            $request->{wait} = 1;
        }

        $class->log ("Processing arguments: %s", \@args) if DEBUG;
        my @requests = $request->process (@args);
        if (@requests) {
            $class->log ("Submitting request(s)") if DEBUG;
            $client->__submit (@requests);
        } else {
            $request->result;
        }

        $class->log ("Checking whether to wait") if DEBUG;
        $request->{cb}->recv if ($request->{wait});
    }
}


sub log {
    my ($self, $format, @args) = @_;
    my $prefix = ref $self || $self;
    $prefix =~ s,Memcached::Client::Request::,Request/,;
    LOG ("$prefix> " . $format, @args);
}


sub result {
    my ($self, @values) = @_;
    $self->log ("$self received result %s", \@values) if DEBUG;
    if (scalar @values) {
        $self->log ("We have a result") if DEBUG;
    } elsif (defined $self->{result}) {
        $self->log ("We have a stored result") if DEBUG;
        push @values, $self->{result};
    } elsif (exists $self->{default}) {
        $self->log ("We have a default") if DEBUG;
        push @values, $self->{default};
    } else {
        $self->log ("We have nothing to return") if DEBUG;
    }
    unshift @values, $self->{key} if ($self->{sendkey});
    $self->{cb}->(@values);
}

package Memcached::Client::Request::Add;
BEGIN {
  $Memcached::Client::Request::Add::VERSION = '2.01';
}
# ABSTRACT: Driver for Memcached::Client add-style requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    my ($self, $key, $value, $expiration) = @_;
    $self->{default} = 0;
    return () unless (defined $key and defined $value);
    $self->{expiration} = int ($expiration || 0);
    $self->{key} = $key;
    $self->{type} = "__add";
    $self->{value} = $value;
    return $self;
}

*Memcached::Client::add = Memcached::Client::Request::Add->generate ("add");
*Memcached::Client::append = Memcached::Client::Request::Add->generate ("append");
*Memcached::Client::prepend = Memcached::Client::Request::Add->generate ("prepend");
*Memcached::Client::replace = Memcached::Client::Request::Add->generate ("replace");
*Memcached::Client::set = Memcached::Client::Request::Add->generate ("set");

package Memcached::Client::Request::AddMulti;
BEGIN {
  $Memcached::Client::Request::AddMulti::VERSION = '2.01';
}
# ABSTRACT: Driver for multiple Memcached::Client add-style requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    my ($self, @requests) = @_;
    $self->{result} = {};
    return () unless @requests;
    $self->{partial} = 0;
    return grep {$_} map {
        my $request = bless {command => $self->{command}, sendkey => 1}, "Memcached::Client::Request::Add";
        $request->{cb} = sub {
            my ($key, $value) = @_;
            $self->log ("Noting that we received %s for %s", $value, $key) if DEBUG;
            $self->{result}->{$key} = $value if (defined $value);
            $self->result unless (--$self->{partial});
            $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
        };
        if ($request->process (@{$_})) {
            $self->{partial}++;
            $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
            $request;
        }
    } @requests;
}

*Memcached::Client::add_multi = Memcached::Client::Request::AddMulti->generate ("add");
*Memcached::Client::append_multi = Memcached::Client::Request::AddMulti->generate ("append");
*Memcached::Client::prepend_multi = Memcached::Client::Request::AddMulti->generate ("prepend");
*Memcached::Client::replace_multi = Memcached::Client::Request::AddMulti->generate ("replace");
*Memcached::Client::set_multi = Memcached::Client::Request::AddMulti->generate ("set");

package Memcached::Client::Request::Decr;
BEGIN {
  $Memcached::Client::Request::Decr::VERSION = '2.01';
}
# ABSTRACT: Driver for multiple Memcached::Client decr-style requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    my ($self, $key, $delta, $initial) = @_;
    return () unless (defined $key);
    $self->log ("arguments are %s", \@_) if DEBUG;
    $self->{data} = defined $initial ? int ($initial) : undef;
    $self->{delta} = int ($delta || 1);
    $self->{key} = $key;
    $self->{type} = "__decr";
    return $self;
}

*Memcached::Client::decr = Memcached::Client::Request::Decr->generate ("decr");
*Memcached::Client::incr = Memcached::Client::Request::Decr->generate ("incr");

package Memcached::Client::Request::DecrMulti;
BEGIN {
  $Memcached::Client::Request::DecrMulti::VERSION = '2.01';
}
# ABSTRACT: Driver for multiple Memcached::Client decr-style requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    my ($self, @requests) = @_;
    $self->{result} = {};
    return () unless (@requests);
    $self->{partial} = 0;
    return grep {defined} map {
        my $request = bless {command => $self->{command}, sendkey => 1}, "Memcached::Client::Request::Decr";
        $request->{cb} = sub {
            my ($key, $value) = @_;
            $self->log ("Noting that we received %s for %s", $value, $key) if DEBUG;
            $self->{result}->{$key} = $value if (defined $value);
            $self->result unless (--$self->{partial});
            $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
        };
        if ($request->process (ref $_ ? @{$_} : $_)) {
            $self->{partial}++;
            $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
            $request;
        }
    } @requests;
}

*Memcached::Client::decr_multi = Memcached::Client::Request::DecrMulti->generate ("decr");
*Memcached::Client::incr_multi = Memcached::Client::Request::DecrMulti->generate ("incr");

package Memcached::Client::Request::Delete;
BEGIN {
  $Memcached::Client::Request::Delete::VERSION = '2.01';
}
# ABSTRACT: Driver for Memcached::Client delete requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    my ($self, $key) = @_;
    $self->{default} = 0;
    return () unless (defined $key);
    $self->log ("arguments are %s", \@_) if DEBUG;
    $self->{key} = $key;
    $self->{type} = "__delete";
    return $self;
}

*Memcached::Client::delete = Memcached::Client::Request::Delete->generate ("delete");

package Memcached::Client::Request::DeleteMulti;
BEGIN {
  $Memcached::Client::Request::DeleteMulti::VERSION = '2.01';
}
# ABSTRACT: Driver for multiple Memcached::Client delete requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    my ($self, @keys) = @_;
    $self->{result} = {};
    return () unless (@keys);
    $self->{partial} = 0;
    return grep {$_} map {
        my $request = bless {command => $self->{command}, sendkey => 1}, "Memcached::Client::Request::Delete";
        $request->{cb} = sub {
            my ($key, $value) = @_;
            $self->log ("Noting that we received %s for %s", $value, $key) if DEBUG;
            $self->{result}->{$key} = $value if (defined $value);
            $self->result unless (--$self->{partial});
            $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
        };
        if ($request->process ($_)) {
            $self->{partial}++;
            $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
            $request;
        }
    } @keys;
}

*Memcached::Client::delete_multi = Memcached::Client::Request::DeleteMulti->generate ("delete");

package Memcached::Client::Request::Get;
BEGIN {
  $Memcached::Client::Request::Get::VERSION = '2.01';
}
# ABSTRACT: Driver for Memcached::Client get requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    my ($self, $key) = @_;
    return () unless (defined $key);
    $self->log ("arguments are %s", \@_) if DEBUG;
    $self->{type} = "__get";
    $self->{key} = $key;
    return $self;
}

*Memcached::Client::get = Memcached::Client::Request::Get->generate ("get");

package Memcached::Client::Request::GetMulti;
BEGIN {
  $Memcached::Client::Request::GetMulti::VERSION = '2.01';
}
# ABSTRACT: Driver for multiple Memcached::Client get requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    my ($self, @keys) = @_;
    $self->{result} = {};
    return () unless (@keys);
    $self->{partial} = 0;
    return grep {defined} map {
        my $request = bless {command => $self->{command}, sendkey => 1}, "Memcached::Client::Request::Get";
        $request->{cb} = sub {
            my ($key, $value) = @_;
            $self->log ("Noting that we received %s for %s", $value, $key) if DEBUG;
            $self->{result}->{$key} = $value if (defined $value);
            $self->result unless (--$self->{partial});
            $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
        };
        if ($request->process ($_)) {
            $self->{partial}++;
            $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
            $request;
        }
    } @keys;
}

*Memcached::Client::get_multi = Memcached::Client::Request::GetMulti->generate ("get");

package Memcached::Client::Request::Broadcast;
BEGIN {
  $Memcached::Client::Request::Broadcast::VERSION = '2.01';
}
# ABSTRACT: Class to manage Memcached::Client server requests

use Memcached::Client::Log qw{DEBUG LOG};
use base qw{Memcached::Client::Request};


sub process {
    return $_[0];
}

package Memcached::Client::Request::BroadcastMulti;
BEGIN {
  $Memcached::Client::Request::BroadcastMulti::VERSION = '2.01';
}
# ABSTRACT: Class to manage Memcached::Client broadcast requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    my ($self, @arguments) = @_;
    $self->{arguments} = \@arguments;
    $self->{result} = {};
    $self->{partial} = 0;
    $self->{type} = "__$self->{command}";
    return $self;
}


sub server {
    my ($self, $server) = @_;
    my $request = bless {command => $self->{command}, key => $server, sendkey => 1, type => $self->{type}}, "Memcached::Client::Request::Broadcast";
    $request->{cb} = sub {
        my ($key, $value) = @_;
        $self->log ("Noting that we received %s for %s", $value, $key) if DEBUG;
        $self->{result}->{$key} = $value if (defined $value);
        $self->result unless (--$self->{partial});
        $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
    };
    $self->{partial}++;
    $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
    $request;
}

*Memcached::Client::flush_all = Memcached::Client::Request::BroadcastMulti->generate ("flush_all");
*Memcached::Client::stats = Memcached::Client::Request::BroadcastMulti->generate ("stats");
*Memcached::Client::version = Memcached::Client::Request::BroadcastMulti->generate ("version");

package Memcached::Client::Request::Connect;
BEGIN {
  $Memcached::Client::Request::Connect::VERSION = '2.01';
}
# ABSTRACT: Class to manage Memcached::Client server request

use Memcached::Client::Log qw{DEBUG LOG};
use base qw{Memcached::Client::Request};


sub process {
    return $_[0];
}

package Memcached::Client::Request::ConnectMulti;
BEGIN {
  $Memcached::Client::Request::ConnectMulti::VERSION = '2.01';
}
# ABSTRACT: Class to manage Memcached::Client connection requests

use Memcached::Client::Log qw{DEBUG};
use base qw{Memcached::Client::Request};


sub process {
    return $_[0];
}


sub server {
    my ($self, $server) = @_;
    my $request = bless {command => "connect", key => $server, sendkey => 1, type => "__connect"}, "Memcached::Client::Request::Connect";
    $request->{cb} = sub {
        my ($key, $value) = @_;
        $self->log ("Noting that we received %s for %s", $value, $key) if DEBUG;
        $self->{result}->{$key} = $value if (defined $value);
        $self->result (1) unless (--$self->{partial});
        $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
    };
    $self->{partial}++;
    $self->log ("%d queries outstanding", $self->{partial}) if DEBUG;
    $request;
}

*Memcached::Client::connect = Memcached::Client::Request::ConnectMulti->generate ("connect");

1;

__END__
=pod

=head1 NAME

Memcached::Client::Request - Base class for Memcached::Client request drivers

=head1 VERSION

version 2.01

=head1 SYNOPSIS

Memcached::Client::Request and its subclasses are responsible for
managing the completion of a given request to the memcached cluster.

=head1 METHODS

=head2 C<generate>

Returns a reference to an anonymous subroutine that creates a new
object in a C<Memcache::Client::Request> subclass, currying in the
command that is specified as the argument to C<generate>, and
expecting to be invoked as a method on a C<Memcache::Client> object.

Each subclass of C<Memcache::Client::Request> is responsible for using
C<generate> to install whatever commands it knows how to implement
into the C<Memcached::Client> namespace.

The resulting subroutine takes a C<Memcache::Client> object as its
first parameter, since it is expected to be called in that context.

It then examines the last argument in the argument list, and if it's a
C<coderef> or an C<AnyEvent::CondVar>, it is removed and stored for
use on completion of the request.  Otherwise, an C<AnyEvent::CondVar>
is created, and the request is marked as needing to manage its own
event looping.

The request's C<process> routine is then called with the remainder of
the arguments, and any returned objects are then handled by the
C<__submit> routine in C<Memcached::Client>.

If C<process> returns no objects, then the submission is assumed to
have failed and the objects C<complete> routine is called to return a
result.

Finally, if the request is marked as needing to manage its own event
looping, it will wait on the C<AnyEvent::CondVar> that it created
earlier.

=head2 C<log>

Log the specified message with an appropriate prefix derived from the
class name.

=head2 C<result>

Intended to be called by the protocol methods, C<result> records the
result value that it is given, if it is given one.

C<complete> is called when the request is finished---regardless of
whether it succeeded or failed---and it is responsible for invoking
the callback to submit the results to their consumer.

If there has been no result gathered, it will return the default if
there is one, otherwise it will return undef.

=head2 C<process>

C<process> accepts a key, value and expiration.  It does some
housekeeping, and assuming the arguments look appropriate, it returns
a reference to itself.

=head2 C<process>

C<process> accepts a reference to an array of arrays containing key,
value and expiration tuples.  For each tuple, it attempts to construct
a C<M::C::Request::Add> object that has a callback that will recognize
when all outstanding requests are in and return the aggregate result.

=head2 C<process>

C<process> accepts a key, delta and initial value.  It does some
housekeeping, and assuming the arguments look appropriate, it returns
a reference to itself.

=head2 C<process>

C<process> accepts a reference to an array of arrays of key, delta and
initial value tuples.  For each tuple, it attempts to construct a
C<M::C::Request::Decr> object that has a callback that will recognize
when all outstanding requests are in and return the aggregate result.

=head2 C<process>

C<process> accepts a key.  It does some housekeeping, and assuming
the arguments look appropriate, it returns a reference to itself.

=head2 C<process>

C<process> accepts a reference to an array of keys.  For each key, it
attempts to construct a C<M::C::Request::Delete> object that has a
callback that will recognize when all outstanding requests are in and
return the aggregate result.

=head2 C<process>

C<process> accepts a key.  It does some housekeeping, and assuming the
arguments look appropriate, it returns a reference to itself.

=head2 C<process>

C<process> accepts a reference to an array of keys.  For each key, it
attempts to construct a C<M::C::Request::Get> object that has a
callback that will recognize when all outstanding requests are in and
return the aggregate result.

=head2 C<process>

C<process> accepts a command and arguments.  It returns it self
assuming a command was specified.

=head2 C<process>

C<process> accepts a command and arguments.  It returns a reference to
itself assuming a command was specified.

=head2 C<server>

C<server> creates a new C<M::C::Request::Broadcast> object
encapsulating the command for a given server.

=head2 C<process>

C<process> accepts a command and arguments.  It returns it self
assuming a command was specified.

=head2 C<process>

C<process> accepts a command and arguments.  It returns it self
assuming a command was specified.

=head2 C<server>

C<server> creates a new C<M::C::Request::Connect> object encapsulating
the command for a given server.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

