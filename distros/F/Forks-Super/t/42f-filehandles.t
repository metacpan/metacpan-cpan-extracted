use Forks::Super qw(:test overload);
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

ok(isValidPid($pid), "$$\\fork successful");
ok(defined $pid->{child_stdin}, "\%CHILD_STDIN defined [exec,child_fh]");
ok(defined $pid->{child_stdout}, "\%CHILD_STDOUT defined");
ok(defined $pid->{child_stderr}, "\%CHILD_STDERR defined");
$msg = sprintf "%x", rand() * 99999999;
$z = $pid->write_stdin("$msg\n");
$pid->close_fh('stdin');
ok($z > 0, "print to child STDIN successful [exec]");
$t = time;
(@out, @err) = ();
while (time < $t+6) {
    push @out, $pid->read_stdout();
    push @err, $pid->read_stderr();
    sleep 1;
}

if (@out != 3 || @err != 1) {
    $Forks::Super::DONT_CLEANUP = 1;
    print STDERR "\nbasic ipc test [exec]: failure imminent\n";
    print STDERR "We expect three lines from stdout and one from stderr\n";
    print STDERR "What we get is:\n";
    print STDERR "--------------------------- \@out ------------------\n";
    print STDERR @out,"\n";
    print STDERR "--------------------------- \@err ------------------\n";
    print STDERR @err,"\n--------------------------------------------------\n";
}

ok(@out == 3, scalar @out . " == 3 lines from STDOUT [exec]");
ok(@err == 1, scalar @err . " == 1 line from STDERR [exec]");
ok($out[0] eq "$msg\n", "got Expected first line from child [exec]");
ok($out[1] eq "$msg\n", "got Expected second line from child [exec]");
ok($out[2] eq "\n", "got Expected third line from child [exec]");
ok($err[0] =~ /received message $msg/, 
   "got Expected msg on child stderr [exec]");

waitall;

