######################################################################
# 01_ltsv_query.pl - Basic LTSV file query with FromLTSV/Where/Select
#
# Usage: perl eg/01_ltsv_query.pl [ltsv_file]
#
# Demonstrates:
#   - FromLTSV: load an LTSV file into a query
#   - Where: filter rows by field value
#   - Select: project (transform) each row
#   - OrderBy: sort results (ascending)
#   - OrderByNumDescending: sort by numeric field descending
#   - Take: limit results to top N
#   - Distinct: remove duplicate values
#   - ToLookup: group results into a hash of arrayrefs
#   - ToArray: execute and collect results
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use LTSV::LINQ;

######################################################################
# Create a sample LTSV file for the demo
######################################################################
my $tmpfile = "sample_access.log.ltsv";

_write_sample($tmpfile);
print "Created sample LTSV file: $tmpfile\n\n";

######################################################################
# 1. Load and filter
######################################################################
print "--- 1. Requests with status 200 ---\n";
my @ok_requests = LTSV::LINQ->FromLTSV($tmpfile)
    ->Where(sub { $_[0]{status} eq '200' })
    ->Select(sub { "$_[0]{method} $_[0]{path}" })
    ->ToArray();

for my $r (@ok_requests) {
    print "  $r\n";
}
print "Total: ", scalar(@ok_requests), "\n\n";

######################################################################
# 2. Aggregate: count by status
######################################################################
print "--- 2. Request count by status ---\n";
my %by_status = %{ LTSV::LINQ->FromLTSV($tmpfile)
    ->ToLookup(sub { $_[0]{status} }) };

for my $status (sort keys %by_status) {
    my $count = scalar @{ $by_status{$status} };
    print "  $status : $count requests\n";
}
print "\n";

######################################################################
# 3. Sort by response size (descending)
######################################################################
print "--- 3. Top 3 largest responses ---\n";
my @top3 = LTSV::LINQ->FromLTSV($tmpfile)
    ->OrderByNumDescending(sub { $_[0]{size} || 0 })
    ->Take(3)
    ->Select(sub { sprintf "size=%-6s  path=%s", $_[0]{size}||0, $_[0]{path} })
    ->ToArray();

for my $r (@top3) {
    print "  $r\n";
}
print "\n";

######################################################################
# 4. Distinct paths
######################################################################
print "--- 4. Distinct paths visited ---\n";
my @paths = LTSV::LINQ->FromLTSV($tmpfile)
    ->Select(sub { $_[0]{path} })
    ->Distinct()
    ->OrderBy(sub { $_[0] })
    ->ToArray();

for my $p (@paths) {
    print "  $p\n";
}

######################################################################
# Cleanup
######################################################################
unlink $tmpfile;

######################################################################
# Helper: write a sample LTSV file
######################################################################
sub _write_sample {
    my ($file) = @_;
    local *FH;
    open FH, ">$file" or die "Cannot write $file: $!";
    print FH join("\n",
        "time:2026-03-22T10:00:01\tmethod:GET\tpath:/\tstatus:200\tsize:1024\tua:Mozilla/5.0",
        "time:2026-03-22T10:00:02\tmethod:GET\tpath:/about\tstatus:200\tsize:512\tua:Mozilla/5.0",
        "time:2026-03-22T10:00:03\tmethod:GET\tpath:/no-such-page\tstatus:404\tsize:128\tua:curl/7.68",
        "time:2026-03-22T10:00:04\tmethod:POST\tpath:/submit\tstatus:200\tsize:64\tua:Mozilla/5.0",
        "time:2026-03-22T10:00:05\tmethod:GET\tpath:/\tstatus:200\tsize:1024\tua:Chrome/120",
        "time:2026-03-22T10:00:06\tmethod:GET\tpath:/api/data\tstatus:500\tsize:256\tua:curl/7.68",
        "time:2026-03-22T10:00:07\tmethod:GET\tpath:/about\tstatus:200\tsize:512\tua:Chrome/120",
    ), "\n";
    close FH;
}
