#! ./perl

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Sync qw(fsync);
use FileHandle;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Open a file for testing, unlink it in case we crash.
open TEST, "> /tmp/test.pl.$$" 
  or die "couldn't create temp. file - please try again";
unlink "/tmp/test.pl.$$";

# Try fsync, with glob ref then glob name.
fsync(\*TEST) || print 'not '; print "ok 2\n";
fsync(TEST) || print 'not '; print "ok 3\n";

# Try fsync_fd on fd of TEST.
$fd = fileno(TEST);
File::Sync::fsync_fd($fd) || print 'not '; print "ok 4\n";

close TEST;

# Open file as FileHandle and unlink it.
$fh = new FileHandle "> /tmp/test.pl.$$"
  or die "couldn't create temp. file - please try again";
unlink "/tmp/test.pl.$$";

# Try fsync as method of FileHandle.
$fh->fsync() || print 'not '; print "ok 5\n";
