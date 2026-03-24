######################################################################
#
# 0005-complex.t - Complex query tests
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use LTSV::LINQ;

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub like { my($g,$re,$n)=@_; $T++; defined($g)&&$g=~$re ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub plan_skip { print "1..0 # SKIP $_[0]\n"; exit 0 }

print "1..14\n";

# Test 1: Method chaining
my @result1 = LTSV::LINQ->Range(1, 20)
    ->Where(sub { $_[0] % 2 == 0 })
    ->Select(sub { $_[0] * 2 })
    ->OrderByDescending(sub { $_[0] })
    ->Take(5)
    ->ToArray();
ok(@result1 == 5 && $result1[0] == 40, 'Complex method chaining works');

# Test 2: All quantifier
my $all_even = LTSV::LINQ->From([2, 4, 6, 8])
    ->All(sub { $_[0] % 2 == 0 });
ok($all_even == 1, 'All returns true when all match');

# Test 3: All returns false
my $not_all = LTSV::LINQ->From([1, 2, 3])
    ->All(sub { $_[0] % 2 == 0 });
ok($not_all == 0, 'All returns false when not all match');

# Test 4: Any quantifier
my $has_even = LTSV::LINQ->From([1, 2, 3])
    ->Any(sub { $_[0] % 2 == 0 });
ok($has_even == 1, 'Any returns true when match exists');

# Test 5: Any without predicate
my $is_not_empty = LTSV::LINQ->From([1])->Any();
ok($is_not_empty == 1, 'Any without predicate checks non-empty');

# Test 6: First with predicate
my $first_big = LTSV::LINQ->From([1, 2, 5, 3, 8])
    ->First(sub { $_[0] > 4 });
ok($first_big == 5, 'First with predicate works');

# Test 7: FirstOrDefault when found
my $found = LTSV::LINQ->From([1, 2, 3])
    ->FirstOrDefault(sub { $_[0] > 2 }, 0);
ok($found == 3, 'FirstOrDefault returns found value');

# Test 8: FirstOrDefault with default
my $not_found = LTSV::LINQ->From([1, 2, 3])
    ->FirstOrDefault(sub { $_[0] > 10 }, 99);
ok($not_found == 99, 'FirstOrDefault returns default when not found');

# Test 9: Last
my $last = LTSV::LINQ->From([1, 2, 3, 4, 5])->Last();
ok($last == 5, 'Last returns last element');

# Test 10: SelectMany - normal arrayref return
my @flattened = LTSV::LINQ->From([
    [1, 2],
    [3, 4],
    [5]
])->SelectMany(sub { $_[0] })->ToArray();
ok(@flattened == 5 && $flattened[0] == 1 && $flattened[4] == 5,
   'SelectMany flattens correctly');

#---------------------------------------------------------------------
# SelectMany strict ARRAY return (v1.03: non-arrayref now dies,
# previously passed through silently like Select)
#---------------------------------------------------------------------

# Test 11: SelectMany dies when selector returns a scalar
eval {
    LTSV::LINQ->From([1, 2, 3])
        ->SelectMany(sub { $_[0] * 2 })
        ->ToArray();
};
ok($@ =~ /must return an ARRAY/,
   'SelectMany dies on scalar return');

# Test 12: SelectMany dies when selector returns a hashref
eval {
    LTSV::LINQ->From([{a => 1}])
        ->SelectMany(sub { $_[0] })
        ->ToArray();
};
ok($@ =~ /must return an ARRAY/,
   'SelectMany dies on hashref return');

# Test 13: SelectMany empty arrayref is valid (produces no elements)
my @empty_flat = LTSV::LINQ->From([1, 2, 3])
    ->SelectMany(sub { [] })
    ->ToArray();
ok(@empty_flat == 0,
   'SelectMany empty arrayref is valid');

# Test 14: SelectMany mixed empty and non-empty
my @mixed_flat = LTSV::LINQ->From([1, 2, 3])
    ->SelectMany(sub { $_[0] % 2 ? [$_[0]] : [] })
    ->ToArray();
ok(@mixed_flat == 2 && $mixed_flat[0] == 1 && $mixed_flat[1] == 3,
   'SelectMany mixed empty/non-empty arrayrefs');

exit($FAIL ? 1 : 0);
