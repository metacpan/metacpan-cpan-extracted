use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Temp 'tempdir';

use ExclusiveLock::Guard;

my $tmpdir  = tempdir( CLEANUP => 1 );
my $tmpfile = File::Spec->catfile( $tmpdir, 'test.lock' );
do {
    my $lock = ExclusiveLock::Guard->new($tmpfile);
    ok($lock->is_locked);
    ok( -f $tmpfile );
};

ok( not -f $tmpfile );

done_testing;
