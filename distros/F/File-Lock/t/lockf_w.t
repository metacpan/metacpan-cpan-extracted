#!/usr/bin/perl

use File::Lock;

$fn = shift || 'test.f';

# avoid dup output
select(STDOUT); $| = 1;

unless( File::Lock::has_lockf ) {
	print "1..1\n";
	print "ok 1\n";
	exit(0);
}

print "1..5\n";

# create the file
open(FH, ">$fn") and close(FH);

open(FH, ">$fn") and ($lk1a = File::Lock::lockf(FH,'wb'));
print 'not ' unless ($lk1a);
print "ok 1\n";

if (fork()) {
  wait(); # hold the lock
} else {
  # we should NOT get exclusive locks on read-opened files
  $lk1b = File::Lock::lockf(FH, 'wn');
  print 'not ' if ($lk1b);
  print "ok 2\n";
  # cleanup if needed
  File::Lock::lockf(FH,'u') if $lk1b;
  
  print STDERR "We = $$, he = ",getppid(),"\n";
  print 'not '  # with fcntl we should see that our dad is locking the file
     if (File::Lock::has_fcntl eq "yes" and ((File::Lock::fcntl(FH,"t"))[4] != getppid()) );
  print "ok 3\n";
          
  exit(0);
}

# releasing the lock should work
print 'not ' unless File::Lock::lockf(FH,'u');
print "ok 4\n";

print 'not '	#  with fcntl we should see that no one is locking the file
	if (File::Lock::has_fcntl and (File::Lock::fcntl(FH,"t") ne "u"));
print "ok 5\n";

close(FH);

unlink($fn);

# eof
