# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Device::Davis;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):
my ($user,$system,$cuser,$csystem) = times();
use POSIX;
use POSIX qw(:errno_h :fcntl_h strftime);
open(LOG, ">test.log") or die "Unable to create test.log file $!\n";
if ( $ENV{AUTOMATED_TESTING} ) {
 print "Skipping 2\n";
 print "Skipping 3\n";
}else{ 
print "Enter the full path to the tty to use (i.e. /dev/tty??)  ";
my $tty = <>;
chomp($tty);
print LOG "Weather station should be connected to $tty\n";
if(-r "$tty"){ print LOG "We have read permission for $tty\n";}else{ print LOG "No read permission for $tty\n"; die "You do not have read permission for $tty\n";};
if(-w "$tty"){ print LOG "We have write permission for $tty\n";}else{ print LOG "No write permission for $tty\n"; die "You do not have write permission for $tty\n";}; 
print LOG "Highest system file descriptor is $^F\n";
# Open the tty
my $fd = station_open($tty);
print LOG "File descriptor for $tty is $fd\n";
if($fd < 0){ die "Unable to open $tty $!\n"; };
$SIG{ALRM} = \&time_out; # set up timeout trap on serial port IO
sub time_out{
# Cause subroutine to die in response to alarm, which allows jumping back into
# script at line following close of eval block.
die "Time out reading serial port.";
};
my $count = 0;
my $failed = 0;
my @data = ();
my $bytes = 0;
wake_up();
sub wake_up{
POSIX::tcflush($fd, TCIOFLUSH);
if($count > 3){
	print "not ok 2\n";
	print "Test 2 failed .... aborting\n";
	print LOG "System times were user $user system $system\n";
	POSIX::close($fd);
	exit 1;
};
$bytes = put_string($fd, "\n");
print LOG "Wrote $bytes byte to $tty for wake up\n";
eval{
alarm(2);  # 2 second timeout
$data[0] = get_char($fd);
$data[1] = get_char($fd);
alarm(0);  # reset timeout
}; # end eval
if($@ =~ /Time out reading serial port/){
	print LOG "Pass number $count through wake up timed out\n";
	print LOG "Received @data from station\n";
        $count++;
	@data = ();
        wake_up();
};
if($data[0] == 10 && $data[1] == 13){ # Test for valid responses
	print LOG "Received $data[0] and $data[1] from station on pass $count through wake up\n";
        print "ok 2\n";
	POSIX::tcflush($fd, TCIOFLUSH);
	print LOG "Wake up successful\n";
}else{ # Response was not what was expected so try again
	print LOG "Received $data[0] and $data[1] from station on pass $count through wake up\n";
	$count++;
        wake_up();
};
};
@data = ();
$bytes = put_string($fd, "TEST\n");
print LOG "Wrote $bytes bytes to $tty for TEST\n";
eval{
alarm(2);  # 2 second timeout
$data[0] = get_char($fd); # \n character
$data[1] = get_char($fd); # \r character
$data[2] = get_char($fd);
$data[3] = get_char($fd);
$data[4] = get_char($fd);
$data[5] = get_char($fd);
$data[6] = get_char($fd); # \n character
$data[7] = get_char($fd); # \r character
alarm(0);  # reset timeout
}; # end eval
if($@ =~ /Time out reading serial port/){
        print LOG "Timed out waiting for response to TEST\n";
	print "not ok 3\n";
	$failed = 1;
};
print LOG "Received @data from station in response to TEST\n";
my $response = pack("C*", $data[2], $data[3], $data[4], $data[5]);
if($response eq 'TEST'){
	print "ok 3\n";
	print LOG "Packed response from TEST was $response\n";
}else{ 
	print LOG "Packed response from TEST was $response\n";
	print "not ok 3\n"; 
	$failed = 1; 
};
};
my $old_crc = 0;
my $crc = 0;
$crc = crc_accum($old_crc, 0xc6);
$old_crc = $crc;
$crc = crc_accum($old_crc, 0xce);
$old_crc = $crc;
$crc = crc_accum($old_crc, 0xa2);
$old_crc = $crc;
$crc = crc_accum($old_crc, 0x03);
$old_crc = $crc;
$crc = crc_accum($old_crc, 0xe2);
$old_crc = $crc;
$crc = crc_accum($old_crc, 0xb4);
print LOG "crc test returned $crc\n";
if($crc == 0){
	print "ok 4\n";
}else{
	print "not ok 4\n";
	$failed = 1;
};
if($failed){
	print "Some tests failed.  Check test.log for details.\n";
}else{
	print "All Tests Successful.\n"; 
};
POSIX::close($fd);
print LOG "System times were user $user system $system\n";
close(LOG);
