package Memcached::Client::Connection;
BEGIN {
  $Memcached::Client::Connection::VERSION = '2.01';
}
# ABSTRACT: Class to manage Memcached::Client server connections

use strict;
use warnings;
use AnyEvent qw{};
use AnyEvent::Handle qw{};
use Memcached::Client::Log qw{DEBUG LOG};


sub new {
    my ($class, $server, $protocol) = @_;
    die "You must give me a server to connect to.\n" unless ($server);
    die "You must give me a protocol to use.\n" unless ($protocol);
    $server .= ":11211" unless 0 < index $server, ':';
    my $self = {attempts => 0, protocol => $protocol, queue => [], server => $server};
    bless $self, $class;
}


sub log {
    my ($self, $format, @args) = @_;
    LOG ("Connection/%s> " . $format, $self->{server}, @args);
}


sub connect {
    my ($self) = @_;
    unless ($self->{handle}) {
        $self->log ("Initiating connection", $self->{server}) if DEBUG;
        $self->{handle} = AnyEvent::Handle->new (connect => [split /:/, $self->{server}],
                                                 keepalive => 1,
                                                 on_connect => sub {
                                                     $self->log ("Connected") if DEBUG;
                                                     $self->{attempts} = 0;
                                                     $self->dequeue;
                                                 },
                                                 on_error => sub {
                                                     my ($handle, $fatal, $message) = @_;
                                                     $self->log ("Removing handle") if DEBUG;
                                                     delete $self->{handle};
                                                     if ($message eq "Broken pipe") {
                                                         $self->log ("Broken pipe, reconnecting") if DEBUG;
                                                         $self->connect;
                                                     } elsif ($message eq "Connection timed out" and ++$self->{attempts} < 5) {
                                                         $self->log ("Connection timed out, retrying") if DEBUG;
                                                         $self->connect;
                                                     } else {
                                                         $self->log ("Error %s, failing", $message) if DEBUG;
                                                         $self->fail;
                                                     }
                                                 },
                                                 on_prepare => sub {
                                                     my ($handle) = @_;
                                                     $self->log ("Preparing handle") if DEBUG;
                                                     $self->{protocol}->prepare_handle ($handle) if ($self->{protocol}->can ("prepare_handle"));
                                                     return $self->{connect_timeout} || 0.5;
                                                 });
    }
}


sub disconnect {
    my ($self) = @_;

    $self->log ("Disconnecting") if DEBUG;
    if (my $handle = delete $self->{handle}) {
        $self->log ("Shutting down handle") if DEBUG;
        $handle->destroy();
    }

    $self->log ("Failing all requests") if DEBUG;
    $self->fail;
}


sub enqueue {
    my ($self, $request) = @_;
    $self->log ("Request is %s", $request) if DEBUG;
    push @{$self->{queue}}, $request;
    $self->dequeue;
}


sub dequeue {
    my ($self) = @_;
    if ($self->{handle}) {
        return if ($self->{executing});
        if ($self->{executing} = shift @{$self->{queue}}) {
            $self->log ("Initiating request") if DEBUG;
            my $command = $self->{executing}->{type};
            $self->{protocol}->$command ($self, $self->{executing});
        }
    } else {
        $self->connect;
    }
}


sub complete {
    my ($self) = @_;
    $self->log ("Done with request") if DEBUG;
    delete $self->{executing};
    goto &dequeue;
}


sub fail {
    my ($self) = @_;
    $self->log ("Checking for executing request") if DEBUG;
    if (my $executing = delete $self->{executing}) {
        $self->log ("Failing executing request %s", $executing) if DEBUG;
        $executing->result;
    }
    $self->log ("Failing requests in queue: %s", $self->{queue}) if DEBUG;
    while (my $request = shift @{$self->{queue}}) {
        $self->log ("Failing request %s", $request) if DEBUG;
        $request->result;
    }
}

1;

__END__
=pod

=head1 NAME

Memcached::Client::Connection - Class to manage Memcached::Client server connections

=head1 VERSION

version 2.01

=head1 SYNOPSIS

  use Memcached::Client::Connection;
  my $connection = Memcached::Client::Connection->new ("server:port");
  $connection->enqueue ($request);

=head1 DESCRIPTION

A C<Memcached::Client::Connection> object is responsible for managing
a connection to a particular memcached server, and a queue of requests
destined for that server.

Connections are, by default, made lazily.

The connection handler will try to automatically reconnect several
times on connection failure, only returning failure responses for all
queued requests as a last resort.

=head1 METHODS

=head2 new

C<new()> builds a new connection object.  The object is constructed
and returned immediately.

Takes two parameters: one is the server specification, in the form of
"hostname" or "hostname:port".  If no port is specified, ":11211" (the
default memcached port) is appended to the server name.

The other, optional, parameter is a subroutine reference that will be
invoked on the raw filehandle before connection.  Generally only
useful for putting the filehandle in binary mode.

No connection is initiated at construction time, because that would
require that we perhaps accept a callback to signal completion, or
create a condvar, etc.  Simpler to lazily construct the connection
when the conditions are already right for doing our asynchronous
dance.

=head2 log

=head2 connect

C<connect()> initiates a connection to the specified server.

If it succeeds in connecting, it will start sending requests for the
server to satisfy.

If it fails, it will respond to all outstanding requests by invoking
their failback routine.

=head2 disconnect

C<disconnect> will disconnect any extant handle from the server it is
connected to, destroy it, and then fail all queued requests.

=head2 enqueue

C<enqueue()> adds the specified request object to the queue of
requests to be processed, if there is already a request in progress,
otherwise, it begins execution of the specified request.  If
necessary, it will initiate connection to the server as well.

=head2 dequeue

C<dequeue()> checks to see if there's already a request processing,
and if so, it simply returns (when that request finishes, it will call
->complete, which will call dequeue).

If nothing is processing, it will attempt to pull the next item from
the queue and start it processing.

=head2 complete

=head2 fail

C<fail()> is called when there is an error on the handle, and it
invokes the failbacks of all queued requests.

=head1 AUTHOR

Michael Alan Dorman <mdorman@ironicdesign.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Michael Alan Dorman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

