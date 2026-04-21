######################################################################
#
# 0003-dsl.t - DSL (key => value) filtering and hash record tests
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
    {name => 'Alice', dept => 'Eng',  status => 'active',   score => 90},
    {name => 'Bob',   dept => 'Sales',status => 'active',   score => 72},
    {name => 'Carol', dept => 'Eng',  status => 'inactive', score => 85},
    {name => 'Dave',  dept => 'Eng',  status => 'active',   score => 68},
    {name => 'Eve',   dept => 'Sales',status => 'inactive', score => 91},
);

my @tests = (
    # 1: DSL single condition
    sub {
        my @r = JSON::LINQ->From(\@data)->Where(dept => 'Eng')->ToArray();
        ok(@r == 3, 'DSL single condition: correct count');
    },

    # 2: DSL two conditions AND
    sub {
        my @r = JSON::LINQ->From(\@data)->Where(dept => 'Eng', status => 'active')->ToArray();
        ok(@r == 2, 'DSL two conditions AND: correct count');
    },

    # 3: DSL + Select
    sub {
        my @n = JSON::LINQ->From(\@data)->Where(status => 'active')->Select(sub { $_[0]{name} })->ToArray();
        ok(@n == 3, 'DSL + Select: correct count');
    },

    # 4: Code ref numeric comparison
    sub {
        my @r = JSON::LINQ->From(\@data)->Where(sub { $_[0]{score} >= 85 })->ToArray();
        ok(@r == 3, 'Code ref numeric: correct count');
    },

    # 5: DSL undefined field returns empty
    sub {
        my @r = JSON::LINQ->From(\@data)->Where(nonexistent => 'value')->ToArray();
        ok(@r == 0, 'DSL undefined field: returns empty');
    },

    # 6: GroupBy count
    sub {
        my $json = '[{"cat":"A","v":10},{"cat":"B","v":20},{"cat":"A","v":30},{"cat":"B","v":5}]';
        my @g = JSON::LINQ->FromJSONString($json)->GroupBy(sub { $_[0]{cat} })->ToArray();
        ok(@g == 2, 'GroupBy: correct number of groups');
    },

    # 7: GroupBy sums
    sub {
        my $json = '[{"cat":"A","v":10},{"cat":"B","v":20},{"cat":"A","v":30},{"cat":"B","v":5}]';
        my @g = JSON::LINQ->FromJSONString($json)
            ->GroupBy(sub { $_[0]{cat} })
            ->Select(sub {
                my $g = shift;
                { cat => $g->{Key}, sum => JSON::LINQ->From($g->{Elements})->Sum(sub { $_[0]{v} }) }
            })
            ->ToArray();
        my %gs = map { $_->{cat} => $_->{sum} } @g;
        ok($gs{A} == 40 && $gs{B} == 25, 'GroupBy: correct sums');
    },

    # 8: OrderByDescending + Take
    sub {
        my @r = JSON::LINQ->From(\@data)
            ->OrderByDescending(sub { $_[0]{score} })->Take(2)
            ->Select(sub { $_[0]{name} })->ToArray();
        ok($r[0] eq 'Eve' && $r[1] eq 'Alice', 'OrderByDescending + Take: top 2');
    },

    # 9: Distinct
    sub {
        my @d = JSON::LINQ->From(\@data)->Select(sub { $_[0]{dept} })->Distinct()->ToArray();
        ok(@d == 2, 'Distinct: correct unique count');
    },

    # 10: Count with predicate
    sub {
        ok(JSON::LINQ->From(\@data)->Count(sub { $_[0]{status} eq 'active' }) == 3,
           'Count with predicate');
    },

    # 11: Average
    sub {
        my $avg = JSON::LINQ->From(\@data)->Average(sub { $_[0]{score} });
        ok($avg == (90+72+85+68+91)/5, 'Average: correct');
    },

    # 12: Min and Max
    sub {
        my $min = JSON::LINQ->From(\@data)->Min(sub { $_[0]{score} });
        my $max = JSON::LINQ->From(\@data)->Max(sub { $_[0]{score} });
        ok($min == 68 && $max == 91, 'Min and Max: correct');
    },

    # 13: First and Last with predicate
    sub {
        my $f = JSON::LINQ->From(\@data)->First(sub { $_[0]{dept} eq 'Sales' });
        my $l = JSON::LINQ->From(\@data)->Last(sub { $_[0]{dept} eq 'Sales' });
        ok($f->{name} eq 'Bob' && $l->{name} eq 'Eve', 'First and Last with predicate');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
END { print "# $PASS passed, $FAIL failed out of $T\n" }
