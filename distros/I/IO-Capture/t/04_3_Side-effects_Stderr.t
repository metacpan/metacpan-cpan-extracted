# vim600: set syn=perl :
use Test::More tests => 5;
BEGIN { use_ok('IO::Capture') };

# Change SIG{__WARN__} to make sure it gets put back correctly
$SIG{__WARN__} = sub {print STDERR "Redirected message from warn(): @_\n"}; 
my $warn_save = $SIG{__WARN__};

#Test 2
ok (my $capture = IO::Capture->new(), "Constructor Test");

#Test 3
ok ($capture->start, "Start Method");
#Test 4
ok ($capture->stop, "Stop Method");


#########################################################
# Check WARN ############################################
#########################################################
#Test 5
my $test_result_5 = $SIG{__WARN__} eq $warn_save;
ok ($test_result_5, "Invariant Check - __WARN__");
diag "\n" . "*"x60 . "\n__WARN__ did not get restored correctly in $0\n" . "*"x60 . "\n\n" unless $test_result_5;

