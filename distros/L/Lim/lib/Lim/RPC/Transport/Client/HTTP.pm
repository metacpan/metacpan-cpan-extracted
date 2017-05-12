package Lim::RPC::Transport::Client::HTTP;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);

use AnyEvent ();
use AnyEvent::Socket ();
use AnyEvent::Handle ();

use HTTP::Request ();
use HTTP::Response ();
use HTTP::Status qw(:constants);

use Lim ();
use Lim::Error ();
use Lim::RPC::TLS ();
use Lim::Util ();

use base qw(Lim::RPC::Transport::Client);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=over 4

=item MAX_RESPONSE_LEN

=back

=cut

our $VERSION = $Lim::VERSION;

sub MAX_RESPONSE_LEN (){ 8 * 1024 * 1024 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 Init

=cut

sub Init {
    my ($self) = @_;

    if ($self->isa('Lim::RPC::Transport::Client::HTTPS') and !defined Lim::RPC::TLS->instance->tls_ctx) {
        confess 'using HTTPS but can not create TLS context';
    }
}

=head2 name

=cut

sub name {
    'http';
}

=head2 request

=cut

sub request {
    my $self = shift;
    my %args = ( @_ );
    my $real_self = $self;
    weaken($self);

    $self->{rbuf} = '';
    $self->{host} = 'localhost';
    $self->{port} = $self->isa('Lim::RPC::Transport::Client::HTTPS') ? 443 : 80;

    unless (blessed $args{request} and $args{request}->isa('HTTP::Request')) {
        confess __PACKAGE__, ': No request or not HTTP::Request';
    }

    foreach (qw(host port)) {
        if (defined $args{$_}) {
            $self->{$_} = $args{$_};
        }
    }
    if (defined $args{cb} and ref($args{cb}) eq 'CODE') {
        $self->{cb} = $args{cb};
    }
    $self->{request} = $args{request};
    $self->{request}->protocol('HTTP/1.1');

    Lim::Util::resolve_host $self->{host}, $self->{port}, sub {
        my ($host, $port) = @_;

        unless (defined $self) {
            return;
        }

        unless (defined $host and defined $port) {
            Lim::WARN and $self->{logger}->warn('Unable to resolve host ', $self->{host});
            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Unable to resolve host '.$self->{host},
                    module => $self
                ));
                delete $self->{cb};
            }
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

    $self->{socket} = AnyEvent::Socket::tcp_connect $self->{host}, $self->{port}, sub {
        my ($fh, $host, $port) = @_;

        unless (defined $self) {
            return;
        }

        unless (defined $fh) {
            Lim::WARN and $self->{logger}->warn('No handle: ', $!);

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => $!,
                    module => $self
                ));
                delete $self->{cb};
            }
            return;
        }

        my $handle;
        $handle = AnyEvent::Handle->new(
            fh => $fh,
            ($self->isa('Lim::RPC::Transport::Client::HTTPS') ? (tls => 'connect', tls_ctx => Lim::RPC::TLS->instance->tls_ctx) : ()),
            timeout => Lim::Config->{rpc}->{timeout},
            on_error => sub {
                my ($handle, $fatal, $message) = @_;

                unless (defined $self) {
                    return;
                }

                Lim::WARN and $self->{logger}->warn($handle, ' Error: ', $message);
                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        message => $message,
                        module => $self
                    ));
                    delete $self->{cb};
                }
                $handle->destroy;
            },
            on_timeout => sub {
                my ($handle) = @_;

                unless (defined $self) {
                    return;
                }

                Lim::WARN and $self->{logger}->warn($handle, ' TIMEOUT');

                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        code => HTTP_REQUEST_TIMEOUT,
                        message => 'Request timed out',
                        module => $self
                    ));
                    delete $self->{cb};
                }
                $handle->destroy;
            },
            on_eof => sub {
                my ($handle) = @_;

                unless (defined $self) {
                    return;
                }

                Lim::WARN and $self->{logger}->warn($handle, ' EOF');

                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        code => HTTP_GONE,
                        message => 'Connection closed',
                        module => $self
                    ));
                    delete $self->{cb};
                }
                $handle->destroy;
            },
            on_read => sub {
                my ($handle) = @_;

                unless (defined $self) {
                    return;
                }

                if ((length($self->{headers}) + (exists $self->{content} ? length($self->{content}) : 0) + length($handle->{rbuf})) > MAX_RESPONSE_LEN) {
                    if (exists $self->{cb}) {
                        $self->{cb}->($self, Lim::Error->new(
                            code => HTTP_REQUEST_ENTITY_TOO_LARGE,
                            message => 'Request too large',
                            module => $self
                        ));
                        delete $self->{cb};
                    }
                    $handle->push_shutdown;
                    $handle->destroy;
                    return;
                }

                unless (exists $self->{content}) {
                    $self->{headers} .= $handle->{rbuf};

                    if ($self->{headers} =~ /\015?\012\015?\012/o) {
                        my ($headers, $content) = split(/\015?\012\015?\012/o, $self->{headers}, 2);
                        $self->{headers} = $headers;
                        $self->{content} = $content;
                        $self->{response} = HTTP::Response->parse($self->{headers});
                    }
                }
                else {
                    $self->{content} .= $handle->{rbuf};
                }
                $handle->{rbuf} = '';

                if (defined $self->{response} and length($self->{content}) == $self->{response}->header('Content-Length')) {
                    my $response = $self->{response};
                    $response->content($self->{content});
                    delete $self->{response};
                    delete $self->{content};
                    $self->{headers} = '';

                    if (exists $self->{cb}) {
                        $self->{cb}->($self, $response);
                        delete $self->{cb};
                    }
                    $handle->push_shutdown;
                    $handle->destroy;
                }
            });

        $self->{handle} = $handle;
        $handle->push_write($self->{request}->as_string("\015\012"));
    };
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

1; # End of Lim::RPC::Transport::Client::HTTP
