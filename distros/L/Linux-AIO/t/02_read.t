$| = 1;

if (-f "/etc/passwd" and -d "/etc") {
   print "1..3\n";
} else {
   print "1..0 # Skipped: unexpected /etc and/or /etc/passwd\n";
   exit;
}

# relies on /etc/passwd to exist...

use Fcntl;
use Linux::AIO;

Linux::AIO::min_parallel 2;

sub pcb {
   while (Linux::AIO::nreqs) {
      my $rfd = ""; vec ($rfd, Linux::AIO::poll_fileno, 1) = 1; select $rfd, undef, undef, undef;
      Linux::AIO::poll_cb;
   }
}

my $pwd;

aio_open "/etc/passwd", O_RDONLY, 0, sub {
   print $_[0] >= 0 ? "ok" : "not ok", " 1\n";
   print +(open $pwd, "<&$_[0]") ? "ok" : "not ok", " 2\n";
};

pcb;

my ($sysread, $aioread);

sysseek $pwd, 7, 0;
sysread $pwd, $sysread, 15;

# I found no way to silence the stupid "uninitialized...subroutine entry" warning.
# this is just braindamaged. Don't use -w, it introduces more bugs than it fixes.
$aioread = "";

aio_read $pwd, 7, 15, $aioread, 0, sub {
   print +($aioread eq $sysread) ? "ok" : "not ok", " 3\n";
};

pcb;

