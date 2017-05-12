use Forks::Super ':test';
use Test::More tests => 9;
use Carp;
use strict;
use warnings;

$Forks::Super::EMULATION_MODE = 1;

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

my $input = join("\n", qw(the quick brown fox jumps over the lazy dog)) . "\n";
my $output = '';
my $error = "overwrite me\n";

$Forks::Super::ON_BUSY = "queue";

my $pid = fork \@cmd, {
    stdin => $input,
    stdout => \$output,
    stderr => \$error,
    delay => 2
};
ok($output eq '' && $error =~ /overwrite/,
   "$$\\output/error not updated, emulation respects delay");
waitpid $pid, 0;
ok($pid->{is_emulation}, 'background task was emulated');
ok($output eq "brown\ndog\nfox\njumps\nlazy\nover\nquick\nthe\nthe\n",
   "updated output from stdout")
    or diag "\ncmd \"@cmd\", output:\n$output";
ok(!$error || $error !~ /overwrite/, "error ref was overwritten");

my $orig_output = $output;
$pid = fork {
    stdin => <<__INPUT__,
tree 1
bike 2
camera 3
car 4
hand 5
gun 6
__INPUT__
    stdout => \$output,
    exec => \@cmd,
};
ok($output ne $orig_output, "emulated task completed, output updated");
my $wait1 = waitpid $pid, 0;
ok($wait1 == $pid, 'waitpid of emulated pid returns pid');
my $wait2 = waitpid $pid, 0;
ok($wait2 == -1, 'second waitpid of emulated pid returns -1');
ok($pid->{is_emulation}, 'background task was emulated');
my @output = split /\n/, $output;
ok($output[0] eq "bike 2" && $output[2] eq "car 4" && $output[3] eq "gun 6",
   "read input from ARRAY ref");
waitall;
