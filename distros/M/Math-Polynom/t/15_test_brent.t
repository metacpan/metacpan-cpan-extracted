use strict;
use warnings;
use Test::More tests => 43;
use lib "../lib/";

use Math::Polynom;

sub alike {
    my($v1,$v2,$precision,$sym) = @_;

    # some polynomials are symetrical and can have 2 symetrical roots
    if ($sym) {
	$v1 = abs($v1);
	$v2 = abs($v2);
    }

    # extending precision since hardcoded root is itself an estimation
    if ( abs($v1-$v2) <= 2*$precision) {
	return 1;
    }
    return 0;
}

sub test_brent {
    my($p,$args,$want)=@_;
    my $precision = $args->{precision} || 0.1;
    my $sym = $args->{sym} || 0;
    my $v = $p->brent(%$args);
    ok(alike($v,$want,$precision,$sym), $p->stringify." ->brent(a => ".$args->{a}.", b => ".$args->{b}.", precision => $precision) = $want (got $v)");
}

# the exemple on wikipedia:
my $p0 = Math::Polynom->new(3 => 1, 2 => 1, 1 => -5, 0 => 3);
is($p0->iterations,0,"p0->iterations=0");
test_brent($p0, {a => -4, b => 4/3}, -3);
is($p0->iterations,8,"p0->iterations=8 after search");

# p1 is 'x^2 - 4'
my $p1 = Math::Polynom->new(2 => 1, 0 => -4);
test_brent($p1, {a => 1, b => 3}, 2);
test_brent($p1, {a => 3, b => 1}, 2);
test_brent($p1, {a => -5, b => -1}, -2);
test_brent($p1, {a => -1, b => -5}, -2);
test_brent($p1, {a => 0, b => 3}, 2);
test_brent($p1, {a => 3, b => 0}, 2);
test_brent($p1, {a => -1, b => 3, precision => 0.0001}, 2);
test_brent($p1, {a => 0, b => 3, precision => 0.0000001}, 2);
test_brent($p1, {a => 0, b => -100, precision => 0.0000001}, -2);

# what happens if a or b is the root?
test_brent($p1, {a => 2, b => 3}, 2);
is($p1->iterations,0,"a was identified as root at once");
test_brent($p1, {a => 1, b => 2}, 2);
is($p1->iterations,0,"b was identified as root at once");

# a more complicated case
my $p2 = Math::Polynom->new(5 => 5, 3.2 => 4, 0.9 => -2);  # 5*x^5 + 4*x^3.2 - 2*x^0.9
test_brent($p2, {a => 0.5, b => 1, precision => 0.000000000000001}, 0.6161718040343);

eval { test_brent($p2, {a => 0.5, b => 1, precision => 0.000000000000001}, 0.6161718040343); };
ok((!defined $@ || $@ eq ''),"brent() does not fails on polynom 2 with negative guess (newton_raphson would)");

my $p3 = Math::Polynom->new(2 => 1, 1 => -2, 0 => 1); # x^2 -2*x +1
test_brent($p3,{a => 0.5, b => 1},1);
# problem: can't find an interval on which polynom is negative on one side and positive on the other, since always pos
#test_brent($p3,{a => 0, b => -500},1);
#test_brent($p3,{a => 0, b => 99999},1);

# TODO: handle calculation overflows...
my $v;
my $p7 = Math::Polynom->new(5 => 5, 3 => 4, 1 => -2);  # 5*x^5 + 4*x^3 - 2*x
eval { $v = $p7->brent(a => -100000000000000000, b => 999999999999999999999, max_depth => 1); };
ok((defined $@ && $@ =~ /reached maximum number of iterations/),"brent() fails when max_depth reached");
ok($p7->error_message =~ /reached maximum number of iterations/,"\$p7->error_message looks good");
is($p7->error,Math::Polynom::ERROR_MAX_DEPTH,"\$p7->error looks good");
# but we still find the solution if enough depth
test_brent($p7,{a => -100000000000000000, b => 999999999999999999999, max_depth => 150, precision => 0.01,sym => 1}, 0.58893);

# empty polynom error
my $p4 = Math::Polynom->new();
eval { $p4->brent(a => 0, b => 1); };
ok((defined $@ && $@ =~ /empty polynom/),"brent() fails on empty polynom");
ok($p4->error_message =~ /empty polynom/,"\$p4->error_message looks good");
is($p4->error,Math::Polynom::ERROR_EMPTY_POLYNOM,"\$p4->error looks good");

# a tuff one: the slope leads to a negative next try, while the polynom contains a root -> complex value
# secant fails on that one, but brent does not
my $p5 = Math::Polynom->new(0.2 => 2, 0 => -1); # 2*x^0.2-1
test_brent($p5,{a => 0, b => 10},0.03125);

# more simple cases, to be sure
test_brent(Math::Polynom->new(1 => 1),           {a => -10, b => 10},   0);    # x
test_brent(Math::Polynom->new(2 => 1, 0 => -1),  {a => .5, b => 10},    1);    # x^2-1
test_brent(Math::Polynom->new(2 => 1, 0 => -1),  {a => -.5, b => -10}, -1);    # x^2-1
test_brent(Math::Polynom->new(.5 => 1, 0 => -1), {a => 0, b => 10},     1);    # x^.5 - 1

# sign check
eval { $p1->brent(a => 0, b => 1); };
ok((defined $@ && $@ =~ /opposite signs at/),"brent() throw sign exception for 'x^2 - 4' on wrong interval [0,1]");
ok($p1->error_message =~ /opposite signs at/,"error_message looks good");
is($p1->error,Math::Polynom::ERROR_WRONG_SIGNS,"error looks good");

eval { $p1->brent(a => 4, b => 5); };
ok((defined $@ && $@ =~ /opposite signs at/),"brent() throw sign exception for 'x^2 - 4' on wrong interval [4,5]");

# fault handling
eval { $p4->brent(a => 0, b => 0); };
ok((defined $@ && $@ =~ /same value for a and b/),"brent() fails when a == b");

eval {$p1->brent(a => undef, b => 0); };
ok((defined $@ && $@ =~ /got undefined a/),"a => undef");

eval {$p1->brent(a => 0, b => undef); };
ok((defined $@ && $@ =~ /got undefined b/),"b => undef");

eval {$p1->brent(precision => undef); };
ok((defined $@ && $@ =~ /got undefined precision/),"precision => undef");

eval {$p1->brent(a => 'abc', b => 0); };
ok((defined $@ && $@ =~ /got non numeric a/),"a => 'abc'");

eval {$p1->brent(a => 0, b => 'abc'); };
ok((defined $@ && $@ =~ /got non numeric b/),"b => 'abc'");

eval {$p1->brent(precision => 'abc'); };
ok((defined $@ && $@ =~ /got non numeric precision/),"precision => 'abc'");
