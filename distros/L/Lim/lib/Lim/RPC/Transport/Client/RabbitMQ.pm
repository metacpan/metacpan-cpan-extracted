package Lim::RPC::Transport::Client::RabbitMQ;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);

use AnyEvent ();
eval 'use AnyEvent::RabbitMQ ();';
undef $@;

use HTTP::Request ();
use HTTP::Response ();
use HTTP::Status qw(:constants);

use Lim ();
use Lim::Error ();
use Lim::Util ();

use base qw(Lim::RPC::Transport::Client);

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

=head2 name

=cut

sub name {
    'rabbitmq';
}

=head2 request

=cut

sub request {
    my $self = shift;
    my %args = ( @_ );
    my $real_self = $self;
    weaken($self);

    $self->{channel} = undef;
    $self->{queue} = undef;
    $self->{host} = 'localhost';
    $self->{port} = 5672;
    $self->{user} = 'guest';
    $self->{pass} = 'guest';
    $self->{vhost} = '/';
    $self->{timeout} = 10;
    $self->{queue_prefix} = 'lim_';
    $self->{verbose} = 0;
    $self->{mandatory} = 0;
    $self->{immediate} = 0;
    $self->{broadcast} = 0;
    $self->{exchange_prefix} = 'lim_exchange_';

    foreach (qw(host port user pass vhost timeout queue_prefix verbose mandatory immediate broadcast exchange_prefix)) {
        if (defined Lim::Config->{rpc}->{transport}->{rabbitmq}->{$_}) {
            $self->{$_} = Lim::Config->{rpc}->{transport}->{rabbitmq}->{$_};
        }
    }

    foreach (qw(plugin call)) {
        unless (defined $args{$_}) {
            confess __PACKAGE__, ': No '.$_.' specified';
        }
    }
    foreach (qw(plugin call host port user pass vhost timeout queue_prefix verbose mandatory immediate broadcast exchange_prefix)) {
        if (defined $args{$_}) {
            $self->{$_} = $args{$_};
        }
    }
    unless (blessed $args{request} and $args{request}->isa('HTTP::Request')) {
        confess __PACKAGE__, ': No request or not HTTP::Request';
    }
    if (defined $args{cb} and ref($args{cb}) eq 'CODE') {
        $self->{cb} = $args{cb};
    }
    $self->{request} = $args{request};

    Lim::RPC_DEBUG and $self->{logger}->debug('Connection to ', $self->{host}, ' port ', $self->{port});
    eval {
        $self->{rabbitmq} = AnyEvent::RabbitMQ->new(verbose => $self->{verbose})->load_xml_spec;
    };
    if ($@) {
        confess 'Failed to initiate AnyEvent::RabbitMQ: '.$@;
    }
    unless (blessed $self->{rabbitmq} and $self->{rabbitmq}->isa('AnyEvent::RabbitMQ')) {
        confess 'unable to create AnyEvent::RabbitMQ object';
    }

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

    $self->{rabbitmq}->connect(
        (map { $_ => $self->{$_} } qw(host port user pass vhost timeout)),
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Server connected successfully');
            $self->_open;
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

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Server connection failure: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
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

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Server connection closed: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
        },
        on_read_failure => sub {
            unless (defined $self) {
                return;
            }

            my ($message) = @_;
            Lim::WARN and $self->{logger}->warn('Server read failure: '.$message);

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Server read failure: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
        }
    );
}

=head2 _open

=cut

sub _open {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);

    $self->{rabbitmq}->open_channel(
        on_success => sub {
            my ($obj) = @_;

            unless (defined $self) {
                return;
            }

            unless (blessed $obj and $obj->isa('AnyEvent::RabbitMQ::Channel')) {
                Lim::ERR and $self->{logger}->error('Channel open failure, object given to on_success is not AnyEvent::RabbitMQ::Channel');
                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        message => 'Channel open failure, object given to on_success is not AnyEvent::RabbitMQ::Channel',
                        module => $self
                    ));
                    delete $self->{cb};
                }
                return;
            }

            $self->{channel} = $obj;
            Lim::RPC_DEBUG and $self->{logger}->debug('Channel opened successfully');
            $self->_exchange;
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel open failure: '.$message);

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Channel open failure: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
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

            Lim::INFO and $self->{logger}->info('Channel closed: '.$message);

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Channel closed: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
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

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Frame returned: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
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
        $self->_declare;
        return;
    }

    unless (blessed $self->{channel} and $self->{channel}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$self->{channel} is not AnyEvent::RabbitMQ::Channel';
    }

    $self->{channel}->declare_exchange(
        exchange => $self->{exchange_prefix}.lc($self->{plugin}),
        type => 'fanout',
        auto_delete => 1,
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel exchange declared successfully');
            $self->_confirm;
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel exchange declare failure: '.$message);

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Channel exchange declare failure: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
        }
    );
}

=head2 _declare

=cut

sub _declare {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);

    unless (blessed $self->{channel} and $self->{channel}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$self->{channel} is not AnyEvent::RabbitMQ::Channel';
    }

    $self->{channel}->declare_queue(
        exclusive => 1,
        auto_delete => 1,
        on_success => sub {
            my ($method) = @_;

            unless (defined $self) {
                return;
            }

            unless (blessed $method and $method->can('method_frame')
                and blessed $method->method_frame and $method->method_frame->can('queue'))
            {
                Lim::ERR and $self->{logger}->error('Declare queue frame invalid');
                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        message => 'Declare queue frame invalid',
                        module => $self
                    ));
                    delete $self->{cb};
                }
                return;
            }

            $self->{queue} = $method->method_frame->queue;

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel queue declared successfully');
            $self->_consume;
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel queue declare failure: '.$message);

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Channel queue declare failure: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
        }
    );
}

=head2 _consume

=cut

sub _consume {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);

    unless (defined $self->{queue}) {
        confess '$self->{queue} not defined';
    }
    unless (blessed $self->{channel} and $self->{channel}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$self->{channel} is not AnyEvent::RabbitMQ::Channel';
    }

    $self->{channel}->consume(
        queue => $self->{queue},
        no_ack => 0,
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel consuming successfully');
            $self->_confirm;
        },
        on_consume => sub {
            my ($frame) = @_;

            unless (defined $self) {
                return;
            }
            unless (defined $self->{channel}) {
                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        message => 'Message consumed without channel',
                        module => $self
                    ));
                    delete $self->{cb};
                }
                return;
            }

            unless (ref($frame) eq 'HASH'
                and blessed $frame->{deliver} and $frame->{deliver}->can('method_frame')
                and blessed $frame->{deliver}->method_frame and $frame->{deliver}->method_frame->can('delivery_tag')
                and blessed $frame->{deliver}->method_frame and $frame->{deliver}->method_frame->can('consumer_tag'))
            {
                Lim::ERR and $self->{logger}->error('Consume frame invalid');
                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        message => 'Consume frame invalid',
                        module => $self
                    ));
                    delete $self->{cb};
                }
                return;
            }

            unless (blessed $frame->{body} and $frame->{body}->can('payload')) {
                Lim::ERR and $self->{logger}->error('Consume request invalid, no payload');
                if (exists $self->{cb}) {
                    $self->{cb}->($self, Lim::Error->new(
                        message => 'Consume request invalid, no payload',
                        module => $self
                    ));
                    delete $self->{cb};
                }
                return;
            }

            my $headers = HTTP::Headers->new;
            if (blessed $frame->{header} and $frame->{header}->can('headers')
                and ref($frame->{header}->headers) eq 'HASH'
                and scalar %{$frame->{header}->headers})
            {
                $headers->header(%{$frame->{header}->headers});
            }
            my $response = HTTP::Response->new(
                ( $headers->header('X-Lim-Code') ? int($headers->header('X-Lim-Code')) : HTTP::Status::HTTP_OK ),
                '',
                $headers,
                $frame->{body}->payload
            );

            Lim::RPC_DEBUG and $self->{logger}->debug('RabbitMQ response: ', $response->as_string);
            $self->{response} = $response;

            $self->{channel}->ack(
                delivery_tag => $frame->{deliver}->method_frame->delivery_tag
            );

            $self->_cancel($frame->{deliver}->method_frame->consumer_tag);
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel consume failure for: '.$message);

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Channel consume failure for: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
        }
    );
}

=head2 _confirm

=cut

sub _confirm {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);

    unless (blessed $self->{channel} and $self->{channel}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$self->{channel} is not AnyEvent::RabbitMQ::Channel';
    }

    $self->{channel}->confirm(
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel confirm successfully');
            $self->_publish;
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel confirm failure: '.$message);

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Channel confirm failure: '.$message,
                    module => $self
                ));
                delete $self->{cb};
            }
        }
    );
}

=head2 _publish

=cut

sub _publish {
    my ($self) = @_;
    my $real_self = $self;
    weaken($self);

    if (!$self->{broadcast} and !defined $self->{queue}) {
        confess '$self->{queue} not defined';
    }
    unless (blessed $self->{channel} and $self->{channel}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$self->{channel} is not AnyEvent::RabbitMQ::Channel';
    }

    Lim::RPC_DEBUG and $self->{logger}->debug('RabbitMQ request: ', $self->{request}->as_string);
    $self->{channel}->publish(
        (exists $self->{mandatory} ? (mandatory => $self->{mandatory}) : ()),
        (exists $self->{immediate} ? (immediate => $self->{immediate}) : ()),
        ($self->{broadcast} ? (
            exchange => $self->{exchange_prefix}.lc($self->{plugin}),
            routing_key => '',
        ) : (
            exchange => '',
            routing_key => $self->{queue_prefix}.lc($self->{plugin}),
        )),
        header => {
            ($self->{broadcast} ? () : (reply_to => $self->{queue})),
            headers => {
                'Content-Type' => $self->{request}->header('Content-Type')
            }
        },
        body => $self->{request}->content,
        on_ack => sub {
            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel publish ack');

            if ($self->{broadcast}) {
                if (exists $self->{cb}) {
                    $self->{cb}->($self, {});
                    delete $self->{cb};
                }
            }
        },
        on_nack => sub {
            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel publish failure: NACK');

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Channel publish failure: NACK',
                    module => $self
                ));
                delete $self->{cb};
            }
        },
        on_return => sub {
            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel publish failure: message returned');

            if (exists $self->{cb}) {
                $self->{cb}->($self, Lim::Error->new(
                    message => 'Channel publish failure: message returned',
                    module => $self
                ));
                delete $self->{cb};
            }
        }
    );
}

=head2 _cancel

=cut

sub _cancel {
    my ($self, $consumer_tag) = @_;
    my $real_self = $self;
    weaken($self);

    unless (defined $consumer_tag) {
        confess '$consumer_tag not defined';
    }
    unless (blessed $self->{channel} and $self->{channel}->isa('AnyEvent::RabbitMQ::Channel')) {
        confess '$self->{channel} is not AnyEvent::RabbitMQ::Channel';
    }

    $self->{channel}->cancel(
        consumer_tag => $consumer_tag,
        on_success => sub {
            unless (defined $self) {
                return;
            }

            Lim::RPC_DEBUG and $self->{logger}->debug('Channel cancel successfully');

            if (exists $self->{cb}) {
                $self->{cb}->($self, $self->{response});
                delete $self->{cb};
            }
        },
        on_failure => sub {
            my ($message) = @_;

            unless (defined $self) {
                return;
            }

            Lim::ERR and $self->{logger}->error('Channel cancel failure: '.$message);

            if (exists $self->{cb}) {
                $self->{cb}->($self, $self->{response});
                delete $self->{cb};
            }
        }
    );
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

1; # End of Lim::RPC::Transport::Client::RabbitMQ
