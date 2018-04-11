use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;
use JavaScript::Duktape::XS;

sub test_stats {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    for (1..3) {
        my $got = $duk->eval('timestamp_ms()');
        my $stats = $duk->get_stats();
        foreach my $key (qw/ compile run /) {
            ok(exists $stats->{$key}, "key $key exists in stats");
            ok($stats->{$key} > 0, "key $key has a positive value in stats");
        }
    }
}

sub main {
    test_stats();
    done_testing;
    return 0;
}

exit main();
