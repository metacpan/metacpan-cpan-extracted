use strict;
use Test::More tests => 7;
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

my $av = new File::Scan::ClamAV(port => "/tmp/clamsock");
ok($av, "Init ok");

my $dir = cwd;
ok($dir, "cd ok");
my $test = "$dir/testfiles/clamavtest";
ok(-f $test, "File exists");

my $data;
if(open(my $fh, $test)){
	local $/;
	$data = <$fh>;
	close($fh);
}

ok($data, "Data exists");

my ($ans, $vir) = $av->streamscan($data);

cmp_ok($ans, 'eq', 'FOUND', "Positive hit");
like($vir, qr/Eicar/i, "Match correct sig");

ok(kill(9 => $pid), "Kill ok");


waitpid($pid, 0);
unlink("/tmp/clamsock");

