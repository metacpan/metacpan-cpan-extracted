#! ./perl

######################### We start with some black magic to print on failure.

BEGIN {
  $| = 1;
  if(-e ".no_fdatasync") {
    warn "fdatasync() not detected, skipping tests...\n";
    print "1..1\nok 1\n";
    exit;
  }
  print "1..4\n";
}
END {print "not ok 1\n" unless $loaded;}
use File::Sync qw(fdatasync);
use FileHandle;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Open a file for testing, unlink it in case we crash.
open TEST, "> /tmp/test.pl.$$" 
  or die "couldn't create temp. file - please try again";
unlink "/tmp/test.pl.$$";

# Try fdatasync, with glob ref then glob name.
fdatasync(\*TEST) || print 'not '; print "ok 2\n";
fdatasync(TEST) || print 'not '; print "ok 3\n";

# Try fdatasync_fd on fd of TEST.
$fd = fileno(TEST);
File::Sync::fdatasync_fd($fd) || print 'not '; print "ok 4\n";

close TEST;

## Open file as FileHandle and unlink it.
#$fh = new FileHandle "> /tmp/test.pl.$$"
#  or die "couldn't create temp. file - please try again";
#unlink "/tmp/test.pl.$$";
#
## Try fdatasync as method of FileHandle.
#$fh->fdatasync() || print 'not '; print "ok 5\n";
