######################################################################
#
# 0001-basic.t - Basic functionality tests for JSON::LINQ
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
    # 1: Module loading
    sub { ok(1, 'JSON::LINQ module loaded') },

    # 2: From array
    sub { ok(defined(JSON::LINQ->From([1,2,3])), 'From creates query object') },

    # 3: ToArray
    sub {
        my @a = JSON::LINQ->From([1,2,3,4,5])->ToArray();
        ok(@a == 5, 'ToArray returns correct count');
    },

    # 4: Range
    sub {
        my @r = JSON::LINQ->Range(1,5)->ToArray();
        ok($r[0] == 1 && $r[4] == 5, 'Range generates correct sequence');
    },

    # 5: Where
    sub {
        my @f = JSON::LINQ->From([1,2,3,4,5])->Where(sub { $_[0] > 2 })->ToArray();
        ok(@f == 3 && $f[0] == 3, 'Where filters correctly');
    },

    # 6: Select
    sub {
        my @d = JSON::LINQ->From([1,2,3])->Select(sub { $_[0] * 2 })->ToArray();
        ok($d[0] == 2 && $d[2] == 6, 'Select transforms correctly');
    },

    # 7: Take
    sub {
        my @t = JSON::LINQ->From([1,2,3,4,5])->Take(3)->ToArray();
        ok(@t == 3, 'Take limits correctly');
    },

    # 8: Skip
    sub {
        my @s = JSON::LINQ->From([1,2,3,4,5])->Skip(2)->ToArray();
        ok(@s == 3 && $s[0] == 3, 'Skip works correctly');
    },

    # 9: OrderBy
    sub {
        my @s = JSON::LINQ->From([3,1,4,1,5,9,2,6])->OrderBy(sub { $_[0] })->ToArray();
        ok($s[0] == 1 && $s[-1] == 9, 'OrderBy sorts correctly');
    },

    # 10: Count
    sub { ok(JSON::LINQ->From([1,2,3,4,5])->Count() == 5, 'Count correct') },

    # 11: Sum
    sub { ok(JSON::LINQ->From([1,2,3,4,5])->Sum() == 15, 'Sum correct') },

    # 12: FromJSONString array count
    sub {
        my @p = JSON::LINQ->FromJSONString('[{"name":"Alice","age":30},{"name":"Bob","age":25}]')->ToArray();
        ok(@p == 2, 'FromJSONString array: correct count');
    },

    # 13: FromJSONString array data
    sub {
        my @p = JSON::LINQ->FromJSONString('[{"name":"Alice","age":30},{"name":"Bob","age":25}]')->ToArray();
        ok($p[0]{name} eq 'Alice', 'FromJSONString array: correct data');
    },

    # 14: FromJSONString object
    sub {
        my @s = JSON::LINQ->FromJSONString('{"id":1,"value":"test"}')->ToArray();
        ok(@s == 1 && $s[0]{id} == 1, 'FromJSONString object: single element');
    },

    # 15: true numifies
    sub { ok(JSON::LINQ::true == 1, 'true numifies to 1') },

    # 16: false numifies
    sub { ok(JSON::LINQ::false == 0, 'false numifies to 0') },

    # 17: true stringifies
    sub { my $s = "" . JSON::LINQ::true;  ok($s eq 'true',  'true stringifies') },

    # 18: false stringifies
    sub { my $s = "" . JSON::LINQ::false; ok($s eq 'false', 'false stringifies') },

    # 19: Empty
    sub {
        my @e = JSON::LINQ->Empty()->ToArray();
        ok(@e == 0, 'Empty returns empty sequence');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
END { print "# $PASS passed, $FAIL failed out of $T\n" }
