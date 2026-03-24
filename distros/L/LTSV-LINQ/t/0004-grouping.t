######################################################################
#
# 0004-grouping.t - Grouping and aggregation tests
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

print "1..16\n";

# Test data
my @data = (
    {category => 'A', value => 10},
    {category => 'B', value => 20},
    {category => 'A', value => 30},
    {category => 'B', value => 40},
    {category => 'C', value => 50},
);

# Test 1: GroupBy creates groups
my @groups = LTSV::LINQ->From(\@data)
    ->GroupBy(sub { $_[0]{category} })
    ->ToArray();
ok(@groups == 3, 'GroupBy creates correct number of groups');

# Test 2: Group keys are correct
my %keys = map { $_->{Key} => 1 } @groups;
ok($keys{A} && $keys{B} && $keys{C}, 'GroupBy creates correct keys');

# Test 3: Group elements are correct
my($group_a) = grep { $_->{Key} eq 'A' } @groups;
ok(scalar(@{$group_a->{Elements}}) == 2, 'GroupBy groups elements correctly');

# Test 4: Aggregation with grouping
my @stats = LTSV::LINQ->From(\@data)
    ->GroupBy(sub { $_[0]{category} })
    ->Select(sub {
        my $g = shift;
        my $sum = 0;
        $sum += $_->{value} for @{$g->{Elements}};
        return {
            Category => $g->{Key},
            Total => $sum,
        };
    })
    ->ToArray();

my($stat_a) = grep { $_->{Category} eq 'A' } @stats;
ok($stat_a->{Total} == 40, 'Aggregation with grouping works');

# Test 5: Distinct
my @values = LTSV::LINQ->From([1, 2, 2, 3, 3, 3, 4])->Distinct()->ToArray();
ok(@values == 4, 'Distinct removes duplicates');

# Test 6: Distinct with comparer
my @data2 = (
    {id => 1, name => 'A'},
    {id => 2, name => 'B'},
    {id => 1, name => 'C'},
);
my @distinct = LTSV::LINQ->From(\@data2)
    ->Distinct(sub { $_[0]{id} })
    ->ToArray();
ok(@distinct == 2, 'Distinct with comparer works');

# Test 7: TakeWhile
my @taken = LTSV::LINQ->From([1, 2, 3, 4, 5])
    ->TakeWhile(sub { $_[0] < 4 })
    ->ToArray();
ok(@taken == 3 && $taken[2] == 3, 'TakeWhile works correctly');

# Test 8: Reverse
my @reversed = LTSV::LINQ->From([1, 2, 3])->Reverse()->ToArray();
ok($reversed[0] == 3 && $reversed[2] == 1, 'Reverse works correctly');

#---------------------------------------------------------------------
# GroupBy insertion order (v1.03: groups returned in first-seen key order,
# matching .NET LINQ behaviour - no longer sorted alphabetically)
#---------------------------------------------------------------------

# Test 9: GroupBy preserves insertion order
my @order_data = (
    {cat => 'B', v => 1},
    {cat => 'A', v => 2},
    {cat => 'C', v => 3},
    {cat => 'A', v => 4},
    {cat => 'B', v => 5},
);
my @og = LTSV::LINQ->From(\@order_data)
    ->GroupBy(sub { $_[0]{cat} })
    ->ToArray();
ok($og[0]{Key} eq 'B' && $og[1]{Key} eq 'A' && $og[2]{Key} eq 'C',
   'GroupBy: groups in insertion order (B A C)');

# Test 10: GroupBy insertion order - first occurrence determines position
my @order2 = (
    {k => 'z', v => 1},
    {k => 'a', v => 2},
    {k => 'z', v => 3},
);
my @og2 = LTSV::LINQ->From(\@order2)
    ->GroupBy(sub { $_[0]{k} })
    ->ToArray();
ok(@og2 == 2 && $og2[0]{Key} eq 'z' && $og2[1]{Key} eq 'a',
   'GroupBy: first-seen key comes first (z before a)');

# Test 11: GroupBy insertion order with original @data (A first, then B, then C)
ok($groups[0]{Key} eq 'A' && $groups[1]{Key} eq 'B' && $groups[2]{Key} eq 'C',
   'GroupBy: A B C order (A is first-seen in @data)');

#---------------------------------------------------------------------
# Distinct with hashref/arrayref content equality
# (v1.03: Distinct without key_selector now uses _make_key for content
#  comparison, consistent with Intersect and Except)
#---------------------------------------------------------------------

# Test 12: Distinct deduplicates hashrefs by content
my @hrefs = (
    {id => 1, name => 'Alice'},
    {id => 2, name => 'Bob'},
    {id => 1, name => 'Alice'},   # content-duplicate of first
);
my @dist_hrefs = LTSV::LINQ->From(\@hrefs)->Distinct()->ToArray();
ok(@dist_hrefs == 2,
   'Distinct: deduplicates hashrefs by content');

# Test 13: Distinct is insensitive to key order in hashrefs
my @hrefs2 = (
    {b => 2, a => 1},
    {a => 1, b => 2},   # same content, different insertion order
);
my @dist2 = LTSV::LINQ->From(\@hrefs2)->Distinct()->ToArray();
ok(@dist2 == 1,
   'Distinct: same-content hashrefs treated as equal regardless of key order');

# Test 14: Distinct deduplicates arrayrefs by content
my @arefs = ([1, 2], [3, 4], [1, 2]);
my @dist3 = LTSV::LINQ->From(\@arefs)->Distinct()->ToArray();
ok(@dist3 == 2,
   'Distinct: deduplicates arrayrefs by content');

# Test 15: Distinct with key_selector still works (unchanged behaviour)
my @hrefs3 = (
    {id => 1, name => 'Alice'},
    {id => 1, name => 'ALICE'},   # same id, different name
    {id => 2, name => 'Bob'},
);
my @dist4 = LTSV::LINQ->From(\@hrefs3)
    ->Distinct(sub { $_[0]{id} })
    ->ToArray();
ok(@dist4 == 2,
   'Distinct: key_selector still deduplicates by extracted key');

# Test 16: Distinct on plain scalars (unchanged behaviour)
my @scalars = ('x', 'y', 'x', 'z', 'y');
my @dist5 = LTSV::LINQ->From(\@scalars)->Distinct()->ToArray();
ok(@dist5 == 3,
   'Distinct: plain scalar deduplication unchanged');

exit($FAIL ? 1 : 0);
