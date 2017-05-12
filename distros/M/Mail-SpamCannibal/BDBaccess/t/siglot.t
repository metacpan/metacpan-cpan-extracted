# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use CTest;
use constant INT	=> 2;

$TCTEST		= 'Mail::SpamCannibal::BDBaccess::CTest';
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

# test that signals can be set and executed
# runs through STDOUT log process producing 
# "Exiting ..." so check that string actually
# is output to STDOUT

my $kid = 0;
my $timeout = 0;
my $found = 0;
local $SIG{ALRM} = sub { 
	die "no child process\n" unless $kid;
	$timeout = 1;
	kill 9, $kid;
};

if ($kid = open(FROMCHILD, "-|")) {
  alarm 5;
  while (my $record = <FROMCHILD>) { 
    if ($record =~ /signals set/) {
      kill INT, $kid;
      next;
    }
    if ($record =~ /Exiting/i) {
      $found = 1;
      last;
    }
  }
  alarm 0;
} else {
  &{"${TCTEST}::t_setsig"}();
  print "signals set\n";
  while(1){
    sleep 1;
  }
}
close FROMCHILD;
  if ($timeout) {
    print "SIGINT failed in child\nnot ";
  }
  elsif (!$found) {
    print "'Exiting' statement not found\nnot ";
  }
&ok;
