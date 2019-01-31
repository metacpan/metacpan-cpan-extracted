use strict;
use warnings;

use Data::Dumper;
use Time::HiRes;
use Test::More;
use Test::Exception;

my $CLASS = 'JavaScript::Duktape::XS';

sub test_this_bug {
    my $vm = $CLASS->new();
    ok($vm, "created $CLASS object");

    my $expected = 11;
    $vm->set("gonzo", sub { return $expected });

    my $got;
    lives_ok { $got = $vm->eval(q[gonzo(this)]) } 'survived calling perl callback';
    is($got, $expected, "got expected value $expected from perl callback");
}

sub main {
    use_ok($CLASS);

    test_this_bug();
    done_testing;
    return 0;
}

exit main();
