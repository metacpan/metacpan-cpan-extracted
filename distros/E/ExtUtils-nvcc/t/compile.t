# A script to see if nvcc actually compiles code that runs.

use Test::More tests => 4;
use strict;
use warnings;

# This script has four main parts. First, we ensure that we are in the
# distribution's root directory and include the blib's script diretory in our
# path. Then we run some basic compile tests against .cu files. Third, we run
# more compile tests against .c files. Finally, I define a function that I use
# for a number of tests called compile_and_run.

#####################
# Environment Setup #
#####################

# Ensure we are in the distribution's root directory (otherwise, including the
# blib in the path will prove futile).
use Cwd;
use File::Spec;
if (cwd =~ /t$/) {
	print "# moving up one directory\n";
	chdir File::Spec->updir() or die "Need to move out of test directory, but can't\n";
}


# Make sure we don't encounter the file-already-exists problem:
unlink 'rename_test.cu' if -f 'rename_test.cu';

###################
# CUDA file tests #
###################
# Tests 1-4 for plain C code and plain cuda code, using .c and .cu file
# extensions.

my $compile_output = compile_and_run('t/simple_compile_test.cu', 'good to go!');
$compile_output = compile_and_run('t/cuda_test.c', 'Success');

###################
# compile_and_run #
###################

# Handy function that wraps a number of lines of code that I kept reusing in my
# testing:
use ExtUtils::nvcc;
sub compile_and_run {
	my ($filename, $match) = @_;
	
	my @InlineOptions = ExtUtils::nvcc::Inline;
	my $compile_command = $InlineOptions[1];
	# Add the blib to the command:
	$compile_command =~ s/--/-Mblib --/;

	# Compile the test code:
	my $compile_output = `$compile_command -o test $filename`;
	# Get the compiler's return value:
	my $results = $?;
	
	# make sure the compilation returns a good result:
	ok($results == 0, "ExtUtils::nvcc compiled $filename");
	
	# Run the program:
	$results = `./test`;
	$match = qr/$match/ unless ref($match) eq 'Regexp';
	like($results, $match, "Output of $filename is correct");
	
	# Remove the executable file, and return the results of the compile:
	unlink 'test';
	
	return $compile_output;
}
