$| = 1;

if (-f "AIO.xs" and -d "bin") {
   print "1..2\n";
} else {
   print "1..0 # Skipped: unexpected bin and/or AIO.xs\n";
   exit;
}

use Fcntl;
use IO::AIO;

IO::AIO::min_parallel 2;

sub pcb {
   while (IO::AIO::nreqs) {
      my $rfd = ""; vec ($rfd, IO::AIO::poll_fileno, 1) = 1; select $rfd, undef, undef, undef;
      IO::AIO::poll_cb;
   }
}

my $pwd;

aio_open "AIO.xs", O_RDONLY, 0, sub {
   print $_[0] ? "ok" : "not ok", " 1\n";
   $pwd = $_[0];
};

pcb;

my ($sysread, $aioread);

sysseek $pwd, 7, 0;
sysread $pwd, $sysread, 15;

# I found no way to silence the stupid "uninitialized...subroutine entry" warning.
# this is just braindamaged. Don't use -w, it introduces more bugs than it fixes.
$aioread = "xxxyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy";

aio_read $pwd, 7, 15, $aioread, 3, sub {
   print +($aioread eq "xxx$sysread") ? "ok" : "not ok", " 2\n";
};

pcb;

