use Forks::Super ':test';
use Test::More tests => 12;
use Carp;
use strict;
use warnings;

#
# test whether the parent can have access to the
# STDIN, STDOUT, and STDERR filehandles from a
# child process when the child process uses
# the "cmd" option to run a shell command.
#

#######################################################
my (@cmd,$pid,$fh_in,$z,$t,@out,@err,$msg);
@cmd = ($^X, "t/external-command.pl", "-s=2", "-y=2");


#######################################################
# test join, read_stdout
# 

$pid = fork \@cmd, timeout => 6, child_fh => 'in,out,join';
ok(isValidPid($pid), "$$\\started job with join");

$msg = sprintf "the message is %x", rand() * 99999999;
$z = print {$Forks::Super::CHILD_STDIN{$pid}} "$msg\n";
ok($z > 0, "successful print to child STDIN");
ok(defined $Forks::Super::CHILD_STDIN{$pid}, 
   "CHILD_STDIN value defined [child_fh]");
ok(defined $Forks::Super::CHILD_STDOUT{$pid}, 
   "CHILD_STDOUT value defined");
ok(defined $Forks::Super::CHILD_STDERR{$pid}, 
   "CHILD_STDERR value defined");
ok($Forks::Super::CHILD_STDOUT{$pid} eq $Forks::Super::CHILD_STDERR{$pid},
   "child stdout and stderr go to same fh");
$t = time;
@out = ();
while (time < $t+10) {
    while ((my $line = Forks::Super::read_stdout($pid, warn => 0))) {
	push @out,$line;
	if (@out > 100) {
	    print STDERR "\nCrud. \@out is growing out of control:\n@out\n";
	    $t -= 20;
	    last;
	}
    }
}

###### these 5 tests were a failure point on many systems ######
# perhaps some warning message was getting into the output stream
if (@out != 4
	|| $out[-4] !~ /the message is/
	|| $out[-3] !~ /$msg/
	|| ($out[-2] !~ /$msg/ && $out[-1] !~ /$msg/)) {
    $Forks::Super::DONT_CLEANUP = 1;

    diag("\ntest join+read stdout: failure imminent.");
    diag("expected four lines but what we got is:");
    diag("--------------------------------------------");
    diag(map { "out $_: << $out[$_] >>\n" } 0 .. $#out );
    diag("--------------------------------------------");
    diag("command was: \"@cmd\"");

    my $job = Forks::Super::Job::get($pid);

    my $file = $job->{fh_config}->{f_out};
    diag("Output file was \"$file\"");
    open(my $F, "<", $file);
    diag("File contents:");
    diag(<$F>);
    close $F;
}

@out = grep { !/alarm\(\) not available/ } @out;
ok(@out == 4, scalar @out . " should be 4");            ### 7 ###
ok($out[-4] =~ /the message is/, "got Expected first line from child");
ok($out[-4] eq "$msg\n", "got Expected first line from child");
ok($out[-3] eq "$msg\n", "got Expected second line from child");
ok($out[-2] eq "received message $msg\n"
	|| $out[-1] eq "received message $msg\n", 
   "got Expected third line from child");
ok($out[-1] eq "\n" || $out[-2] eq "\n", 
   "got Expected fourth line from child");
waitall;

