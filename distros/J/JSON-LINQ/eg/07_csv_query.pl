######################################################################
#
# 07_csv_query.pl - JSON::LINQ CSV query examples
#
# Demonstrates: FromCSV, Where (DSL and coderef), Select,
#               GroupBy, Sum, OrderByNumDescending, Distinct,
#               ToCSV, TSV support
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

# Create sample CSV in memory for demo
my $tmpcsv = "/tmp/eg07_sales_$$.csv";
local *FH;
open(FH, ">$tmpcsv") or die "Cannot open: $!";
print FH "name,amount,category,city\n";
print FH "Alice,1500,Electronics,Tokyo\n";
print FH "Bob,800,Books,Osaka\n";
print FH "Carol,2000,Electronics,Tokyo\n";
print FH "Dave,300,Books,Nagoya\n";
print FH "Eve,1200,Electronics,Osaka\n";
print FH "Frank,600,Books,Tokyo\n";
close(FH);

print "=== High-value Electronics sales (code ref Where) ===\n";
my @high = JSON::LINQ->FromCSV($tmpcsv)
    ->Where(category => 'Electronics')
    ->Where(sub { $_[0]{amount} >= 1200 })
    ->OrderByNumDescending(sub { $_[0]{amount} })
    ->ToArray();

for my $r (@high) {
    printf "  %-10s %5d  %s\n", $r->{name}, $r->{amount}, $r->{city};
}

print "\n=== Sales by category (GroupBy + Sum) ===\n";
my @by_cat = JSON::LINQ->FromCSV($tmpcsv)
    ->GroupBy(sub { $_[0]{category} })
    ->Select(sub {
        my $g = shift;
        return {
            Category => $g->{Key},
            Count    => scalar(@{$g->{Elements}}),
            Total    => JSON::LINQ->From($g->{Elements})
                            ->Sum(sub { $_[0]{amount} }),
        };
    })
    ->OrderByNumDescending(sub { $_[0]{Total} })
    ->ToArray();

for my $r (@by_cat) {
    printf "  %-15s  count=%d  total=%d\n",
        $r->{Category}, $r->{Count}, $r->{Total};
}

print "\n=== Cities (Distinct + OrderByStr) ===\n";
my @cities = JSON::LINQ->FromCSV($tmpcsv)
    ->Select(sub { $_[0]{city} })
    ->Distinct()
    ->OrderByStr(sub { $_[0] })
    ->ToArray();

print "  ", join(", ", @cities), "\n";

print "\n=== Write filtered CSV (Tokyo rows) ===\n";
my $outcsv = "/tmp/eg07_out_$$.csv";
JSON::LINQ->FromCSV($tmpcsv)
    ->Where(city => 'Tokyo')
    ->ToCSV($outcsv, headers => [qw(name amount category city)]);

local *OUTFH;
open(OUTFH, $outcsv) or die;
while (<OUTFH>) { print "  $_" }
close(OUTFH);

print "\n=== TSV support (sep => \"\\t\") ===\n";
my $tsv = "/tmp/eg07_data_$$.tsv";
local *TSVFH;
open(TSVFH, ">$tsv") or die;
print TSVFH "name\tscore\tstatus\n";
print TSVFH "Alice\t95\tactive\n";
print TSVFH "Bob\t72\tinactive\n";
print TSVFH "Carol\t88\tactive\n";
close(TSVFH);

my @active = JSON::LINQ->FromCSV($tsv, sep => "\t")
    ->Where(status => 'active')
    ->OrderByNumDescending(sub { $_[0]{score} })
    ->ToArray();

for my $r (@active) {
    printf "  %-8s %d\n", $r->{name}, $r->{score};
}

unlink $tmpcsv, $outcsv, $tsv;
