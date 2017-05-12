#!/usr/bin/perl

use File::Lock;

$fn = shift || 'test.f';

# avoid dup output
select(STDOUT); $| = 1;

unless( File::Lock::has_fcntl() ) {
	print "1..1\n";
	print "ok 1\n";
	exit(0);
}

print "1..9\n";

# create the file
open(FH, ">$fn");
print FH "Test";
close(FH);

print 'not ' unless open(FH, "<$fn");
print "ok 1\n";
print 'not ' unless File::Lock::fcntl(FH,'rb');
print "ok 2\n";
print 'not ' unless File::Lock::fcntl(FH,'u');
print "ok 3\n";
print 'not ' unless close(FH);
print "ok 4\n";

print 'not ' unless open(FH, ">$fn");
print "ok 5\n";
print 'not ' unless File::Lock::fcntl(FH,'wb');
print "ok 6\n";
print 'not ' unless File::Lock::fcntl(FH,'u');
print "ok 7\n";
print 'not ' unless close(FH);
print "ok 8\n";

print 'not ' unless unlink($fn);
print "ok 9\n";

# eof
