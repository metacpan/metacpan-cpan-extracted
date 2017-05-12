use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Temp 'tempdir';

use ExclusiveLock::Guard;

my $tmpdir  = tempdir( CLEANUP => 1 );
my $tmpfile = File::Spec->catfile( $tmpdir, 'test.lock' );

my $pid = fork;
die "fork failed: $!" unless defined $pid;
if ($pid) {
    # parent
    sleep 1;

    ok( -f $tmpfile );
    do {
        my $lock1 = ExclusiveLock::Guard->new($tmpfile, nonblocking => 1);
        ok( not $lock1->is_locked);
    };
    ok( -f $tmpfile );

    sleep 2;

    ok( not -f $tmpfile );
    my $lock2 = ExclusiveLock::Guard->new($tmpfile, nonblocking => 1);
    ok($lock2->is_locked);
    ok( -f $tmpfile );

    waitpid $pid, 0;
} else {
    # chiled
    do {
        my $lock = ExclusiveLock::Guard->new($tmpfile);
        sleep 2;
    };
    exit;
}

ok( not -f $tmpfile );

done_testing;
