######################################################################
#
# 0002-dsl.t - DSL syntax tests
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

print "1..6\n";

# Test data
my @data = (
    {status => 200, url => '/home'},
    {status => 404, url => '/missing'},
    {status => 200, url => '/about'},
    {status => 500, url => '/error'},
);

# Test 1: Single condition DSL
my @res1 = LTSV::LINQ->From(\@data)
    ->Where(status => 200)
    ->ToArray();
ok(@res1 == 2, 'DSL single condition works');

# Test 2: Multiple conditions DSL
my @res2 = LTSV::LINQ->From(\@data)
    ->Where(status => 200, url => '/home')
    ->ToArray();
ok(@res2 == 1 && $res2[0]{url} eq '/home', 'DSL multiple conditions work');

# Test 3: Code reference still works
my @res3 = LTSV::LINQ->From(\@data)
    ->Where(sub { $_[0]{status} == 200 })
    ->ToArray();
ok(@res3 == 2, 'Code reference still works with DSL');

# Test 4: DSL with chaining
my @res4 = LTSV::LINQ->From(\@data)
    ->Where(status => 200)
    ->Select(sub { $_[0]{url} })
    ->ToArray();
ok(@res4 == 2 && $res4[0] eq '/home', 'DSL chains correctly');

# Test 5: DSL finds nothing
my @res5 = LTSV::LINQ->From(\@data)
    ->Where(status => 999)
    ->ToArray();
ok(@res5 == 0, 'DSL returns empty when no match');

# Test 6: DSL with string values
my @res6 = LTSV::LINQ->From(\@data)
    ->Where(url => '/about')
    ->ToArray();
ok(@res6 == 1 && $res6[0]{status} == 200, 'DSL works with string values');

exit($FAIL ? 1 : 0);
