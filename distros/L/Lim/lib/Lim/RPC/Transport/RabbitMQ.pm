package Lim::RPC::Transport::RabbitMQ;

use common::sense;
use Carp;

use Scalar::Util qw(blessed weaken);

use AnyEvent ();
eval 'use AnyEvent::RabbitMQ ();';
undef $@;

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();

use Lim ();
use Lim::RPC::Callback ();
use Lim::Util ();

use base qw(Lim::RPC::Transport);

=encoding utf8

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

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

    $self->{channel} = {};
    $self->{host} = 'localhost';
    $self->{port} = 5672;
    $self->{user} = 'guest';
    $self->{pass} = 'guest';
    $self->{vhost} = '/';
    $self->{timeout} = 10;
    $self->{queue_prefix} = 'lim_';
    $self->{verbose} = 0;
    $self->{prefetch_count} = 1;
    $self->{broadcast} = 0;
    $self->{exchange_prefix} = 'lim_exchange_';
    $self->{retry_interval} = 5;
    $self->{closing} = 0;

    foreach (qw(host port user pass vhost timeout queue_prefix verbose prefetch_count broadcast exchange_prefix retry_interval)) {
        if (defined Lim::Config->{rpc}->{transport}->{rabbitmq}->{$_}) {
            $self->{$_} = Lim::Config->{rpc}->{transport}->{rabbitmq}->{$_};
        }
    }
    foreach (qw(host port user pass vhost timeout queue_prefix verbose prefetch_count broadcast exchange_prefix retry_interval)) {
        if (defined $args{$_}) {
            $self->{$_} = $args{$_};
        }
    }

    if (exists $args{uri}) {
        unless (blessed($args{uri}) and $args{uri}->isa('URI')) {
            confess 'uri argument is not a URI class';
        }

        $self->{host} = $args{uri}->host;
        $self->{port} = $args{uri}->port;
    }

    eval {
        $self->{rabbitmq} = AnyEvent::RabbitMQ->new(verbose => $self->{verbose})->load_xml_spec;
    };
    if ($@) {
        confess 'Failed to initiate AnyEvent::RabbitMQ: '.$@;
    }
    unless (blessed $self->{rabbitmq} and $self->{rabbitmq}->isa('AnyEvent::RabbitMQ')) {
        confess 'unable to create AnyEvent::RabbitMQ object';
    }

    $self->_resolve;
}

=head2 _resolve

=cut

sub _resolve {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);

    Lim::RPC_DEBUG and $self->{logger}->debug('Resolving ', $self->{host}, '...');

    Lim::Util::resolve_host $self->{host}, $self->{port}, sub {
        my ($host, $port) = @_;

        unless (defined $self) {
            return;
        }

        unless (defined $host and defined $port) {
            Lim::WARN and $self->{logger}->warn('Unable to resolve host ', $self->{host});
            $self->{retry} = AnyEvent->timer(after => $self->{retry_interval}, cb => sub {
                unless (defined $self) {
                    return;
                }

                $self->_resolve;
            });
            return;
        }

        $self->{host} = $host;
        $self->{port} = $port;
        $self->{uri} = URI->new('rabbitmq://'.$host.':'.$port);
        $self->_connect;
    };
}

=head2 _connect

=cut

sub _connect {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);

    Lim::RPC_DEBUG and $self->{logger}->debug('Server connecting...');

    unless (exists $self->{rabbitmq}) {
        $self->{rabbitmq} = AnyEvent::RabbitMQ->new(verbose => $self->{verbose})->load_xml_spec;
    }

    $self->{closing} = 0;
    $self->{rabbitmq}->connect(
        (map { $_ => $self->{$_} } qw(host port user pass vhost timeout)),
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Server connected successfully');

            foreach my $channel (values %{$self->{channel}}) {
                if (exists $channel->{obj}) {
                    next;
                }
                $self->_open($channel);
            }
        },
        on_failure => sub {
            my (undef, $fatal, $message) = @_;

            unless (defined $self) {
                return;
            }

            if ($fatal) {
                Lim::ERR and $self->{logger}->error('Server connection failure: '.$message);
            }
            else {
                Lim::WARN and $self->{logger}->warn('Server connection failure: '.$message);
            }
            $self->{retry} = AnyEvent->timer(after => $self->{retry_interval}, cb => sub {
                unless (defined $self) {
                    return;
                }

                $self->close(sub {
                    unless ($self->{rabbitmq}->{_state}) {
                        $self->{rabbitmq}->{_state} = 1;
                    }
                    delete $self->{rabbitmq};
                    $self->_connect;
                });
            });
        },
        on_close => sub {
            my ($frame) = @_;

            unless (defined $self) {
                return;
            }

            my $message = 'Unknown';
            if (blessed $frame
                and $frame->can('method_frame')
                and blessed $frame->method_frame
                and $frame->method_frame->can('reply_code')
                and $frame->method_frame->can('reply_text'))
            {
                $message = '['.$frame->method_frame->reply_code.'] '.$frame->method_frame->reply_text;
            }
            elsif (defined $frame) {
                $message = $frame;
            }

            Lim::INFO and $self->{logger}->info('Server connection closed: '.$message);
            $self->{retry} = AnyEvent->timer(after => $self->{retry_interval}, cb => sub {
                unless (defined $self) {
                    return;
                }

                $self->close(sub {
                    unless ($self->{rabbitmq}->{_state}) {
                        $self->{rabbitmq}->{_state} = 1;
                    }
                    delete $self->{rabbitmq};
                    $self->_connect;
                });
            });
        },
        on_read_failure => sub {
            unless (defined $self) {
                return;
            }

            my ($message) = @_;
            Lim::WARN and $self->{logger}->warn('Server read failure: '.$message);
        }
    );
}

=head2 Destroy

=cut

sub Destroy {
    my ($self) = @_;

    unless ($self->{rabbitmq}->{_state}) {
        $self->{rabbitmq}->{_state} = 1;
    }
    delete $self->{rabbitmq};
}

=head2 name

=cut

sub name {
    'rabbitmq';
}

=head2 uri

=cut

sub uri {
    $_[0]->{uri};
}

=head2 host

=cut

sub host {
    $_[0]->{host};
}

=head2 port

=cut

sub port {
    $_[0]->{port};
}

=head2 serve

=cut

sub serve {
    my ($self, $module, $module_shortname) = @_;
    my $real_self = $self;
    weaken($self);

    unless (defined $module_shortname) {
        confess '$module_shortname not set';
    }

    if (exists $self->{channel}->{$module_shortname}) {
        Lim::WARN and $self->{logger}->warn('Already serving '.$module_shortname);
        return;
    }

    $self->{channel}->{$module_shortname} = {
        module => $module_shortname
    };

    if ($self->{rabbitmq}->is_open) {
        $self->_open($self->{channel}->{$module_shortname});
    }
}

=head2 _reopen

=cut

sub _reopen {
    my ($self, $channel) = @_;
    my $real_self = $self;
    weaken($self);

    unless (ref($channel) eq 'HASH') {
        confess '$channel is not HASH';
    }

    delete $channel->{obj};
    delete $channel->{queue};
    my $w; $w = AnyEvent->timer(after => 1, cb => sub {
        unless (defined $self) {
            return;
        }

        if ($self->{rabbitmq}->is_open) {
            $self->_open($channel);
        }
        $w = undef;
    });
}

=head2 _open

=cut

sub _open {
    my ($self, $channel) = @_;
    my $real_self = $self;
    weaken($self);

    unless (ref($channel) eq 'HASH') {
        confess '$channel is not HASH';
    }

    $channel->{obj} = 1;
    $self->{rabbitmq}->open_channel(
        on_success => sub {
            my ($obj) = @_;

            unless (defined $self) {
                return;
            }

            unless (blessed $obj and $obj->isa('AnyEvent::RabbitMQ::Channel')) {
                Lim::ERR and $self->{logger}->error('Channel open failure for '.$channel->{module}.': object given to on_success is not AnyEvent::RabbitMQ::Channel');
                return;
            }

            $channel->{obj} = $obj;
            Lim::RPC_DEBUG and $self->{logger}->debug('Channel opened successfully for '.$channel->{module});
            $self->_qos($channel);
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel open failure for '.$channel->{module}.': '.$message);
            $self->_reopen($channel);
        },
        on_close => sub {
            my ($frame) = @_;

            unless (defined $self) {
                return;
            }

            my $message = 'Unknown';
            if (blessed $frame
                and $frame->can('method_frame')
                and blessed $frame->method_frame
                and $frame->method_frame->can('reply_code')
                and $frame->method_frame->can('reply_text'))
            {
                $message = '['.$frame->method_frame->reply_code.'] '.$frame->method_frame->reply_text;
            }

            Lim::INFO and $self->{logger}->info('Channel closed for '.$channel->{module}.': '.$message);
            $self->_reopen($channel);
        },
        on_return => sub {
            my ($frame) = @_;

            my $message = 'Unknown';
            if (blessed $frame
                and $frame->can('method_frame')
                and blessed $frame->method_frame
                and $frame->method_frame->can('reply_code')
                and $frame->method_frame->can('reply_text'))
            {
                $message = '['.$frame->method_frame->reply_code.'] '.$frame->method_frame->reply_text;
            }

            Lim::WARN and $self->{logger}->warn('Frame returned: '.$message);
        }
    );
}

=head2 _qos

=cut

sub _qos {
    my ($self, $channel) = @_;
    my $real_self = $self;
    weaken($self);

    unless (ref($channel) eq 'HASH') {
        confess '$channel is not HASH';
    }
    unless (blessed $channel->{obj} and $channel->{obj}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$channel->{obj} is not AnyEvent::RabbitMQ::Channel';
    }

    $channel->{obj}->qos(
        prefetch_count => $self->{prefetch_count},
        on_success => sub {
            my ($obj) = @_;

            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel QoS setup successfully for '.$channel->{module});
            $self->_exchange($channel);
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel QoS setup failure for '.$channel->{module}.': '.$message);
            $self->_reopen($channel);
        }
    );
}

=head2 _exchange

=cut

sub _exchange {
    my ($self, $channel) = @_;
    my $real_self = $self;
    weaken($self);

    unless ($self->{broadcast}) {
        $self->_declare($channel);
        return;
    }

    unless (ref($channel) eq 'HASH') {
        confess '$channel is not HASH';
    }
    unless (blessed $channel->{obj} and $channel->{obj}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$channel->{obj} is not AnyEvent::RabbitMQ::Channel';
    }

    $channel->{obj}->declare_exchange(
        exchange => $self->{exchange_prefix}.$channel->{module},
        type => 'fanout',
        auto_delete => 1,
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel exchange declared successfully for '.$channel->{module});
            $self->_declare($channel);
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel exchange declare failure for '.$channel->{module}.': '.$message);
            $self->_reopen($channel);
        }
    );
}

=head2 _declare

=cut

sub _declare {
    my ($self, $channel) = @_;
    my $real_self = $self;
    weaken($self);

    unless (ref($channel) eq 'HASH') {
        confess '$channel is not HASH';
    }
    unless (blessed $channel->{obj} and $channel->{obj}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$channel->{obj} is not AnyEvent::RabbitMQ::Channel';
    }

    $channel->{obj}->declare_queue(
        ($self->{broadcast} ? (
            exclusive => 1
        ) : (
            queue => $self->{queue_prefix}.$channel->{module}
        )),
        auto_delete => 1,
        on_success => sub {
            my ($method) = @_;

            unless (defined $self) {
                return;
            }

            if ($self->{broadcast}) {
                unless (blessed $method and $method->can('method_frame')
                    and blessed $method->method_frame and $method->method_frame->can('queue'))
                {
                    Lim::ERR and $self->{logger}->error('Declare queue frame invalid for '.$channel->{module});
                    $self->_reopen($channel);
                    return;
                }

                $channel->{queue} = $method->method_frame->queue;
            }
            else {
                $channel->{queue} = $self->{queue_prefix}.$channel->{module};
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel queue declared successfully for '.$channel->{module});
            $self->_bind($channel);
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel queue declare failure for '.$channel->{module}.': '.$message);
            $self->_reopen($channel);
        }
    );
}

=head2 _bind

=cut

sub _bind {
    my ($self, $channel) = @_;
    my $real_self = $self;
    weaken($self);

    unless ($self->{broadcast}) {
        $self->_consume($channel);
        return;
    }

    unless (ref($channel) eq 'HASH') {
        confess '$channel is not HASH';
    }
    unless (blessed $channel->{obj} and $channel->{obj}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$channel->{obj} is not AnyEvent::RabbitMQ::Channel';
    }
    unless (defined $channel->{queue}) {
        confess '$channel->{queue} is not defined';
    }

    $channel->{obj}->bind_queue(
        exchange => $self->{exchange_prefix}.$channel->{module},
        queue => $channel->{queue},
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel queue declared successfully for '.$channel->{module});
            $self->_consume($channel);
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel queue declare failure for '.$channel->{module}.': '.$message);
            $self->_reopen($channel);
        }
    );
}

=head2 _consume

=cut

sub _consume {
    my ($self, $channel) = @_;
    my $real_self = $self;
    weaken($self);

    unless (ref($channel) eq 'HASH') {
        confess '$channel is not HASH';
    }
    unless (blessed $channel->{obj} and $channel->{obj}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$channel->{obj} is not AnyEvent::RabbitMQ::Channel';
    }
    unless (defined $channel->{queue}) {
        confess '$channel->{queue} is not defined';
    }

    $channel->{obj}->consume(
        queue => $channel->{queue},
        no_ack => 0,
        on_success => sub {
            my ($method) = @_;

            unless (defined $self) {
                return;
            }

            unless (blessed $method and $method->can('method_frame')
                and blessed $method->method_frame and $method->method_frame->can('consumer_tag'))
            {
                Lim::WARN and $self->{logger}->debug('Channel consuming for '.$channel->{module}.' but no consumer_tag found');
            }
            else {
                Lim::RPC_DEBUG and $self->{logger}->debug('Channel consuming successfully for '.$channel->{module});
                $channel->{consumer_tag} = $method->method_frame->consumer_tag;
            }
        },
        on_consume => sub {
            my ($frame) = @_;

            unless (defined $self and defined $channel->{obj}) {
                return;
            }

            unless (ref($frame) eq 'HASH'
                and blessed $frame->{deliver} and $frame->{deliver}->can('method_frame')
                and blessed $frame->{deliver}->method_frame and $frame->{deliver}->method_frame->can('delivery_tag'))
            {
                Lim::ERR and $self->{logger}->error('Consume request invalid, may go unacked');
                return;
            }

            unless (blessed $frame->{body} and $frame->{body}->can('payload')) {
                Lim::ERR and $self->{logger}->error('Consume request invalid, no payload');
                return;
            }

            my $headers = HTTP::Headers->new;
            if (blessed $frame->{header} and $frame->{header}->can('headers') and ref($frame->{header}->headers) eq 'HASH') {
                $headers->header(%{$frame->{header}->headers});
            }
            my $request = HTTP::Request->new(
                GET => '/'.$channel->{module},
                $headers,
                $frame->{body}->payload
            );

            Lim::RPC_DEBUG and $self->{logger}->debug('RabbitMQ request: ', $request->as_string);

            my $cb = Lim::RPC::Callback->new(
                cb => sub {
                    my ($response) = @_;

                    unless (defined $self and defined $channel->{obj}) {
                        return;
                    }

                    if (!$self->{broadcast}
                        and blessed $frame->{header}
                        and $frame->{header}->can('reply_to')
                        and blessed($response)
                        and $response->isa('HTTP::Response'))
                    {
                        Lim::RPC_DEBUG and $self->{logger}->debug('RabbitMQ response: ', $response->as_string);

                        $channel->{obj}->publish(
                            exchange    => '',
                            routing_key => $frame->{header}->reply_to,
                            header => {
                                headers => {
                                    'X-Lim-Code' => $response->code,
                                    'Content-Type' => $response->header('Content-Type')
                                }
                            },
                            body        => $response->content
                        );
                    }

                    $channel->{obj}->ack(
                        delivery_tag => $frame->{deliver}->method_frame->delivery_tag
                    );
                },
                reset_timeout => sub {
                }
            );

            foreach my $protocol ($self->protocols) {
                Lim::RPC_DEBUG and $self->{logger}->debug('Trying protocol ', $protocol->name);
                if ($protocol->handle($cb, $request, $self)) {
                    Lim::RPC_DEBUG and $self->{logger}->debug('Request handled by protocol ', $protocol->name);
                    return;
                }
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Did not find any protocol handler for request');

            # TODO: reject rabbitmq frame?

            $channel->{obj}->ack(
                delivery_tag => $frame->{deliver}->method_frame->delivery_tag
            );
        },
        on_cancel => sub {
            unless (defined $self) {
                return;
            }

            if ($self->{closing}) {
                Lim::RPC_DEBUG and $self->{logger}->debug('Channel cancelled for '.$channel->{module});
            }
            else {
                Lim::ERR and $self->{logger}->error('Channel cancelled for '.$channel->{module});
                $self->_reopen($channel);
            }
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel consume failure for '.$channel->{module}.': '.$message);
            $self->_reopen($channel);
        }
    );
}

=head2 close

=cut

sub close {
    my ($self, $cb) = @_;
    my $real_self = $self;
    weaken($self);
    my $queue_prefix = $self->{queue_prefix};

    unless (ref($cb) eq 'CODE') {
        confess '$cb is not CODE';
    }

    my $cv = AnyEvent->condvar;
    $cv->begin(sub {
        $cb->();
        $cv = undef;
    });

    $self->{closing} = 1;
    foreach my $channel (values %{$self->{channel}}) {
        unless (blessed $channel->{obj} and $channel->{obj}->isa('AnyEvent::RabbitMQ::Channel') and defined $channel->{queue}) {
            next;
        }

        if ($channel->{consumer_tag}) {
            $cv->begin;
            $channel->{obj}->cancel(
                consumer_tag => $channel->{consumer_tag},
                on_success => sub {
                    Lim::RPC_DEBUG and defined $self and $self->{logger}->debug('Channel cancel successfully');
                    $cv->end;
                },
                on_failure => sub {
                    my ($message) = @_;

                    Lim::ERR and defined $self and $self->{logger}->error('Channel cancel failure: '.$message);
                    $cv->end;
                }
            );
        }
    }
    $cv->end;

    $self;
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

1; # End of Lim::RPC::Transport::RabbitMQ
