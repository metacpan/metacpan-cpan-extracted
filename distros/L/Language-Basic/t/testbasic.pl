# testbasic.pl
# This file is included by a bunch of Language::Basic test scripts.
# It provides subs that make it easy to write test scripts and run them
# using Test::Harness (i.e., "make test")
#
# Each script has one or more BASIC test programs in it. For each test program,
# the script calls sub setup_test with the BASIC code and the expected output.
# Then perform_tests is called.
#
# This method might seem a bit cumbersome, but it means that sub perform_tests
# can automatically figure out how many tests there are.

use Language::Basic;

# Temporary file that BASIC programs write to. We then read in the file
# & compare the output to our expected output.
my $tempname = "test.out";
# Strings containing a program & its expected output
my (@codes, @expecteds);

# Setup one test
# arg0 is BASIC code (with a bunch of \n's in it)
# arg1 is the expected output (including whitespace!) 
sub setup_test {
    my ($code, $expected) = @_;
    # This allows indenting code in test scripts, for readability
    $code =~ s/^\s*//gm;
    push @codes, $code;
    push @expecteds, $expected;
}

# Write "1..foo".
# Then run all the tests
sub perform_tests {
    if (@codes != @expecteds) {
	print "Test file had different number of codes and expected outputs!\n";
	print "1..1\nnot ok";
	return;
    }

    # How many tests are we running
    my $numtests = @codes;
    print "1..$numtests\n";

    foreach my $num (1..$numtests) {
        my ($code, $expected) = (shift @codes, shift @expecteds);
	&expect($code, $expected, $num);
    }
    # TODO we should also (here or in expect) convert file to Perl,
    # run the Perl program, and test its output
}

# Run code in arg0, expecting arg1, (test number arg2).
# Output stuff that Test::Harness will like. Print out lots more stuff if
# we did "make test TEST_VERBOSE=1" and we get an error
sub expect {
    my ($code, $expected, $num) = @_;
    my $error = 0;

    # Read in and run the program
    my $prog = new Language::Basic::Program;
    my @lines = split(/\n/, $code);
    foreach (@lines) {
        defined $prog->line( $_ ) or $error = "parse", last;
    }

    my $output;
    if (!$error) {
	# TODO should act like below rather than using a temp file
	#my $output = '';
	#$prog->output( \$output );
	  # By this point of course PRINT etc can print to a
	  # provided output handle *or* appended to a provided
	  # string ref (here) *or* call a print callback sub

	open(OUT, ">$tempname");
	select(OUT);

	# TODO call with eval, set $error="implement" if it dies
	$prog->implement;
	close(OUT);
	select(STDOUT);

	open (IN, "<$tempname") or die $!;
	local $/;
	undef $/;
	$output = <IN>;
	$output = "" unless defined $output; # empty file?
	close(IN);
	unlink $tempname;

	$error = "output" if $expected ne $output;
    }

    if ($error) {
	print "Code is:\n$code\n";
	if ($error eq "parse") {
	    # TODO why not just print $output, which has the error in it?
	    print "Error during parsing\n";
	} elsif ($output =~ /\n/) {
	    print "Output is:\n$output\n";
	} elsif ($output ne "") {
	    print  "Output is: '$output'\n";
	} else {
	    print "There was no output\n";
	}

	# TODO actually, we should sometimes expect errors during parsing
	if ($error ne "parse") {
	    if ($expected =~ /\n/) {
		print "Expected:\n$expected\n";
	    } elsif ($expected ne "") {
		# (extra space lines it up with 'Output is:' line)
		print "Expected : '$expected'\n";
	    } else {
	        print "No output expected\n";
	    }
	}
    }
    print "not " if $error;
    print "ok $num\n"; 
}

1;
