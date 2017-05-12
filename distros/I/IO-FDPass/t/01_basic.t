BEGIN { $| = 1; print "1..7\n"; }

use Socket;
use IO::FDPass;

print "ok 1\n";

socketpair my $fh1, my $fh2, AF_UNIX, SOCK_STREAM, 0
   or die "socketpair: $!";

socketpair my $fh3, my $fh4, AF_UNIX, SOCK_STREAM, 0
   or die "socketpair: $!";

print "ok 2\n";

my $pid = fork;

defined $pid
   or die "fork: $!";

unless ($pid) {
   close $fh3;

   my $fd = IO::FDPass::recv fileno $fh2;

   print $fd > 0 ? "" : "not ", "ok 4 # $fd\n";

   open my $fh, "+<&=$fd"
      or die "open(fd) failed: $!";

   sysread $fh, my $buf, 1
      or die "sysread(child) failed: $!";

   print $buf eq "4" ? "" : "not ", "ok 5 # $buf\n";

   syswrite $fh, "3", 1
      or die "syswrite(child) failed: $!";

   exit;
}

print "ok 3\n";

IO::FDPass::send fileno $fh1, fileno $fh4
   or die "send failed: $!";

close $fh4;

syswrite $fh3, "4", 1
   or die "syswrite(parent) failed: $!";

sysread $fh3, my $buf, 1
   or die "sysread(parent) failed: $!";

print $buf eq "3" ? "" : "not ", "ok 6 # $buf\n";

print "ok 7\n";

