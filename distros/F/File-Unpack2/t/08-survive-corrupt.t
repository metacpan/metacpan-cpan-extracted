#!perl -T

use Test::More;
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;
use JSON;
use Data::Dumper;

my $bad = 't/data/bad34.pdf';
my $good = 't/data/good10.pdf';
my $destdir = File::Temp::tempdir("FU_06_XXXXX", TMPDIR => 1, CLEANUP => 1);

my $log_str;
my $u = File::Unpack2->new(logfile => \$log_str, destdir => $destdir, verbose => 0, one_shot => 0);
my $m = $u->mime($bad);
# diag("$bad: $m->[0]; charset=$m->[1]\n -> $destdir");

$u->unpack($bad);
my $log = JSON::from_json($log_str);
# TW does not crash
if ($log->{unpacked}{'bad34.txt'}{mime} ne 'text/plain') {
  # diag(Dumper $log->{unpacked});
  is($log->{unpacked}{'bad34.txt'}{mime}, 'application/pdf',   "detecting pdf.");
  is($log->{unpacked}{'bad34.txt'}{passed}, 'application=pdf', "bad pdf: passed unchanged.");
  like(m{stderr}, $log->{unpacked}{'bad34.txt'}{diag},     "bad pdf: stderr has diagnostics.");
}

$log_str = '';
## cannot call unpack() a second time.
$u = File::Unpack2->new(logfile => \$log_str, destdir => $destdir, verbose => 0, one_shot => 0);
$u->unpack($good);
$log = JSON::from_json($log_str);
# diag(Dumper $log);
ok($log->{unpacked}{'good10.txt'}{mime} eq 'text/plain',      "good pdf: has text.");
ok(!defined($log->{unpacked}{'good10.txt'}{diag}),            "good pdf: no diagnostics.");

done_testing;
