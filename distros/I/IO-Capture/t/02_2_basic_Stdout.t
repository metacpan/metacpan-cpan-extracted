# vim600: set syn=perl :
use strict;
use Test::More tests => 13;
BEGIN { use_ok('IO::Capture::Stdout') };

#Save initial values
my ($initial_stdout_dev, $initial_stdout_inum) = (stat(STDOUT))[0,1];
my ($initial_stderr_dev, $initial_stderr_inum) = (stat(STDERR))[0,1];
my $warn_save = $SIG{__WARN__}; 

#Test 2
ok (my $capture = IO::Capture::Stdout->new(), "Constructor Test");

#########################################################
# Start, put some data, Stop ############################
#########################################################

my $rv1 = $capture->start() || 0;
my $rv2;
if ($rv1) {
    print "Test Line One";
    print "Test Line Two";
    print "Test Line Three";
    print "Test Line Four";
    $rv2 = $capture->stop()  || 0;
}

#########################################################
# Check the results #####################################
#########################################################

#Test 3
ok ($rv1, "Start Method");

#Test 4
ok ($rv2, "Stop Method");

#Test 5
my $line1 = $capture->read();
my $results_line1 = $line1 eq "Test Line One";
ok ($results_line1, "Read Method, First Line");
diag "*"x60 . "\n1st line read was: $line1\n" . "*"x60 . "\n\n" unless $results_line1;

#Test 6
my $line2 = $capture->read();
my $results_line2 = $line2 eq "Test Line Two";
ok ($results_line2, "Read Method, Second Line");
diag "*"x60 . "\n2nd line read was: $line2\n" . "*"x60 . "\n\n" unless $results_line2;

#Test 7
my $line3 = $capture->read();
my $results_line3 = $line3 eq "Test Line Three";
ok ($results_line3, "Read Method, Third Line");
diag "*"x60 . "\n3rd line read was: $line3\n" . "*"x60 . "\n\n" unless $results_line3;


#Test 8
$capture->line_pointer(1);
my $new_line_pointer = $capture->line_pointer;
ok($new_line_pointer == 1, "Check set line_pointer");

#Test 9
my $line1_2 = $capture->read();
my $results_line1_2 = $line1_2 eq "Test Line One";
ok ($results_line1_2, "Read After line_pointer(), First Line");
diag "*"x60 . 
     "\nline read after line_pointer() was: $line1_2\n" . 
     "*"x60 . 
     "\n\n" 
     unless $results_line1_2;

#Test 10
my @lines_array = $capture->read;
ok(@lines_array == 4, "List Context Check");


#########################################################
# Check for untie #######################################
#########################################################

#Test 11
my $tie_check = tied *STDOUT;
ok(!$tie_check, "Untie Test");

#########################################################
# Check filehandles - STDOUT ############################
#########################################################

my ($ending_stdout_dev, $ending_stdout_inum) = (stat(STDOUT))[0,1];

#Test 12
ok ($initial_stdout_dev == $ending_stdout_dev, "Invariant Check - STDOUT filesystem dev number");

#Test 13
ok ($initial_stdout_inum == $ending_stdout_inum, "Invariant Check - STDOUT inode number");
