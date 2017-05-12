package JSONRPC::Transport::TCP;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/result error/);

use IO::Select;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Carp;

our $VERSION = '0.04';
our $XS_AVAILABLE = 1;

BEGIN {
    eval { require JSON::XS };
    if ($@) {
        $XS_AVAILABLE = 0;
        require JSON;
    }
}

=for stopwords Hostname Str tcp ip unix

=head1 NAME

JSONRPC::Transport::TCP - Client component for TCP JSONRPC

=head1 SYNOPSIS

    use JSONRPC::Transport::TCP;
    
    my $rpc = JSONRPC::Transport::TCP->new( host => '127.0.0.1', port => 3000 );
    my $res = $rpc->call('echo', 'arg1', 'arg2' )
        or die $rpc->error;
    
    print $res->result;

=head1 DESCRIPTION

This module is a simple client side implementation about JSONRPC via TCP.

This module doesn't support continual tcp streams, and so it open/close connection on each request.

=head1 METHODS

=head2 new

Create new client object.

Parameters:

=over

=item host => 'Str'

Hostname or ip address to connect.

This should be set 'unix/' when you want to connect to unix socket.

=item port => 'Int | Str'

Port number or unix socket path to connect

=back

=cut

sub new {
    my $self = shift->SUPER::new( @_ > 1 ? {@_} : $_[0] );

    $self->{id} = 0;
    $self->{json} ||= $XS_AVAILABLE ? JSON::XS->new->utf8 : JSON->new->utf8;
    $self->{delimiter} ||= q[];

    $self;
}

=head2 connect

Connect remote host.

This module automatically connect on following "call" method, so you have not to call this method.

=cut

sub connect {
    my $self = shift;
    my $params = @_ > 1 ? {@_} : $_[0];

    $self->disconnect if $self->{socket};

    my $socket;
    eval {
        # unix socket
        my $host = $params->{host} || $self->{host};
        my $port = $params->{port} || $self->{port};

        if ($host eq 'unix/') {
            $socket = IO::Socket::UNIX->new(
                Peer    => $port,
                Timeout => $self->{timeout} || 30,
            ) or croak qq/Unable to connect to unix socket "$port": $!/;
        }
        else {
            $socket = IO::Socket::INET->new(
                PeerAddr => $host,
                PeerPort => $port,
                Proto    => 'tcp',
                Timeout  => $self->{timeout} || 30,
            )
                or croak
                    qq/Unable to connect to "@{[ $params->{host}  || $self->{host} ]}:@{[ $params->{port}  || $self->{port} ]}": $!/;
        }

        $socket->autoflush(1);

        $self->{socket} = $socket;
    };
    if ($@) {
        $self->{error} = $@;
        return;
    }

    1;
}

=head2 disconnect

Disconnect the connection

=cut

sub disconnect {
    my $self = shift;
    delete $self->{socket} if $self->{socket};
}

=head2 call($method_name, @params)

Call remote method.

When remote method is success, it returns self object that contains result as ->result accessor.

If some error are occurred, it returns undef, and you can check the error by ->error accessor.

Parameters:

=over

=item $method_name

Remote method name to call

=item @params

Remote method parameters.

=back

=cut

sub call {
    my ($self, $method, @params) = @_;

    $self->connect unless $self->{socket};
    return unless $self->{socket};

    my $request = {
        id     => ++$self->{id},
        method => $method,
        params => \@params,
    };
    $self->{socket}->print($self->{json}->encode($request) . $self->{delimiter});

    my $timeout = $self->{socket}->timeout;
    my $limit   = time + $timeout;

    my $select = IO::Select->new or croak $!;
    $select->add($self->{socket});

    my $buf = '';

    while ($limit >= time) {
        my @ready = $select->can_read( $limit - time )
            or last;

        for my $s (@ready) {
            croak qq/$s isn't $self->{socket}/ unless $s eq $self->{socket};
        }

        unless (my $l = $self->{socket}->sysread( $buf, 512, length($buf) )) {
            my $e = $!;
            $self->disconnect;
            croak qq/Error reading: $e/;
        }

        my $json = eval { $self->{json}->incr_parse($buf) };

        if ($@) {
            $self->{error} = $@;
            $self->disconnect;
            return;
        }
        elsif ($json) {
            if ($json->{error}) {
                $self->{error} = $json->{error};
                $self->disconnect;
                return;
            }
            else {
                $self->{result} = $json->{result};
                $self->disconnect;
                return $self;
            }
        }
        else {
            $buf = '';
            next;
        }
    }

    croak "request timeout";
}

=head2 DESTROY

Automatically disconnect when object destroy.

=cut

sub DESTROY {
    my $self = shift;
    $self->disconnect;
}

=head1 ACCESSORS

=head2 result

Contains result of remote method

=head2 error

Contains error of remote method

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
