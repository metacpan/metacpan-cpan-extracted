#
# This file is part of Log-Dispatch-Socket
#
# This software is copyright (c) 2012 by Loïc TROCHET.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Log::Dispatch::Socket;
{
  $Log::Dispatch::Socket::VERSION = '0.130020';
}
# ABSTRACT: Subclass of Log::Dispatch::Output that log messages to a socket

use strict;
use warnings;

use IO::Socket::INET;
use Params::Validate qw(validate SCALAR);

use Log::Dispatch::Output;
use parent qw(Log::Dispatch::Output);

Params::Validate::validation_options( allow_extra => 1 );


sub new
{
    my $this = shift;
    my $class = ref $this || $this;

    my $self = validate
    (
        @_
    ,   {
            PeerHost   => { type => SCALAR, default => 'localhost' }
        ,   PeerPort   => { type => SCALAR                         }
        ,   Proto      => { type => SCALAR, default =>       'tcp' }
        }
    );

    bless $self, $class;

    $self->_basic_init(%$self);

    $self->{Attempt} = 0;
    $self->{Socket} = undef;

    die "Connect to '$self->{PeerHost}:$self->{PeerPort}' failed: $!"
        unless $self->_connect(%$self);

    return $self;
}

sub _connect
{
    my $self = shift;
    return $self->{Socket} = IO::Socket::INET->new(@_);
}

sub _disconnect
{
    my $self = shift;

    if (defined $self->{Socket})
    {
        eval { close $self->{Socket}; };
        undef $self->{Socket};
    }
}


sub log_message
{
    my ($self, %params) = @_;

    RETRY:
    {
        unless (defined $self->{Socket})
        {
            return if $self->{Attempt};
            $self->{Attempt} += 1;
            unless ($self->_connect(%$self))
            {
                die "Disconnect from '$self->{PeerHost}:$self->{PeerPort}'";
                return;
            }
            $self->{Attempt} = 0;
        }

        eval { $self->{Socket}->send($params{message}); };

        if ($@)
        {
            $self->_disconnect;
            redo RETRY;
        }
    }
}


sub DESTROY
{
    $_[0]->_disconnect;
}

1;

__END__

=pod

=head1 NAME

Log::Dispatch::Socket - Subclass of Log::Dispatch::Output that log messages to a socket

=head1 VERSION

version 0.130020

=head1 SYNOPSIS

    use Log::Dispatch;

    my $log = Log::Dispatch->new(
        outputs => [
            [
                'Socket'
            ,   PeerHost  => 'server.foo.com'
            ,   PeerPort  => 9876
            ,   Proto     => 'tcp'
            ,   min_level => 'info'
            ]
        ]
    );

    $log->info("Sorry for my (poor/beginner's/basic) English.");

=head1 DESCRIPTION

This module provides, under the L<Log::Dispatch>::* system, a simple object to write messages to a socket listening on
some remote host.

It relies on L<IO::Socket::INET> and offers all parameters this module offers.

If this module cannot contact the server during the initialization phase (while running the constructor new),
it will die().

If this module fails to log a message because the socket's send() method fails , it will try to reconnect once.
If it succeeds, the message will be sent. If the reconnect fails, this module will die().

=head1 METHODS

=head2 new

The constructor offers all L<IO::Socket::INET> parameters in addition to the standard parameters documented
in L<Log::Dispatch::Output>:

=head2 log_message(level => $, message => $)

Sends a message if the level is greater than or equal to the object's minimum level.

=head2 DESTROY

We disconnect on destruction if it is necessary.

=head1 SEE ALSO

L<Log::Dispatch>

L<Log::Dispatch::UDP>

L<Log::Log4perl::Appender::Socket>

=encoding utf8

=head1 AUTHOR

Loïc TROCHET <losyme@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Loïc TROCHET.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
