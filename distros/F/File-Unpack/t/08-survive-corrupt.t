#!perl -T

use Test::More tests => 5;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack;
use JSON;
use Data::Dumper;

my $bad = 't/data/bad34.pdf';
my $good = 't/data/good10.pdf';
my $destdir = File::Temp::tempdir("FU_06_XXXXX", TMPDIR => 1, CLEANUP => 1);

my $log_str;
my $u = File::Unpack->new(logfile => \$log_str, destdir => $destdir, verbose => 0, one_shot => 0);
my $m = $u->mime($bad);
# diag("$bad: $m->[0]; charset=$m->[1]\n -> $destdir");

$u->unpack($bad);
my $log = JSON::from_json($log_str);
# diag(Dumper $log->{unpacked}{'bad34.txt'});
ok($log->{unpacked}{'bad34.txt'}{mime} eq 'application/pdf',   "detecting pdf.");
ok($log->{unpacked}{'bad34.txt'}{passed} eq 'application=pdf', "bad pdf: passed unchanged.");
ok($log->{unpacked}{'bad34.txt'}{diag} =~ m{stderr},           "bad pdf: stderr has diagnostics.");

$log_str = '';
## cannot call unpack() a second time.
$u = File::Unpack->new(logfile => \$log_str, destdir => $destdir, verbose => 0, one_shot => 0);
$u->unpack($good);
$log = JSON::from_json($log_str);
# diag(Dumper $log);
ok($log->{unpacked}{'good10.txt'}{mime} eq 'text/plain',      "good pdf: has text.");
ok(!defined($log->{unpacked}{'good10.txt'}{diag}),            "good pdf: no diagnostics.");

