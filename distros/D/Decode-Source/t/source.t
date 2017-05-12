# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use Test::More tests => 6;

#########################

# test01: Test version...

	use Decode::Source 'iso-8859-1';
	ok( 1, "use Decode::Source 'iso-8859-1';" );

# test02: Test a variable...

	ok(eval 'our $Âke = "≈ke"', "Set strange variable");

# test03: Change encoding...

	use Decode::Source 'cp-850';
	ok( 1, "use Decode::Source 'cp-850';" );

# test04: # Check content in variable...

	ok(eval '$Üke eq "èke"', "Reach strange variable data");

# test05: # Turn off any encodings...

	no Decode::Source;
	ok( 1, "no Decode::Source;" );

# test06: # Fail to reach data ? 

	close STDERR; # Avoid "Bareword found..."
	ok(!eval('$Âke'), "No strange variables");

