use Forks::Super ':test';
use Test::More tests => 11;
use strict;
use warnings;

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
    local $!;

    Forks::Super::debug("repeater: ready to read input")
	if $Forks::Super::DEBUG;

    while (time < $end_at) {
	while (defined ($_ = <STDIN>)) {
	    if ($Forks::Super::DEBUG) {
		$input = substr($_,0,-1);
		$input_found = 1;
		Forks::Super::debug("repeater: read \"$input\" on STDIN/",
				    fileno(STDIN));
	    }
	    if ($e) {
		print STDERR $_;
		if ($Forks::Super::DEBUG) {
		    Forks::Super::debug(
                        "repeater: wrote \"$input\" to STDERR/",
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
	seek STDIN, 0, 1;
    }
    if ($Forks::Super::DEBUG) {
	my $f_in = Forks::Super::Job->this->{fh_config}->{f_in};
	Forks::Super::debug("repeater: time expired. ",
			    "Not processing any more input");
	Forks::Super::debug("input was from file: $f_in");
	open(my $F_IN, "<", $f_in);
	while (<$F_IN>) {
	    s/\s+$//;
	    Forks::Super::debug("    input $.: $_");
	}
	close $F_IN;
    }
}

#######################################################

my $pid = fork { sub => \&repeater, timeout => 10, args => [ 3, 1 ], 
		   child_fh => "all" };

ok(isValidPid($pid), "pid $pid valid");
ok(defined $Forks::Super::CHILD_STDIN{$pid},"found stdin fh");
ok(defined $Forks::Super::CHILD_STDOUT{$pid},"found stdout fh");
ok(defined $Forks::Super::CHILD_STDERR{$pid},"found stderr fh");
my $msg = sprintf "%x", rand() * 99999999;
my $fh_in = $Forks::Super::CHILD_STDIN{$pid};
my $z = print $fh_in "$msg\n";

Forks::Super::close_fh($pid, 'stdin');

ok($z > 0, "print to child stdin successful");
my $t = time;
my $fh_out = $Forks::Super::CHILD_STDOUT{$pid};
my $fh_err = $Forks::Super::CHILD_STDERR{$pid};
my (@out,@err);
while (time < $t+10) {
    push @out, Forks::Super::read_stdout($pid);
    push @err, Forks::Super::read_stderr($pid);
    sleep 1;
}

# remaining tests are failure point in v5.6.2
ok(@out == 3, scalar @out . " == 3 lines from STDOUT   [ @out ]");

# exclude warning to child STDERR
@err = grep { !/alarm\(\) not available/ } @err;

ok(@err == 1, scalar @err . " == 1 line from STDERR\n" . join $/,@err);

ok($out[0] eq "0:$msg\n", "got Expected first line from child output");
ok($out[1] eq "1:$msg\n", "got Expected second line from child output");
ok($out[2] eq "2:$msg\n", "got Expected third line from child output");
ok($err[-1] eq "$msg\n", "got Expected line from child error");
waitall;
