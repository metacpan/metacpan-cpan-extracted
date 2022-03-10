use 5.006;
use strict;
use warnings;

use IPC::Shareable;
use Test::More;

BEGIN {
    use_ok( 'IPC::Shareable' ) || print "Bail out!\n";
}

if (! $ENV{CI_TESTING}) {
    done_testing();
    exit;
}

tie my %store, 'IPC::Shareable', {key => 'async_tests', destroy => 1};

my $start_segs = $store{segs};
IPC::Shareable::clean_up_all;

my $segs = IPC::Shareable::ipcs();

is $segs, $start_segs, "All test segments cleaned up after test run";

print "Started with $start_segs, ending with $segs\n";

done_testing();