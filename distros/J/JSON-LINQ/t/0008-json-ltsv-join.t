######################################################################
#
# 0008-json-ltsv-join.t - JOIN tests across JSON and LTSV files
#
# Two patterns:
#   (1) main JSON  x sub-table LTSV (department lookup)
#   (2) main LTSV  x sub-table JSON (price master)
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use JSON::LINQ;
use File::Spec ();

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }

my $tmpdir   = File::Spec->tmpdir();
my $emp_json = File::Spec->catfile($tmpdir, "jl_emp_$$.json");
my $dep_ltsv = File::Spec->catfile($tmpdir, "jl_dep_$$.ltsv");
my $ord_ltsv = File::Spec->catfile($tmpdir, "jl_ord_$$.ltsv");
my $prc_json = File::Spec->catfile($tmpdir, "jl_prc_$$.json");

# ----------------------------------------------------------------------
# Setup files
# ----------------------------------------------------------------------

# employees.json: main table for pattern (1)
local *EMP_FH;
open(EMP_FH, "> $emp_json") or die $!;
binmode EMP_FH;
print EMP_FH '[';
print EMP_FH '{"id":1,"name":"Alice","dept_id":10},';
print EMP_FH '{"id":2,"name":"Bob","dept_id":20},';
print EMP_FH '{"id":3,"name":"Carol","dept_id":10},';
print EMP_FH '{"id":4,"name":"Dave","dept_id":99}';   # no matching dept
print EMP_FH ']';
close EMP_FH;

# departments.ltsv: sub-table for pattern (1)
local *DEP_FH;
open(DEP_FH, "> $dep_ltsv") or die $!;
binmode DEP_FH;
print DEP_FH "id:10\tname:Engineering\n";
print DEP_FH "id:20\tname:Sales\n";
close DEP_FH;

# orders.ltsv: main table for pattern (2)
local *ORD_FH;
open(ORD_FH, "> $ord_ltsv") or die $!;
binmode ORD_FH;
print ORD_FH "id:1001\tsku:A100\tqty:2\n";
print ORD_FH "id:1002\tsku:B200\tqty:1\n";
print ORD_FH "id:1003\tsku:A100\tqty:5\n";
print ORD_FH "id:1004\tsku:Z999\tqty:7\n";   # no matching price
close ORD_FH;

# prices.json: sub-table for pattern (2)
local *PRC_FH;
open(PRC_FH, "> $prc_json") or die $!;
binmode PRC_FH;
print PRC_FH '[{"sku":"A100","price":300},{"sku":"B200","price":1200}]';
close PRC_FH;

my @tests = (

    # ------------------------------------------------------------------
    # Pattern (1): main JSON x sub-table LTSV
    # ------------------------------------------------------------------

    # 1: Inner Join JSON x LTSV - matched count (3, Dave excluded)
    sub {
        my $depts = JSON::LINQ->FromLTSV($dep_ltsv);
        my @r = JSON::LINQ->FromJSON($emp_json)
            ->Join($depts,
                sub { $_[0]{dept_id} },
                sub { $_[0]{id}      },
                sub { { name => $_[0]{name}, dept => $_[1]{name} } })
            ->ToArray();
        ok(@r == 3, 'JSON x LTSV: inner join produces 3 matches');
    },

    # 2: Inner Join JSON x LTSV - mapping correctness
    sub {
        my $depts = JSON::LINQ->FromLTSV($dep_ltsv);
        my %by_name = map { $_->{name} => $_->{dept} }
            @{ [
                JSON::LINQ->FromJSON($emp_json)
                    ->Join($depts,
                        sub { $_[0]{dept_id} },
                        sub { $_[0]{id}      },
                        sub { { name => $_[0]{name}, dept => $_[1]{name} } })
                    ->ToArray()
            ] };
        ok($by_name{Alice} eq 'Engineering'
        && $by_name{Bob}   eq 'Sales'
        && $by_name{Carol} eq 'Engineering'
        && !exists $by_name{Dave},
           'JSON x LTSV: each employee mapped to correct dept; Dave excluded');
    },

    # 3: GroupJoin JSON x LTSV (LEFT OUTER) - all 4 employees retained
    sub {
        my $depts = JSON::LINQ->FromLTSV($dep_ltsv);
        my @r = JSON::LINQ->FromJSON($emp_json)
            ->GroupJoin($depts,
                sub { $_[0]{dept_id} },
                sub { $_[0]{id}      },
                sub { my($e, $g) = @_;
                      my @g = $g->ToArray();
                      { name => $e->{name},
                        dept => @g ? $g[0]{name} : undef } })
            ->ToArray();
        my $dave = (grep { $_->{name} eq 'Dave' } @r)[0];
        ok(@r == 4 && defined($dave) && !defined($dave->{dept}),
           'JSON x LTSV: GroupJoin (LEFT OUTER) keeps unmatched Dave with undef dept');
    },

    # 4: Where on outer (JSON) before Join - lazy filter applied first
    sub {
        my $depts = JSON::LINQ->FromLTSV($dep_ltsv);
        my @r = JSON::LINQ->FromJSON($emp_json)
            ->Where(sub { $_[0]{name} ne 'Bob' })
            ->Join($depts,
                sub { $_[0]{dept_id} },
                sub { $_[0]{id}      },
                sub { { name => $_[0]{name}, dept => $_[1]{name} } })
            ->ToArray();
        # Bob excluded; Dave excluded by inner join => Alice, Carol
        ok(@r == 2, 'JSON x LTSV: Where + Join chain');
    },

    # ------------------------------------------------------------------
    # Pattern (2): main LTSV x sub-table JSON
    # ------------------------------------------------------------------

    # 5: Inner Join LTSV x JSON - matched count (3, Z999 excluded)
    sub {
        my $prices = JSON::LINQ->FromJSON($prc_json);
        my @r = JSON::LINQ->FromLTSV($ord_ltsv)
            ->Join($prices,
                sub { $_[0]{sku} },
                sub { $_[0]{sku} },
                sub { { order_id => $_[0]{id},
                        amount   => $_[0]{qty} * $_[1]{price} } })
            ->ToArray();
        ok(@r == 3, 'LTSV x JSON: inner join produces 3 matches');
    },

    # 6: Inner Join LTSV x JSON - amount calculations
    sub {
        my $prices = JSON::LINQ->FromJSON($prc_json);
        my @r = JSON::LINQ->FromLTSV($ord_ltsv)
            ->Join($prices,
                sub { $_[0]{sku} },
                sub { $_[0]{sku} },
                sub { { order_id => $_[0]{id},
                        amount   => $_[0]{qty} * $_[1]{price} } })
            ->ToArray();
        my %by_id = map { $_->{order_id} => $_->{amount} } @r;
        ok($by_id{1001} == 600 && $by_id{1002} == 1200 && $by_id{1003} == 1500
           && !exists $by_id{1004},
           'LTSV x JSON: amounts computed correctly; unmatched 1004 excluded');
    },

    # 7: Sum of all matched order amounts
    sub {
        my $prices = JSON::LINQ->FromJSON($prc_json);
        my $total = JSON::LINQ->FromLTSV($ord_ltsv)
            ->Join($prices,
                sub { $_[0]{sku} },
                sub { $_[0]{sku} },
                sub { { amount => $_[0]{qty} * $_[1]{price} } })
            ->Sum(sub { $_[0]{amount} });
        ok($total == 600 + 1200 + 1500, 'LTSV x JSON: total amount = 3300');
    },

    # 8: GroupJoin LTSV x JSON (LEFT OUTER) - keeps unmatched 1004
    sub {
        my $prices = JSON::LINQ->FromJSON($prc_json);
        my @r = JSON::LINQ->FromLTSV($ord_ltsv)
            ->GroupJoin($prices,
                sub { $_[0]{sku} },
                sub { $_[0]{sku} },
                sub { my($o, $g) = @_;
                      my @g = $g->ToArray();
                      { order_id => $o->{id},
                        price    => @g ? $g[0]{price} : undef } })
            ->ToArray();
        my $miss = (grep { $_->{order_id} eq '1004' } @r)[0];
        ok(@r == 4 && defined($miss) && !defined($miss->{price}),
           'LTSV x JSON: GroupJoin keeps unmatched order 1004 with undef price');
    },

    # 9: Round-trip: JOIN result -> ToJSON -> FromJSON
    sub {
        my $prices = JSON::LINQ->FromJSON($prc_json);
        my $tmp_out = File::Spec->catfile($tmpdir, "jl_join_out_$$.json");
        JSON::LINQ->FromLTSV($ord_ltsv)
            ->Join($prices,
                sub { $_[0]{sku} },
                sub { $_[0]{sku} },
                sub { { order_id => $_[0]{id},
                        amount   => $_[0]{qty} * $_[1]{price} } })
            ->ToJSON($tmp_out);
        my @r = JSON::LINQ->FromJSON($tmp_out)->ToArray();
        unlink $tmp_out;
        ok(@r == 3, 'LTSV x JSON: round-trip via ToJSON/FromJSON yields 3 records');
    },

    # 10: Round-trip: JOIN result -> ToLTSV -> FromLTSV
    sub {
        my $depts = JSON::LINQ->FromLTSV($dep_ltsv);
        my $tmp_out = File::Spec->catfile($tmpdir, "jl_join_out_$$.ltsv");
        JSON::LINQ->FromJSON($emp_json)
            ->Join($depts,
                sub { $_[0]{dept_id} },
                sub { $_[0]{id}      },
                sub { { name => $_[0]{name}, dept => $_[1]{name} } })
            ->ToLTSV($tmp_out);
        my @r = JSON::LINQ->FromLTSV($tmp_out)->ToArray();
        unlink $tmp_out;
        ok(@r == 3 && (grep { $_->{name} eq 'Alice' && $_->{dept} eq 'Engineering' } @r),
           'JSON x LTSV: round-trip via ToLTSV/FromLTSV preserves join result');
    },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;

END {
    unlink $emp_json, $dep_ltsv, $ord_ltsv, $prc_json;
    print "# $PASS passed, $FAIL failed out of $T\n";
}
