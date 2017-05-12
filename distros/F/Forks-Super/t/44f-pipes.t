use Forks::Super qw(:test overload);
use Forks::Super::Util qw(is_pipe IS_WIN32);
use Test::More tests => 12;
use strict;
use warnings;
$| = 1;

#
# test whether a parent process can have access to the
# STDIN, STDOUT, and STDERR filehandles of a child
# process. This features allows for communication
# between parent and child processes.
#

sub _read_pipe_that_might_be_a_socket {
    # on MSWin32, we almost never use pipes
    my $handle = shift;
    return $Forks::Super::Job::Ipc::USE_TIE_SH
		 || !Forks::Super::Util::is_socket($handle)
        ? <$handle>
	: Forks::Super::Job::Ipc::_read_socket($handle, undef, 0);
}

# this is a subroutine that copies STDIN to STDOUT and optionally STDERR
sub repeater {
    my ($n, $e) = @_;

    Forks::Super::debug("repeater: method beginning") if $Forks::Super::DEBUG;
    my $end_at = time + 6;
    my ($input_found, $input) = 1;
    my $curpos;
    local $!;

    binmode STDOUT;  # for Windows compatibility
    binmode STDERR;  # has no bad effect on other OS
    Forks::Super::debug("repeater: ready to read input")
	if $Forks::Super::DEBUG;
    while (time < $end_at) {
	while ($_ = _read_pipe_that_might_be_a_socket(*STDIN)) {

	    if ($Forks::Super::DEBUG) {
		$input = substr($_,0,-1);
		$input_found = 1;
		Forks::Super::debug("repeater: read \"$input\" on STDIN/",
				    fileno(*STDIN));
	    }
	    if ($e) {
		print STDERR $_;
		if ($Forks::Super::DEBUG) {
		    Forks::Super::debug("repeater: wrote \"$input\" to STDERR/",
					fileno(*STDERR));
		}
	    }
	    for (my $i = 0; $i < $n; $i++) {
		print STDOUT "$i:$_";
		if ($Forks::Super::DEBUG) {
                    Forks::Super::debug(
                        "repeater: wrote [$i] '$input' to STDOUT/",
                        fileno(*STDOUT));
		}
	    }
	}
	if ($Forks::Super::DEBUG && $input_found) {
	    $input_found = 0;
	    Forks::Super::debug("repeater: no input");
	}
	Forks::Super::pause();
    }
}

#######################################################

my $pid = fork { sub => \&repeater, timeout => 10, args => [ 3, 1 ], 
		 child_fh => "in,out,err,pipe" };

ok(isValidPid($pid), "pid $pid valid");
ok(defined($pid->{child_stdin}) 
   && defined(fileno($pid->{child_stdin})),
   "found stdin fh");
ok(defined($pid->{child_stdout})
   && defined(fileno($pid->{child_stdout})),
   "found stdout fh");
ok(defined($pid->{child_stderr}) 
   && defined(fileno($pid->{child_stderr})),
   "found stderr fh");
SKIP: {
    if (&IS_WIN32 && !$ENV{WIN32_PIPE_OK}) {
	skip "using sockets instead of pipes on Win32", 1;
    }
    ok(is_pipe($pid->{child_stdin}) &&
       is_pipe($pid->{child_stdout}) &&
       is_pipe($pid->{child_stderr}),
       "STDxxx handles are pipes");
}
my $msg = sprintf "%x", rand() * 99999999;
#my $fh_in = $Forks::Super::CHILD_STDIN{$pid};
#my $z = print $fh_in "$msg\n";
my $z = $pid->write_stdin("$msg\n");
ok($z > 0, "print to child stdin successful");
my $t = time;
#my $fh_out = $Forks::Super::CHILD_STDOUT{$pid};
#my $fh_err = $Forks::Super::CHILD_STDERR{$pid};
my (@out,@err);
while (time < $t+8) {
    push @out, $pid->read_stdout; # Forks::Super::read_stdout($pid);
    push @err, $pid->read_stderr; # Forks::Super::read_stderr($pid);
    sleep 1;
}
Forks::Super::close_fh($pid);

ok(@out == 3, scalar @out . " == 3 lines from STDOUT   [\n @out ]");

# exclude warning to child STDERR
@err = grep { !/alarm\(\) not available/ } @err;

ok(@err == 1,                                                   ### 8 ###
   scalar @err . " == 1 line from STDERR\n----\n" . join $/,@err,"---");

ok($out[0] eq "0:$msg\n", "got Expected first line from child output");
ok($out[1] eq "1:$msg\n", "got Expected second line from child output");
ok($out[2] eq "2:$msg\n", "got Expected third line from child output");
ok($err[0] eq "$msg\n" || $err[-1] eq "$msg\n",                 ### 12 ###
   "got Expected line from child error @err");

my $r = waitall 10;
