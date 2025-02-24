#!/usr/bin/perl

use File::Lock;

$fn = shift || 'test.f';

# avoid dup output
select(STDOUT); $| = 1;

unless( File::Lock::has_lockf() ) {
	print "1..1\n";
	print "ok 1\n";
	exit(0);
}

print "1..5\n";

# create the file
open(FH, ">$fn");
print FH "Test";
close(FH);

print 'not ' unless open(FH, ">$fn");
print "ok 1\n";
print 'not ' unless File::Lock::lockf(FH,'wb');
print "ok 2\n";
print 'not ' unless File::Lock::lockf(FH,'u');
print "ok 3\n";
print 'not ' unless close(FH);
print "ok 4\n";

print 'not ' unless unlink($fn);
print "ok 5\n";

# eof
