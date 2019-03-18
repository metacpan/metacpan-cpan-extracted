package MariaDB::NonBlocking::AE;
use parent 'MariaDB::NonBlocking';

use v5.18.2; # needed for __SUB__, implies strict
use warnings;
use Sub::StrictDecl;

use constant DEBUG => $ENV{MariaDB_NonBlocking_DEBUG} // $ENV{MariaDB_NonBlocking_DEBUG_AE} // 0;
sub TELL (@) {
    say STDERR __PACKAGE__, ': ', join " ", @_;
}

use AE;

use MariaDB::NonBlocking ':all';

sub _clean_object {
    my ($maria) = @_;
    delete $maria->{watcher_storage};
}

sub _disarm_timer {
    my ($maria) = @_;
    delete $maria->{watcher_storage}{timer};
}

sub _set_timer {
    my ($maria, $watcher_type, $timeout_s, $cb) = @_;
    my $storage = $maria->{watcher_storage} //= {};

    AE::now_update();
    $storage->{$watcher_type} = AE::timer(
        $timeout_s,
        0,
        sub { $cb->(MYSQL_WAIT_TIMEOUT) },
    );
}

sub _set_io_watcher {
    my ($maria, $fd, $wait_for, $cb) = @_;
    my $storage = $maria->{watcher_storage} //= {};

    # We might need a read watcher, we might need
    # a write watcher.. we might need both : (

    # drop any previous watchers
    delete @{$storage}{qw/io_r io_w/};

    # amusingly, this is broken in libuv, since
    # you cannot have two watchers on the same fd;
    DEBUG && TELL "Started new io watcher ($wait_for)";
    $storage->{io_r} = AE::io(
        $fd,
        0,
        sub { $cb->(MYSQL_WAIT_READ) },
    ) if $wait_for & MYSQL_WAIT_READ;
    $storage->{io_w} = AE::io(
        $fd,
        1,
        sub { $cb->(MYSQL_WAIT_WRITE) },
    ) if $wait_for & MYSQL_WAIT_WRITE;
    return;
}

1;
