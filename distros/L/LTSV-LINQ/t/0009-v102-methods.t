######################################################################
#
# 0009-v102-methods.t - Tests for v1.02 new methods
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

print "1..27\n";

#---------------------------------------------------------------------
# Empty
#---------------------------------------------------------------------

# Test 1: Empty returns empty sequence
my @empty = LTSV::LINQ->Empty()->ToArray();
ok(@empty == 0, 'Empty returns empty sequence');

# Test 2: Empty Count
my $count = LTSV::LINQ->Empty()->Count();
ok($count == 0, 'Empty Count is 0');

#---------------------------------------------------------------------
# Repeat
#---------------------------------------------------------------------

# Test 3: Repeat scalar
my @repeat = LTSV::LINQ->Repeat('x', 5)->ToArray();
ok(@repeat == 5 && $repeat[0] eq 'x', 'Repeat scalar 5 times');

# Test 4: Repeat number
my @nums = LTSV::LINQ->Repeat(0, 3)->ToArray();
ok(@nums == 3 && $nums[0] == 0, 'Repeat number');

# Test 5: Repeat zero times
my @zero = LTSV::LINQ->Repeat('x', 0)->ToArray();
ok(@zero == 0, 'Repeat zero times');

#---------------------------------------------------------------------
# Zip
#---------------------------------------------------------------------

# Test 6: Zip basic
my @zip = LTSV::LINQ->From([1,2,3])
    ->Zip(LTSV::LINQ->From(['a','b','c']), sub { "$_[0]-$_[1]" })
    ->ToArray();
ok(@zip == 3 && $zip[0] eq '1-a', 'Zip basic');

# Test 7: Zip stops at shorter
my @zip2 = LTSV::LINQ->From([1,2,3,4])
    ->Zip(LTSV::LINQ->From(['a','b']), sub { [$_[0], $_[1]] })
    ->ToArray();
ok(@zip2 == 2, 'Zip stops at shorter sequence');

# Test 8: Zip with hash creation
my @zip3 = LTSV::LINQ->From(['name','age'])
    ->Zip(LTSV::LINQ->From(['Alice',30]), sub { +{$_[0] => $_[1]} })
    ->ToArray();
ok((@zip3 == 2) && ($zip3[0]{name} eq 'Alice'), 'Zip hash creation');

#---------------------------------------------------------------------
# Join
#---------------------------------------------------------------------

# Test 9: Join basic
my @users = ({id => 1, name => 'Alice'}, {id => 2, name => 'Bob'});
my @orders = ({user_id => 1, product => 'Book'}, {user_id => 2, product => 'Pen'});

my @join = LTSV::LINQ->From(\@users)->Join(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { {name => $_[0]{name}, product => $_[1]{product}} }
)->ToArray();
ok(@join == 2 && $join[0]{name} eq 'Alice', 'Join basic');

# Test 10: Join multiple matches
my @orders2 = (
    {user_id => 1, product => 'Book'},
    {user_id => 1, product => 'Pen'}
);
my @join2 = LTSV::LINQ->From([{id => 1}])->Join(
    LTSV::LINQ->From(\@orders2),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { $_[1]{product} }
)->ToArray();
ok(@join2 == 2, 'Join multiple matches');

# Test 11: Join no match
my @join3 = LTSV::LINQ->From([{id => 1}])->Join(
    LTSV::LINQ->From([{user_id => 2, product => 'X'}]),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { $_[1] }
)->ToArray();
ok(@join3 == 0, 'Join no match');

# Test 12: Join empty outer
my @join4 = LTSV::LINQ->From([])->Join(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { $_[1] }
)->ToArray();
ok(@join4 == 0, 'Join empty outer');

#---------------------------------------------------------------------
# ToDictionary
#---------------------------------------------------------------------

# Test 13: ToDictionary basic
my $dict = LTSV::LINQ->From([{id => 1, name => 'Alice'}, {id => 2, name => 'Bob'}])
    ->ToDictionary(sub { $_[0]{id} }, sub { $_[0]{name} });
ok($dict->{1} eq 'Alice' && $dict->{2} eq 'Bob', 'ToDictionary basic');

# Test 14: ToDictionary without value selector
my $dict2 = LTSV::LINQ->From([{id => 1}, {id => 2}])
    ->ToDictionary(sub { $_[0]{id} });
ok($dict2->{1}{id} == 1, 'ToDictionary without value selector');

# Test 15: ToDictionary duplicate keys (last wins)
my $dict3 = LTSV::LINQ->From([{id => 1, v => 'a'}, {id => 1, v => 'b'}])
    ->ToDictionary(sub { $_[0]{id} }, sub { $_[0]{v} });
ok($dict3->{1} eq 'b', 'ToDictionary duplicate keys last wins');

# Test 16: ToDictionary empty
my $dict4 = LTSV::LINQ->From([])->ToDictionary(sub { $_[0] });
ok(keys(%$dict4) == 0, 'ToDictionary empty');

#---------------------------------------------------------------------
# ToLookup
#---------------------------------------------------------------------

# Test 17: ToLookup basic
my $lookup = LTSV::LINQ->From([
    {status => 200, url => '/a'},
    {status => 200, url => '/b'},
    {status => 404, url => '/c'}
])->ToLookup(sub { $_[0]{status} }, sub { $_[0]{url} });
ok(@{$lookup->{200}} == 2 && $lookup->{200}[0] eq '/a', 'ToLookup basic');

# Test 18: ToLookup without value selector
my $lookup2 = LTSV::LINQ->From([
    {status => 200, url => '/a'},
    {status => 200, url => '/b'}
])->ToLookup(sub { $_[0]{status} });
ok(@{$lookup2->{200}} == 2 && $lookup2->{200}[0]{url} eq '/a', 'ToLookup without value selector');

# Test 19: ToLookup single value per key
my $lookup3 = LTSV::LINQ->From([{k => 1, v => 'a'}])
    ->ToLookup(sub { $_[0]{k} }, sub { $_[0]{v} });
ok(@{$lookup3->{1}} == 1, 'ToLookup single value per key');

# Test 20: ToLookup empty
my $lookup4 = LTSV::LINQ->From([])->ToLookup(sub { $_ });
ok(keys(%$lookup4) == 0, 'ToLookup empty');

#---------------------------------------------------------------------
# Combined operations
#---------------------------------------------------------------------

# Test 21: Empty + DefaultIfEmpty
my @def = LTSV::LINQ->Empty()->DefaultIfEmpty(0)->ToArray();
ok(@def == 1 && $def[0] == 0, 'Empty + DefaultIfEmpty');

# Test 22: Repeat + Where
my @rep = LTSV::LINQ->Repeat(5, 10)->Where(sub { $_[0] == 5 })->ToArray();
ok(@rep == 10, 'Repeat + Where');

# Test 23: Zip + Select
my @zs = LTSV::LINQ->From([1,2])
    ->Zip(LTSV::LINQ->From([3,4]), sub { $_[0] + $_[1] })
    ->Select(sub { $_[0] * 2 })
    ->ToArray();
ok($zs[0] == 8, 'Zip + Select');

# Test 24: Join + Count
my $jc = LTSV::LINQ->From(\@users)->Join(
    LTSV::LINQ->From(\@orders),
    sub { $_[0]{id} },
    sub { $_[0]{user_id} },
    sub { $_[1] }
)->Count();
ok($jc == 2, 'Join + Count');

# Test 25: Range + Zip
my @rz = LTSV::LINQ->Range(1, 3)
    ->Zip(LTSV::LINQ->From(['a','b','c']), sub { "$_[0]:$_[1]" })
    ->ToArray();
ok($rz[0] eq '1:a', 'Range + Zip');

# Test 26: ToDictionary + lookup
my $td = LTSV::LINQ->Range(1, 5)->ToDictionary(sub { $_[0] }, sub { $_[0] * 2 });
ok($td->{3} == 6, 'ToDictionary + lookup');

# Test 27: ToLookup + count values
my $tl = LTSV::LINQ->From([
    {k => 'a', v => 1},
    {k => 'a', v => 2},
    {k => 'b', v => 3}
])->ToLookup(sub { $_[0]{k} });
ok(@{$tl->{a}} == 2 && @{$tl->{b}} == 1, 'ToLookup + count values');


exit($FAIL ? 1 : 0);
