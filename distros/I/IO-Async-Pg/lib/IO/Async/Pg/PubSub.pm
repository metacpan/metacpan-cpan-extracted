package IO::Async::Pg::PubSub;

use strict;
use warnings;
use parent 'IO::Async::Notifier';

use Future::AsyncAwait;
use IO::Async::Handle;

sub new {
    my ($class, %args) = @_;

    my $self = bless {
        conn       => undef,
        pool       => $args{pool},
        channels   => {},      # channel => [callbacks]
        connected  => 0,
        _handle    => undef,
    }, $class;

    return $self;
}

# Accessors
sub is_connected        { shift->{connected} }
sub subscribed_channels { scalar keys %{shift->{channels}} }

# Validate channel name to prevent injection
sub _validate_channel {
    my ($self, $channel) = @_;

    return 0 unless defined $channel && length $channel;
    return 0 if $channel =~ /[\s;'"\\]/;  # No whitespace, semicolon, quotes, backslash
    return 0 if $channel =~ /[\x00-\x1f]/;  # No control characters
    return 1;
}

# Connect to the database for listening
async sub connect {
    my ($self) = @_;

    return if $self->{connected};

    my $pool = $self->{pool} or die "No pool configured";

    # Get a dedicated connection for listening
    $self->{conn} = await $pool->connection;
    $self->{connected} = 1;

    # Set up socket watching
    $self->_setup_socket_watcher;

    return $self;
}

# Subscribe to a channel
async sub subscribe {
    my ($self, $channel, $callback) = @_;

    die "Invalid channel name: $channel"
        unless $self->_validate_channel($channel);

    # Ensure connected
    await $self->connect unless $self->{connected};

    # Add callback to list
    push @{$self->{channels}{$channel}}, $callback;

    # If first subscription to this channel, send LISTEN
    if (@{$self->{channels}{$channel}} == 1) {
        await $self->{conn}->query("LISTEN $channel");
    }

    return $self;
}

# Unsubscribe from a channel
async sub unsubscribe {
    my ($self, $channel, $callback) = @_;

    return unless exists $self->{channels}{$channel};

    if ($callback) {
        # Remove specific callback
        @{$self->{channels}{$channel}} =
            grep { $_ != $callback } @{$self->{channels}{$channel}};
    }
    else {
        # Remove all callbacks
        $self->{channels}{$channel} = [];
    }

    # If no more callbacks, send UNLISTEN
    if (!@{$self->{channels}{$channel}}) {
        delete $self->{channels}{$channel};
        if ($self->{conn}) {
            await $self->{conn}->query("UNLISTEN $channel");
        }
    }

    return $self;
}

# Unsubscribe from all channels
async sub unsubscribe_all {
    my ($self) = @_;

    $self->{channels} = {};

    if ($self->{conn}) {
        await $self->{conn}->query("UNLISTEN *");
    }

    return $self;
}

# Publish/notify a channel
async sub notify {
    my ($self, $channel, $payload) = @_;

    die "Invalid channel name: $channel"
        unless $self->_validate_channel($channel);

    # We can use any connection for NOTIFY
    my $pool = $self->{pool};
    my $conn = $self->{conn};

    if (!$conn) {
        # Get a temporary connection
        $conn = await $pool->connection;
        eval {
            if (defined $payload) {
                await $conn->query("NOTIFY $channel, \$1", $payload);
            }
            else {
                await $conn->query("NOTIFY $channel");
            }
        };
        my $err = $@;
        $conn->release;
        die $err if $err;
    }
    else {
        if (defined $payload) {
            await $conn->query("NOTIFY $channel, \$1", $payload);
        }
        else {
            await $conn->query("NOTIFY $channel");
        }
    }

    return $self;
}

# Set up socket watcher for incoming notifications
sub _setup_socket_watcher {
    my ($self) = @_;

    my $conn = $self->{conn} or return;
    my $dbh = $conn->dbh or return;

    my $socket_fd = $dbh->{pg_socket};
    return unless defined $socket_fd;

    my $handle;
    $handle = IO::Async::Handle->new(
        read_fileno    => $socket_fd,
        want_readready => 1,
        on_read_ready  => sub {
            $self->_process_notifications;
        },
    );

    $self->{_handle} = $handle;

    if (my $loop = $self->loop) {
        $loop->add($handle);
    }
}

# Process incoming notifications
sub _process_notifications {
    my ($self) = @_;

    my $conn = $self->{conn} or return;
    my $dbh = $conn->dbh or return;

    # Check for notifications
    while (my $notification = $dbh->pg_notifies) {
        my ($channel, $pid, $payload) = @$notification;

        # Call all registered callbacks for this channel
        if (my $callbacks = $self->{channels}{$channel}) {
            for my $cb (@$callbacks) {
                eval { $cb->($channel, $payload, $pid) };
                if ($@) {
                    warn "PubSub callback error for $channel: $@";
                }
            }
        }
    }
}

# Override to add handle to loop
sub _add_to_loop {
    my ($self, $loop) = @_;
    $self->SUPER::_add_to_loop($loop);

    if (my $handle = $self->{_handle}) {
        $loop->add($handle) unless $handle->loop;
    }
}

# Override to remove handle from loop
sub _remove_from_loop {
    my ($self, $loop) = @_;

    if (my $handle = $self->{_handle}) {
        $loop->remove($handle) if $handle->loop;
    }

    $self->SUPER::_remove_from_loop($loop);
}

# Disconnect and cleanup
async sub disconnect {
    my ($self) = @_;

    return unless $self->{connected};

    # Remove socket watcher
    if (my $handle = $self->{_handle}) {
        if (my $loop = $handle->loop) {
            $loop->remove($handle);
        }
        $self->{_handle} = undef;
    }

    # UNLISTEN all
    if ($self->{conn}) {
        eval { await $self->{conn}->query("UNLISTEN *") };
        $self->{conn}->release;
        $self->{conn} = undef;
    }

    $self->{channels} = {};
    $self->{connected} = 0;

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    # Synchronous cleanup only
    if (my $handle = $self->{_handle}) {
        if (my $loop = $handle->loop) {
            $loop->remove($handle);
        }
    }

    if (my $conn = $self->{conn}) {
        $conn->release;
    }
}

1;

__END__

=head1 NAME

IO::Async::Pg::PubSub - PostgreSQL LISTEN/NOTIFY pub/sub

=head1 SYNOPSIS

    my $pubsub = $pg->pubsub;

    # Subscribe to a channel
    await $pubsub->subscribe('my_channel', sub {
        my ($channel, $payload, $pid) = @_;
        print "Got notification: $payload\n";
    });

    # Publish to a channel
    await $pubsub->notify('my_channel', 'Hello World');

    # Unsubscribe
    await $pubsub->unsubscribe('my_channel');

=head1 DESCRIPTION

This module provides PostgreSQL LISTEN/NOTIFY support for pub/sub messaging.

Note: This is in-memory only. For multi-server deployments, use an external
message broker like Redis.

=head1 METHODS

=head2 subscribe($channel, $callback)

Subscribe to a channel. The callback is called with ($channel, $payload, $pid).

=head2 unsubscribe($channel, [$callback])

Unsubscribe from a channel. If callback is provided, only that callback is
removed; otherwise all callbacks for the channel are removed.

=head2 notify($channel, [$payload])

Send a notification to a channel with optional payload.

=head2 disconnect

Disconnect from the database and clean up.

=head1 AUTHOR

John Napiorkowski E<lt>jjn1056@yahoo.comE<gt>

=cut
