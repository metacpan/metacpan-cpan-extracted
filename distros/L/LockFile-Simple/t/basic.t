#!./perl

# $Id: basic.t,v 0.2 1999/12/07 20:51:05 ram Exp ram $
#
#  @COPYRIGHT@
#
# $Log: basic.t,v $
# Revision 0.2  1999/12/07 20:51:05  ram
# Baseline for 0.2 release.
#

use LockFile::Simple qw(lock trylock unlock);

print "1..5\n";

unlink 't.lock';
print "not " unless lock('t');
print "ok 1\n";

print "not " unless -r 't.lock';
print "ok 2\n";

print "not " if trylock('t');
print "ok 3\n";

print "not " unless unlock('t');
print "ok 4\n";

print "not " if -f 't.lock';
print "ok 5\n";

