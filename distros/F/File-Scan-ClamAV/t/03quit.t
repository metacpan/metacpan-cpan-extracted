use strict;
use Test::More tests => 4;
use File::Scan::ClamAV;
use POSIX ":sys_wait_h";

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

my $av = new File::Scan::ClamAV(port => "/tmp/clamsock");
ok($av, "Init ok");

ok($av->quit, "Quit ok");
sleep(1);
ok(!$av->ping, "Ping succeeded after quit");


$SIG{ALRM} = sub { kill(9 => $pid); };

alarm(5);
1 while(waitpid($pid, &WNOHANG) != -1);

ok(! kill(9 => $pid), "Kill should fail");
unlink("/tmp/clamsock");
