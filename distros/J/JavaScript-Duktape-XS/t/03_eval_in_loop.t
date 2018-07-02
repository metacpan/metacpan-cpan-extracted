use strict;
use warnings;

use Data::Dumper;
use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_eval {
    # my $vm = $CLASS->new();
    # ok($vm, "created $CLASS object");

    my $times = 500;
    my $count = 0;
    my $js = '2 * 2';
    my $expected = 4;
    my @vms;
    for ($count = 0; $count < $times; ++$count) {
        my $vm = $CLASS->new();
        push @vms, $vm;
        # my $got = $vm->eval("2 * 2");
        # next if $got == $expected;
        # ok(0, "$got == $expected");
        # last;
    }
    ok($count == $times, "did all $times iterations");
}

sub main {
    use_ok($CLASS);

    test_eval();
    done_testing;
    return 0;
}

exit main();
