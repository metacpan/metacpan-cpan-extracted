use strict;
use warnings;

use Test::More;
use Devel::Probe (check_config_file => 1);
# use Devel::Probe;

exit main();

sub main {
    foreach my $n (1..5) {
        printf("%d...\n", $n);
        sleep 1;
    }
    ok(1, "done");
    done_testing;
    return 0;
}

