#!perl -T

# number of tests is variable here. using no_plan, as this works on both SLE11_SP2 and 12.1
use Test::More qw(no_plan);
use FindBin;
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;
use File::Temp;
use JSON;

# plan tests => 5;

my $testdir = File::Temp::tempdir("FU_06_XXXXX", TMPDIR => 1, CLEANUP => 1);

my $u = File::Unpack2->new(destdir => $testdir, verbose => 0, logfile => "$testdir/log");
$u->exclude(vcs => 1, add => ['data']);
$u->unpack("t");
ok(-f "$testdir/log", "have $testdir/log after unpacking");
open IN, "<", "$testdir/log";
my $log = JSON::from_json(join '', <IN>);
close IN;
ok(ref($log) eq 'HASH', "logfile is valid JSON");
ok(!exists($log->{unpacked}{'/'}), "Dummy not file seen");
ok(length($log->{end}), "end timstamp file seen");

my $log_scalar;
my $testdir2 = File::Temp::tempdir("FU_06_XXXXX", TMPDIR => 1, CLEANUP => 1);
$u = File::Unpack2->new(destdir => $testdir2, verbose => 0, logfile => \$log_scalar);
$u->exclude(vcs => 1, add => ['data']);
$u->unpack("t");
my $log2 = JSON::from_json($log_scalar);
ok(ref($log2) eq 'HASH', "scalar log is valid JSON");

my $filecount = 0;
for my $f (keys %{$log2->{unpacked}})
  {
    ok($log2->{unpacked}{$f}{mime} =~ m{^text/}, "$f: $log2->{unpacked}{$f}{mime} matches text/*");
    $filecount++
  }
ok($filecount > 10, "more than 10 unpacked files: $filecount");

# done_testing does not exist in SLE11_SP2
# done_testing();
