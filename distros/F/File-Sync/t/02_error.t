#! ./perl

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Sync qw(fsync);
use FileHandle;
use POSIX qw(:errno_h);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Check errors for wrong number of arguments.
eval "fsync(\*STDOUT, 1)";
unless ($@ and $@ =~ m/^Too many arguments/)
  { print STDERR $@; print 'not '; }
print "ok 2\n";

eval "File::Sync::fsync_fd()";
unless ($@ and $@ =~ m/^Not enough arguments/)
  { print STDERR $@; print 'not '; }
print "ok 3\n";

eval { &fsync(); };
unless ($@ and $@ =~ m/^usage:/i)
  { print STDERR $@; print 'not '; }
print "ok 4\n";

eval { &File::Sync::fsync_fd(0, 0); };
unless ($@ and $@ =~ m/^usage:/i)
  { print STDERR $@; print 'not '; }
print "ok 5\n";

# Open a file for testing, unlink it in case we crash.
$fh = new FileHandle "> /tmp/test.pl.$$"
  or die "couldn't create temp. file - please try again";
unlink "/tmp/test.pl.$$";

# Check number of arguments on method invocation.
eval { $fh->fsync(1); };
unless ($@ and $@ =~ m/^usage/)
  { print STDERR $@; print 'not '; }
print "ok 6\n";

# Close it so we have a known closed file descriptor.
$fd = fileno($fh);
close $fh;

# Try fsync_fd on closed file, make sure error is EBADF.
$! = 0;
File::Sync::fsync_fd($fd) && print 'not '; print "ok 7\n";
($! == EBADF) || print 'not '; print "ok 8\n";

# Try fsync on a tty, make sure it fails.
# >>> Oops!  Turns out this is a test for Linux.
#open TTY, '> /dev/tty' || die;
#fsync(\*TTY) && print 'not '; print "ok 9\n";
