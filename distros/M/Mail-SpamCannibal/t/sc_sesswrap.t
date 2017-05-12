# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;

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

my @input = qw(echo test send some text that we must catch);
my $response;
if (open(FROMCHILD,"-|")) {
  undef local $/;
  $response = <FROMCHILD>;
  close FROMCHILD;
} else {
# program name is always argv[0]
  unless (open STDERR, '>&STDOUT') {
    print "can't dup STDERR to STDOUT: $!";
    exit;
  }
  exec './scripts/sc_sesswrap', @input
	or die "can't exec ./scripts/sc_sesswrap";
  exit 0;
}

shift @input;
my $expect = join(' ',@input) . "\n";
print "sc_sesswrap wrapper failed\ngot: |$response|\nexp: |$expect|\nnot "
  unless $expect eq $response;
&ok;
