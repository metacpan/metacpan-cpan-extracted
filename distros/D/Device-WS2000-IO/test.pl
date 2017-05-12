# CVS: $Id: test.pl,v 1.4 2002/04/20 07:29:23 michael Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)
my $loaded = 1;
my $not ;
BEGIN { $| = 1; $not = 4; print "1..$not\n"; }
END {print "not ok $loaded\n" if $loaded < $not;}
use Device::WS2000::IO qw(:all) ;

######################### End of black magic.
# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

if (open_ws("ttyS1")) {
  my ($nread,$buffer);
  print "ok $loaded\n";
  $loaded ++;
  send_ws(0,0);
  print "ok $loaded\n";
  $loaded ++;
  $buffer = read_ws();
  print join(":","got","$buffer ",ord($buffer),"ok",$loaded,"\n");
  $loaded ++;
  close_ws();
  print "ok $loaded\n";
}
