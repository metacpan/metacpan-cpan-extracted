use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;
use JavaScript::Duktape::XS;

sub test_now {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my $expected = Time::HiRes::gettimeofday() * 1000.0;
    my $got = $duk->eval('timestamp_ms()');
    my $margin = 0.2;
    my $delta = abs($got - $expected);
    ok($delta < $margin, "got correct JS timestamp within $margin ms");

    my $js = q<print('this is a string', JSON.stringify({this: 'object'}))>;
    $duk->eval($js);
}

sub main {
    test_now();
    done_testing;
    return 0;
}

exit main();
