# Exclusive Fork Test
#
# This tests the capabilities of fork after lock to
# ensure parent retains exclusive lock even if child releases it.

use strict;
use warnings;
use File::Temp qw(tempfile);

use Test::More tests => 6;
use File::NFSLock;
use Fcntl qw(O_CREAT O_RDWR O_RDONLY O_TRUNC O_APPEND LOCK_EX LOCK_SH LOCK_NB);

$| = 1; # Buffer must be autoflushed because of fork() below.

my $datafile = (tempfile 'XXXXXXXXXX')[1];

# Wipe lock file in case it exists
unlink ("$datafile$File::NFSLock::LOCK_EXTENSION");

# Create a blank file
sysopen ( my $fh, $datafile, O_CREAT | O_RDWR | O_TRUNC );
close ($fh);
ok (-e $datafile && !-s _);

pipe(my $dad_rd, my $dad_wr);
{
  # Forced dummy scope
  my $lock1 = new File::NFSLock {
    file => $datafile,
    lock_type => LOCK_EX,
  };

  ok ($lock1);

  my $pid = fork;
  if (!defined $pid) {
    die "fork failed!";
  } elsif (!$pid) {
    # Child process

    # Fork worked
    ok 1;

    # Let go of the other side $dad_rd
    close $dad_wr;

    # Test possible race condition
    # by making parent reach newpid()
    # and attempt relock before child
    # even calls newpid() the first time.
    sleep 2;
    $lock1->newpid;

    # Child continues on while parent holds onto the lock...
  } else {
    # Parent process

    # Notify lock that we've forked.
    $lock1->newpid;

    # Parent hangs onto the lock for a bit
    sleep 5;

    # Parent finally releases the lock
    undef $lock1;

    # And releases $dad_rd to signal the child
    # that's the lock should be free.
    close $dad_wr;

    # Clear the Child Zombie
    wait;

    # Avoid normal "exit" checking plan counts.
    require POSIX;
    POSIX::_exit(0);
    # Don't continue on since the child should have already done the tests.
  }
}
# Lock is out of scope, but should
# still be acquired by the parent.

# Try to get a non-blocking lock.
# Quickly, before the parent releases it.
# This lock should fail.
{
  # Forced dummy scope
  my $lock2 = new File::NFSLock {
    file => $datafile,
    lock_type => LOCK_EX|LOCK_NB,
  };

  ok(!$lock2);
}

# Wait for the parent process to release the lock
scalar <$dad_rd>;
ok(1);

# Try again now that the parent is done.
# This time it should work.
{
  # Forced dummy scope
  my $lock2 = new File::NFSLock {
    file => $datafile,
    lock_type => LOCK_EX|LOCK_NB,
  };

  ok($lock2);
}

# Wipe the temporary file
unlink $datafile;
