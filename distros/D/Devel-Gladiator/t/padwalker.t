use strict;
use warnings;

# this module runs if padwalker is installed
# it tests getting data through padwalker that is has found on the arena

use Test::More;
use Devel::Peek;

if ($] < '5.009') {
    plan skip_all => "Tests with PadWalker do not pass on 5.8.x - patches welcome";
}
if (!eval "require PadWalker; 1") {
    plan skip_all => "No PadWalker installed";
}

plan tests => 5;
use Devel::Gladiator;

{
    my $outer = "outer";
    my %bar;
    $bar{baz} = "baz";
    sub blah {
        my $foo = "foo";
        my $bar = "bar";
        $bar{foz} = "foz";

        return bless sub { $foo . $bar . $outer . $bar{baz}} , "Dummy";
    }
}

my $sub1 = blah();

{
    my $array = Devel::Gladiator::walk_arena();
    foreach my $value (@$array) {
        next unless ref ($value) eq 'Dummy';
        my $peek_sub = PadWalker::peek_sub($value);

        is(${$peek_sub->{'$foo'}}, "foo");
        is(${$peek_sub->{'$outer'}}, "outer"); # used to be testing for 'undef', but it's a closure var, should be refcnt = 2 (one in Dummy, one in sub blah)
        is(${$peek_sub->{'$bar'}}, "bar");
        is($peek_sub->{'%bar'}->{baz}, "baz");
        is($peek_sub->{'%bar'}->{foz}, "foz");


        last;
    }
    $array = undef;
}
