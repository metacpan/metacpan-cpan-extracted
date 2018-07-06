use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;

my $CLASS = 'JavaScript::V8::XS';

sub test_now {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $margin_ms = 5;
    my $expected = Time::HiRes::gettimeofday() * 1000.0;
    my $got = $vm->eval('timestamp_ms()');
    my $delta = abs($got - $expected);
    ok($delta < $margin_ms, "got correct JS timestamp within $margin_ms ms");
}

sub main {
    use_ok($CLASS);

    test_now();
    done_testing;
    return 0;
}

exit main();
