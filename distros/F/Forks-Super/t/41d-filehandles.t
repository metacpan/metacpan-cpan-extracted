use Forks::Super ':test';
use Test::More tests => 6;
use strict;
use warnings;

#
# test whether a parent process can have access to the
# STDIN, STDOUT, and STDERR filehandles of a child
# process. This features allows for communication
# between parent and child processes.
#

#######################################################

# exercise stdout, stdin, stderr 

my $input = "Hello world\n";
my $output = "";
my $error = "overwrite me!";
my $pid = fork { 
    stdin => $input, 
    stdout => \$output, 
    stderr => \$error,
    sub => sub {
      sleep 2;
      while(<STDIN>) {
	print STDERR "Got input: $_";
	chomp;
	my $a = reverse $_;
	print $a, "\n";
      }
      sleep 2;
    } };
ok($output eq "" && $error =~ /overwrite/,          ### 1d ###
   "$$\\output($output)/error($error) not updated until child is complete "
   ." (pid=$pid)");
waitpid $pid, 0;
ok($output eq "dlrow olleH\n", "updated output from stdout");
ok($error !~ /overwrite/, "error ref was overwritten");
ok($error =~ qr"^Got input: $input", "\$error=$error");

my @input = ("Hello world\n", "How ", "is ", "it ", "going?\n");
my $orig_output = $output;
$pid = fork { stdin => \@input , stdout => \$output,
		sub => sub {
		  sleep 1;
		  while (<STDIN>) {
		    chomp;
		    my $a = reverse $_;
		    print length($_), $a, "\n";
		  }
#		print STDERR "$$ is done...\n";
		} };
ok($output eq $orig_output, 
   "output not updated until child is complete (pid=$pid)");
waitpid $pid, 0;
ok($output eq "11dlrow olleH\n16?gniog ti si woH\n", 
   "read input from ARRAY ref");
waitall;

# MSWin32: this script leaves one stray IPC file