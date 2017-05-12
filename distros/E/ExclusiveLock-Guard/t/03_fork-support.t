use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Temp 'tempdir';

use ExclusiveLock::Guard;

my $tmpdir  = tempdir( CLEANUP => 1 );
my $tmpfile = File::Spec->catfile( $tmpdir, 'test.lock' );

my $lock = ExclusiveLock::Guard->new($tmpfile);

my $pid = fork;
die "fork failed: $!" unless defined $pid;
if ($pid) {
    # parent

    waitpid $pid, 0;
} else {
    # chiled
    exit;
}
warn 'continue';

ok( -f $tmpfile );
undef $lock;
ok( not -f $tmpfile );

done_testing;
