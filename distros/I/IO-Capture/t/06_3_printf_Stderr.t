# vim600: set syn=perl :
use Test::More tests => 13;
BEGIN { use_ok('IO::Capture::Stderr') };

#Save initial values
my ($initial_stderr_dev, $initial_stderr_inum) = (stat(STDERR))[0,1];

#Test 2
ok (my $capture = IO::Capture::Stderr->new(), "Constructor Test");

#########################################################
# Start, put some data, stop ############################
#########################################################

my $rv1 = $capture->start() || 0;
my $rv2;
if ($rv1) {
    printf STDERR ("Test Line %08d", 1);
    printf STDERR ("Test Line %.3f", 2);
    printf STDERR ("Test Line %8d", 3);
    printf STDERR ("Test Line %s", '4');
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
my $results_line1 = $line1 eq "Test Line 00000001";
ok ($results_line1, "Read Method via printf, First Line");
diag "*"x60 . "\n1st line read was: $line1\n" . "*"x60 . "\n\n" unless $results_line1;

#Test 6
my $line2 = $capture->read();
my $results_line2 = $line2 eq "Test Line 2.000";
ok ($results_line2, "Read Method via printf, Second Line");
diag "*"x60 . "\n2nd line read was: $line2\n" . "*"x60 . "\n\n" unless $results_line2;

#Test 7
$capture->line_pointer(1);
my $new_line = $capture->line_pointer;
ok($new_line == 1, "Check set line_pointer");

#Test 8
my $line1_2 = $capture->read();
my $results_line1_2 = $line1_2 eq "Test Line 00000001";
ok ($results_line1_2, 
    "Read method via printf after line_pointer(), First Line");
diag "*"x60 .
     "\nline read after line_pointer() was: $line1_2\n" .
     "*"x60 .
     "\n\n"
     unless $results_line1_2;


#Test 9
my @lines_array = $capture->read;
ok(@lines_array == 4, "List Context Check");

is($lines_array[3], 'Test Line 4', 
    "List Context: check for individual element");


#########################################################
# Check for untie #######################################
#########################################################

#Test 10 
my $tie_check = tied *STDERR;
ok(!$tie_check, "Untie Test");

#########################################################
# Check filehandles - STDERR ############################
#########################################################

my ($ending_stderr_dev, $ending_stderr_inum) = (stat(STDERR))[0,1];
#Test 11 
ok ($initial_stderr_dev == $ending_stderr_dev, "Invariant Check - STDERR filesystem dev number");

#Test 12
ok ($initial_stderr_inum == $ending_stderr_inum, "Invariant Check - STDERR inode number");

