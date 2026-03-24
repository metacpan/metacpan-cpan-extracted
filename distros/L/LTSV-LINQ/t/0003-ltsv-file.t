######################################################################
#
# 0003-ltsv-file.t - LTSV file I/O tests
#
######################################################################

use strict;
BEGIN { if ($] < 5.006) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use LTSV::LINQ;

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub like { my($g,$re,$n)=@_; $T++; defined($g)&&$g=~$re ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub plan_skip { print "1..0 # SKIP $_[0]\n"; exit 0 }

print "1..14\n";

# Create test LTSV file
my $testfile = 't/test_data.ltsv';
open(FH, "> $testfile") or die "Cannot create test file: $!";
print FH "time:2026-01-01T10:00:00\tstatus:200\turl:/home\tbytes:1024\n";
print FH "time:2026-01-01T10:01:00\tstatus:404\turl:/missing\tbytes:512\n";
print FH "time:2026-01-01T10:02:00\tstatus:200\turl:/about\tbytes:2048\n";
print FH "\n";  # Empty line
print FH "time:2026-01-01T10:03:00\tstatus:500\turl:/error\tbytes:256\n";
close FH;

# Test 1: FromLTSV reads file
my $query = LTSV::LINQ->FromLTSV($testfile);
ok(defined($query), 'FromLTSV creates query object');

# Test 2: Read all records
my @all = $query->ToArray();
ok(@all == 4, 'FromLTSV reads correct number of records');

# Test 3: Parse fields correctly
ok($all[0]{status} eq '200' && $all[0]{url} eq '/home',
   'FromLTSV parses fields correctly');

# Test 4: Handle empty lines
ok($all[3]{status} eq '500', 'FromLTSV skips empty lines');

# Test 5: Field with colon in value
open(FH, "> $testfile") or die;
print FH "url:http://example.com:8080\tstatus:200\n";
close FH;

my @colon_test = LTSV::LINQ->FromLTSV($testfile)->ToArray();
ok($colon_test[0]{url} eq 'http://example.com:8080',
   'FromLTSV handles colons in values');

# Test 6: ToLTSV writes file
my $outfile = 't/test_output.ltsv';
LTSV::LINQ->From([
    {status => 200, url => '/home'},
    {status => 404, url => '/missing'},
])->ToLTSV($outfile);

open(FH, "< $outfile") or die;
my @lines = <FH>;
close FH;

ok(@lines == 2, 'ToLTSV writes correct number of lines');

# Test 7: ToLTSV formats correctly
ok($lines[0] =~ /status:200/ && $lines[0] =~ /url:\/home/,
   'ToLTSV formats fields correctly');

# Test 8: Round-trip
my @roundtrip = LTSV::LINQ->FromLTSV($outfile)->ToArray();
ok($roundtrip[0]{status} eq '200' && $roundtrip[1]{status} eq '404',
   'Round-trip preserves data');

# -----------------------------------------------------------------------
# Tests 9-13: ToLTSV value sanitization (added in v1.05)
# -----------------------------------------------------------------------

my $sanfile = 't/test_sanitize.ltsv';

# Test 9: Tab in value is replaced with space
LTSV::LINQ->From([
    { key => "val\tue" },
])->ToLTSV($sanfile);
open(FH, "< $sanfile") or die;
my $san_line = <FH>;
close FH;
chomp $san_line;
ok($san_line eq 'key:val ue', 'ToLTSV replaces tab in value with space');

# Test 10-11: Newline in value is replaced with space
LTSV::LINQ->From([
    { key => "line1\nline2" },
])->ToLTSV($sanfile);
open(FH, "< $sanfile") or die;
my @san_lines = <FH>;
close FH;
ok(@san_lines == 1, 'ToLTSV newline in value does not create extra line');
chomp $san_lines[0];
ok($san_lines[0] eq 'key:line1 line2', 'ToLTSV replaces newline in value with space');

# Test 12: CR in value is replaced with space
LTSV::LINQ->From([
    { key => "val\rue" },
])->ToLTSV($sanfile);
open(FH, "< $sanfile") or die;
my $cr_line = <FH>;
close FH;
$cr_line =~ s/\r?\n$//;
ok($cr_line eq 'key:val ue', 'ToLTSV replaces CR in value with space');

# Test 13: undef value is written as empty string
LTSV::LINQ->From([
    { key => undef },
])->ToLTSV($sanfile);
open(FH, "< $sanfile") or die;
my $undef_line = <FH>;
close FH;
chomp $undef_line;
ok($undef_line eq 'key:', 'ToLTSV writes undef value as empty string');

# Test 14: Sanitized file round-trips correctly via FromLTSV
LTSV::LINQ->From([
    { msg => "hello\tworld", code => "200" },
])->ToLTSV($sanfile);
my @rt = LTSV::LINQ->FromLTSV($sanfile)->ToArray();
ok($rt[0]{msg} eq 'hello world' && $rt[0]{code} eq '200',
   'ToLTSV sanitized output round-trips correctly via FromLTSV');

# Clean up
unlink $testfile;
unlink $outfile;
unlink $sanfile;

exit($FAIL ? 1 : 0);
