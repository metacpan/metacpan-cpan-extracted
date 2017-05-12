use Forks::Super ':test';
use Forks::Super::Util qw(is_pipe IS_WIN32);
use Test::More tests => 11;
use strict;
use warnings;


sub _read_pipe_that_might_be_a_socket {
    # on MSWin32, we almost never use pipes
    my $handle = shift;
    return $Forks::Super::Job::Ipc::USE_TIE_SH
		|| !Forks::Super::Util::is_socket($handle)
        ? <$handle>
	: Forks::Super::Job::Ipc::_read_socket($handle, undef, 0);
}

#
# test whether a parent process can have access to the
# STDIN, STDOUT, and STDERR filehandles of a child
# process. This features allows for communication
# between parent and child processes.
#

# this is a subroutine that copies STDIN to STDOUT and optionally STDERR
sub repeater {
    Forks::Super::debug("repeater: method beginning") if $Forks::Super::DEBUG;

    my ($n, $e) = @_;
    my $end_at = time + 6;
    my ($input_found, $input) = 1;
    my $curpos;
    local $!;

    binmode STDOUT;  # for Windows compatibility
    binmode STDERR;  # has no bad effect on other OS

    if ($Forks::Super::DEBUG) {
        Forks::Super::debug("repeater: ready to read input");
    }
    while (time < $end_at) {

	# not using pipes on MSWin32 -- using sockets instead
	while (defined ($_ = _read_pipe_that_might_be_a_socket(*STDIN))) {

	    if ($Forks::Super::DEBUG) {
		$input = substr($_,0,-1);
		$input_found = 1;
		Forks::Super::debug("repeater: read \"$input\" on STDIN/",
				    fileno(*STDIN));
	    }
	    if ($e) {
		print STDERR $_;
		if ($Forks::Super::DEBUG) {
		    Forks::Super::debug(
                        "repeater: wrote \"$input\" to STDERR/",
                        fileno(*STDERR));
		}
	    }
	    for (my $i = 0; $i < $n; $i++) {
		print STDOUT "$i:$_";

		# how does MSWin32 hang right here ???

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

# test join, read_stdout

my $pid = fork { sub => \&repeater , args => [ 2, 1 ] , timeout => 12,
		child_fh => [ "in", "out", "join", "pipe" ] };
ok(isValidPid($pid), "started job with join");

my $msg = sprintf "the message is %x", rand() * 99999999;
my $z = print {$Forks::Super::CHILD_STDIN{$pid}} "$msg\n";
ok($z > 0, "successful print to child STDIN");
SKIP: {
    if (&IS_WIN32 && !$ENV{WIN32_PIPE_OK}) {
	skip "using sockets instead of pipes on Win32", 3;
    }
    ok(defined($Forks::Super::CHILD_STDIN{$pid})
       && (is_pipe($Forks::Super::CHILD_STDIN{$pid})), 
       "CHILD_STDIN is a pipe");
    ok(defined($Forks::Super::CHILD_STDOUT{$pid})
       && (is_pipe($Forks::Super::CHILD_STDOUT{$pid})), 
       "CHILD_STDOUT is a pipe");
    ok(defined($Forks::Super::CHILD_STDERR{$pid})
       && (is_pipe($Forks::Super::CHILD_STDERR{$pid})), 
       "CHILD_STDERR is a pipe");
}
ok($Forks::Super::CHILD_STDOUT{$pid} eq $Forks::Super::CHILD_STDERR{$pid}, 
   "child stdout and stderr go to same fh");
my $t = time;
my @out = ();
while (time < $t+9) {
    while (my $line = Forks::Super::read_stdout($pid)) {
	push @out, $line;
    }
}

Forks::Super::close_fh($pid);

# perhaps some warning message was getting into the output stream
if (@out != 3) {
    print STDERR "\ntest join+read stdout: failure imminent.\n";
    print STDERR "Expecting three lines but what we get is:\n";
    my $i;
    print STDERR map { ("Output line ", ++$i , ": $_") } @out;
    print STDERR "\n";
}

@out = grep { !/alarm\(\) not available/ } @out;
ok(@out == 3, "read ".(scalar @out)
	." [3] lines from child STDOUT:   @out"); # 18 #
ok($out[-3] =~ /the message is/, "first line matches Expected pattern");
ok($out[-3] eq "$msg\n", "first line matches Expected pattern");
ok($out[-2] eq "0:$msg\n", "second line matches Expected pattern");
ok($out[-1] eq "1:$msg\n", "third line matches Expected pattern");
waitall;

