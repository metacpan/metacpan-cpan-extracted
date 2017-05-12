package Lim::RPC::Transport::HTTP;

use common::sense;
use Carp;

use Scalar::Util qw(blessed weaken);

use AnyEvent ();
use AnyEvent::Handle ();
use AnyEvent::Socket ();

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();
use URI ();
use Socket;

use Lim ();
use Lim::RPC::TLS ();
use Lim::RPC::Callback ();

use base qw(Lim::RPC::Transport);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=over 4

=item MAX_REQUEST_LEN

=back

=cut

our $VERSION = $Lim::VERSION;

sub MAX_REQUEST_LEN (){ 8 * 1024 * 1024 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 Init

=cut

sub Init {
    my $self = shift;
    my %args = ( @_ );
    my $real_self = $self;
    weaken($self);

    $self->{client} = {};
    $self->{host} = Lim::Config->{rpc}->{transport}->{http}->{host};
    $self->{port} = Lim::Config->{rpc}->{transport}->{http}->{port};

    if (exists $args{uri}) {
        unless (blessed($args{uri}) and $args{uri}->isa('URI')) {
            confess 'uri argument is not a URI class';
        }

        $self->{host} = $args{uri}->host;
        $self->{port} = $args{uri}->port;
    }

    if ($self->isa('Lim::RPC::Transport::HTTPS') and !defined Lim::RPC::TLS->instance->tls_ctx) {
        confess 'using HTTPS but can not create TLS context';
    }

    Lim::Util::resolve_host $self->{host}, $self->{port}, sub {
        my ($host, $port) = @_;

        unless (defined $self) {
            return;
        }

        unless (defined $host and defined $port) {
            Lim::WARN and $self->{logger}->warn('Unable to resolve host ', $self->{host});
            return;
        }

        $self->{host} = $host;
        $self->{port} = $port;
        $self->_connect;
    };
}

=head2 _connect

=cut

sub _connect {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);

    $self->{socket} = AnyEvent::Socket::tcp_server exists $self->{addr} ? $self->{addr} : $self->{host}, $self->{port}, sub {
        my ($fh, $host, $port) = @_;
        my ($sockport, $sockaddr) = AnyEvent::Socket::unpack_sockaddr(getsockname($fh));
        my $sockhost = AnyEvent::Socket::ntoa($sockaddr);

        Lim::RPC_DEBUG and $self->{logger}->debug('Connection from ', $host, ':', $port);

        my $handle;
        $handle = AnyEvent::Handle->new(
            fh => $fh,
            ($self->isa('Lim::RPC::Transport::HTTPS') ? (tls => 'accept', tls_ctx => Lim::RPC::TLS->instance->tls_ctx) : ()),
#            timeout => Lim::Config->{rpc}->{timeout},
            on_error => sub {
                my ($handle, $fatal, $message) = @_;

                unless (defined $self) {
                    return;
                }

                Lim::WARN and $self->{logger}->warn($handle, ' Error: ', $message);

                delete $self->{client}->{$handle};
                $handle->destroy;
            },
            on_timeout => sub {
                my ($handle) = @_;

                unless (defined $self) {
                    return;
                }

                Lim::WARN and $self->{logger}->warn($handle, ' TIMEOUT');

#                my $client = $self->{client}->{$handle};
#
#                if (defined $client) {
#                    if (exists $client->{processing} and exists $client->{protocol}) {
#                        $client->{protocol}->timeout($client->{request});
#                    }
#                }

                delete $self->{client}->{$handle};
                $handle->destroy;
            },
            on_eof => sub {
                my ($handle) = @_;

                unless (defined $self) {
                    return;
                }

                Lim::RPC_DEBUG and $self->{logger}->debug($handle, ' EOF');

                delete $self->{client}->{$handle};
                $handle->destroy;
            },
            on_drain => sub {
                my ($handle) = @_;

                unless (defined $self) {
                    return;
                }

                if ($self->{client}->{$handle}->{close}) {
                    shutdown $handle->{fh}, 2;
                }
            },
            on_read => sub {
                my ($handle) = @_;

                unless (defined $self) {
                    return;
                }

                my $client = $self->{client}->{$handle};

                unless (defined $client) {
                    Lim::WARN and $self->{logger}->warn($handle, ' unknown client');
                    $handle->push_shutdown;
                    $handle->destroy;
                    return;
                }

                if (exists $client->{process_watcher}) {
                    Lim::WARN and $self->{logger}->warn($handle, ' Request received while processing other request');
                    $handle->push_shutdown;
                    $handle->destroy;
                    return;
                }

                if ((length($client->{headers}) + (exists $client->{content} ? length($client->{content}) : 0) + length($handle->{rbuf})) > MAX_REQUEST_LEN) {
                    Lim::WARN and $self->{logger}->warn($handle, ' Request too long');
                    $handle->push_shutdown;
                    $handle->destroy;
                    return;
                }

                unless (exists $client->{content}) {
                    $client->{headers} .= $handle->{rbuf};

                    if ($client->{headers} =~ /\015?\012\015?\012/o) {
                        my ($headers, $content) = split(/\015?\012\015?\012/o, $client->{headers}, 2);
                        $client->{headers} = $headers;
                        $client->{content} = $content;
                        $client->{request} = HTTP::Request->parse($client->{headers});
                        $client->{request}->header('X-Lim-Base-URL' => ($self->isa('Lim::RPC::Transport::HTTPS') ? 'https' : 'http').'://'.$sockhost.':'.$self->{port});
                    }
                }
                else {
                    $client->{content} .= $handle->{rbuf};
                }
                $handle->{rbuf} = '';

                if (defined $client->{request} and length($client->{content}) == $client->{request}->header('Content-Length')) {
                    $client->{request}->content($client->{content});
                    delete $client->{content};
                    $client->{headers} = '';

                    Lim::RPC_DEBUG and $self->{logger}->debug('HTTP Request: ', $client->{request}->as_string);

                    $client->{processing} = 1;
#                    $handle->timeout(Lim::Config->{rpc}->{call_timeout});
                    my $real_client = $client;
                    weaken($client);
                    $client->{process_watcher} = AnyEvent->timer(
                        after => 0,
                        cb => sub {
                            unless (defined $self and defined $client) {
                                return;
                            }

                            my $cb = Lim::RPC::Callback->new(
                                cb => sub {
                                    my ($response) = @_;

                                    unless (defined $self and defined $client) {
                                        return;
                                    }

                                    unless (exists $client->{processing}) {
                                        return;
                                    }

                                    unless (blessed($response) and $response->isa('HTTP::Response')) {
                                        return;
                                    }

                                    unless ($response->code) {
                                        $response->code(HTTP_NOT_FOUND);
                                    }

                                    if ($response->code != HTTP_OK and !length($response->content)) {
                                        $response->header('Content-Type' => 'text/plain; charset=utf-8');
                                        $response->content($response->code.' '.HTTP::Status::status_message($response->code)."\015\012");
                                    }

                                    $response->header('Content-Length' => length($response->content));
                                    unless (defined $response->header('Content-Type')) {
                                        $response->header('Content-Type' => 'text/html; charset=utf-8');
                                    }

                                    unless ($response->protocol) {
                                        $response->protocol('HTTP/1.1');
                                    }

                                    if ($client->{request}->protocol ne 'HTTP/1.1' and lc($client->{request}->header('Connection')) ne 'keep-alive') {
                                        Lim::RPC_DEBUG and $self->{logger}->debug('Connection requested to be closed');
#                                        $client->{handle}->timeout(0);
                                        $response->header('Connection' => 'close');
                                        $client->{close} = 1;
                                    }
                                    else {
#                                        $client->{handle}->timeout(Lim::Config->{rpc}->{timeout});
                                        $response->header('Connection' => 'keep-alive');
                                    }

                                    Lim::RPC_DEBUG and $self->{logger}->debug('HTTP Response: ', $response->as_string);
                                    $client->{handle}->push_write($response->as_string("\015\012"));

                                    delete $client->{processing};
                                    delete $client->{request};
                                    delete $client->{response};
                                    delete $client->{process_watcher};
                                    delete $client->{protocol};
                                },
                                reset_timeout => sub {
                                    unless (defined $client) {
                                        return;
                                    }

#                                    $client->{handle}->timeout_reset;
                                });

                            foreach my $protocol ($self->protocols) {
                                Lim::RPC_DEBUG and $self->{logger}->debug('Trying protocol ', $protocol->name);
                                if ($protocol->handle($cb, $client->{request}, $self)) {
                                    $client->{protocol} = $protocol;
                                    Lim::RPC_DEBUG and $self->{logger}->debug('Request handled by protocol ', $protocol->name);
                                    return;
                                }
                            }
                            Lim::RPC_DEBUG and $self->{logger}->debug('Did not find any protocol handler for request');
                            my $response = HTTP::Response->new;
                            $response->request($client->{request});
                            $response->protocol($client->{request}->protocol);
                            $cb->cb->($response);
                        });
                }
            });

        $self->{client}->{$handle} = {
            handle => $handle,
            headers => '',
            close => 0
        };
    }, sub {
        my (undef, $host, $port) = @_;

        Lim::RPC_DEBUG and $self->{logger}->debug(__PACKAGE__, ' ', $self, ' ready at ', $host, ':', $port);

        $self->{real_host} = $host;
        $self->{real_port} = $port;

        $self->{uri} = URI->new(
            ($self->isa('Lim::RPC::Transport::HTTPS') ? 'https://' : 'http://').
            $host.':'.$port);
        $Lim::CONFIG->{rpc}->{srv_listen};
    };
}

=head2 Destroy

=cut

sub Destroy {
    my ($self) = @_;

    delete $self->{client};
    delete $self->{socket};
}

=head2 name

=cut

sub name {
    'http';
}

=head2 uri

=cut

sub uri {
    $_[0]->{uri};
}

=head2 host

=cut

sub host {
    $_[0]->{real_host};
}

=head2 port

=cut

sub port {
    $_[0]->{real_port};
}

=head2 serve

=cut

sub serve {
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Transport::HTTP
