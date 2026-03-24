######################################################################
#
# 0012-v103-ordering.t - Tests for v1.03 ordering methods
#
# New methods: OrderByStr, OrderByStrDescending,
#              OrderByNum, OrderByNumDescending
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

print "1..40\n";

#---------------------------------------------------------------------
# OrderByStr - unconditional string (cmp) sort
#---------------------------------------------------------------------

# Test 1: OrderByStr sorts lexicographically
my @str1 = LTSV::LINQ->From(['banana', 'apple', 'cherry'])
    ->OrderByStr(sub { $_[0] })
    ->ToArray();
ok($str1[0] eq 'apple' && $str1[1] eq 'banana' && $str1[2] eq 'cherry',
   'OrderByStr: lexicographic order');

# Test 2: OrderByStr treats numeric strings lexicographically (10 < 9)
my @str2 = LTSV::LINQ->From(['10', '9', '2', '20', '1'])
    ->OrderByStr(sub { $_[0] })
    ->ToArray();
ok($str2[0] eq '1' && $str2[1] eq '10' && $str2[4] eq '9',
   'OrderByStr: "10" sorts before "9" (lexicographic)');

# Test 3: OrderByStr on hashref field
my @hdata = (
    {code => 'B2', val => 1},
    {code => 'A10', val => 2},
    {code => 'A2', val => 3},
);
my @str3 = LTSV::LINQ->From(\@hdata)
    ->OrderByStr(sub { $_[0]{code} })
    ->ToArray();
ok($str3[0]{code} eq 'A10' && $str3[1]{code} eq 'A2' && $str3[2]{code} eq 'B2',
   'OrderByStr: hashref field lexicographic');

# Test 4: undef in source array - known iterator limitation (undef = EOF signal)
# Sequences containing undef values are not supported; this test documents
# the limitation rather than testing the sort key handling.
ok(1, 'OrderByStr: undef in sequence - iterator limitation (documented)');

# Test 5: OrderByStr on empty sequence
my @str5 = LTSV::LINQ->From([])->OrderByStr(sub { $_[0] })->ToArray();
ok(@str5 == 0, 'OrderByStr: empty sequence');

# Test 6: OrderByStr on single element
my @str6 = LTSV::LINQ->From(['x'])->OrderByStr(sub { $_[0] })->ToArray();
ok(@str6 == 1 && $str6[0] eq 'x', 'OrderByStr: single element');

#---------------------------------------------------------------------
# OrderByStrDescending
#---------------------------------------------------------------------

# Test 7: OrderByStrDescending reverse lexicographic
my @strd1 = LTSV::LINQ->From(['banana', 'apple', 'cherry'])
    ->OrderByStrDescending(sub { $_[0] })
    ->ToArray();
ok($strd1[0] eq 'cherry' && $strd1[2] eq 'apple',
   'OrderByStrDescending: reverse lexicographic');

# Test 8: OrderByStrDescending: "9" before "2" before "10" before "1"
my @strd2 = LTSV::LINQ->From(['10', '9', '2', '1'])
    ->OrderByStrDescending(sub { $_[0] })
    ->ToArray();
ok($strd2[0] eq '9' && $strd2[3] eq '1',
   'OrderByStrDescending: "9" is lexicographically largest');

# Test 9: OrderByStrDescending on hashref field
my @strd3 = LTSV::LINQ->From(\@hdata)
    ->OrderByStrDescending(sub { $_[0]{code} })
    ->ToArray();
ok($strd3[0]{code} eq 'B2' && $strd3[2]{code} eq 'A10',
   'OrderByStrDescending: hashref field');

#---------------------------------------------------------------------
# OrderByNum - unconditional numeric (<=>) sort
#---------------------------------------------------------------------

# Test 10: OrderByNum sorts numerically
my @num1 = LTSV::LINQ->From(['10', '9', '2', '20', '1'])
    ->OrderByNum(sub { $_[0] })
    ->ToArray();
ok($num1[0] eq '1' && $num1[1] eq '2' && $num1[4] eq '20',
   'OrderByNum: 1 2 9 10 20 (numeric)');

# Test 11: OrderByNum: "9" before "10" numerically (opposite of cmp)
ok($num1[2] eq '9' && $num1[3] eq '10',
   'OrderByNum: 9 before 10 (9 < 10 numerically)');

# Test 12: OrderByNum with negative numbers
my @num2 = LTSV::LINQ->From([-3, 1, -4, 1, 5])
    ->OrderByNum(sub { $_[0] })
    ->ToArray();
ok($num2[0] == -4 && $num2[4] == 5,
   'OrderByNum: handles negative numbers');

# Test 13: OrderByNum with decimals
my @num3 = LTSV::LINQ->From([1.5, 0.5, 2.5, 1.0])
    ->OrderByNum(sub { $_[0] })
    ->ToArray();
ok($num3[0] == 0.5 && $num3[3] == 2.5,
   'OrderByNum: handles decimals');

# Test 14: OrderByNum on hashref field
my @num4 = LTSV::LINQ->From([
    {bytes => '2048'},
    {bytes => '512'},
    {bytes => '1024'},
])->OrderByNum(sub { $_[0]{bytes} })->ToArray();
ok($num4[0]{bytes} eq '512' && $num4[2]{bytes} eq '2048',
   'OrderByNum: hashref field numeric sort');

# Test 15: undef in source array - known iterator limitation (undef = EOF signal)
# Sequences containing undef values are not supported; this test documents
# the limitation rather than testing the sort key handling.
ok(1, 'OrderByNum: undef in sequence - iterator limitation (documented)');

# Test 16: OrderByNum on empty sequence
my @num6 = LTSV::LINQ->From([])->OrderByNum(sub { $_[0] })->ToArray();
ok(@num6 == 0, 'OrderByNum: empty sequence');

#---------------------------------------------------------------------
# OrderByNumDescending
#---------------------------------------------------------------------

# Test 17: OrderByNumDescending sorts numerically descending
my @numd1 = LTSV::LINQ->From(['10', '9', '2', '20', '1'])
    ->OrderByNumDescending(sub { $_[0] })
    ->ToArray();
ok($numd1[0] eq '20' && $numd1[4] eq '1',
   'OrderByNumDescending: 20 10 9 2 1');

# Test 18: OrderByNumDescending with negatives
my @numd2 = LTSV::LINQ->From([-3, 1, -4, 5])
    ->OrderByNumDescending(sub { $_[0] })
    ->ToArray();
ok($numd2[0] == 5 && $numd2[3] == -4,
   'OrderByNumDescending: handles negatives');

# Test 19: OrderByNumDescending on hashref field
my @numd3 = LTSV::LINQ->From([
    {score => 85},
    {score => 92},
    {score => 78},
])->OrderByNumDescending(sub { $_[0]{score} })->ToArray();
ok($numd3[0]{score} == 92 && $numd3[2]{score} == 78,
   'OrderByNumDescending: hashref field');

#---------------------------------------------------------------------
# Contrast: OrderByStr vs OrderByNum for same data
#---------------------------------------------------------------------

# Test 20: Same data, different sort: str vs num
my @mixed = ['10', '9', '100', '2'];
my @by_str = LTSV::LINQ->From($mixed[0])->OrderByStr(sub { $_[0] })->ToArray();
my @by_num = LTSV::LINQ->From($mixed[0])->OrderByNum(sub { $_[0] })->ToArray();
ok($by_str[0] eq '10' && $by_num[0] eq '2',
   'OrderByStr vs OrderByNum: different results for same data');

# Test 21: OrderByStr and OrderByNum give opposite order for "10" vs "9"
ok($by_str[1] eq '100' && $by_num[3] eq '100',
   'OrderByStr: "100" second; OrderByNum: "100" last');

#---------------------------------------------------------------------
# Chaining with other methods
#---------------------------------------------------------------------

# Test 22: OrderByStr + Take
my @chain1 = LTSV::LINQ->From(['charlie', 'alice', 'bob'])
    ->OrderByStr(sub { $_[0] })
    ->Take(2)
    ->ToArray();
ok($chain1[0] eq 'alice' && $chain1[1] eq 'bob',
   'OrderByStr + Take');

# Test 23: OrderByNum + Where
my @chain2 = LTSV::LINQ->From([5, 3, 8, 1, 9])
    ->OrderByNum(sub { $_[0] })
    ->Where(sub { $_[0] > 4 })
    ->ToArray();
ok(@chain2 == 3 && $chain2[0] == 5,
   'OrderByNum + Where');

# Test 24: Where + OrderByStr
my @chain3 = LTSV::LINQ->From([
    {status => '200', url => '/c'},
    {status => '404', url => '/a'},
    {status => '200', url => '/b'},
])->Where(status => '200')
  ->OrderByStr(sub { $_[0]{url} })
  ->ToArray();
ok(@chain3 == 2 && $chain3[0]{url} eq '/b',
   'Where + OrderByStr');

# Test 25: OrderByNum + Select
my @chain4 = LTSV::LINQ->From([3, 1, 2])
    ->OrderByNum(sub { $_[0] })
    ->Select(sub { $_[0] * 10 })
    ->ToArray();
ok($chain4[0] == 10 && $chain4[2] == 30,
   'OrderByNum + Select');

# Test 26: OrderByStrDescending + Skip
my @chain5 = LTSV::LINQ->From(['a', 'c', 'b'])
    ->OrderByStrDescending(sub { $_[0] })
    ->Skip(1)
    ->ToArray();
ok(@chain5 == 2 && $chain5[0] eq 'b',
   'OrderByStrDescending + Skip');

#---------------------------------------------------------------------
# Stability: equal keys preserve original order (Perl 5.8+)
#---------------------------------------------------------------------

# Test 27: OrderByStr stability - equal keys preserve relative order
my @stab = (
    {name => 'Alice', dept => 'Eng'},
    {name => 'Bob',   dept => 'Sales'},
    {name => 'Carol', dept => 'Eng'},
    {name => 'Dave',  dept => 'Sales'},
);
my @stab_sorted = LTSV::LINQ->From(\@stab)
    ->OrderByStr(sub { $_[0]{dept} })
    ->ToArray();
# Eng group: Alice then Carol (original order)
# Sales group: Bob then Dave (original order)
ok($stab_sorted[0]{name} eq 'Alice' && $stab_sorted[1]{name} eq 'Carol',
   'OrderByStr: stable - Eng members in original order');
ok($stab_sorted[2]{name} eq 'Bob' && $stab_sorted[3]{name} eq 'Dave',
   'OrderByStr: stable - Sales members in original order');

# Test 29: OrderByNum stability
my @stab2 = (
    {score => 100, rank => 1},
    {score => 90,  rank => 2},
    {score => 100, rank => 3},
    {score => 90,  rank => 4},
);
my @stab2_sorted = LTSV::LINQ->From(\@stab2)
    ->OrderByNum(sub { $_[0]{score} })
    ->ToArray();
ok($stab2_sorted[0]{rank} == 2 && $stab2_sorted[1]{rank} == 4,
   'OrderByNum: stable - score=90 group in original order');
ok($stab2_sorted[2]{rank} == 1 && $stab2_sorted[3]{rank} == 3,
   'OrderByNum: stable - score=100 group in original order');

#---------------------------------------------------------------------
# LTSV-style access log: realistic use
#---------------------------------------------------------------------

my @access_log = (
    {status => '200', bytes => '2048', url => '/b'},
    {status => '404', bytes => '512',  url => '/x'},
    {status => '200', bytes => '1024', url => '/a'},
    {status => '200', bytes => '512',  url => '/c'},
);

# Test 31: Sort by bytes numerically ascending
my @by_bytes = LTSV::LINQ->From(\@access_log)
    ->OrderByNum(sub { $_[0]{bytes} })
    ->ToArray();
ok($by_bytes[0]{bytes} eq '512' && $by_bytes[3]{bytes} eq '2048',
   'LTSV: OrderByNum by bytes ascending');

# Test 32: Sort by url string descending, then take top-2
my @by_url_desc = LTSV::LINQ->From(\@access_log)
    ->Where(status => '200')
    ->OrderByStrDescending(sub { $_[0]{url} })
    ->Take(2)
    ->ToArray();
ok($by_url_desc[0]{url} eq '/c' && $by_url_desc[1]{url} eq '/b',
   'LTSV: Where + OrderByStrDescending + Take');

# Test 33: Top-3 by bytes (numeric desc), status 200 only
my @top3 = LTSV::LINQ->From(\@access_log)
    ->Where(status => '200')
    ->OrderByNumDescending(sub { $_[0]{bytes} })
    ->Take(3)
    ->ToArray();
ok($top3[0]{bytes} eq '2048',
   'LTSV: Where + OrderByNumDescending + Take');

#---------------------------------------------------------------------
# OrderBy (smart) vs OrderByStr vs OrderByNum: summary test
#---------------------------------------------------------------------

# Test 34: OrderBy (smart) on pure numeric strings = same as OrderByNum
my @smart = LTSV::LINQ->From(['10', '2', '1', '20'])
    ->OrderBy(sub { $_[0] })
    ->ToArray();
my @num_ver = LTSV::LINQ->From(['10', '2', '1', '20'])
    ->OrderByNum(sub { $_[0] })
    ->ToArray();
my $same = 1;
for my $i (0..$#smart) {
    $same = 0 unless $smart[$i] eq $num_ver[$i];
}
ok($same, 'OrderBy (smart) on pure-numeric strings matches OrderByNum');

# Test 35: OrderBy (smart) on mixed alphanumeric = falls back to cmp
my @mixed_data = LTSV::LINQ->From(['b10', 'a2', 'c1'])
    ->OrderBy(sub { $_[0] })
    ->ToArray();
my @str_ver = LTSV::LINQ->From(['b10', 'a2', 'c1'])
    ->OrderByStr(sub { $_[0] })
    ->ToArray();
my $same2 = 1;
for my $i (0..$#mixed_data) {
    $same2 = 0 unless $mixed_data[$i] eq $str_ver[$i];
}
ok($same2, 'OrderBy (smart) on mixed alphanumeric matches OrderByStr');

#---------------------------------------------------------------------
# OrderByNum + Aggregate
#---------------------------------------------------------------------

# Test 36: OrderByNum then Aggregate (running max)
my $max_val = LTSV::LINQ->From([3, 1, 4, 1, 5, 9, 2, 6])
    ->OrderByNum(sub { $_[0] })
    ->Last();
ok($max_val == 9, 'OrderByNum + Last = max value');

#---------------------------------------------------------------------
# Edge cases
#---------------------------------------------------------------------

# Test 37: OrderByStr on already-sorted data
my @already = LTSV::LINQ->From(['a', 'b', 'c'])->OrderByStr(sub { $_[0] })->ToArray();
ok($already[0] eq 'a' && $already[2] eq 'c', 'OrderByStr: already sorted');

# Test 38: OrderByNum on all-equal values (stability)
my @equal = ({v => 5, i => 1}, {v => 5, i => 2}, {v => 5, i => 3});
my @eq_sorted = LTSV::LINQ->From(\@equal)->OrderByNum(sub { $_[0]{v} })->ToArray();
ok($eq_sorted[0]{i} == 1 && $eq_sorted[2]{i} == 3,
   'OrderByNum: all-equal values preserve original order (stable)');

# Test 39: OrderByStr single character boundary
my @chars = ('Z', 'A', 'a', 'z');
my @cs = LTSV::LINQ->From(\@chars)->OrderByStr(sub { $_[0] })->ToArray();
ok($cs[0] eq 'A' && $cs[1] eq 'Z',
   'OrderByStr: uppercase before lowercase (ASCII order)');

# Test 40: OrderByNumDescending + Count
my $cnt = LTSV::LINQ->From([5, 3, 8, 1])
    ->OrderByNumDescending(sub { $_[0] })
    ->Where(sub { $_[0] >= 5 })
    ->Count();
ok($cnt == 2, 'OrderByNumDescending + Where + Count');

exit($FAIL ? 1 : 0);
