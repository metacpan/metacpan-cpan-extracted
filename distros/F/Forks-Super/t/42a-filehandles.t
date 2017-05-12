use Forks::Super ':test';
use Test::More tests => 11;
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
my (@cmd,$pid,$fh_in,$z,$t,$fh_out,$fh_err,@out,@err,$msg);
@cmd = ($^X, "t/external-command.pl", "-s=2", "-y=2");


$pid = fork { exec => [ @cmd ], timeout => 5, child_fh => "all" };

Forks::Super::Debug::use_Carp_Always();

ok(isValidPid($pid), "$$\\fork successful");
ok(defined $Forks::Super::CHILD_STDIN{$pid}, 
   "\%CHILD_STDIN defined [exec,child_fh]");
ok(defined $Forks::Super::CHILD_STDOUT{$pid}, "\%CHILD_STDOUT defined");
ok(defined $Forks::Super::CHILD_STDERR{$pid}, "\%CHILD_STDERR defined");
$msg = sprintf "%x", rand() * 99999999;
$fh_in = $Forks::Super::CHILD_STDIN{$pid};
$z = print $fh_in "$msg\n";
Forks::Super::close_fh($pid, 'stdin');
ok($z > 0, "print to child STDIN successful [exec]");
$t = time;
$fh_out = $Forks::Super::CHILD_STDOUT{$pid};
$fh_err = $Forks::Super::CHILD_STDERR{$pid};
(@out, @err) = ();
while (time < $t+6) {
    push @out, Forks::Super::read_stdout($pid);
    push @err, Forks::Super::read_stderr($pid);
    sleep 1;
}

# this is a failure point on many systems
# perhaps some warning message is getting in the output stream?
if (@out != 3 || @err != 1) {
    $Forks::Super::DONT_CLEANUP = 1;
    print STDERR "\nbasic ipc test [exec]: failure imminent\n";
    print STDERR "We expect three lines from stdout and one from stderr\n";
    print STDERR "What we get is:\n";
    print STDERR "--------------------------- \@out ------------------\n";
    print STDERR @out,"\n";
    print STDERR "--------------------------- \@err ------------------\n";
    print STDERR @err,"\n---------------------------------------------------\n";
}

ok(@out == 3, scalar @out . " == 3 lines from STDOUT [exec]");
ok(@err == 1, scalar @err . " == 1 line from STDERR [exec]");
ok($out[0] eq "$msg\n", "got Expected first line from child [exec]")
    or diag("got $out[0], expected \"$msg\\n\"");
ok($out[1] eq "$msg\n", "got Expected second line from child [exec]")
    or diag("got $out[1] expected \"$msg\\n\"");
ok($out[2] eq "\n", "got Expected third line from child [exec]")
    or diag("got $out[2] expected \"\\n\"");
ok($err[0] =~ /received message $msg/,
   "got Expected msg on child stderr [exec]");
waitall;

