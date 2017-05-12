# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use MMM::Sylk;

$MMM::Sylk::EOL = "\r\n";

my $slk = new MMM::Sylk { FirstRecord => [ "H_first", "H_second", "H_third" ] };


$slk->push_record( [ "uno", "due", "tre" ] );
$slk->push_record( [ "one", "two", "three" ] );
$slk->push_record( [ "ein", "zwei", "drei" ] );
$slk->push_record( [ "però", "com'è", "va là" ] );


$slk->print( \*STDERR );

print STDERR "\n----------------\n";

print ">" .$slk->as_string() . "<";

print STDERR "\n----------------\n";

ok(1); # If we made it this far, we're ok.

