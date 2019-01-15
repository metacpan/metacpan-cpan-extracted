use strict;
use warnings;

use Test::More;
use Devel::Probe (config_file => 'foo.json', check_config_file => 1);

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

