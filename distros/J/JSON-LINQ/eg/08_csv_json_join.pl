######################################################################
#
# 08_csv_json_join.pl - JSON::LINQ CSV/JSON interoperability examples
#
# Demonstrates: FromCSV x FromJSON Join, FromCSV x FromCSV Join,
#               GroupJoin, CSV to JSON conversion, JSON to CSV conversion
#
######################################################################
use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings;
local $^W = 1;

BEGIN { pop @INC if $INC[-1] eq '.' }

use FindBin;
use lib "$FindBin::Bin/../lib";

use JSON::LINQ;

# ---------------------------------------------------------------
# Sample data files
# ---------------------------------------------------------------
my $orders_csv    = "/tmp/eg08_orders_$$.csv";
my $customers_csv = "/tmp/eg08_customers_$$.csv";
my $prices_json   = "/tmp/eg08_prices_$$.json";
my $out_json      = "/tmp/eg08_out_$$.json";
my $out_csv       = "/tmp/eg08_out_$$.csv";

local *F1; local *F2; local *F3;

open(F1, ">$orders_csv") or die;
print F1 "id,customer_id,sku,qty\n";
print F1 "1001,C01,A100,2\n";
print F1 "1002,C02,B200,1\n";
print F1 "1003,C01,A100,5\n";
print F1 "1004,C03,C300,3\n";
close(F1);

open(F2, ">$customers_csv") or die;
print F2 "id,name,city\n";
print F2 "C01,Alice,Tokyo\n";
print F2 "C02,Bob,Osaka\n";
print F2 "C03,Carol,Nagoya\n";
close(F2);

open(F3, ">$prices_json") or die;
print F3 "[{\"sku\":\"A100\",\"price\":300},{\"sku\":\"B200\",\"price\":1200},{\"sku\":\"C300\",\"price\":500}]\n";
close(F3);

# ---------------------------------------------------------------
# 1. Join: CSV (main) x CSV (sub-table)
# ---------------------------------------------------------------
print "=== Orders with customer name (CSV x CSV inner join) ===\n";
my @joined = JSON::LINQ->FromCSV($orders_csv)->Join(
    JSON::LINQ->FromCSV($customers_csv),
    sub { $_[0]{customer_id} },
    sub { $_[0]{id} },
    sub {
        {
            order_id => $_[0]{id},
            name     => $_[1]{name},
            city     => $_[1]{city},
            sku      => $_[0]{sku},
            qty      => $_[0]{qty},
        }
    }
)->OrderByNum(sub { $_[0]{order_id} })->ToArray();

for my $r (@joined) {
    printf "  Order#%s  %-8s  %-8s  %s x%s\n",
        $r->{order_id}, $r->{name}, $r->{city},
        $r->{sku}, $r->{qty};
}

# ---------------------------------------------------------------
# 2. Join: CSV (main) x JSON (sub-table) - compute amount
# ---------------------------------------------------------------
print "\n=== Order amounts (CSV x JSON join) ===\n";
my $prices = JSON::LINQ->FromJSON($prices_json);
my @priced = JSON::LINQ->FromCSV($orders_csv)->Join(
    $prices,
    sub { $_[0]{sku} },
    sub { $_[0]{sku} },
    sub {
        {
            order_id => $_[0]{id},
            sku      => $_[0]{sku},
            qty      => $_[0]{qty},
            amount   => $_[0]{qty} * $_[1]{price},
        }
    }
)->OrderByNum(sub { $_[0]{order_id} })->ToArray();

for my $r (@priced) {
    printf "  Order#%s  %s  qty=%s  amount=%d\n",
        $r->{order_id}, $r->{sku}, $r->{qty}, $r->{amount};
}

# ---------------------------------------------------------------
# 3. GroupJoin: total per customer
# ---------------------------------------------------------------
print "\n=== Total per customer (GroupJoin) ===\n";
my @totals = JSON::LINQ->FromCSV($customers_csv)->GroupJoin(
    JSON::LINQ->FromCSV($orders_csv),
    sub { $_[0]{id} },
    sub { $_[0]{customer_id} },
    sub {
        my($cust, $ord_q) = @_;
        my @ords  = $ord_q->ToArray();
        my $total = JSON::LINQ->From(\@ords)->Sum(sub { $_[0]{qty} });
        return {
            name  => $cust->{name},
            count => scalar(@ords),
            total_qty => $total,
        };
    }
)->OrderByNumDescending(sub { $_[0]{total_qty} })->ToArray();

for my $r (@totals) {
    printf "  %-8s  orders=%d  total_qty=%d\n",
        $r->{name}, $r->{count}, $r->{total_qty};
}

# ---------------------------------------------------------------
# 4. CSV -> JSON conversion
# ---------------------------------------------------------------
print "\n=== CSV to JSON conversion ===\n";
JSON::LINQ->FromCSV($customers_csv)->ToJSON($out_json);
my @from_json = JSON::LINQ->FromJSON($out_json)->ToArray();
printf "  %d customers written to JSON, first = %s\n",
    scalar(@from_json), $from_json[0]{name};

# ---------------------------------------------------------------
# 5. JSON -> CSV conversion
# ---------------------------------------------------------------
print "\n=== JSON to CSV conversion ===\n";
JSON::LINQ->FromJSON($prices_json)
    ->ToCSV($out_csv, headers => [qw(sku price)]);
local *OUTFH;
open(OUTFH, $out_csv) or die;
while (<OUTFH>) { print "  $_" }
close(OUTFH);

unlink $orders_csv, $customers_csv, $prices_json, $out_json, $out_csv;
