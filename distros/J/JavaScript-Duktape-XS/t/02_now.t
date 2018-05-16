use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;
use JavaScript::Duktape::XS;

sub test_now {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my $margin_ms = 5;
    my $expected = Time::HiRes::gettimeofday() * 1000.0;
    my $got = $duk->eval('timestamp_ms()');
    my $delta = abs($got - $expected);
    ok($delta < $margin_ms, "got correct JS timestamp within $margin_ms ms");
}

sub main {
    test_now();
    done_testing;
    return 0;
}

exit main();
