#
# $Header: /cvsroot/WWW::Fido/test.pl,v 1.4 2002/10/31 01:07:27 mina Exp $
#

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use WWW::Fido;
$loaded = 1;
print "ok 1\n";
$counter++;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

&showresult (
	$phone = new WWW::Fido ("1234567890", "Firstname Lastname")
	);

&showresult (
	$phone->setphone("1112223333")
	);

&showresult (
	$phone->setname("Mina Naguib")
	);

warn ("\n\nNOTICE: I did not actually send a message to anyone. You'll need to test this manually through your script later on.\n\n");

sub showresult() {
	my $result = shift;
	$counter++;
	if (!$result) {
		print "not ok $counter\n";
		warn ("ERROR REASON: $@\n\n");
		}
	else {
		print "ok $counter\n";
		}
	}

