use strict;
use Test::More tests => 3;
use File::Scan::ClamAV;
use POSIX ":sys_wait_h";

do "t/mkconf.pl" || BAIL_OUT("Failed to configure local clamd: $@");

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

my $av = new File::Scan::ClamAV(port => "/tmp/clamsock");
ok($av, "Init ok");

my $result = $av->ping;
ok($result, "Ping ok");

ok(kill(9 => $pid), "Kill ok");
1 while (waitpid($pid, &WNOHANG) != -1);
unlink("/tmp/clamsock");

my $out = `$ENV{CLAMD_PATH}/clamd -V`;
BAIL_OUT("Couldn't ping so no use in going on. Executable: $out") unless $result;
