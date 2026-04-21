######################################################################
#
# 0005-ordering.t - OrderBy, ThenBy, Reverse sorting tests
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

my @data = (
    {name => 'Carol', dept => 'Eng',   salary => 800},
    {name => 'Alice', dept => 'Eng',   salary => 1000},
    {name => 'Dave',  dept => 'Sales', salary => 600},
    {name => 'Bob',   dept => 'Eng',   salary => 800},
    {name => 'Eve',   dept => 'Sales', salary => 900},
);

my @tests = (
    # 1: OrderBy ascending
    sub {
        my @r = JSON::LINQ->From(\@data)->OrderBy(sub{$_[0]{name}})->Select(sub{$_[0]{name}})->ToArray();
        ok($r[0] eq 'Alice' && $r[-1] eq 'Eve', 'OrderBy name asc');
    },

    # 2: OrderByDescending
    sub {
        my @r = JSON::LINQ->From(\@data)->OrderByDescending(sub{$_[0]{name}})->Select(sub{$_[0]{name}})->ToArray();
        ok($r[0] eq 'Eve' && $r[-1] eq 'Alice', 'OrderByDescending name');
    },

    # 3: OrderByNum asc
    sub {
        my @r = JSON::LINQ->From(\@data)->OrderByNum(sub{$_[0]{salary}})->Select(sub{$_[0]{salary}})->ToArray();
        ok($r[0] == 600 && $r[-1] == 1000, 'OrderByNum asc');
    },

    # 4: OrderByNumDescending
    sub {
        my @r = JSON::LINQ->From(\@data)->OrderByNumDescending(sub{$_[0]{salary}})->Select(sub{$_[0]{salary}})->ToArray();
        ok($r[0] == 1000 && $r[-1] == 600, 'OrderByNumDescending');
    },

    # 5: ThenByStr Eng order
    sub {
        my @r = JSON::LINQ->From(\@data)->OrderByStr(sub{$_[0]{dept}})->ThenByStr(sub{$_[0]{name}})->Select(sub{$_[0]{name}})->ToArray();
        ok($r[0] eq 'Alice' && $r[1] eq 'Bob' && $r[2] eq 'Carol', 'ThenBy: Eng sorted correctly');
    },

    # 6: ThenByStr Sales order
    sub {
        my @r = JSON::LINQ->From(\@data)->OrderByStr(sub{$_[0]{dept}})->ThenByStr(sub{$_[0]{name}})->Select(sub{$_[0]{name}})->ToArray();
        ok($r[3] eq 'Dave' && $r[4] eq 'Eve', 'ThenBy: Sales sorted correctly');
    },

    # 7: ThenByNumDescending
    sub {
        my @r = JSON::LINQ->From(\@data)->OrderByStr(sub{$_[0]{dept}})->ThenByNumDescending(sub{$_[0]{salary}})->Select(sub{$_[0]{name}})->ToArray();
        ok($r[0] eq 'Alice', 'ThenByNumDescending: highest salary first in Eng');
    },

    # 8: Reverse
    sub {
        my @r = JSON::LINQ->From([1,2,3,4,5])->Reverse()->ToArray();
        ok($r[0] == 5 && $r[-1] == 1, 'Reverse: order inverted');
    },

    # 9: OrderByStr lexicographic
    sub {
        my @r = JSON::LINQ->From(['10','9','20','3'])->OrderByStr(sub{$_[0]})->ToArray();
        ok($r[0] eq '10' && $r[1] eq '20', 'OrderByStr: lexicographic order');
    },

    # 10: OrderByNum numeric
    sub {
        my @r = JSON::LINQ->From(['10','9','20','3'])->OrderByNum(sub{$_[0]})->ToArray();
        ok($r[0] eq '3' && $r[-1] eq '20', 'OrderByNum: numeric order');
    },

    # 11: Smart comparison
    sub {
        my @r = JSON::LINQ->From([{k=>'100'},{k=>'20'},{k=>'3'}])->OrderBy(sub{$_[0]{k}})->Select(sub{$_[0]{k}})->ToArray();
        ok($r[0] eq '3' && $r[1] eq '20' && $r[2] eq '100', 'OrderBy smart: numeric when all numeric');
    },

    # 12: Non-destructive ThenBy branching
    sub {
        my $base = JSON::LINQ->From(\@data)->OrderByStr(sub{$_[0]{dept}});
        my @c1 = $base->ThenByStr(sub{$_[0]{name}})->Select(sub{$_[0]{name}})->ToArray();
        my @c2 = $base->ThenByNumDescending(sub{$_[0]{salary}})->Select(sub{$_[0]{salary}})->ToArray();
        ok($c1[0] eq 'Alice' && $c2[0] == 1000, 'ThenBy non-destructive branching');
    },

    # 13: OrderByStr from JSON
    sub {
        my @r = JSON::LINQ->FromJSONString('[{"n":"C"},{"n":"A"},{"n":"B"}]')
            ->OrderByStr(sub{$_[0]{n}})->Select(sub{$_[0]{n}})->ToArray();
        ok(join(',',@r) eq 'A,B,C', 'OrderByStr from JSON string');
    },

    # 14: Stable sort
    sub {
        my @sd = ({k=>'x',i=>1},{k=>'y',i=>2},{k=>'x',i=>3},{k=>'y',i=>4});
        my @r = JSON::LINQ->From(\@sd)->OrderByStr(sub{$_[0]{k}})->Select(sub{$_[0]{i}})->ToArray();
        ok($r[0]==1 && $r[1]==3 && $r[2]==2 && $r[3]==4, 'OrderBy: stable sort');
    },

    # 15: ThenByStr after OrderByNum
    sub {
        my @r = JSON::LINQ->From(\@data)->OrderByNum(sub{$_[0]{salary}})->ThenByStr(sub{$_[0]{name}})->Select(sub{"$_[0]{salary}:$_[0]{name}"})->ToArray();
        ok($r[1] eq '800:Bob' && $r[2] eq '800:Carol', 'ThenByStr after OrderByNum: ties broken alpha');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
END { print "# $PASS passed, $FAIL failed out of $T\n" }
