######################################################################
#
# 0008-set-and-aggregate.t - Tests for set operations and aggregate
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

print "1..25\n";

#---------------------------------------------------------------------
# SequenceEqual
#---------------------------------------------------------------------

# Test 1: SequenceEqual - same sequences
my $equal = LTSV::LINQ->From([1,2,3])
    ->SequenceEqual(LTSV::LINQ->From([1,2,3]));
ok($equal, 'SequenceEqual same sequences');

# Test 2: SequenceEqual - different elements
my $diff = LTSV::LINQ->From([1,2,3])
    ->SequenceEqual(LTSV::LINQ->From([1,2,4]));
ok(!$diff, 'SequenceEqual different elements');

# Test 3: SequenceEqual - different lengths
my $len = LTSV::LINQ->From([1,2])
    ->SequenceEqual(LTSV::LINQ->From([1,2,3]));
ok(!$len, 'SequenceEqual different lengths');

# Test 4: SequenceEqual - both empty
my $empty_eq = LTSV::LINQ->From([])
    ->SequenceEqual(LTSV::LINQ->From([]));
ok($empty_eq, 'SequenceEqual both empty');

# Test 5: SequenceEqual - with comparer
my $case_eq = LTSV::LINQ->From(['A','B'])
    ->SequenceEqual(LTSV::LINQ->From(['a','b']), sub { lc($_[0]) eq lc($_[1]) });
ok($case_eq, 'SequenceEqual case-insensitive');

#---------------------------------------------------------------------
# Aggregate
#---------------------------------------------------------------------

# Test 6: Aggregate - sum without seed
my $sum1 = LTSV::LINQ->From([1,2,3,4])
    ->Aggregate(sub { $_[0] + $_[1] });
ok($sum1 == 10, 'Aggregate sum without seed');

# Test 7: Aggregate - product with seed
my $prod = LTSV::LINQ->From([2,3,4])
    ->Aggregate(1, sub { $_[0] * $_[1] });
ok($prod == 24, 'Aggregate product with seed');

# Test 8: Aggregate - string concatenation
my $str = LTSV::LINQ->From(['a','b','c'])
    ->Aggregate('', sub { $_[0] ? "$_[0],$_[1]" : $_[1] });
ok($str eq 'a,b,c', 'Aggregate string concatenation');

# Test 9: Aggregate - with result selector
my $result = LTSV::LINQ->From([1,2,3])
    ->Aggregate(0,
        sub { $_[0] + $_[1] },
        sub { "Sum: $_[0]" });
ok($result eq 'Sum: 6', 'Aggregate with result selector');

# Test 10: Aggregate - empty without seed dies
eval { LTSV::LINQ->From([])->Aggregate(sub { $_[0] + $_[1] }) };
ok($@, 'Aggregate dies on empty without seed');

#---------------------------------------------------------------------
# Union
#---------------------------------------------------------------------

# Test 11: Union - basic
my @u1 = LTSV::LINQ->From([1,2,3])
    ->Union(LTSV::LINQ->From([3,4,5]))
    ->ToArray();
ok(@u1 == 5 && grep($_ == 4, @u1), 'Union basic');

# Test 12: Union - removes duplicates
my @u2 = LTSV::LINQ->From([1,1,2])
    ->Union(LTSV::LINQ->From([2,2,3]))
    ->ToArray();
ok(@u2 == 3, 'Union removes duplicates');

# Test 13: Union - empty
my @u3 = LTSV::LINQ->From([])
    ->Union(LTSV::LINQ->From([1,2]))
    ->ToArray();
ok(@u3 == 2, 'Union with empty first');

#---------------------------------------------------------------------
# Intersect
#---------------------------------------------------------------------

# Test 14: Intersect - basic
my @i1 = LTSV::LINQ->From([1,2,3])
    ->Intersect(LTSV::LINQ->From([2,3,4]))
    ->ToArray();
ok(@i1 == 2 && grep($_ == 2, @i1) && grep($_ == 3, @i1), 'Intersect basic');

# Test 15: Intersect - no common elements
my @i2 = LTSV::LINQ->From([1,2])
    ->Intersect(LTSV::LINQ->From([3,4]))
    ->ToArray();
ok(@i2 == 0, 'Intersect no common elements');

# Test 16: Intersect - removes duplicates
my @i3 = LTSV::LINQ->From([1,1,2,2])
    ->Intersect(LTSV::LINQ->From([2,2,3]))
    ->ToArray();
ok(@i3 == 1 && $i3[0] == 2, 'Intersect removes duplicates');

# Test 17: Intersect - with hash references
my @users1 = ({id => 1}, {id => 2});
my @users2 = ({id => 2}, {id => 3});
my @i_hash = LTSV::LINQ->From(\@users1)
    ->Intersect(LTSV::LINQ->From(\@users2))
    ->ToArray();
ok(@i_hash == 1, 'Intersect with hash references');

#---------------------------------------------------------------------
# Except
#---------------------------------------------------------------------

# Test 18: Except - basic
my @e1 = LTSV::LINQ->From([1,2,3])
    ->Except(LTSV::LINQ->From([2,3,4]))
    ->ToArray();
ok(@e1 == 1 && $e1[0] == 1, 'Except basic');

# Test 19: Except - all removed
my @e2 = LTSV::LINQ->From([1,2])
    ->Except(LTSV::LINQ->From([1,2,3]))
    ->ToArray();
ok(@e2 == 0, 'Except all removed');

# Test 20: Except - no common elements
my @e3 = LTSV::LINQ->From([1,2])
    ->Except(LTSV::LINQ->From([3,4]))
    ->ToArray();
ok(@e3 == 2, 'Except no common elements returns all');

# Test 21: Except - removes duplicates
my @e4 = LTSV::LINQ->From([1,1,2,2,3])
    ->Except(LTSV::LINQ->From([2]))
    ->ToArray();
ok(@e4 == 2 && grep($_ == 1, @e4) && grep($_ == 3, @e4), 'Except removes duplicates');

#---------------------------------------------------------------------
# Combined operations
#---------------------------------------------------------------------

# Test 22: Union + Where
my @comb1 = LTSV::LINQ->From([1,2,3])
    ->Union(LTSV::LINQ->From([3,4,5]))
    ->Where(sub { $_[0] > 2 })
    ->ToArray();
ok(@comb1 == 3, 'Union + Where');

# Test 23: Intersect + Select
my @comb2 = LTSV::LINQ->From([1,2,3])
    ->Intersect(LTSV::LINQ->From([2,3,4]))
    ->Select(sub { $_[0] * 2 })
    ->ToArray();
ok(@comb2 == 2 && grep($_ == 4, @comb2), 'Intersect + Select');

# Test 24: Aggregate array building
my $arr = LTSV::LINQ->From(['a','b','c'])
    ->Aggregate([], sub {
        my($list, $item) = @_;
        push @$list, uc($item);
        return $list;
    });
ok(@$arr == 3 && $arr->[0] eq 'A', 'Aggregate builds array');

# Test 25: Complex set operations
my @complex = LTSV::LINQ->From([1,2,3,4,5])
    ->Except(LTSV::LINQ->From([2,4]))
    ->Union(LTSV::LINQ->From([6]))
    ->ToArray();
ok(@complex == 4 && grep($_ == 6, @complex), 'Complex set operations');


exit($FAIL ? 1 : 0);
