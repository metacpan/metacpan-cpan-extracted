# vim600: set syn=perl :
use strict;
use warnings;
use Test::More tests => 9;
BEGIN { use_ok('IO::Capture::Stderr') };

#Save initial values
my ($initial_stderr_dev, $initial_stderr_inum) = (stat(STDERR))[0,1];

# Tests the additional functionality to steal the WARN Handler.
# (and then put back)

#Test 2
ok (my $capture = IO::Capture::Stderr->new( {FORCE_CAPTURE_WARN => 1} ), "Constructor Test");

# Set a new handler
my $new_handler = sub {print "Test message to STDERR - Please ignore. It is normal.  :-)\n"};
$SIG{__WARN__} =  $new_handler;

#########################################################
# Start, put some data, stop ############################
#########################################################

my $rv1 = $capture->start() || 0;
my $rv2;
if ($rv1) {
    warn "Test Line One";
    warn "Test Line Two";
    warn "Test Line Three";
    warn "Test Line Four";
    $rv2 = $capture->stop()  || 0;
}

#########################################################
# Check the results #####################################
#########################################################

#Test 3
ok ($rv1, "Start Method returned true");

#Test 4
ok ($rv2, "Stop Method returned true");

#Test 5
my $line1 = $capture->read();
cmp_ok ($line1,  "==", undef, "Don't overwrite program's handler");

#########################################################
# Check for untie #######################################
#########################################################

#Test 6 
my $tie_check = tied *STDERR;
ok(!$tie_check, "Untie Test");

#########################################################
# Check filehandles - STDERR ############################
#########################################################

my ($ending_stderr_dev, $ending_stderr_inum) = (stat(STDERR))[0,1];
#Test 7 
ok ($initial_stderr_dev == $ending_stderr_dev, "Invariant Check - STDERR filesystem dev number");

#Test 8
ok ($initial_stderr_inum == $ending_stderr_inum, "Invariant Check - STDERR inode number");

#Test 9
# make sure $SIG{__WARN__} is set back to original
cmp_ok ( $SIG{__WARN__}, '==', $new_handler, "warn back to beginning hander");

