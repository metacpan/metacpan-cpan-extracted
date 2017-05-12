# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "Starting tests\n\n"; }
END {print "not ok 1\n\n" unless $loaded;}
use Mail::Bulkmail;
$loaded = 1;

my $ok = 1;

print "loaded Mail::Bulkmail...ok ", $ok++, "\n\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Mail::Bulkmail::Object;
use Mail::Bulkmail::Dynamic;
use Mail::Bulkmail::Server;
use Mail::Bulkmail::DummyServer;

$loaded = 1;

print "Loaded all modules...ok ", $ok++, "\n\n";

#create a DummyServer that sends to /dev/null
my $dummy = Mail::Bulkmail::DummyServer->new(
	'dummy_file'	=> '/dev/null',
	'Domain'		=> 'yourdomain.com'
) || die Mail::Bulkmail::DummyServer->error();

print "Successfully created dummy server object...ok ", $ok++, "\n\n";

print "okay...now I'm going to try a test message. Nothing will actually be sent...\n\n";

my $bulk = Mail::Bulkmail->new(
	'LIST'		=> [qw(valid_address@yourdomain.com invalid_address@yourdomain valid_address2@yourdomain.com)],
	'GOOD'		=> \&good,
	'BAD'		=> \&bad,
	'From'		=> 'test@yourdomain.com',
	'Message'	=> 'This is a test message',
	'Subject'	=> "test message",
	'servers'	=> [$dummy]
) || die Mail::Bulkmail->error();

print "Successfully created bulkmail object...ok ", $ok++, "\n\n";

$bulk->bulkmail || die $bulk->error();

print "Successfully bulkmailed...ok ", $ok++, "\n\n";

print "All succesful...done\n\n";

sub good {
	my $obj = shift;
	my $email = shift;
	if ($email eq 'valid_address@yourdomain.com' || $email eq 'valid_address2@yourdomain.com'){
		print "Mail successfully sent to $email...ok ", $ok++, "\n\n";
	}
	else {
		print "Mail could not be sent to $email...not ok", $ok++, "\n\n";
	};
};

sub bad {
	my $obj = shift;
	my $email = shift;
	if ($email eq 'invalid_address@yourdomain'){
		print "Mail did not send to $email...ok ", $ok++, "\n\n";
	}
	else {
		print "Mail could successfully sent to $email...not ok", $ok++, "\n\n";
	};
};
