#!/usr/bin/perl

use File::Lock;

$fn = shift || 'test.f';

# avoid dup output
select(STDOUT); $| = 1;


unless( File::Lock::has_flock ) {
	print "1..1\n";
	print "ok 1\n";
	exit(0);
}

print "1..5\n";

# create the file
open(FH, ">$fn") and close(FH);

open(FH, "<$fn") and ($lk1a = File::Lock::flock(FH,'r'));
print 'not ' unless ($lk1a);
print "ok 1\n";

if (fork()) {
  wait(); # hold the lock
} else {
  # we SHOULD get multiple shared locks on read-opened files
  print 'not ' unless ($lk1b = File::Lock::flock(FH,'r'));
  print "ok 2\n";
  exit(0);
}

if (fork()) {
  wait(); # hold the lock
} else {
  close(FH);
  open(FH,"+>$fn");
  
  # we should NOT get exclusive locks on read-opened files
  print 'not ' if ($lk1b = File::Lock::flock(FH, 'wn'));
  print "ok 3\n";
  # cleanup if needed
  File::Lock::flock(FH,'u') if $lk1b;
  
  close(FH);
  exit(0);
}

# releasing the lock should work
print 'not ' unless File::Lock::flock(FH,'u');
print "ok 4\n";

print 'not '	#  with fcntl we should see that no one is locking the file
	if (File::Lock::has_fcntl and File::Lock::fcntl(FH,"t") ne "u");
  
print "ok 5\n";

close(FH);

unlink($fn);

# eof
