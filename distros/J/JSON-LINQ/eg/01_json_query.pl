######################################################################
#
# 01_json_query.pl - JSON file query example
#
# Demonstrates:
#   - FromJSON: read a JSON array file
#   - Where: filter records
#   - Select: project fields
#   - OrderByDescending: sort descending
#   - Distinct: remove duplicates
#   - ToLookup: group results into a hash
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

my $tmpdir  = File::Spec->tmpdir();
my $tmpfile = File::Spec->catfile($tmpdir, "eg01_jsonlinq_$$.json");

# --- Create a sample JSON file ---
my @sample = (
    {user => 'alice', status => 200, url => '/index.html',  bytes => 1024},
    {user => 'bob',   status => 404, url => '/missing.html',bytes => 200},
    {user => 'alice', status => 200, url => '/about.html',  bytes => 512},
    {user => 'carol', status => 200, url => '/index.html',  bytes => 1024},
    {user => 'bob',   status => 500, url => '/api/data',    bytes => 0},
    {user => 'alice', status => 304, url => '/index.html',  bytes => 0},
    {user => 'carol', status => 200, url => '/products',    bytes => 4096},
);
JSON::LINQ->From(\@sample)->ToJSON($tmpfile);

print "=== JSON LINQ Query Examples ===\n\n";

# --- Query 1: Filter by status, extract URL, sort by bytes descending ---
print "[ Successful requests sorted by bytes ]\n";
my @results = JSON::LINQ->FromJSON($tmpfile)
    ->Where(sub { $_[0]{status} == 200 })
    ->Select(sub { { url => $_[0]{url}, bytes => $_[0]{bytes} } })
    ->OrderByDescending(sub { $_[0]{bytes} })
    ->ToArray();

for my $r (@results) {
    printf "  %-30s  %d bytes\n", $r->{url}, $r->{bytes};
}

# --- Query 2: Distinct users ---
print "\n[ Distinct users ]\n";
my @users = JSON::LINQ->FromJSON($tmpfile)
    ->Select(sub { $_[0]{user} })
    ->Distinct()
    ->OrderByStr(sub { $_[0] })
    ->ToArray();
print "  ", join(', ', @users), "\n";

# --- Query 3: Error URLs ---
print "\n[ Error URLs (status >= 400) ]\n";
my @errors = JSON::LINQ->FromJSON($tmpfile)
    ->Where(sub { $_[0]{status} >= 400 })
    ->Select(sub { "$_[0]{status} $_[0]{url}" })
    ->ToArray();
print "  $_\n" for @errors;

# --- Query 4: ToLookup by user ---
print "\n[ Request count per user ]\n";
my $by_user = JSON::LINQ->FromJSON($tmpfile)
    ->ToLookup(sub { $_[0]{user} });
for my $u (sort keys %$by_user) {
    printf "  %-10s  %d requests\n", $u, scalar(@{$by_user->{$u}});
}

# --- Query 5: Aggregation ---
print "\n[ Aggregation: total bytes for successful requests ]\n";
my $total = JSON::LINQ->FromJSON($tmpfile)
    ->Where(sub { $_[0]{status} == 200 })
    ->Sum(sub { $_[0]{bytes} });
printf "  Total: %d bytes\n", $total;

unlink $tmpfile;
print "\nDone.\n";
