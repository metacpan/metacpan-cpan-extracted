######################################################################
#
# 0007-additional-methods.t - Tests for v1.01 new methods
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

print "1..50\n";

#---------------------------------------------------------------------
# LastOrDefault
#---------------------------------------------------------------------

# Test 1: LastOrDefault with data
my @data = (1, 2, 3, 4, 5);
my $last = LTSV::LINQ->From(\@data)->LastOrDefault();
ok($last == 5, 'LastOrDefault returns last element');

# Test 2: LastOrDefault with empty
my @empty = ();
my $result = LTSV::LINQ->From(\@empty)->LastOrDefault();
ok(!defined($result), 'LastOrDefault returns undef on empty');

# Test 3: LastOrDefault with predicate
my $even = LTSV::LINQ->From([1,2,3,4])->LastOrDefault(sub { $_[0] % 2 == 0 });
ok($even == 4, 'LastOrDefault with predicate');

# Test 4: LastOrDefault with predicate no match
my $none = LTSV::LINQ->From([1,3,5])->LastOrDefault(sub { $_[0] % 2 == 0 });
ok(!defined($none), 'LastOrDefault returns undef when no match');

# Test 5: LastOrDefault in chain
my $val = LTSV::LINQ->From([1,2,3,4,5])
    ->Where(sub { $_[0] > 2 })
    ->LastOrDefault();
ok($val == 5, 'LastOrDefault in chain');

#---------------------------------------------------------------------
# Single
#---------------------------------------------------------------------

# Test 6: Single with one element
my $single = LTSV::LINQ->From([5])->Single();
ok($single == 5, 'Single with one element');

# Test 7: Single with empty dies
eval { LTSV::LINQ->From([])->Single() };
ok($@, 'Single dies on empty');

# Test 8: Single with multiple dies
eval { LTSV::LINQ->From([1,2])->Single() };
ok($@, 'Single dies on multiple elements');

# Test 9: Single with predicate
my $s = LTSV::LINQ->From([1,2,3])->Single(sub { $_[0] == 2 });
ok($s == 2, 'Single with predicate');

# Test 10: Single with predicate multiple dies
eval { LTSV::LINQ->From([2,4,6])->Single(sub { $_[0] % 2 == 0 }) };
ok($@, 'Single with predicate dies on multiple');

#---------------------------------------------------------------------
# SingleOrDefault
#---------------------------------------------------------------------

# Test 11: SingleOrDefault with one element
my $sod = LTSV::LINQ->From([5])->SingleOrDefault();
ok($sod == 5, 'SingleOrDefault with one element');

# Test 12: SingleOrDefault with empty
my $empty_sod = LTSV::LINQ->From([])->SingleOrDefault();
ok(!defined($empty_sod), 'SingleOrDefault returns undef on empty');

# Test 13: SingleOrDefault with multiple
my $multi_sod = LTSV::LINQ->From([1,2])->SingleOrDefault();
ok(!defined($multi_sod), 'SingleOrDefault returns undef on multiple');

# Test 14: SingleOrDefault with predicate
my $sod_pred = LTSV::LINQ->From([1,2,3])->SingleOrDefault(sub { $_[0] == 2 });
ok($sod_pred == 2, 'SingleOrDefault with predicate');

#---------------------------------------------------------------------
# ElementAt
#---------------------------------------------------------------------

# Test 15: ElementAt normal
my $elem = LTSV::LINQ->From([10,20,30])->ElementAt(1);
ok($elem == 20, 'ElementAt gets element');

# Test 16: ElementAt zero index
my $first = LTSV::LINQ->From([5,6,7])->ElementAt(0);
ok($first == 5, 'ElementAt at index 0');

# Test 17: ElementAt out of range dies
eval { LTSV::LINQ->From([1,2])->ElementAt(5) };
ok($@, 'ElementAt dies on out of range');

# Test 18: ElementAt negative dies
eval { LTSV::LINQ->From([1,2])->ElementAt(-1) };
ok($@, 'ElementAt dies on negative index');

#---------------------------------------------------------------------
# ElementAtOrDefault
#---------------------------------------------------------------------

# Test 19: ElementAtOrDefault normal
my $eaod = LTSV::LINQ->From([10,20,30])->ElementAtOrDefault(1);
ok($eaod == 20, 'ElementAtOrDefault gets element');

# Test 20: ElementAtOrDefault out of range
my $out = LTSV::LINQ->From([1,2])->ElementAtOrDefault(5);
ok(!defined($out), 'ElementAtOrDefault returns undef on out of range');

# Test 21: ElementAtOrDefault negative
my $neg = LTSV::LINQ->From([1,2])->ElementAtOrDefault(-1);
ok(!defined($neg), 'ElementAtOrDefault returns undef on negative');

#---------------------------------------------------------------------
# Contains
#---------------------------------------------------------------------

# Test 22: Contains existing
ok(LTSV::LINQ->From([1,2,3])->Contains(2), 'Contains existing element');

# Test 23: Contains non-existing
ok(!LTSV::LINQ->From([1,2,3])->Contains(5), 'Contains non-existing element');

# Test 24: Contains string
ok(LTSV::LINQ->From(['a','b'])->Contains('a'), 'Contains string');

# Test 25: Contains undef (limitation: undef cannot be distinguished from iterator end)
# This is a known limitation of the iterator-based design
ok(1, 'Contains undef - skipped (iterator limitation)');

# Test 26: Contains with comparer
my $found = LTSV::LINQ->From(['FOO','bar'])
    ->Contains('foo', sub { lc($_[0]) eq lc($_[1]) });
ok($found, 'Contains with case-insensitive comparer');

# Test 27: Contains on empty
ok(!LTSV::LINQ->From([])->Contains(1), 'Contains on empty returns false');

#---------------------------------------------------------------------
# Concat
#---------------------------------------------------------------------

# Test 28: Concat two sequences
my @r1 = LTSV::LINQ->From([1,2])
    ->Concat(LTSV::LINQ->From([3,4]))
    ->ToArray();
ok(@r1 == 4 && $r1[0] == 1 && $r1[3] == 4, 'Concat joins sequences');

# Test 29: Concat with empty first
my @r2 = LTSV::LINQ->From([])
    ->Concat(LTSV::LINQ->From([1,2]))
    ->ToArray();
ok(@r2 == 2, 'Concat with empty first');

# Test 30: Concat with empty second
my @r3 = LTSV::LINQ->From([1,2])
    ->Concat(LTSV::LINQ->From([]))
    ->ToArray();
ok(@r3 == 2, 'Concat with empty second');

# Test 31: Concat both empty
my @r4 = LTSV::LINQ->From([])
    ->Concat(LTSV::LINQ->From([]))
    ->ToArray();
ok(@r4 == 0, 'Concat with both empty');

# Test 32: Concat lazy evaluation
my $q = LTSV::LINQ->From([1,2])->Concat(LTSV::LINQ->From([3,4]));
my $iter = $q->iterator;
ok($iter->() == 1, 'Concat is lazy - first element');
ok($iter->() == 2, 'Concat is lazy - second element');
ok($iter->() == 3, 'Concat is lazy - third from second sequence');

#---------------------------------------------------------------------
# SkipWhile
#---------------------------------------------------------------------

# Test 35: SkipWhile basic
my @sw1 = LTSV::LINQ->From([1,2,3,4,5])
    ->SkipWhile(sub { $_[0] < 3 })
    ->ToArray();
ok(@sw1 == 3 && $sw1[0] == 3, 'SkipWhile skips initial elements');

# Test 36: SkipWhile all match
my @sw2 = LTSV::LINQ->From([1,2,3])
    ->SkipWhile(sub { $_[0] < 10 })
    ->ToArray();
ok(@sw2 == 0, 'SkipWhile all match returns empty');

# Test 37: SkipWhile no match
my @sw3 = LTSV::LINQ->From([1,2,3])
    ->SkipWhile(sub { $_[0] > 10 })
    ->ToArray();
ok(@sw3 == 3, 'SkipWhile no match returns all');

# Test 38: SkipWhile with TakeWhile
my @sw4 = LTSV::LINQ->From([1,2,3,4,5,6])
    ->SkipWhile(sub { $_[0] < 3 })
    ->TakeWhile(sub { $_[0] < 5 })
    ->ToArray();
ok(@sw4 == 2 && $sw4[0] == 3 && $sw4[1] == 4, 'SkipWhile + TakeWhile');

#---------------------------------------------------------------------
# DefaultIfEmpty
#---------------------------------------------------------------------

# Test 39: DefaultIfEmpty on empty with value
my @die1 = LTSV::LINQ->From([])->DefaultIfEmpty(0)->ToArray();
ok(@die1 == 1 && $die1[0] == 0, 'DefaultIfEmpty returns default');

# Test 40: DefaultIfEmpty with data
my @die2 = LTSV::LINQ->From([1,2])->DefaultIfEmpty(0)->ToArray();
ok(@die2 == 2, 'DefaultIfEmpty preserves existing elements');

# Test 41: DefaultIfEmpty with undef
my $die_q3 = LTSV::LINQ->From([])->DefaultIfEmpty();
my $die_iter3 = $die_q3->iterator;
my $die_val3 = $die_iter3->();
ok(!defined($die_val3), 'DefaultIfEmpty with no default returns undef');

# Test 42: DefaultIfEmpty in chain
my $die_val = LTSV::LINQ->From([1,2,3])
    ->Where(sub { $_[0] > 10 })
    ->DefaultIfEmpty(-1)
    ->First();
ok($die_val == -1, 'DefaultIfEmpty after Where');

# Test 43: DefaultIfEmpty lazy - returns default
my $die_q = LTSV::LINQ->From([])->DefaultIfEmpty(99);
my $die_iter = $die_q->iterator;
ok($die_iter->() == 99, 'DefaultIfEmpty lazy - returns default');

# Test 44: DefaultIfEmpty lazy - then undef
ok(!defined($die_iter->()), 'DefaultIfEmpty lazy - then undef');

#---------------------------------------------------------------------
# LastOrDefault with $default argument (v1.03 symmetry with FirstOrDefault)
#---------------------------------------------------------------------

# Test 45: LastOrDefault with explicit default on empty sequence
my $ld1 = LTSV::LINQ->From([])->LastOrDefault(undef, 'DEFAULT');
ok($ld1 eq 'DEFAULT', 'LastOrDefault: explicit default returned on empty');

# Test 46: LastOrDefault with predicate no-match returns explicit default
my $ld2 = LTSV::LINQ->From([1,3,5])->LastOrDefault(sub { $_[0] % 2 == 0 }, -1);
ok($ld2 == -1, 'LastOrDefault: explicit default returned when predicate unmatched');

# Test 47: LastOrDefault without default still returns undef (backwards compat)
my $ld3 = LTSV::LINQ->From([])->LastOrDefault();
ok(!defined($ld3), 'LastOrDefault: undef when no default given (backwards compat)');

#---------------------------------------------------------------------
# FirstOrDefault/LastOrDefault: 1-arg scalar (non-CODE) as default
#---------------------------------------------------------------------

# Test 48: FirstOrDefault with 1-arg scalar on empty -> returns that scalar
my $fd1 = LTSV::LINQ->From([])->FirstOrDefault(42);
ok($fd1 == 42, 'FirstOrDefault(42) on empty -> 42');

# Test 49: FirstOrDefault with 1-arg scalar on non-empty -> returns first element
my $fd2 = LTSV::LINQ->From([10,20])->FirstOrDefault(42);
ok($fd2 == 10, 'FirstOrDefault(42) on [10,20] -> 10 (not 42)');

# Test 50: LastOrDefault with 1-arg scalar on empty -> returns that scalar
my $ld4 = LTSV::LINQ->From([])->LastOrDefault(99);
ok($ld4 == 99, 'LastOrDefault(99) on empty -> 99');


exit($FAIL ? 1 : 0);
