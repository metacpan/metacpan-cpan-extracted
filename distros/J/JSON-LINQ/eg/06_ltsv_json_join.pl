######################################################################
#
# 06_ltsv_json_join.pl - JOIN main LTSV log with sub-table JSON master
#
# Demonstrates:
#   - FromLTSV: read main orders log (often append-only, high-volume)
#   - FromJSON: read sub-table price master from JSON
#   - Join:     inner join LTSV x JSON on sku == sku
#   - Sum:      aggregate joined amounts
#   - GroupJoin: LEFT OUTER variant keeping orders with unknown SKUs
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

my $tmpdir   = File::Spec->tmpdir();
my $ord_ltsv = File::Spec->catfile($tmpdir, "eg06_ord_$$.ltsv");
my $prc_json = File::Spec->catfile($tmpdir, "eg06_prc_$$.json");

# --- Setup: write sample input files ---
local *ORD_FH;
open(ORD_FH, "> $ord_ltsv") or die $!;
binmode ORD_FH;
print ORD_FH "id:1001\tsku:A100\tqty:2\n";
print ORD_FH "id:1002\tsku:B200\tqty:1\n";
print ORD_FH "id:1003\tsku:A100\tqty:5\n";
print ORD_FH "id:1004\tsku:Z999\tqty:7\n";   # no matching price
close ORD_FH;

local *PRC_FH;
open(PRC_FH, "> $prc_json") or die $!;
binmode PRC_FH;
print PRC_FH '[{"sku":"A100","price":300},{"sku":"B200","price":1200}]';
close PRC_FH;

print "=== JOIN: main LTSV x sub-table JSON ===\n\n";

# --- (a) Inner Join: priced orders only ---
print "[ Inner Join (priced orders only) ]\n";
my $prices = JSON::LINQ->FromJSON($prc_json);
my @priced = JSON::LINQ->FromLTSV($ord_ltsv)
    ->Join($prices,
        sub { $_[0]{sku} },                          # outer key (LTSV side)
        sub { $_[0]{sku} },                          # inner key (JSON side)
        sub { { order_id => $_[0]{id},
                sku      => $_[0]{sku},
                qty      => $_[0]{qty},
                amount   => $_[0]{qty} * $_[1]{price} } })
    ->ToArray();

for my $r (@priced) {
    printf "  order=%-5s sku=%-5s qty=%s  amount=%d\n",
           $r->{order_id}, $r->{sku}, $r->{qty}, $r->{amount};
}

# --- (b) Total amount across joined orders ---
print "\n[ Total amount ]\n";
my $prices2 = JSON::LINQ->FromJSON($prc_json);
my $total = JSON::LINQ->FromLTSV($ord_ltsv)
    ->Join($prices2,
        sub { $_[0]{sku} },
        sub { $_[0]{sku} },
        sub { { amount => $_[0]{qty} * $_[1]{price} } })
    ->Sum(sub { $_[0]{amount} });
printf "  Total: %d\n", $total;

# --- (c) GroupJoin (LEFT OUTER): keep orders with unknown SKUs ---
print "\n[ GroupJoin (LEFT OUTER, all orders) ]\n";
my $prices3 = JSON::LINQ->FromJSON($prc_json);
my @all = JSON::LINQ->FromLTSV($ord_ltsv)
    ->GroupJoin($prices3,
        sub { $_[0]{sku} },
        sub { $_[0]{sku} },
        sub { my($o, $g) = @_;
              my @g = $g->ToArray();
              { order_id => $o->{id},
                sku      => $o->{sku},
                price    => @g ? $g[0]{price} : undef } })
    ->ToArray();

for my $r (@all) {
    printf "  order=%-5s sku=%-5s price=%s\n",
           $r->{order_id}, $r->{sku},
           defined($r->{price}) ? $r->{price} : '(unknown)';
}

unlink $ord_ltsv, $prc_json;
print "\nDone.\n";
