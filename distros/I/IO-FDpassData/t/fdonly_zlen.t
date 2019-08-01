# fdonly_zlen.t
#
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}

$loaded = 1;
print "ok 1\n";

my $test = 2;

use diagnostics;
use Socket;
use IO::FDpassData;

my ($fh1,$fh2,$fh3,$fh4,$buf,$fh);

# test 2	set up pipes
socketpair($fh1,$fh2,AF_UNIX,SOCK_STREAM,0) or die "no socketpair: $!";
socketpair($fh3,$fh4,AF_UNIX,SOCK_STREAM,0) or die "no socketpair: $!";

#print "
#fh1 = ", fileno $fh1, "
#fh2 = ", fileno $fh2, "
#fh3 = ", fileno $fh3, "
#fh4 = ", fileno $fh4, "
#";

print "ok 2\n";

my $pid = fork;
die "no fork: $|" unless defined $pid;

# test 3	fork
if ($pid) {
  print "ok 3\n";

  local $SIG{ALRM} = sub {die "parent timeout"};
  alarm(5);

  fd_sendata(fileno $fh1, '', fileno $fh4) or die "send failed: $!";

  close $fh4;

  syswrite $fh3, "4", 1 or die "syswrite(parent) failed: $!";

  sysread $fh3, $buf, 1 or die "sysread(parent) failed: $!";

  print "# $buf\nnot"
	unless $buf eq 3;
  print "ok 8\n";

  print "ok 9\n";

  alarm(0);

} else {

  $SIG{ALRM} = sub {die "child timeout"};
  alarm(5);

  close $fh3;
  my($size,$msg,$fd) = fd_recvdata(fileno $fh2,32);

  unless ($fd && $fd > 0) {
    print "# $fd\nnot ";
  }
  print "ok 4\n";

  print "size = $size, exp 0\nnot "
	unless $size == 0;
  print "ok 5\n";

  print "message not zero length: '$msg'\nnot "
	unless $msg eq '';
  print "ok 6\n";

  open($fh, "+<&=$fd") or die "open(fd) failed: $!";

  sysread $fh, $buf, 1 or die "sysread(child) failed: $!";
  print "# $buf\nnot"
	unless $buf eq "4";
  print "ok 7\n";

  syswrite($fh, "3", 1) or die "syswrite(child) failed $!";

  alarm(0);

  exit;
}
