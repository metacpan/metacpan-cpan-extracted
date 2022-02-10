package Log::Dispatch::Gelf;
use 5.010;
use strict;
use warnings;

our $VERSION = '1.4.0';

use base qw(Log::Dispatch::Output);
use Params::Validate qw(validate SCALAR HASHREF CODEREF BOOLEAN);

use Log::GELF::Util qw(
    parse_size
    compress
    enchunk
    encode
);
use Sys::Hostname;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self = bless {}, $class;

    $self->_basic_init(@_);
    $self->_init(@_);

    return $self;
}

sub _init {
    my $self = shift;

    Params::Validate::validation_options(allow_extra => 1);
    my %p = validate(
        @_,
        {
            send_sub          => { type => CODEREF, optional => 1 },
            short_message_sub => { type => CODEREF, optional => 1 },
            additional_fields => { type => HASHREF, optional => 1 },
            host              => { type => SCALAR,  optional => 1 },
            compress          => { type => BOOLEAN, optional => 1 },
            chunked           => { type => SCALAR,  default  => 0 },
            socket            => {
                type      => HASHREF,
                optional  => 1,
                callbacks => {
                    protocol_is_tcp_or_udp_or_default => sub {
                        my ($socket) = @_;

                        $socket->{protocol} //= 'udp';
                        die 'socket protocol must be tcp or udp' unless $socket->{protocol} =~ /^(?:tcp|udp)$/;
                    },
                    host_must_be_set => sub {
                        my ($socket) = @_;

                        die 'socket host must be set' unless exists $socket->{host} && length $socket->{host} > 0;
                    },
                    port_must_be_number_or_default => sub {
                        my ($socket) = @_;

                        $socket->{port} //= 12201;
                        die 'socket port must be integer' unless $socket->{port} =~ /^\d+$/;
                    },
                }
            }
        }
    );

    $p{chunked} = parse_size($p{chunked});

    if (!defined $p{socket} && !defined $p{send_sub}) {
        die 'Must be set socket or send_sub';
    }

    if ( defined $p{socket}
         && $p{chunked}
         && $p{socket}{protocol} ne 'udp'
    ) {
        die 'chunked only applicable to udp';
    }

    $self->{host}              = $p{host}              // hostname();
    $self->{additional_fields} = $p{additional_fields} // {};
    $self->{send_sub}          = $p{send_sub};
    $self->{short_message_sub} = $p{short_message_sub} // sub { $_[0] =~ s/\n.*//sr };
    $self->{gelf_version}      = '1.1';
    $self->{chunked}           = $p{chunked};

    if ($p{socket}) {
        my $socket = $self->_create_socket($p{socket});

        $self->{send_sub} = sub {
            my ($msg) = @_;

            $msg = compress($msg) if $p{compress};
            foreach my $chunk (enchunk($msg, $self->{chunked})) {
                if ($p{socket}{protocol} ne 'udp') {
                    $chunk .= "\x00";
                }
                $socket->send($chunk);
            }
        };
    }

    return;
}

sub _create_socket {
    my ($self, $socket_opts) = @_;

    require IO::Socket::INET;
    my $socket = IO::Socket::INET->new(
        PeerAddr => $socket_opts->{host},
        PeerPort => $socket_opts->{port},
        Proto    => $socket_opts->{protocol},
    ) or die "Cannot create socket: $!";

    return $socket;
}

sub log_message {
    my ($self, %p) = @_;

    my %additional_fields;
    while (my ($key, $value) = each %{ $self->{additional_fields} }) {
        $additional_fields{"_$key"} = $value;
    }

    while (my ($key, $value) = each %{ $p{additional_fields} }) {
        $additional_fields{"_$key"} = $value;
    }

    my $log_unit = {
        version       => $self->{gelf_version},
        host          => $self->{host},
        short_message => $self->{short_message_sub}->($p{message}),
        level         => $p{level},
        full_message  => $p{message},
        %additional_fields,
    };

    $self->{send_sub}->(encode($log_unit));

    return;
}

sub log {
    my $self = shift;

    my %p = validate(
        @_, {
            additional_fields => {
                type     => HASHREF,
                optional => 1,
            },
        }
    );

    $self->SUPER::log(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Log::Dispatch::Gelf - Log::Dispatch plugin for Graylog's GELF format.

=head1 SYNOPSIS

    use Log::Dispatch;

    my $sender = ... # e.g. RabbitMQ queue.
    my $log = Log::Dispatch->new(
        outputs => [
            #some custom sender
            [
                'Gelf',
                min_level         => 'debug',
                additional_fields => { facility => __FILE__ },
                send_sub          => sub { $sender->send($_[0]) },
            ],
            #or send to graylog via TCP/UDP socket
            [
                'Gelf',
                min_level         => 'debug',
                additional_fields => { facility => __FILE__ },
                socket            => {
                    host     => 'graylog.server',
                    port     => 21234,
                    protocol => 'tcp',
                }
            ],
            # define callback to crop your full message to short in your own way
            [
                'Gelf',
                min_level         => 'debug',
                additional_fields => { facility => __FILE__ },
                send_sub          => sub { $sender->send($_[0]) },
                short_message_sub => sub { substr($_[0], 0, 10) }
            ],
        ],
    );
    $log->info('It works');

    $log->log(
        level             => 'info',
        message           => "It works\nMore details.",
        additional_fields => { test => 1 }
    );

=head1 DESCRIPTION

Log::Dispatch::Gelf is a Log::Dispatch plugin which formats the log message
according to Graylog's GELF Format version 1.1. It supports sending via a
socket (TCP or UDP) or a user provided sender.

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over

=item additional_fields

optional hashref of additional fields of the gelf message (no need to prefix
them with _, the prefixing is done automatically).

=item chunked

optional scalar. An integer specifying the chunk size or the special
string values 'lan' or 'wan' corresponding to 8154 or 1420 respectively.
A zero chunk size means no chunking will be applied.

Chunking is only applicable to UDP connections.

=item compress

optional scalar. If a true value the message will be gzipped with
IO::Compress::Gzip.

=item send_sub

mandatory sub for sending the message to graylog. It is triggered after the
gelf message is generated.

=item short_message_sub

sub for code that will crop your full message to short message. By default
it deletes everything after first newline character

=item socket

optional hashref create tcp or udp (default behavior) socket and set
C<send_sub> to sending via socket

=back

=head1 METHODS

=head2 $log->log( level => $, message => $, additional_fields => \% )

In addition to the corresponding method in L<Log::Dispatch::Output> this
subclassed method takes an optional hashref of additional_fields for the
gelf message. As in the corresponding parameter on the constructor there is
no need to prefix them with an _. If the same key appears in both the
constructor's and method's additional_fields then the method's value will
take precedence overriding the constructor's value for the current call.

The subclassed log method is still called with all parameters passed on.

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Miroslav Tynovsky E<lt>tynovsky@avast.comE<gt>

=cut
