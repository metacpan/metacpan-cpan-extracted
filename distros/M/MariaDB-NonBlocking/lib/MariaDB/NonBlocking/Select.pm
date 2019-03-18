package MariaDB::NonBlocking::Select;
use parent 'MariaDB::NonBlocking';

use v5.18.2;
use warnings;
use Sub::StrictDecl;

use IO::Select  ();
use MariaDB::NonBlocking ':all';

sub _clean_object {
    my ($maria) = @_;
    delete $maria->{watcher_storage};
}
sub _disarm_timer {}
sub _set_timer {}

sub _set_io_watcher {
    my ($maria, $fd, $new_wait_for, $cb) = @_;

    if ( exists $maria->{watcher_storage}{$fd} ) {
        $maria->{watcher_storage}{$fd} = $new_wait_for;
        return;
    }

    $maria->{watcher_storage}{$fd} = $new_wait_for;

    while ( my $wait_for = $maria->{watcher_storage}{$fd} ) {
        my $rin = '';
        my $win = '';

        vec($rin, $fd, 1) = 1 if $wait_for & MYSQL_WAIT_READ;
        vec($win, $fd, 1) = 1 if $wait_for & MYSQL_WAIT_WRITE;

        my $per_operation_timeout = $maria->{per_operation_timeout};
        my $found = select(my $rout = $rin, my $wout = $win, undef, $per_operation_timeout);
        if ( !$found ) {
            die "timeout";
        }
        my $status = 0;
        if ( vec($rout, $fd, 1) == 1 ) {
            $status |= MYSQL_WAIT_READ;
        }
        if ( vec($wout, $fd, 1) == 1 ) {
            $status |= MYSQL_WAIT_WRITE;
        }

        $cb->($status)
    }
}

sub run_query {
    my ($maria, $sql, $extra, $bind) = @_;
    my ($result, $error, $failed);
    $maria->SUPER::run_query($sql, $extra, $bind, sub { $result = $_[0] }, sub { $error = $_[0]; $failed = 1; }, $extra->{perl_timeout});
    Carp::croak($error) if $failed;
    return $result;
}

sub ping {
    my ($maria, $extra) = @_;
    my ($result, $error, $failed);
    $maria->SUPER::ping(sub { $result = $_[0] }, sub { $error = $_[0]; $failed = 1; }, $extra->{perl_timeout});
    Carp::croak($error) if $failed;
    return $result;
}

sub connect {
    my ($maria, $connect_args, $extra) = @_;
    my ($result, $error, $failed);
    $maria->SUPER::connect($connect_args, sub { $result = $_[0] }, sub { $error = $_[0]; $failed = 1; }, $extra->{perl_timeout});
    Carp::croak($error) if $failed;
    return $result;
}

1;
