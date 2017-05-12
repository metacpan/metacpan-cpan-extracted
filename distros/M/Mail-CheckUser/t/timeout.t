use Mail::CheckUser qw(check_email);
 
require 't/check.pl';
 
# timeout test
$Mail::CheckUser::Skip_Network_Checks = 0;
$Mail::CheckUser::Timeout = 1;
 
$email = 'm_ilya@agava.com';
@timeouts = (1, 5, 10);
 
start(scalar(@timeouts));
 
foreach my $timeout (@timeouts) {
        run_timeout_test($email, $timeout);
}
