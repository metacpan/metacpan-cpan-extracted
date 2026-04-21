######################################################################
#
# 02_jsonl_query.pl - JSONL streaming query example
#
# Demonstrates:
#   - FromJSONL: read a JSONL file (streaming, one line at a time)
#   - Where: filter by field value
#   - Count: count matching records
#   - GroupBy: group by field
#   - Sum: aggregate field values
#   - ToJSONL: write results as JSONL
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
my $tmpfile  = File::Spec->catfile($tmpdir, "eg02_jsonlinq_$$.jsonl");
my $outfile  = File::Spec->catfile($tmpdir, "eg02_out_$$.jsonl");

# --- Create a sample JSONL file (event log) using ToJSONL ---
my @events = (
    {ts => '10:00:01', level => 'INFO',  svc => 'auth', msg => 'user alice logged in'},
    {ts => '10:00:02', level => 'INFO',  svc => 'api',  msg => 'GET /users'},
    {ts => '10:00:03', level => 'ERROR', svc => 'db',   msg => 'connection timeout'},
    {ts => '10:00:04', level => 'WARN',  svc => 'api',  msg => 'slow query 1200ms'},
    {ts => '10:00:05', level => 'ERROR', svc => 'api',  msg => 'internal server error'},
    {ts => '10:00:06', level => 'INFO',  svc => 'auth', msg => 'user bob logged in'},
    {ts => '10:00:07', level => 'INFO',  svc => 'api',  msg => 'POST /orders'},
    {ts => '10:00:08', level => 'ERROR', svc => 'db',   msg => 'query failed'},
    {ts => '10:00:09', level => 'INFO',  svc => 'api',  msg => 'GET /products'},
    {ts => '10:00:10', level => 'WARN',  svc => 'auth', msg => 'login attempt failed'},
);
JSON::LINQ->From(\@events)->ToJSONL($tmpfile);

print "=== JSONL Streaming Query Examples ===\n\n";

# --- Query 1: Count total events ---
print "[ Total events ]\n";
my $total = JSON::LINQ->FromJSONL($tmpfile)->Count();
print "  $total events\n";

# --- Query 2: Count by level ---
print "\n[ Count by level ]\n";
my $by_level = JSON::LINQ->FromJSONL($tmpfile)
    ->ToLookup(sub { $_[0]{level} });
for my $level (sort keys %$by_level) {
    printf "  %-7s  %d\n", $level, scalar(@{$by_level->{$level}});
}

# --- Query 3: Error events ---
print "\n[ ERROR events ]\n";
JSON::LINQ->FromJSONL($tmpfile)
    ->Where(sub { $_[0]{level} eq 'ERROR' })
    ->ForEach(sub {
        printf "  [%s] %s: %s\n", $_[0]{ts}, $_[0]{svc}, $_[0]{msg};
    });

# --- Query 4: GroupBy service ---
print "\n[ Events per service ]\n";
my @by_svc = JSON::LINQ->FromJSONL($tmpfile)
    ->GroupBy(sub { $_[0]{svc} })
    ->Select(sub {
        my $g = shift;
        my $errors = JSON::LINQ->From($g->{Elements})
            ->Count(sub { $_[0]{level} eq 'ERROR' });
        return {
            svc    => $g->{Key},
            total  => scalar(@{$g->{Elements}}),
            errors => $errors,
        };
    })
    ->OrderByStr(sub { $_[0]{svc} })
    ->ToArray();

for my $s (@by_svc) {
    printf "  %-8s  total=%d errors=%d\n", $s->{svc}, $s->{total}, $s->{errors};
}

# --- Query 5: Write errors to JSONL ---
print "\n[ Write errors to JSONL ]\n";
JSON::LINQ->FromJSONL($tmpfile)
    ->Where(sub { $_[0]{level} eq 'ERROR' })
    ->ToJSONL($outfile);
print "  Errors written to $outfile\n";
my $err_count = JSON::LINQ->FromJSONL($outfile)->Count();
print "  Verification: $err_count error records\n";

unlink $tmpfile, $outfile;
print "\nDone.\n";
