# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..257\n"; }
END {print "not ok 1\n" unless $loaded;}

use CTest;

$TCTEST		= 'Mail::SpamCannibal::DNSBLserver::CTest';
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

my @validchars = qw( 1 2 3 4 5 . 6 7 8 9 0 );
my @otherchars = (0x1..0xFF);

## test 2	check that valids are really valid
$valid = join('',@validchars);
print "$_ not numeric set\nnot "
	if &{"${TCTEST}::t_not_numeric"}($valid);
&ok;

## test 3	check all invalids
foreach my $invalid (@otherchars) {
  my $rinvc = pack('C',$invalid);
  if (grep($_ eq $rinvc,@validchars)) {	# skip valid chars
    printf ("Skipping.... 0x%02X %c\n",$invalid,$invalid);
  } else {
    printf("passed invalid character %02X\nnot ",$invalid)
	unless &{"${TCTEST}::t_not_numeric"}(pack('C a*',$invalid,$valid));
  }
  &ok;
}
