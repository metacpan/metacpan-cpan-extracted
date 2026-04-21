######################################################################
#
# 0006-set-aggregate.t - Set operations, quantifiers, Aggregate tests
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use JSON::LINQ;

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }

my @tests = (
    # 1: Union
    sub {
        my @u = JSON::LINQ->From([1,2,3,4])->Union(JSON::LINQ->From([3,4,5,6]))->ToArray();
        my %h = map { $_ => 1 } @u;
        ok(scalar(@u)==6 && $h{1} && $h{6}, 'Union: correct');
    },

    # 2: Intersect
    sub {
        my @i = JSON::LINQ->From([1,2,3,4])->Intersect(JSON::LINQ->From([3,4,5,6]))->ToArray();
        ok(scalar(@i)==2 && $i[0]==3 && $i[1]==4, 'Intersect: correct');
    },

    # 3: Except
    sub {
        my @e = JSON::LINQ->From([1,2,3,4])->Except(JSON::LINQ->From([3,4,5,6]))->ToArray();
        ok(scalar(@e)==2 && $e[0]==1 && $e[1]==2, 'Except: correct');
    },

    # 4: Distinct
    sub {
        my @d = JSON::LINQ->From([1,2,2,3,3,3])->Distinct()->ToArray();
        ok(scalar(@d)==3, 'Distinct: deduplicates');
    },

    # 5: Distinct with key selector
    sub {
        my @hd = JSON::LINQ->From([{id=>1,x=>'a'},{id=>2,x=>'b'},{id=>1,x=>'c'}])
            ->Distinct(sub{$_[0]{id}})->ToArray();
        ok(scalar(@hd)==2 && $hd[0]{x} eq 'a', 'Distinct key selector');
    },

    # 6: All true
    sub { ok(JSON::LINQ->From([2,4,6,8])->All(sub{$_[0]%2==0}), 'All: true case') },

    # 7: All false
    sub { ok(!JSON::LINQ->From([2,3,6])->All(sub{$_[0]%2==0}), 'All: false case') },

    # 8: Any true
    sub { ok(JSON::LINQ->From([1,2,3])->Any(sub{$_[0]>2}), 'Any: true case') },

    # 9: Any false
    sub { ok(!JSON::LINQ->From([1,2,3])->Any(sub{$_[0]>10}), 'Any: false case') },

    # 10: Any no predicate non-empty
    sub { ok(JSON::LINQ->From([1])->Any(), 'Any no pred: non-empty is true') },

    # 11: Any no predicate empty
    sub { ok(!JSON::LINQ->Empty()->Any(), 'Any no pred: empty is false') },

    # 12: Contains found
    sub { ok(JSON::LINQ->From([1,2,3])->Contains(2), 'Contains: found') },

    # 13: Contains not found
    sub { ok(!JSON::LINQ->From([1,2,3])->Contains(9), 'Contains: not found') },

    # 14: Aggregate seed+func
    sub {
        ok(JSON::LINQ->From([2,3,4])->Aggregate(1, sub{$_[0]*$_[1]}) == 24,
           'Aggregate seed+func: product');
    },

    # 15: Aggregate func only
    sub {
        ok(JSON::LINQ->From([1,2,3,4])->Aggregate(sub{$_[0]+$_[1]}) == 10,
           'Aggregate func only: sum');
    },

    # 16: Aggregate with result_selector
    sub {
        my $r = JSON::LINQ->From([1,2,3])->Aggregate(0, sub{$_[0]+$_[1]}, sub{"Sum=$_[0]"});
        ok($r eq 'Sum=6', 'Aggregate with result_selector');
    },

    # 17: SequenceEqual equal
    sub {
        ok(JSON::LINQ->From([1,2,3])->SequenceEqual(JSON::LINQ->From([1,2,3])),
           'SequenceEqual: equal');
    },

    # 18: SequenceEqual not equal
    sub {
        ok(!JSON::LINQ->From([1,2,3])->SequenceEqual(JSON::LINQ->From([1,2,4])),
           'SequenceEqual: not equal');
    },

    # 19: DefaultIfEmpty non-empty
    sub {
        my @r = JSON::LINQ->From([1,2,3])->DefaultIfEmpty(99)->ToArray();
        ok(scalar(@r)==3 && $r[0]==1, 'DefaultIfEmpty: non-empty unchanged');
    },

    # 20: DefaultIfEmpty empty
    sub {
        my @r = JSON::LINQ->Empty()->DefaultIfEmpty(42)->ToArray();
        ok(scalar(@r)==1 && $r[0]==42, 'DefaultIfEmpty: empty gets default');
    },

    # 21: AverageOrDefault empty
    sub {
        ok(!defined(JSON::LINQ->Empty()->AverageOrDefault()), 'AverageOrDefault: undef for empty');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
END { print "# $PASS passed, $FAIL failed out of $T\n" }
