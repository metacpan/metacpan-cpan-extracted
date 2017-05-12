# vim600: set syn=perl :
use Test::More tests => 9;
BEGIN { use_ok('IO::Capture') };


#Test 2
ok (my $capture = IO::Capture->new(), "Constructor Test");

# These will generate some warnings -> preventing from printing
open STDERR_SAV, ">&STDERR"; open STDERR, ">/dev/null";

# Save current values to check after start/stop
my ($initial_stdout_dev, $initial_stdout_inum) = (stat(STDOUT))[0,1];
my ($initial_stderr_dev, $initial_stderr_inum) = (stat(STDERR))[0,1];
my $warn_save = $SIG{__WARN__}; 

my $rv1 = $capture->start() || 0;
my $rv2;
if ($rv1) {
    $rv2 = $capture->stop()  || 0;
}

# Grab these before putting STDERR back
my ($ending_stdout_dev, $ending_stdout_inum) = (stat(STDOUT))[0,1];
my ($ending_stderr_dev, $ending_stderr_inum) = (stat(STDERR))[0,1];

close STDERR; open STDERR, ">&STDERR_SAV"; close STDERR_SAV;

#Test 3
ok ($rv1, "Start Method");

#Test 4
ok ($rv2, "Stop Method");

#########################################################
# Check filehandles - STDOUT ############################
#########################################################

#Test 5
ok ($initial_stdout_dev == $ending_stdout_dev, "Invariant Check - STDOUT filesystem dev number ");

#Test 6
ok ($initial_stdout_inum == $ending_stdout_inum, "Invariant Check - STDOUT inode number");

#########################################################
# Check filehandles - STDERR ############################
#########################################################

#Test 7
ok ($initial_stderr_dev == $ending_stderr_dev, "Invariant Check - STDERR filesystem dev number");

#Test 8
ok ($initial_stderr_inum == $ending_stderr_inum, "Invariant Check - STDERR inode number");

#########################################################
# Check $SIG{__WARN__} ##################################
#########################################################

#Test 9
my $test_result_9 = $SIG{__WARN__} eq $warn_save;
ok ($test_result_9, "Invariant Check - __WARN__");
print "\n" . "*"x60 . "\n__WARN__ did not get restored correctly in $0\n" . "*"x60 . "\n\n" unless $test_result_9;
