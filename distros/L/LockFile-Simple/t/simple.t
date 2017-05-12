#!./perl

# $Id: simple.t,v 0.3 2007/09/28 19:18:46 jv Exp $
#
#  @COPYRIGHT@
#
# $Log: simple.t,v $
# Revision 0.3  2007/09/28 19:18:46  jv
# Forgot to remove "t.mark".
#
# Revision 0.2.1.1  2000/08/15 18:37:45  ram
# patch3: forgot to remove "t.mark"
#
# Revision 0.2  1999/12/07 20:51:05  ram
# Baseline for 0.2 release.
#

use LockFile::Simple;

$| = 1;				# We're going to fork
print "1..6\n";

#
# Basic tests made via the OO interface.
#

my $manager = LockFile::Simple->make;

unlink 't.lock';

my $lock = $manager->lock('t');

print "not " unless ref $lock;
print "ok 1\n";

print "not " unless -r 't.lock';
print "ok 2\n";

print "not " if $manager->trylock('t');
print "ok 3\n";

print "not " unless $manager->unlock('t');
print "ok 4\n";

print "not " if -f 't.lock';
print "ok 5\n";

#
# Autocleaning
#

sub mark {
	my ($msg) = join(' ', @_);
	open(MARK, ">t.mark");
	print MARK "$msg\n";
	close MARK;
}

$manager = LockFile::Simple->make(-autoclean => 1, -wfunc => \&mark);

unlink 't.mark';

if (0 == fork()) {
	$manager->lock('t');
	exit 0;
}

wait;

print "not " unless -r 't.mark';
print "ok 6\n";

unlink 't.mark';
