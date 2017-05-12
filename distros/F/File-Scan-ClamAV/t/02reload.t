use strict;
use Test::More tests => 3;
use File::Scan::ClamAV;

do "t/mkconf.pl";

# start clamd
my $pid = fork;
die "Fork failed" unless defined $pid;
if (!$pid) {
    exec "$ENV{CLAMD_PATH}/clamd -c clamav.conf";
    die "clamd failed to start: $!";
}
for (1..120) {
  last if (-e "clamsock");
  if (kill(0 => $pid) == 0) {
    die "clamd appears to have died";
  }
  sleep(1);
}

my $av = new File::Scan::ClamAV(port => "clamsock"); 
ok($av, "Init ok");   
ok($av->reload, "Reload ok");

ok(kill(9 => $pid), "Kill ok");
waitpid($pid, 0);
unlink("clamsock");

