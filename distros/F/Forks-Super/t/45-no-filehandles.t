use Forks::Super ':test', 'overload';
use Forks::Super::Util qw(is_socket);
use Test::More tests => 11;
use strict;
use warnings;

# test $Forks::Super::Config::CONFIG{'filehandles'} = 0 --
# forces Forks::Super to use sockets/pipes exclusively

sub _read_socket {
    my $handle = shift;

    if ($Forks::Super::Job::Ipc::USE_TIE_SH) {
	return <$handle>;
    } else {
	return Forks::Super::Job::Ipc::_read_socket($handle, undef, 0);
    }
}

sub repeater {
    Forks::Super::debug("repeater: method beginning") if $Forks::Super::DEBUG;

    my ($n, $e) = @_;
    my $end_at = time + 6;
    my ($input_found, $input) = 1;
    local $!;

    if ($Forks::Super::DEBUG) {
        Forks::Super::debug("repeater: ready to read input");
    }
    while (time < $end_at) {
	while ( do { 
	    if (Forks::Super::Util::is_socket(*STDIN)) {
		$_ = _read_socket(*STDIN);
	    } else {
		$_ = <STDIN>;
	    }
		} ) {
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
                        fileno(STDERR), "/", *STDERR->{dup_glob});
		}
	    }
	    for (my $i = 0; $i < $n; $i++) {
		print STDOUT "$i:$_";
		if ($Forks::Super::DEBUG) {
                    Forks::Super::debug(
                        "repeater: wrote [$i] \"$input\" to STDOUT/",
                        fileno(STDOUT), "/", *STDOUT->{dup_glob});
		}
	    }
	}
	if ($Forks::Super::DEBUG && $input_found) {
	    $input_found = 0;
	    Forks::Super::debug("repeater: no input");
	}
	Forks::Super::pause();
	if (!is_socket(*STDIN)) {
	    seek STDIN, 0, 1;
	}
    }
}

#######################################################

$Forks::Super::Config::CONFIG{"filehandles"} = 0;

my $pid = fork { sub => \&repeater, timeout => 12, args => [ 3, 1 ], 
		   child_fh => "all" };

ok(defined($Forks::Super::CHILD_STDIN{$pid})
   && defined(fileno($Forks::Super::CHILD_STDIN{$pid})),"found stdin fh");
ok(defined($Forks::Super::CHILD_STDOUT{$pid})
   && defined(fileno($Forks::Super::CHILD_STDOUT{$pid})),"found stdout fh");
ok(defined($Forks::Super::CHILD_STDERR{$pid})
   && defined(fileno($Forks::Super::CHILD_STDERR{$pid})),"found stderr fh");
ok(is_socket($Forks::Super::CHILD_STDIN{$pid}) &&
   is_socket($Forks::Super::CHILD_STDOUT{$pid}) &&
   is_socket($Forks::Super::CHILD_STDERR{$pid}),
   "STDxxx handles are socket handles");

my $msg = sprintf "%x", rand() * 99999999;
my $fh_in = $Forks::Super::CHILD_STDIN{$pid};
my $z = print $fh_in "$msg\n";
Forks::Super::close_fh($pid, 'stdin');
ok($z > 0, "print to child stdin successful");
my $t = time;
my $fh_out = $Forks::Super::CHILD_STDOUT{$pid};
my $fh_err = $Forks::Super::CHILD_STDERR{$pid};
my (@out,@err);
while (time < $t+15) {
    push @out, Forks::Super::read_stdout($pid);
    push @err, Forks::Super::read_stderr($pid);
    sleep 1;
}

ok(@out == 3, scalar @out . " == 3 lines from STDOUT   [ @out ]");    ### 6 ###

@err = grep { !/alarm\(\) not available/ } @err; # exclude warn to child STDERR
ok(@err == 1, scalar @err . " == 1 line from STDERR\n" . join $/,@err);

# account for possible different line endings from sockets
for (@out,@err) { s/[\r\n]+$// }

ok($out[0] eq "0:$msg", 
   "got Expected first line \"0:$msg\" from child output \"$out[0]\"");
ok($out[1] eq "1:$msg", "got Expected second line from child output");
ok($out[2] eq "2:$msg", "got Expected third line from child output");
ok($err[-1] eq "$msg", "got Expected line from child error");
waitall;
