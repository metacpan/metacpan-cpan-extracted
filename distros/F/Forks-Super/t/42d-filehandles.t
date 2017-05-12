use Forks::Super ':test';
use Test::More tests => 5;
use Carp;
use strict;
use warnings;

#
# test whether the parent can have access to the
# STDIN, STDOUT, and STDERR filehandles from a
# child process when the child process uses
# the "cmd" option to run a shell command.
#

##########################################################

# exercise stdout, stdin, stderr 
my @cmd;

if (-x '/bin/sort') {
    @cmd = ("/bin/sort");
} elsif (-x '/usr/bin/sort') {
    @cmd = ("/usr/bin/sort");
} else {
    open(my $POOR_MANS_SORT, '>', 't/poorsort.pl');
    print $POOR_MANS_SORT "#!$^X\n";
    print $POOR_MANS_SORT "print sort <>\n";
    close $POOR_MANS_SORT;
    @cmd = ($^X, "t/poorsort.pl");
}

#my $input = join("\n", qw(the quick brown fox jumps over the lazy dog)) . "\n";
my $output = '';
my $error = "overwrite me\n";

$Forks::Super::ON_BUSY = "queue";

my $pid = fork \@cmd, { 
        stdin => <<__INPUT__,
the
quick
brown
fox
jumps
over
the
lazy
dog
__INPUT__
	stdout => \$output, 
	stderr => \$error, 
	delay => 2 
};
ok($output eq '' && $error =~ /overwrite/,
   "$$\\output/error not updated until child is complete");
waitpid $pid, 0;
ok($output eq "brown\ndog\nfox\njumps\nlazy\nover\nquick\nthe\nthe\n",
   "updated output from stdout\ncmd \"@cmd\", output:\n$output");
ok(!$error || $error !~ /overwrite/, "error ref was overwritten");

my @input = ("tree 1\n","bike 2\n","camera 3\n",
	     "car 4\n","hand 5\n","gun 6\n");
my $orig_output = $output;
$pid = fork {
	stdin => \@input, 
	stdout => \$output, 
	exec => \@cmd, 
	delay => 2 
};
ok($output eq $orig_output, "output not updated until child is complete.");
waitpid $pid, 0;
my @output = split /\n/, $output;
ok($output[0] eq "bike 2" && $output[2] eq "car 4" && $output[3] eq "gun 6",
   "read input from ARRAY ref");
waitall;

