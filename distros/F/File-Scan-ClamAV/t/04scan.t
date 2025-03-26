use strict;
use Test::More tests => 8;

use File::Scan::ClamAV;
use Cwd;

do "t/mkconf.pl";

# start clamd
my $pid = fork;
die "Fork failed" unless defined $pid;
if (!$pid) {
    exec "$ENV{CLAMD_PATH}/clamd -c clamav.conf";
    die "clamd failed to start: $!";
}
for (1..120) {
  last if (-e "/tmp/clamsock");
  if (kill(0 => $pid) == 0) {
    die "clamd appears to have died";
  }
  sleep(1);
}

my $av = new File::Scan::ClamAV(port => "/tmp/clamsock", find_all => 1);
ok($av, "Init ok");   

my $dir = cwd;
ok($dir, "cd ok");

my $testdir = "$dir/testfiles";
ok(-d $testdir, "Dir exits");

my %results = $av->scan($testdir);

ok(exists($results{"$testdir/clamavtest"}), "Didn't detect $testdir/clamavtest");
ok(exists($results{"$testdir/clamavtest.zip"}), "Didn't detect $testdir/clamavtest.zip");
ok(exists($results{"$testdir/clamavtest.gz"}), "Didn't detect $testdir/clamavtest.gz");
ok(!exists($results{"$testdir/innocent"}), "Accidentally detected $testdir/innocent file");

ok(kill(9 => $pid), "Kill ok");
waitpid($pid, 0);
unlink("/tmp/clamsock");

