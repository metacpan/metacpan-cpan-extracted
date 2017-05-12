# Test program for MPE::Spoonfeed
# This test does depend on MPE::CIvar, but the module does not
# 
######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}
use MPE::Spoonfeed;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

if (!eval "use MPE::CIvar ':all'; 1") {
  die "This test program depends on module MPE::CIvar\n";
}

$CIVAR{CPTEST} = 997;
my $ciproc = MPE::Spoonfeed->new("CI.PUB.SYS", activate=>0, parm=>3)
   or die "Error on createprocess: $CreateStatus\n";
# Note: this is just for testing purposes, because all systems
# have CI.PUB.SYS.  It is not a good way to run CI commands

print "ok 2\n";
$ciproc->cmds("SETVAR CPTEST 105");

if (defined($ciproc)) {
  print "ok 3\n";
} else {
  print "not ok 3\n";
  print STDERR "createstatus = $MPE::Process::CreateStatus\n";
  die "Error on CreateProcess\n";
}

if ($ciproc->activate) {
  print "ok 4\n";
} else {
  print "not ok 4\n";
}
print "Pausing for 5 seconds ...\n";
# I pause because I don't know when the CI command will be run
sleep(5);
if ($CIVAR{CPTEST} == 105) {
  print "ok 5\n";
} else {
  print "not ok 5\n";
}
