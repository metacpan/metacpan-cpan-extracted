use Forks::Super ':test';
use Test::More tests => 3;
use strict;
use warnings;

# Test whether F::S::J::Ipc::_config_cmd_fh_child can put the
# < ipcfile  tokens in the right place on windows.

# these programs should run in both Unix [sh/csh/bash] shell
# and Windows shell
my $prog1 = "$^X -e \"print qq/Hello|world|/.<>\"";
my $prog2 = "$^X -ne \"print uc\"";

my $pid = fork 
    [ "$prog1 | $prog2" ],
    stdin => "foo\n",
    timeout => 5,
    child_fh => "all" ;

waitall;

my @out = Forks::Super::read_stdout($pid);
my @err = Forks::Super::read_stderr($pid);
ok(isValidPid($pid), "launched piped command");
ok(@out==1 && $out[0] eq "HELLO|WORLD|FOO\n", "got expected output: @out");
ok(@err==0, "got no error output @err")
    or diag("error output was: @err");
