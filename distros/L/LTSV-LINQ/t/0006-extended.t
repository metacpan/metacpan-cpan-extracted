######################################################################
#
# 0006-extended.t - Extended functionality tests
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

print "1..20\n";

# Test 1: From with array
my @data = (1, 2, 3, 4, 5);
my $q1 = LTSV::LINQ->From(\@data);
ok(defined($q1), 'From creates query object');

# Test 2: Where filtering
my @filtered = LTSV::LINQ->From(\@data)->Where(sub { $_[0] > 2 })->ToArray();
ok(@filtered == 3 && $filtered[0] == 3, 'Where filters correctly');

# Test 3: Select transformation
my @doubled = LTSV::LINQ->From([1, 2, 3])->Select(sub { $_[0] * 2 })->ToArray();
ok($doubled[0] == 2 && $doubled[2] == 6, 'Select transforms correctly');

# Test 4: GroupBy
my @items = (
    {type => 'A', value => 1},
    {type => 'B', value => 2},
    {type => 'A', value => 3},
);
my @groups = LTSV::LINQ->From(\@items)
    ->GroupBy(sub { $_[0]{type} })
    ->ToArray();
ok(@groups == 2, 'GroupBy creates correct number of groups');

# Test 5: OrderBy with positive numbers
my @sorted = LTSV::LINQ->From([3, 1, 4, 1, 5])
    ->OrderBy(sub { $_[0] })
    ->ToArray();
ok($sorted[0] == 1 && $sorted[4] == 5, 'OrderBy sorts positive numbers');

# Test 6: OrderBy with negative numbers
my @neg_sorted = LTSV::LINQ->From([-3, 1, -4, 1, 5])
    ->OrderBy(sub { $_[0] })
    ->ToArray();
ok($neg_sorted[0] == -4 && $neg_sorted[4] == 5, 'OrderBy handles negative numbers');

# Test 7: OrderBy with exponential notation
my @exp_sorted = LTSV::LINQ->From(['1.2e+3', '500', '2e+3'])
    ->OrderBy(sub { $_[0] })
    ->ToArray();
ok($exp_sorted[0] eq '500' && $exp_sorted[2] eq '2e+3', 'OrderBy handles exponential notation');

# Test 8: OrderBy with whitespace
my @ws_sorted = LTSV::LINQ->From([' 3 ', '1', ' 2'])
    ->OrderBy(sub { $_[0] })
    ->ToArray();
ok($ws_sorted[0] eq '1', 'OrderBy handles whitespace');

# Test 9: Count
my $count = LTSV::LINQ->From([1, 2, 3, 4, 5])->Count();
ok($count == 5, 'Count returns correct value');

# Test 10: Sum
my $sum = LTSV::LINQ->From([1, 2, 3, 4, 5])->Sum();
ok($sum == 15, 'Sum calculates correctly');

# Test 11: AverageOrDefault with empty sequence
my @empty = ();
my $avg_empty = LTSV::LINQ->From(\@empty)->AverageOrDefault();
ok(!defined($avg_empty), 'AverageOrDefault returns undef for empty sequence');

# Test 12: AverageOrDefault with data
my $avg = LTSV::LINQ->From([2, 4, 6])->AverageOrDefault();
ok($avg == 4, 'AverageOrDefault calculates correctly');

# Test 13: LTSV file parsing - create test file
{
    open(FH, ">t/test_parse.ltsv") || die "Cannot create test file: $!";
    print FH "time:2026-02-14T10:00:00\tstatus:200\turl:/index.html\tbytes:1024\n";
    print FH "time:2026-02-14T10:01:00\tstatus:404\turl:/missing\tbytes:512\n";
    print FH "time:2026-02-14T10:02:00\tstatus:200\turl:/about\tbytes:2048\n";
    close FH;
}
ok(-f 't/test_parse.ltsv', 'create test file');

# Test 14: FromLTSV
my @ltsv = LTSV::LINQ->FromLTSV('t/test_parse.ltsv')->ToArray();
ok(@ltsv == 3, 'FromLTSV parses file correctly');

# Test 15: LTSV field access
ok($ltsv[0]{status} eq '200', 'LTSV fields parsed correctly');

# Test 16: LTSV filtering
my @status200 = LTSV::LINQ->FromLTSV('t/test_parse.ltsv')
    ->Where(status => '200')
    ->ToArray();
ok(@status200 == 2, 'LTSV filtering works');

# Test 17: Lazy evaluation - verify iterator is not exhausted
my $query = LTSV::LINQ->From([1, 2, 3, 4, 5]);
my $first = $query->iterator->();
ok($first == 1, 'Lazy evaluation - first element');

# Test 18: Lazy evaluation - second element
my $second = $query->iterator->();
ok($second == 2, 'Lazy evaluation - second element');

# Test 19: Chaining doesn't execute immediately
my $executed = 0;
my $lazy_query = LTSV::LINQ->From([1, 2, 3])
    ->Where(sub { $executed++; $_[0] > 1 });
ok($executed == 0, 'Lazy evaluation - Where does not execute immediately');

# Test 20: Execution happens on ToArray
my @lazy_result = $lazy_query->ToArray();
ok($executed >= 3 && @lazy_result == 2, 'Lazy evaluation - execution on ToArray');

# Cleanup
unlink 't/test_parse.ltsv';

exit($FAIL ? 1 : 0);
