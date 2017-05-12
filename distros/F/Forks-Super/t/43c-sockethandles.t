use Forks::Super ':test';
use Test::More tests => 9;
use strict;
use warnings;

sub _read_socket {
    my $handle = shift;
    return $Forks::Super::Job::Ipc::USE_TIE_SH
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
    Forks::Super::debug("repeater: ready to read input") 
	if $Forks::Super::DEBUG;
    while (time < $end_at) {
	while (defined ($_ = _read_socket(*STDIN))) {
	    if ($Forks::Super::DEBUG) {
		$input = substr($_,0,-1);
		$input_found = 1;
		Forks::Super::debug("repeater: read \"$input\" on STDIN/",
				    fileno(STDIN));
	    }
	    if ($e) {
		print STDERR $_;
		if ($Forks::Super::DEBUG) {
		    Forks::Super::debug("repeater: wrote \"$input\" to STDERR/",
					fileno(STDERR));
		}
	    }
	    for (my $i = 0; $i < $n; $i++) {
		print STDOUT "$i:$_";
		if ($Forks::Super::DEBUG) {
		    Forks::Super::debug(
			"repeater: wrote [$i] \"$input\" to STDOUT/",
			fileno(STDOUT));
		}
	    }
	}
	if ($Forks::Super::DEBUG && $input_found) {
	    $input_found = 0;
	    Forks::Super::debug("repeater: no input");
	}
	Forks::Super::pause();
    }
    if (0 && $Forks::Super::DEBUG) { # f_in can't be read in socket context
	my $f_in = Forks::Super::Job->this->{fh_config}->{f_in};
	Forks::Super::debug("repeater: time expired. ",
			    "Not processing any more input");
	Forks::Super::debug("input was from file: $f_in");
	open(my $F_IN, '<', $f_in);
	while (<$F_IN>) {
	    s/\s+$//;
	    Forks::Super::debug("    input $.: $_");
	}
	close $F_IN;
    }
}

#######################################################

# test read_stderr -- this is the last significant failure point from 0.08
# the usual error is that @err contains one line instead of two
# let's retest with debugging if we detect that this test is going to fail ...

my $read_stderr_calls = 0;
sub read_stderr_test {

    my $pid = fork { sub => \&repeater , args => [ 3, 1 ] , timeout => 10,
		     child_fh => "in,err,socket" };

    my $z = 0;
    $read_stderr_calls++;
    if ($read_stderr_calls == 1) {
	ok(isValidPid($pid), "started job with stdin,stderr");
    }

    my $msg = sprintf "the message is %x", rand() * 99999999;
    my $pid_stdin_fh = $Forks::Super::CHILD_STDIN{$pid};

    $z = print $pid_stdin_fh "$msg\n";

    if ($Forks::Super::DEBUG) {
	Forks::Super::debug("Printed \"$msg\\n\" to child stdin ($pid). ",
			    "Result:$z");
    }
    sleep 1;
    $z *= print $pid_stdin_fh "That was a test\n";
    if ($read_stderr_calls == 1) {
	ok($z > 0, "successful print to STDIN");
	ok(defined $Forks::Super::CHILD_STDIN{$pid},
	   "CHILD_STDIN value defined");
	ok(!defined $Forks::Super::CHILD_STDOUT{$pid}, 
	   "CHILD_STDOUT value not defined pid $pid");
	ok(defined $Forks::Super::CHILD_STDERR{$pid},           ### 5 ###
	   "CHILD_STDERR value defined");
    }

    if ($Forks::Super::DEBUG) {
	Forks::Super::debug("Printed \"That was a test\\n\" ",
			    "to child stdin ($pid). Result:$z");
    }

    Forks::Super::close_fh($pid, 'stdin');

    if ($Forks::Super::DEBUG) {
	Forks::Super::debug("Closed filehandle to $pid STDIN");
    }
    return ($z,$pid);
}

my ($z,$pid) = &read_stderr_test;

my $t = time;
my @out = ();
my @err = ();
while (time < $t+12) {
    my @data = Forks::Super::read_stdout($pid);
    push @out, @data if @data>0 and $data[0] ne "";

    @data = Forks::Super::read_stderr($pid);
    push @err, @data if @data>0 and $data[0] ne "";
}
ok(@out == 0, "received no output from child");
@err = grep { !/alarm\(\) not available/ } @err;

if (@err != 2) {
    print STDERR "\ntest read stderr: failure imminent.\n";
    print STDERR "Expecting two lines but what we get is:\n";
    my $i;
    print STDERR map { ("Error line ", ++$i , ": $_") } @err;
    print STDERR "\n";
    print STDERR "Rerunning read_stderr test with debugging on ...\n";

    # retest with debugging -- let's see if we can figure out what's going on
    $Forks::Super::DEBUG = 1;
    ($z,$pid) = &read_stderr_test;
    $t = time;
    $i = 0;
    @err = ();
    while (time < $t+12) {
	my @data = Forks::Super::read_stderr($pid);
	push @err, @data if @data>0 and $data[0] ne "";
    }
    print STDERR "Standard error from retest:\n";
    print STDERR map { ("Error line ", ++$i, ": $_") } @err;
    @err = grep { !/repeater:/ && !/alarm/ } @err;
}

ok(@err == 2, "received 2 lines from child stderr");
ok($err[0] =~ /the message is/, "got Expected first line from child error");
ok($err[-1] =~ /a test/, "got Expected second line from child error");
waitall; 
$Forks::Super::DEBUG = 0;
