use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;
use Test::Exception;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_set_get_stack_bug {
    my ($iters) = @_;

    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    for (my $step = 0; $step < $iters; ++$step) {
        my @data = (1..3);
        $vm->set(global_name => \@data);
        $vm->get('bullshit');
    }
}

sub test_eval_stack_bug {
    my ($iters) = @_;

    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    for (my $step = 0; $step < $iters; ++$step) {
        $vm->eval("result = Math.random()");
    }
}

sub test_eval_get_stack_bug {
    my ($iters) = @_;

    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    for (my $step = 0; $step < $iters; ++$step) {
        $vm->eval("result = Math.random()");
        $vm->get('result');
    }
}

sub main {
    use_ok($CLASS);

    lives_ok { test_set_get_stack_bug(1_000) } 'survived get/set stack bug';
    lives_ok { test_eval_stack_bug(1_000_000) } 'survived eval stack bug';
    lives_ok { test_eval_get_stack_bug(1_000_000) } 'survived eval stack bug';
    done_testing;
    return 0;
}

exit main();
