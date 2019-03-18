package MariaDB::NonBlocking::EV;
use parent 'MariaDB::NonBlocking';

use v5.18.2; # needed for __SUB__, implies strict
use warnings;

use constant DEBUG => $ENV{MariaDB_NonBlocking_DEBUG} // 0;
sub TELL (@) {
    say STDERR __PACKAGE__, ': ', join " ", @_;
}

use Sub::StrictDecl;
use MariaDB::NonBlocking qw':all';
use EV;

sub new {
    my ($class, $args) = @_;
    $args //= {};
    my $loop = delete $args->{ev} || EV::default_loop();
    my $self = $class->SUPER::new($args);
    $self->{loop} = $loop;
    return $self;
}

sub _mysql_watchers_to_ev_watchers {
    my $wait_on = 0;
    $wait_on |= EV::READ  if $_[0] & MYSQL_WAIT_READ;
    $wait_on |= EV::WRITE if $_[0] & MYSQL_WAIT_WRITE;
    return $wait_on;
}

sub _ev_event_to_mysql_event {
    return MYSQL_WAIT_TIMEOUT
        if $_[0] & EV::TIMER;

    my $events = 0;
    $events |= MYSQL_WAIT_READ  if $_[0] & EV::READ;
    $events |= MYSQL_WAIT_WRITE if $_[0] & EV::WRITE;

    return $events;
}

# The following is used later to prevent a really annoying memory leak
sub empty;
# If a watcher is kept alive (because we tossed it into the pool)
# then the callback the watcher has attached will be kept alive.
# This means that the success and/or failure callbacks the user
# provided will be kept, which likely means keeping a bunch
# of closed-over variables alive too.
# So we always blank out callbacks before stopping/releasing timers.

sub __stop_watcher {
    my ($watcher_type, $watcher) = @_;
    return unless $watcher;
    $watcher->stop; # includes $watcher->clear_pending;
    $watcher->keepalive(0); # No need to keep the eventloop alive if we are running
    $watcher->cb(\&empty);
}

our %WATCHER_POOL;
our $WATCHER_POOL_MAX = 2; # keep two standby watchers alive at most
sub __return_watcher_to_pool {
    my ($watcher_type, $watcher) = @_;
    return unless $watcher;
    my $pool = $WATCHER_POOL{$watcher_type} //= [];
    __stop_watcher($watcher_type, $watcher); # Always stop it, even if the watcher pool is full; see
                                             # the explanation in 'sub empty;'
    return if @$pool >= $WATCHER_POOL_MAX;
    push @$pool, $watcher;
}

sub _disarm_timer {
    my ($maria) = @_;
    # If this connection had a mysql-prompted timeout, odds are
    # it'll have another one
    __stop_watcher($maria->{watcher_storage}{timer});
}

sub _clean_object {
    my ($maria) = @_;
    my $watchers = delete $maria->{watcher_storage} // {};
    return unless %$watchers;

    foreach my $watcher_type ( keys %$watchers ) {
        my $watcher = delete $watchers->{$watcher_type};
        $watcher_type = 'io'    if index($watcher_type, 'io')    != -1;
        $watcher_type = 'timer' if index($watcher_type, 'timer') != -1;
        __return_watcher_to_pool($watcher_type, $watcher);
    }
}

sub __wrap_ev_cb {
    my ($cb) = @_;
    return sub {
        my (undef, $ev_event) = @_;
        my $events_for_mysql  = _ev_event_to_mysql_event($ev_event);
        $cb->($events_for_mysql);
    }
}

sub __restart_watcher {
    my ($existing_watcher, $cb) = @_;

    $existing_watcher->cb($cb);
    $existing_watcher->keepalive(1); # keep the eventloop alive if we are running
    $existing_watcher->start;

    return;
}

sub _set_io_watcher {
    my ($maria, $fd, $wait_for, $original_cb) = @_;
    my $storage = $maria->{watcher_storage} //= {};

    my $wrapped_cb = __wrap_ev_cb($original_cb);

    # If we are using EV, reuse a watcher if we can.
    my $existing_watcher = $storage->{io} ||= pop @{ $WATCHER_POOL{io} //= [] };

    my $ev_mask = _mysql_watchers_to_ev_watchers($wait_for);

    if ( !$existing_watcher ) {
        # No pre-existing watcher for us to use;
        # make a new one!
        DEBUG && TELL "Started new io watcher ($ev_mask)";
        $storage->{io} = $maria->{loop}->io(
            $fd,
            $ev_mask,
            $wrapped_cb
        );
        return;
    }

    DEBUG && TELL "Reusing existing io watcher ($ev_mask)";
    $existing_watcher->set( $fd, $ev_mask );
    __restart_watcher($existing_watcher, $wrapped_cb);

    return;
}

sub _set_timer {
    my ($maria, $watcher_type, $timeout_s, $cb) = @_;
    my $storage = $maria->{watcher_storage} //= {};

    my $wrapped_cb = __wrap_ev_cb($cb);

    # If we are using EV, reuse a watcher if we can.
    my $existing_watcher = $storage->{$watcher_type}
                       ||= pop @{ $WATCHER_POOL{timer} //= [] };

    $maria->{loop}->now_update();
    if ( !$existing_watcher ) {
        DEBUG && TELL "Started new $watcher_type watcher";
        $storage->{$watcher_type} = $maria->{loop}->timer(
            $timeout_s,
            0,
            $wrapped_cb,
        );
        return;
    }
    DEBUG && TELL "Reusing existing $watcher_type watcher";
    $existing_watcher->set( $timeout_s, 0 );

    __restart_watcher($existing_watcher, $cb);

    return;
}

1;
