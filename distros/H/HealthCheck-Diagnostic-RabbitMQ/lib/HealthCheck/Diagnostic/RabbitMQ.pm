package HealthCheck::Diagnostic::RabbitMQ;

# ABSTRACT: Check connectivity and queues on a RabbitMQ server
use version;
our $VERSION = 'v1.3.1'; # VERSION

use 5.010;
use strict;
use warnings;
use parent 'HealthCheck::Diagnostic';

use Carp;

sub new {
    my ($class, @params) = @_;

    # Allow either a hashref or even-sized list of params
    my %params = @params == 1 && ( ref $params[0] || '' ) eq 'HASH'
        ? %{ $params[0] } : @params;

    return $class->SUPER::new(
        label => 'rabbit_mq',
        %params
    );
}

sub check {
    my ( $self, %params ) = @_;

    # The method the object needs to have for us to proceed
    my $method = 'get_server_properties';

    # These are the params that we actually use to make our decisions
    # and that we're going to return in the result to make that clear.
    my %decision_params = ( rabbit_mq => undef );

    my @limits = qw(
        listeners_min_critical
        listeners_min_warning
        listeners_max_critical
        listeners_max_warning

        messages_critical
        messages_warning
    );

    # If we have a queue to check, that changes our requirements
    if ( defined $params{queue}
        or ( ref $self and defined $self->{queue} ) )
    {
        $method = 'queue_declare';
        $decision_params{$_} = undef for qw(
            queue
            channel
        ), @limits;
    }

    # Now we prefer the params passed to check,
    # and fall back to what is on the instance.
    foreach my $param ( keys %decision_params ) {
        $decision_params{$param}
            = exists $params{$param} ? $params{$param}
            : ref $self              ? $self->{$param}
            :                          undef;
    }

    # No need to return the limits we aren't using in the result
    delete @decision_params{ grep { !defined $decision_params{$_} } @limits };

    # The rabbit_mq param was only "known" so we could choose between
    # one that was passed to check and the one on the instance.
    my $rabbit_mq = delete $decision_params{rabbit_mq};
    my $should_disconnect = 0;
    if (ref $rabbit_mq eq 'CODE') {
        local $@;
        ($rabbit_mq, $should_disconnect) = eval {
            local $SIG{__DIE__};
            $rabbit_mq->(%params);
        };
        if ($@) {
            return $self->summarize({ status => 'CRITICAL', info => "$@" })
        }
    }

    croak("'rabbit_mq' must have '$method' method") unless $rabbit_mq and do {
        local $@; eval { local $SIG{__DIE__}; $rabbit_mq->can($method) } };

    # Any "should_disconnect" in the params or the instance should take
    # precedence over what might have been returned by a coderef:
    #
    $should_disconnect = exists $params{should_disconnect}
                              ? $params{should_disconnect}
                              : (ref $self && exists $self->{should_disconnect})
                                     ? $self->{should_disconnect}
                                     : $should_disconnect;

    # In theory we could default to random channel in the
    # range of 1..$rabbit_mq->get_max_channel
    # but then we would have to:
    # 1. Hope it's not in use
    # 2. Open and then close it.
    # Instead we default to 1 as that's what our internal code does.
    $decision_params{channel} //= 1
        if exists $decision_params{channel};

    my $res = $self->SUPER::check(
        %params,
        %decision_params,
        rabbit_mq => $rabbit_mq,
        should_disconnect => $should_disconnect,
    );

    # Make sure we report what we actually *used*
    # not what our parent may have copied out of %{ $self }
    $res->{data} = { %{ $res->{data} || {} }, %decision_params }
        if %decision_params;
    delete $res->{rabbit_mq};    # don't include the object in the result

    return $res;
}

sub run {
    my ( $self, %params ) = @_;
    my $rabbit_mq = $params{rabbit_mq};

    my $cb = sub { $rabbit_mq->get_server_properties };

    if ( defined $params{queue} ) {
        my $queue   = $params{queue};
        my $channel = $params{channel};

        $cb = sub {
            my ( $name, $messages, $listeners )
                = $rabbit_mq->queue_declare( $channel, $queue,
                { passive => 1 } );

            my $server_properties;
            if ($rabbit_mq->can("get_server_properties")) {
                $server_properties = $rabbit_mq->get_server_properties;
            }

            return {
                (   $server_properties
                    ? (server_properties => $server_properties)
                    : ()
                ),
                name      => $name,
                messages  => $messages,
                listeners => $listeners,
            };
        };
    }

    my $data;
    {
        local $@;
        eval {
            local $SIG{__DIE__};
            $data = $cb->();
            $rabbit_mq->disconnect if $params{should_disconnect};
        };

        if ( my $e = $@ ) {
            my $file = quotemeta __FILE__;
            $e =~ s/ at $file line \d+\.?\n\Z//ms;
            $e =~ s/^Declaring queue: //;
            return { status => 'CRITICAL', info => $e };
        }
    }

    my %res = ( status => 'OK', data => $data );

    if ( defined $data->{listeners} ) {
        my $listeners = $data->{listeners};
        if ((   defined $params{listeners_max_critical}
                and $params{listeners_max_critical} <= $listeners
            )
            or ( defined $params{listeners_min_critical}
                and $params{listeners_min_critical} >= $listeners )
            )
        {
            my $min = $params{listeners_min_critical};
            my $max = $params{listeners_max_critical};
            $res{status} = 'CRITICAL';
            my $info = "Listeners out of range! Expected";
            $info .= " min: $min" if defined $min;
            $info .= " max: $max" if defined $max;
            $res{info} = "$info have: $listeners";
        }
        elsif (
            (   defined $params{listeners_max_warning}
                and $params{listeners_max_warning} <= $listeners
            )
            or ( defined $params{listeners_min_warning}
                and $params{listeners_min_warning} >= $listeners )
            )
        {
            my $min = $params{listeners_min_warning};
            my $max = $params{listeners_max_warning};
            $res{status} = 'WARNING';
            my $info = "Listeners out of range! Expected";
            $info .= " min: $min" if defined $min;
            $info .= " max: $max" if defined $max;
            $res{info} = "$info have: $listeners";
        }
    }

    if ( $res{status} ne 'CRITICAL' and defined $data->{messages} ) {
        my $messages = $data->{messages};
        if ( defined $params{messages_critical}
            and $params{messages_critical} <= $messages )
        {
            $res{status} = 'CRITICAL';
            $res{info} = sprintf(
                "Messages out of range! Expected max: %d have: %d",
                $params{messages_critical},
                $messages,
            );
        }
        elsif ( defined $params{messages_warning}
            and $params{messages_warning} <= $messages )
        {
            $res{status} = 'WARNING';
            $res{info} = sprintf(
                "Messages out of range! Expected max: %d have: %d",
                $params{messages_warning},
                $messages,
            );
        }
    }

    return \%res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HealthCheck::Diagnostic::RabbitMQ - Check connectivity and queues on a RabbitMQ server

=head1 VERSION

version v1.3.1

=head1 SYNOPSIS

Check that you can talk to the server.

    my $health_check = HealthCheck->new( checks => [
        HealthCheck::Diagnostic::RabbitMQ->new( rabbit_mq => \&connect_mq ),
    ] );

Or verify that a queue exists,
has an appropriate number of listeners,
and not too many queued messages waiting.

    my $check_rabbit_mq => HealthCheck::Diagnostic::RabbitMQ->new(
        rabbit_mq => \&connect_mq,
        queue     => $queue_name,
        channel   => $channel,       # default channel is 1

        # All the rest are optional and only work on queue.
        listeners_min_critical => 0,
        listeners_min_warning  => 1,
        listeners_max_critical => 3,
        listeners_max_warning  => 3,    # noop, matches critical

        messages_critical => 10_000,
        messages_warning  => 1_000,
    );

    my $health_check = HealthCheck->new( checks => [$check_rabbit_mq] );

Here the C<connect_mq> function could be something like:

    sub connect_mq {
        my $mq = Net::AMQP::RabbitMQ->new;
        $mq->connect( $host, {
            user            => $username,
            password        => $password,
            vhost           => $vhost,
        } );
        $mq->channel_open(1);
        return $mq;
    };

The C<< $mq->channel_open >> is only needed to check a queue,
in which case you will need to open the L</channel> that will be used.

Checking additional queues could be as easy as:

    $health_check->register( {
        label    => "other_rabbit_mq_check",
        invocant => $check_rabbit_mq,
        check    => sub { shift->check( @_, queue => 'other.queue' },
    } );

=head1 DESCRIPTION

Determines if the RabbitMQ connection is available.
Sets the C<status> to "OK" or "CRITICAL" based on the
return value from C<< rabbit_mq->get_server_properties >>.

If you pass in a L</queue>,
it will instead check that the queue exists
and if you additionally provide L</listeners> or L</messages>
will also verify those limits.
Limits are ignored without a queue.

=head1 ATTRIBUTES

Can be passed either to C<new> or C<check>.

=head2 rabbit_mq

A coderef that returns a
L<Net::AMQP::RabbitMQ> or L<Net::RabbitMQ> or compatible object,
or the object itself.

If using a coderef, the first returned value should always be the
RabbitMQ object.  If more than one value is returned, the second is
assumed to be a Boolean L</should_disconnect> flag (see below).

=head2 should_disconnect

An optional Boolean value specifying whether to call C<< ->disconnect >>
on the RabbitMQ object after doing the health check.  The default is
false.

If specified as a parameter, it will override any value that might
be returned by a L</rabbit_mq> coderef as described above.

=head2 queue

The name of the queue to check whether it exists.

Accomplishes the check by using C<< rabbit_mq->queue_declare >>
to try to declare a passive queue.
Requires a L</channel>.

=head2 channel

Allow specifying which channel will be used to check the L</queue>.

The passed in L</rabbit_mq> must open this channel with C<channel_open>
to use this method.

Defaults to 1.

=head2 Limits

=head3 listeners

With these set, checks to see that the number of listeners on
the L</queue> is within the exclusive range.

Checked in the order listed here:

=over

=item listeners_min_critical

Check is C<CRITICAL> if the number of listeners is this many or less.

=item listeners_max_critical

Check is C<CRITICAL> if the number of listeners is this many or more.

=item listeners_min_warning

Check is C<WARNING> if the number of listeners is this many or less.

=item listeners_max_warning

Check is C<WARNING> if the number of listeners is this many or more.

=back

=head3 messages

Thresholds for number of messages in the queue.

=over

=item messages_critical

Check is C<CRITICAL> if the number of messages is this many or more.

=item messages_warning

Check is C<WARNING> if the number of messages is this many or more.

=back

=head1 BUGS AND LIMITATIONS

L<Net::RabbitMQ> does not support C<get_server_properties> and so doesn't
provide a way to just check that the server is responding to
requests.

=head1 DEPENDENCIES

L<HealthCheck::Diagnostic>

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 AUTHOR

Grant Street Group <developers@grantstreet.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 - 2023 by Grant Street Group.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
