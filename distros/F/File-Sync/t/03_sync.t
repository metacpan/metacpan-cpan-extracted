#! ./perl

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use File::Sync qw(sync);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Make sure sync doesn't crash.
sync(); print "ok 2\n";

# Test error-checking: number of arguments.
eval "sync(1)";
unless ($@ and $@ =~ m/^Too many arguments/)
  { print STDERR $@; print 'not '; }
print "ok 3\n";

eval { &sync(1); };
unless ($@ and $@ =~ m/^usage:/i)
  { print STDERR $@; print 'not '; }
print "ok 4\n";
