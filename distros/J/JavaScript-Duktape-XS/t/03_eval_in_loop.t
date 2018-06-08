use strict;
use warnings;

use Data::Dumper;
use Test::More;
use JavaScript::Duktape::XS;

sub test_eval {
    # my $duk = JavaScript::Duktape::XS->new();
    # ok($duk, "created JavaScript::Duktape::XS object");

    my $times = 2_000;
    my $count = 0;
    my $js = '2 * 2';
    my $expected = 4;
    my @duks;
    for ($count = 0; $count < $times; ++$count) {
        my $duk = JavaScript::Duktape::XS->new();
        push @duks, $duk;
        # my $got = $duk->eval("2 * 2");
        # next if $got == $expected;
        # ok(0, "$got == $expected");
        # last;
    }
    ok($count == $times, "did all $times iterations");
}

sub main {
    test_eval();
    done_testing;
    return 0;
}

exit main();
