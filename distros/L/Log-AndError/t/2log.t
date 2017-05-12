# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..14\n"; }
END {print "not ok 1\n" unless $loaded;}
use Log::AndError;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub log_sub {
# sprintf() like sub
}

$axis = -100;
$of   = 'ENTRY NOT LOGGED';
$evil = $of;
$good = 'ENTRY LOGGED';

$ref_logger = Log::AndError->new(
	'LOG_LOGGER' => \&log_sub,
	'LOG_SERVICE_NAME' => 'TEST_SERVICE', 
	'LOG_DEBUG_LEVEL'  =>  3,
	'LOG_INFO_LEVEL' => -2, 
	'LOG_ALWAYSLOG_LEVEL' => -3, 
);

if(ref($ref_logger) eq 'Log::AndError'){
	print("ok 2\n");
}
else{
	print("not ok 2\n");
}

{
	my ($err, $msg) = $ref_logger->error($axis, $of);
	if($err eq $axis){
		print("ok 3\n");
	}
	else{
		print("not ok 3\n");
	}
	if($msg eq $of){
		print("ok 4\n");
	}
	else{
		print("not ok 4\n");
	}
}

{
	my($err,$msg) = $ref_logger->error();
	if($err eq $axis){
		print("ok 5\n");
	}
	else{
		print("not ok 5\n");
	}
	if($msg eq $evil){
		print("ok 6\n");
	}
	else{
		print("not ok 6\n");
	}
}

{
	my($retval, $msg ) = $ref_logger->logger(4, $evil);
	if($msg eq $evil){
		print("ok 7\n");
	}
	else{
		print("not ok 7\n");
	}
}

{
	my($retval, $msg ) = $ref_logger->logger(2, $good);
	if($msg eq $good){
		print("ok 8\n");
	}
	else{
		print("not ok 8\n");
	}
}


{
	$ref_logger->debug_level(6);
	my($retval) = $ref_logger->debug_level();
	if($retval == 6){
		print("ok 9\n");
	}
	else{
		print("not ok 9\n");
	}
}

{
	$ref_logger->info_level(-20);
	my($retval) = $ref_logger->info_level();
	if($retval == -20){
		print("ok 10\n");
	}
	else{
		print("not ok 10\n");
	}
}

{
	$ref_logger->alwayslog_level(-30);
	my($retval) = $ref_logger->alwayslog_level();
	if($retval == -30){
		print("ok 11\n");
	}
	else{
		print("not ok 11\n");
	}
}

{
	my $template = "%s, %d, %s";
	$ref_logger->template($template);
	my($retval) = $ref_logger->template();
	if($retval eq $template){
		print("ok 12\n");
	}
	else{
		print("not ok 12\n");
	}
}

{
	my $template = "%s: LEVEL[%d]: and THIS is different %s";
	$ref_logger->template($template);
	my($retval) = $ref_logger->template();
	if($retval eq $template){
		print("ok 13\n");
	}
	else{
		print("not ok 13\n");
	}
}

{
	my $template = "%s: LEVEL[%d]: and THIS is wrong";
	$ref_logger->template($template);
	my($retval) = $ref_logger->template();
	if($retval ne 'Bad sprintf() Template'){
		print("ok 14\n");
	}
	else{
		print("not ok 14\n");
	}
}
