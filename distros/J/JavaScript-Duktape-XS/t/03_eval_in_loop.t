use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_eval {
    my ($times, $use_reset) = @_;

    my $count = 0;
    my $js = '2 * 2';
    my $expected = 4;
    my @vms;
    my $vm;
    my $t0 = Time::HiRes::gettimeofday();
    $vm = $CLASS->new() if $use_reset;
    for ($count = 0; $count < $times; ++$count) {
        if ($use_reset) {
            $vm->reset();
        }
        else {
            $vm = $CLASS->new();
        }
        push @vms, $vm;

        # my $got = $vm->eval("2 * 2");
        # next if $got == $expected;
        # ok(0, "$got == $expected");
        # last;
    }
    my $t1 = Time::HiRes::gettimeofday();
    my $elapsed = 1000.0 * ($t1 - $t0);
    ok($count == $times,
       sprintf("did all %d iterations with reset=%d, %.0f ms, %.2fms each",
               $times, $use_reset ? 1 : 0, $elapsed, $elapsed / $times));
}

sub main {
    use_ok($CLASS);

    my $times = 100;
    test_eval($times, 1);
    test_eval($times, 0);
    done_testing;
    return 0;
}

exit main();
