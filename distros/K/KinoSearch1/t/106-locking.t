#!perl
use strict;
use warnings;
use Time::HiRes qw( sleep );
use Test::More;

BEGIN {
    if ( $^O =~ /mswin/i ) {
        plan( 'skip_all', "fork on Windows not supported by KS" );
    }
    else {
        plan( tests => 3 );
    }
    use_ok 'KinoSearch1::Store::FSLock';
}

use KinoSearch1::Store::FSInvIndex;
my $lock_path = "$KinoSearch1::Store::FSInvIndex::LOCK_DIR/test-foo";

Dead_locks_are_removed: {

    # Remove any existing lockfile
    unlink $lock_path;
    die "Can't unlink '$lock_path'" if -e $lock_path;

    # Fake index for test simplicity
    my $mock_index = MockIndex->new( prefix => 'test' );

    sub make_lock {
        my $lock = KinoSearch1::Store::FSLock->new(
            invindex  => $mock_index,
            lock_name => 'foo',
        );
        $lock->obtain;
        return $lock;
    }

    # Fork a process that will create a lock and then exit
    my $pid = fork();
    if ( $pid == 0 ) {    # child
        make_lock();
        exit;
    }
    else {
        waitpid( $pid, 0 );
    }

    ok( -e $lock_path, "child secured lock" );

    # The locking attempt will fail if the pid from the process that made the
    # lock is active, so do the best we can to see whether another process
    # started up with the child's pid (which would be weird).
    my $pid_active = kill( 0, $pid );
    eval { make_lock() };
    warn $@ if $@;
    my $saved_err = $@;
    $pid_active ||= kill( 0, $pid );
SKIP: {
        skip( "Child's pid is active", 1 ) if $pid_active;
        ok( !$saved_err,
            'second lock attempt clobbered dead lock file and did not die' );
    }

    # clean up
    unlink $lock_path;
}

package MockIndex;
use strict;
use warnings;

sub new {
    my ( $class, %args ) = @_;
    bless \%args, $class;
}

sub get_path        {"bar"}
sub get_lock_prefix { $_[0]->{prefix} }
