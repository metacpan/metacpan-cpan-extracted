#!perl
#
# forked_harness.pl [options] tests
#
# Forks::Super proof-of-concept to run unit tests in parallel.
#
# this framework is good for
#     fast testing
#       * if you have lots of tests and your distribution is mature
#         enough that you expect the vast majority to pass
#       * if you have an intermittent failure and you might
#         need to run a test many many times to reproduce
#         a problem
#     stress testing
#       * run your tests under a heavier CPU load
#       * expose issues caused by multiple instances of
#         a test script running at once
#
# The Makefile for the Forks::Super module includes additional targets
# that use this script:
#
#     # fasttest -- run all tests once, in "parallel" (using
#     #    Forks::Super to manage and throttle the tests)
#     fasttest :: pure_all
#           $(PERLRUN) t/forked_harness.pl $(TEST_FILES) -h
#
#     # stresstest -- run all tests 100 times, in parallel
#     stresstest :: pure_all
#           $(PERLRUN) t/forked_harness.pl $(TEST_FILES) -r 20 -x 5 -s -q
#
# options and environment: see &print_usage
#

package t::forked_harness;

use lib qw(blib/lib blib/arch lib .);
use strict;
use warnings;

BEGIN {
    if ($^O eq 'MSWin32' && 'undef' eq ($ENV{IPC_DIR} || '')) {
	delete $ENV{IPC_DIR};
	push @ARGV, '-e', 'IPC_DIR=undef';
    }
}
use Forks::Super 
    MAX_PROC => 10, 
    ON_BUSY => 'queue', 
    ENABLE_DUMP => $ENV{FORKS_SUPER_ENABLE_DUMP} || 'QUIT';
use IO::Handle;
use Getopt::Long;
use POSIX ':sys_wait_h';

eval 'use Time::HiRes; 1'
    or do { *Time::HiRes::time = sub { time } };
$| = 1;

$^T = Time::HiRes::time();
BEGIN {
if (${^TAINT}) {
    if ($^O eq 'MSWin32') {
	($ENV{PATH}) = $ENV{PATH} =~ /(.*)/;
    } else {
	$ENV{PATH} = '/bin:/usr/bin:/usr/local/bin';
    }
    delete $ENV{ENV};
    use Config;
    $^X = $Config::Config{perlpath};
    ($ENV{HOME})=$ENV{HOME}=~/(.*)/;
    $ENV{PWD} = Cwd::getcwd();
    ($ENV{PWD})=$ENV{PWD}=~/(.*)/;
    $ENV{TEMP} = "C:/Temp";
    ($ENV{IPC_DIR}) = $ENV{IPC_DIR} =~ /(.*)/
	if defined $ENV{IPC_DIR};
    @ARGV = map { /(.*)/ } @ARGV;
}
}

my @use_libs = qw(blib/lib blib/arch);
my @perl_opts = ();
my @env = ();
my $maxproc = &maxproc_initial;
my $use_color = $ENV{COLOR} && -t STDOUT &&
    eval 'use Term::ANSIColor; $Term::ANSIColor::VERSION >= 3.00';
my $timeout = $ENV{TEST_TIMEOUT} || 150;
my $repeat = 1;
my $xrepeat = 1;
my $test_verbose = $ENV{TEST_VERBOSE} || 0;
my $check_endgame = $ENV{ENDGAME_CHECK} || 0;
my $quiet = 0;
my $really_quiet = 0;
my $abort_on_first_error = 0;
my $use_harness = '';
my $shuffle = '';
my $debug = $ENV{DEBUG} || '';
my $use_socket = '';
my $help = '';
my $pause = 0;
my $inorder = 0;
my $ssh_test = $ENV{TEST_SSH};
$::fail35584 = '';

# [-h] [-c] [-v] [-I lib [-I lib [...]]] [-p xxx [-p xxx [...]]] [-s]
# [-t nnn] [-r nnn] [-x nnn] [-m nnn] [-q] [-a]
# abcdefghijklmnopqrstuvwxyz
# x s @  x@   i x@xixi x i x
my $result = GetOptions(
    'h|harness'   => \$use_harness,
    'C|color'     => \$use_color,
    'verbose'     => \$test_verbose,
    'include=s'   => \@use_libs,
    'p|popts=s'   => \@perl_opts,
    'env=s'       => \@env,
    's|shuffle'   => \$shuffle,
    't|timeout=i' => \$timeout,
    'r|repeat=i'  => \$repeat,
    'xrepeat=i'   => \$xrepeat,
    'maxproc=i'   => \$maxproc,
    'q|quiet'     => \$quiet,
    'qq|really-quiet' => \$really_quiet,
    'debug'       => \$debug,
    'z|socket'    => \$use_socket,
    'abort-on-fail' => \$abort_on_first_error,
    'pause=s'     => \$pause,
    'O|order'    => \$inorder,
    'help'       => \$help,
    );

if ($help) {
    &print_usage;
    exit;
}

my %fail = ();
if ($ENV{TAINT_CHECK} || ${^TAINT}) {
    @perl_opts = map { /(.*)/ } @perl_opts;
    push @perl_opts, '-T';
}

$test_verbose ||= 0;
$repeat = 1 if $repeat < 1;
$xrepeat = 1 if $xrepeat < 1;
$quiet ||= $really_quiet;
$Forks::Super::MAX_PROC = $maxproc if $maxproc;
$Forks::Super::ON_BUSY = 'block' if $ENV{BLOCK} || $pause > 0;
sub color_print;

# these colors are appropriate when your terminal has a dark background.
# XXX-How can this program determine when your terminal
#     has a dark background?
my %colors = (ITERATION => 'bold white',
	      GOOD_STATUS => 'bold green',
	      BAD_STATUS => 'bold red',
	      'STDERR' => 'yellow bold',
	      DEBUG => 'cyan bold',
	      NORMAL => '');

if ($debug) {
    color_print('DEBUG', "MAX_PROC is $Forks::Super::MAX_PROC, ",
		"on busy is $Forks::Super::ON_BUSY\n");
}

#####################################################3
#
# determine the set of test scripts to run
#

my $glob_required = 0;
if (@ARGV == 0) {
    # read ${TEST_FILES} from %ENV
    @ARGV = split /\s+/, $ENV{TEST_FILES} || '';

    if (@ARGV == 0) {
	# read  $(TEST_FILES) from Makefile
	my $mfile;
	open($mfile, '<', 'Makefile')
	    or open($mfile, '<', '../Makefile')
	    or die 'No test files specified, ',
	    	   "can't read defaults from Makefile!\n";
	my ($test_files) = grep { /^TEST_FILES\s*=/ } <$mfile>;
	close $mfile;
	$test_files =~ s/\s+=/= /;
	my @test_files = split /\s+/, $test_files;
	shift @test_files;

	@ARGV = @test_files;
    }
    $glob_required = 1;
}

if ($^O eq 'MSWin32' || $glob_required) {
    # might need to glob the command line arg ourselves ...
    my @to_glob = grep { /[*?]/ } @ARGV;
    if (@to_glob > 0) {
	@ARGV = grep { !/[*?]/ } @ARGV;
	push @ARGV, glob($_) foreach @to_glob;
    }
}

my @test_files = (@ARGV) x $xrepeat;
my @result = ();
my $total_status = 0;
my $total_fail = 0;
my $iteration;
my $ntests = scalar @test_files;
if ($debug) {
    # running too many tests simultaneously will use up all your filehandles ...
    color_print(DEBUG => "There are $ntests tests to run (",
		scalar @ARGV, " x $xrepeat)\n");
}
my (%j,$jcount,@j);

&main;
&summarize;
&check_endgame if $check_endgame;
exit ($total_fail > 254 ? 254 : $total_fail);

# exit ($total_status > 254 << 8 ? 254 : $total_status >> 8);

##################################################################
#
# iterate over list of test files and run tests in background processes.
# when child processes are reaped, dispatch &process_test_output
# to analyze the output
#
sub main {
    if ($debug) {
	color_print(DEBUG => "Test files: @test_files\n");
    }
    if (@test_files == 0) {
	die "No tests specified.\n";
    }

    my $sshd;

    if ($ssh_test) {
        print STDERR "Trying to identify or create test ssh server ...\n";
        Forks::Super::POSTFORK_CHILD {
            *Test::SSH::Backend::OpenSSH::_run_dir = sub { };
        };

        # first, try public key authentication for the current user and host
        my $userathost = $ENV{USER} . '@' . $ENV{HOSTNAME};
        my $ssh = Forks::Super::Config::CONFIG_external_program("ssh");
        if ($ssh && $userathost =~ /.@./) {
            my @cmds = ("true", "echo", "dir");
            foreach my $cmd (@cmds) {
                local $SIG{ALRM} = sub { die "ssh timeout $$ $0 @ARGV\n"; };
                alarm 15;
                if (eval {my $c1=system($ssh, $userathost, $cmd);$c1==0}) {
                    $ENV{TEST_SSH_TARGET} = "ssh://$userathost";
                    print STDERR
                        "... publickey on current user,host works!\n";
                    last;
                }
                alarm 0;
            }
        }

        # second, let Test::SSH try to find a server or set one up
        if (!$ENV{TEST_SSH_TARGET}) {
            my $main_pid = $$;
            if (eval "use Test::SSH;1") {
                my %opts = (logger => sub {}, timeout => 600);
                $sshd = eval { Test::SSH->new(%opts) };
                if ($sshd) {
                    $ENV{TEST_SSH_TARGET} = $sshd->uri;
                    print STDERR "... Test::SSH uri: $ENV{TEST_SSH_TARGET}\n";
                }
            }
        }
    }

    for ($iteration = 1; $iteration <= $repeat; $iteration++) {
	color_print ITERATION => "Iteration #$iteration/$repeat\n" if $repeat>1;
	if ($iteration > 1) {
	    sleep 1;
	}

	if ($shuffle) {
	    for (my $j = $#test_files; $j >= 1; $j--) {
		my $k = int($j * rand());
		($test_files[$j],$test_files[$k]) =
		    ($test_files[$k],$test_files[$j]);
	    }
	}

	%j = ();
	$jcount = 0;

	foreach my $test_file (@test_files) {

	    $test_file =~ /(.*)/;
	    $test_file = $1;

	    launch_test_file($test_file);
	    Forks::Super::pause($pause) if $pause;

	    if ($debug) {
		color_print(DEBUG => 'Queue size: ',
			    scalar @Forks::Super::Deferred::QUEUE, "\n");
	    }

	    # see if any tests have finished lately
	    my $waitproc = $inorder ? $j[0] : -1;
	    my $reap = waitpid $waitproc, WNOHANG;
	    while (Forks::Super::Util::isValidPid($reap)) {
		return if process_test_output($reap) eq 'ABORT';
		$reap = -1;
		shift @j;
		$waitproc = $inorder && @j ? $j[0] : -1;
		$reap = waitpid $waitproc, WNOHANG;
	    }
	}

	# all tests have launched. Now wait for all tests to complete.

	if ($debug) {
	    color_print(DEBUG =>
			'All tests launched for this iteration, ',
			"waiting for results.\n");
	}

	if ($inorder) {
	    my $pid = waitpid $j[0], 0;
	    while (Forks::Super::Util::isValidPid($pid)) {
		shift @j;
		return if process_test_output($pid) eq 'ABORT';
		$pid = @j ? waitpid $j[0], 0 : -1;
	    }
	} else {
	    my $pid = wait;
	    while (Forks::Super::Util::isValidPid($pid)) {
		return if process_test_output($pid) eq 'ABORT';
		$pid = wait;
	    }
	}
	if ($total_status > 0) {
	    last;
	}

    }  # next iteration
    return;
}

# read the options to the perl interpreter from a shebang line
#     #! perl -w -T     ==>  (-w, -T)
sub _get_perl_opts {
    my ($file) = @_;
    open my $ph, '<', $file or return ();
    my $shebang = <$ph>;
    close $ph;
    return $shebang =~ /^#!/ ? grep { /^-/ } split /\s+/, $shebang : ();
}

sub launch_test_file {
    my ($test_file) = @_;
    my ($test_harness, @cmd);
    if (grep { /^-t$/i } @perl_opts) {
	$ENV{PATH} = '';
    }
    if ($use_harness) {
	$test_harness = "test_harness($test_verbose";
	$test_harness .= ",'$_'" foreach @use_libs;
	$test_harness .= ')';
	my @extra_opts = _get_perl_opts($test_file);
	if ($] < 5.007) {
	    @cmd = ($^X, '-Iblib/lib', '-Iblib/arch',
		    '-e', 'use Test::Harness qw(&runtests $verbose);',
		    '-e', '$verbose=0;',
		    '-e', 'runtests @ARGV',
		    $test_file);
	} else {
	    @cmd = ($^X, '-MExtUtils::Command::MM',
                    '-e', $test_harness, $test_file);
	}
    } else {
	my @extra_opts = _get_perl_opts($test_file);
	@cmd = ($^X, @perl_opts, @extra_opts,
		(map{"-I$_"}@use_libs), $test_file);
    }

    if ($debug) {
	color_print(DEBUG => "Launching test $test_file:\n");
    }
    my $child_fh = 'out,err';
    $child_fh .= ',socket' if $use_socket;
    if ($] < 5.007) {
	# workaround for Cygwin 5.6.1 where sockets/pipes
	# don't function right ...
	$child_fh = "in,$child_fh";
    }

    @cmd = map { /(.*)/ } @cmd if ${^TAINT};
    foreach my $env (@env) {
	my ($k,$v) = split /=/, $env, 2;
	$ENV{$k} = $v;
    }

    if ($debug) {
	color_print DEBUG => "Launching: [ @cmd ]\n";
    }

    my $pid = fork {
	cmd => [ @cmd ],
	child_fh => $child_fh,
	timeout => $timeout,
	env => { FORKED_HARNESS => 1 },
    };

    $j{$pid} = $test_file;
    $j{"$test_file:pid"} = $pid;
    $j{"$pid:count"} = ++$jcount;
    $j{"$test_file:iteration"} = $iteration;
    push @j,$pid;
    return;
}

sub process_test_output {
    my ($pid) = @_;

    my $j = Forks::Super::Job::get($pid);
    my $status = $j->{status};
    my $test_file = $j{$j->{pid}};
    my $test_time = sprintf '%6.3fs', $j->{end} - $j->{start};
    my @stdout = Forks::Super::read_stdout($pid);
    my @stderr = Forks::Super::read_stderr($pid);
    $j->close_fh;

    if ($debug) {
	color_print DEBUG => "Open FH: $Forks::Super::Job::Ipc::__OPEN_FH \n";
	color_print DEBUG => "Processing results of test $test_file\n";
    }

    # see which tests failed ...
    my @s = @stdout;
    my $not_ok = 0;
    foreach my $s (@s) {
	if ($s =~ /^not ok (\d+)/) {        # raw test output
	    $fail{$test_file}{$1}++;
	    $not_ok++;
	}

	# ExtUtils::MM::test_harness output
	elsif ($s =~ /Failed tests?:\s+(.+)/
	       || $s =~ /DIED. FAILED tests? (.+)/) {
	    my @failed_tests = split /\s*,\s*/, $1;
	    foreach my $failed_test (@failed_tests) {
		my ($test1,$test2) = split /-/, $failed_test;
		$test2 ||= $test1;
		$fail{$test_file}{$_}++ for $test1..$test2;
	    }
	    $not_ok++;
	}
	elsif ($s =~ /Non-zero exit status: (\d+)/) {
	    my $actual_status = $status & 0xFF00;
	    my $expected_status = $1 << 8;
	    if ($actual_status != $expected_status) {
		warn "Status $status from test $test_file does not match ",
		    "reported exit status $expected_status\n";
	    }
#	    $fail{$test_file}{"NZEC_$expected_status"}++;
	    $fail{$test_file} ||= {"NZEC_$expected_status" => 1};
	    $not_ok++;
	}
	elsif ($s =~ /Non-zero wait status: (\d+)/) {
	    my $actual_status = $status;
	    my $expected_status = $1;
	    if ($actual_status != $expected_status) {
		warn "Status $status from test $test_file does not match ",
		     "reported wait status $expected_status\n";
	    }
	    $fail{$test_file}{"NZWS_$expected_status"}++;
	    $not_ok++;
	}
	elsif ($s =~ /Result: FAIL/) {
	    # even if all tests pass, exit status is zero,
	    # test could fail if you didn't follow the plan
	    $fail{$test_file} ||= { 'BadPlan' => 1 };
	    $not_ok++;
	}
    }

    if ($use_harness && $not_ok == 0) {
	# look for one of:
	#     t/nn-xxx.t .. ok
	#     t/nn-xxx.t .. skipped: <Reason>
	my @stdout2 = grep { m/ ?\.+ ?ok/ || m/ ?\.+ ?skipped:/ } @stdout;
	if (@stdout2 > 0) {
	    @stdout = @stdout2;
	} elsif (grep { m/All tests successful./ } @stdout) {
	    @stdout = @stdout2;
	} elsif (grep { 0 && m/child process timeout/ } @stderr) {
	    $fail{$test_file}{'TIMEOUT'}++;
	    $not_ok = 1;
	    $status = 255 + 127 * 256;
	} else {
	    # the output didn't say anything about test failures and
	    # the exit code was zero, but the output also didn't say "ok" --
	    # this test is not quite right -- 
	    # the test harness could have aborted

	    $not_ok = 0.5;
	    $status = 0.5;

	    if ($j->{end} && $j->{timeout}
		&& $j->{end} - $j->{start} >= $j->{timeout} * 0.99) {
		$fail{$test_file}{'TIMEOUT'}++;
	    } else {
		$fail{$test_file}{'UnknownError'}++;
	    }

	    unless ($really_quiet) {
		color_print STDERR => "Abnormal result for $test_file: ",
		                      $j->toString(), "\n";

		sleep 3;
		push @stdout, Forks::Super::read_stdout($pid); 
		push @stderr, Forks::Super::read_stderr($pid); 

		color_print STDERR => 'OUTPUT: ', @stdout, "\n";
		color_print STDERR => 'ERROR: ', @stderr, "\n";
	    }
	}
    }




    my $redo = 0;

    if ($^O eq 'linux' && $status == 35584) {
	$redo++;
    }

    my $pp = $j->{pid};
    my $count = $j{"$pp:count"};
    my $iter = $j{"$test_file:iteration"};
    my $dashes = '-' x (40 + length($test_file));

    # print "\n$dashes\n";
    my $status_color = $status > 0 ? 'BAD_STATUS' : 'GOOD_STATUS';
    my $sep_color = $status > 0 ? 'BAD_STATUS' : 'NORMAL';
    if ($quiet == 0 || $status > 0) {
	if ($really_quiet == 0) {
	    color_print $sep_color,
	            "------------------- $test_file -------------------\n";
	}
    }
    my $aggr_status = $::fail35584
	? "$total_status+$::fail35584" : $total_status;
    my $test_id;
    if ($repeat > 1) {
	$test_id = sprintf ('%*s', 2*length("$repeat$ntests")+3,
			    "$iter.$count/$repeat.$ntests");
    } else {
	$test_id = sprintf ('%*s', 2*length($ntests)+1,
			    "$count/$ntests");
    }

    if ($use_harness && $quiet && $not_ok == 0) {
	if (1 || $really_quiet < 0) {
	    color_print $status_color, "|= test=$test_id; ",
	        "status: $status/$aggr_status ",
	        "time=$test_time ", '| ', @stdout;
	}
    } else {
	if ($status > 0 || $really_quiet == 0) {
	    color_print $status_color, "|= test=$test_id; ",
	            "status: $status/$aggr_status ","time=$test_time ",
	            "| $test_file\n";
	} else {
	    print " test=$test_id | $test_file $status             \r";
	    *STDOUT->flush;
	}
    }

    if ($status > 0 || $quiet == 0) {
	if ($really_quiet == 0) {
	    print map{"|- $_"}@stdout;
	    print "|= $dashes\n";
	    color_print STDERR => map{"|: $_"}@stderr;
	}
    }

    # there are some circumstances where the tests passed but there
    # was some intermittent error during cleanup. Detect some of these
    # and redo the test.

    if (grep { /^Failed/ && /100.00% okay/ } @stderr) {
	$redo++;
    } elsif ($use_harness && grep { /All \d+ subtests passed/ } @stdout) {
	$redo++;
    } elsif ($status == 35584 && $not_ok == 0) {
	$redo++;
    } elsif ($status != 0 && $not_ok == 0) {
	$fail{$test_file}{'unknown'} += 1;
    }
    # elsif ($quiet && $use_harness) { should summarize test results }

    if ($redo) {

	# in Forks::Super module testing, we observe an
	# intermittent segmentation fault that occurs after
	# a test has passed. It seems to occur when the
	# module and/or the perl interpreter are cleaning up,
	# and it causes the test to be marked as failed, even if
	# all of the individual tests were ok.
	# <strike>Rerun this test if we trap the condition.</strike>

	print "Received status == $status for a test of $test_file, ",
	        "possibly an intermittent segmentation fault. Rerunning ...\n";
	launch_test_file($test_file);
	$::fail35584++;
	return 'ABORT';
    }



    $total_status = $status if $total_status < $status;
    if ($status > 255) {
	$total_fail += $status >> 8;
    } elsif ($status > 0) {
	$total_fail++;
    }
    if ($status != 0) {
	if (!$use_harness
	    || (grep { /Result: FAIL/ } @stdout)
	    || (grep { /Failed Test/ } @stdout)) {
	    if ($abort_on_first_error == 0) {
		push @result, "Error in $test_file: $status / $total_status\n";
		push @result, "--------------------------------------\n";
		push @result,
		@stdout, "-----------------------------------\n",
		@stderr, "===================================\n";
	    }
	}
    }
    my $num_dequeued = 0;
    my $num_terminated = 0;
    if ($total_status > 0 && $abort_on_first_error) {
	foreach my $j (@Forks::Super::Deferred::QUEUE) {
	    $j->_mark_complete;
	    $j->{status} = -1;
	    $num_dequeued++;
	    Forks::Super::Deferred::queue_job();
	}
	foreach my $j (@Forks::Super::ALL_JOBS) {
	    next if ref $j ne 'Forks::Super::Job';
	    next if not defined $j->{status};
	    if ($j->{status} eq 'ACTIVE'
		&& Forks::Super::Util::isValidPid($j->{real_pid})) {
		$num_terminated += kill 'TERM', $j->{real_pid};
	    }
	}
	print STDERR "Removed $num_dequeued jobs from queue; ",
	    "terminated $num_terminated active jobs.\n";
	$abort_on_first_error = 2;
	return 'ABORT';
    }
    $j->dispose;
    return $total_status > 0 && $abort_on_first_error ? 'ABORT' : 'CONTINUE';
}


sub summarize {
    if (@result > 0) {
	_summarize_results();
    }
    if ($really_quiet == 0 && scalar keys %fail > 0) {
	_summarize_failures();
    }
    if ($total_status == 0) {
	_summarize_success();
    }
    my $elapsed = Time::HiRes::time() - $^T;
    printf "Elapsed time: %.3f\n", $elapsed;
    sleep 3 if $debug;
    return;
}

sub _summarize_results {
    print "\n\n\n\n\nThere were errors in iteration #$iteration:\n";
    if (1 || $ENV{EXTRA}) {
	my $hostname = qx(hostname 2>/dev/null);
	chomp($hostname);
	print "[ \$^X = $^X";
	print ", host = $hostname" if $hostname;
	print "]\n";
    }
    print "=====================================\n";
    print scalar localtime, "\n";
    print @result;
    print "=====================================\n";
    print "\n\n\n\n\n";
    return;
}

sub _summarize_failures {
    print "\nTest failures:\n";
    if (1 || $ENV{EXTRA}) {
	my $hostname = qx(hostname 2>/dev/null);
	chomp($hostname);
	print "[ \$^X = $^X";
	print ", host = $hostname" if $hostname;
	print "]\n";
    }
    print "================\n";
    foreach my $test_file (sort keys %fail) {
	no warnings 'numeric';
	foreach my $test_no (sort {
	    $a+0<=>$b+0 || $a cmp $b
			     } keys %{$fail{$test_file}}) {
	    print "\t$test_file#$test_no ";
	    if ($fail{$test_file}{$test_no} > 1) {
		print "$fail{$test_file}{$test_no} times\n";
	    } else {
                print "\n";
            }
	}
    }
    print "================\n";
    return;
}

sub _summarize_success {
    $iteration--;
    print "All tests successful. $iteration iterations.\n";
    if (1 || $ENV{EXTRA}) {
	my $hostname = qx(hostname 2>/dev/null);
	chomp($hostname);
	print "[ \$^X = $^X";
	print ", host = $hostname" if $hostname;
	print "]\n";
    }
    return;
}

#
# make sure the Forks::Super module is cleaning up after itself.
# This is mainly helpful for testing the Forks::Super module.
#
sub check_endgame {
    print "Checking endgame $Forks::Super::IPC_DIR\n";

    # fork so the main process can exit and the Forks::Super
    # module can start cleanup.

    # Forks::Super shouldn't leave temporary dirs/files around
    # after testing, but it might

    my $x = $Forks::Super::IPC_DIR;
    if (!defined $x) {
	my $p = fork { child_fh => 'out', sub => {} };
	waitpid $p, 0;
	$x = $Forks::Super::IPC_DIR;
    }

    CORE::fork() && return;

    sleep 12;

    my @fhforks = ();
    opendir(D, $x);
    while (my $g = readdir(D)) {
	if ($g =~ /^.fh/) {
	    opendir(E, "$x/$g");
	    my $gg = readdir(E);
	    closedir E;
	    $gg -= 2;
	    print STDERR "Directory $x/$g still exists with $gg files\n";
	}
    }
    closedir D;

    $0 = '-';

    # to do: check the process table and see if any languishing
    #    processes came from here ...

    return;
}

#
# find good initial setting for $Forks::Super::MAX_PROC.
# This can be overridden with -m|--maxproc command-line arg
#
sub maxproc_initial {
    if ($ENV{MAX_PROC}) {
	return $ENV{MAX_PROC};
    }
    eval {
	require Sys::CpuAffinity; 1
    } or do {
	return 2;
    };
    my $n = Sys::CpuAffinity::getNumCpus();
    if ($n <= 0) {
	return 2;
    }
    my @mask = Sys::CpuAffinity::getAffinity($$);
    if (@mask < $n) {
	$n = @mask || $n;
    }
    return $n < 8 ? int(2 * $n + 1) : 16;
}

# if appropriate and supported, enhance output to STDOUT with color.
sub color_print {
    my ($color, @msg) = @_;
    if ($color eq '' || !$use_color) {
	return print STDOUT @msg;
    }
    $color = $colors{$color} if defined $colors{$color};
    if (@msg > 0 && chomp($msg[-1])) {
	return print STDOUT colored([$color], @msg), "\n";
    }
    return print STDOUT colored([$color], @msg);
}
sub color_printf { return color_print shift, sprintf @_ }

sub print_usage {

    print STDERR <<"__END_USAGE__";

perl forked_harness.pl [options] [tests]

Run test suite in parallel using Forks::Super. If  tests  are not
specified, defaults to value of  TEST_FILES  in ./Makefile or ../Makefile

Recognized options:

    -h,--harness         wrap tests in ExtUtils::Command::MM::test_harness
    -v,--verbose         with -h, use verbose test harness
    -I,--include lib     use Perl lib dirs [default: blib/lib, blib/arch]
    -p,--popts option    pass option to perl interpreter during test
                       [e.g., -p -d:Trace, -p -MCarp::Always]
    -s,--shuffle         run tests in random order
    -t,--timeout n       abort test after <n> seconds [default: 150]
    -r,--repeat n        do up to <n> iterations of testing, aborting if
                       an iteration had test failures
    -x,--xrepeat n       run each test <n> times within each test iteration
    -m,--maxproc n       run up to <n> tests simultaneously
    -q,--quiet           produce less output (-q is *not* the opposite of -v!)
    --qq,--really-quiet  show test status, no other output
    -d,--debug           produce output about what forked_harness.pl is doing
    -a,--abort-on-fail   stop immediately after any test failure
    -C,--color           colorize output (requires Term::ANSIColor >= 3.00)
    -E,--env var=value   pass environment variable to the tests
    -O,--order           return test results in order

ENVIRONMENT

    COLOR               if true, try to colorize output [like -C flag]
    ENDGAME_CHECK       if true, check that program cleans up after itself
    MAX_PROC            number of simultaneous tests [like -m flag]
    TEST_VERBOSE        if true, use verbose test harness [like -v flag]

__END_USAGE__
    ;
    return;
}

=head1 NAME

forked_harness.pl - run tests in parallel with Forks::Super

=head1 VERSION

0.89

=head1 SYNOPSIS

    $ perl t/forked_harness.pl [options] [test-files]
    |= test= 1/86; status: 0/0 time= 2.988s | t/00-use.t .. ok
    ...
    |= test=86/86; status: 0/0 time=11.441s | t/43c-foo.t .. ok
    All tests successful. 1 iterations.
    Elapsed time: 73.919

=head1 DESCRIPTION

The C<forked_harness.pl> script runs a suite of unit tests in parallel
using the L<Forks::Super> framework. It can be used in any context
where you might run the command C<make test>. Aside from being able
to finish running your test suite faster, this paradigm has many
additional uses:

=head2 Intermittent failures

If you have one or more unit tests that only fail intermittently,
C<forked_harness.pl> can help you to run the test multiple times,
isolating the test output of the failed tests.

    # run intermittent.t 200 times, only output on failure
    $ forked_harness.pl -x 200 -q t/intermittent.t

=head2 Stress testing

As C<forked_harness.pl> will make use of more CPU while running
your tests, it can expose problems with your tests or your code
that only occur under high CPU loads.

=head2 Synchronization issues

C<forked_harness.pl> can expose issues caused by running multiple
instances of a test. For example, if your module or some of your
test scripts need to write to a file with a hard-coded
filename, multiple instances of the test might interfere
with each other and cause the test to fail.

=head1 TEST FILES

There are several ways to specify which tests to run. 

=head2 Command-line

The tests to run may be specified on the command-line.

    $ forked_harness.pl t/00-load.t t/43-foo.t
    $ forked_harness.pl t/*server*.t

Arguments with filesystem wildcard characters will be expanded to
include all filenames that match the pattern, even on Windows.

=head2 $ENV{TEST_FILES}

If test files are not specified on the command-line and the environment
variable C<TEST_FILES> is set, C<forked_harness.pl> will use that
variable as the list of tests to run.

    $ TEST_FILES=t-special/*.t forked_harness.pl

=head2 Makefile

If test files are not specified on the command-line or in the 
C<$ENV{TEST_FILES}> variable, C<forked_harness.pl> will look for a
file called C<Makefile> in the current directory and in the parent
directory. If such a file is found, it is scanned for a line matching

    TEST_FILES\s*=\s*(.*)

and extracts the set of test files from that line.

If all of these methods to identify a set of test files fails,
C<forked_harness.pl> will fail with the message:

    No test files specified, can't read defaults from Makefile!

=head1 OPTIONS

C<forked_harness.pl> recognizes several command-line options to
fine tune its behavior. Any of these options may be used in
combination, except as noted.

=head2 -a, --abort-on-fail

When this option is used and a test fails, no further tests are
performed and a quit signal is sent to any currently running tests.

=head2 -c, --color

When this option is used, and a L<Term::ANSIColor> module
with at least version 3.00 can be located, the output of
C<forked_harness.pl> will be colorized. If a recent version
of L<Term::ANSIColor> can not be found, this option has no
effect.

=head2 -d, --debug

When this option is used, C<forked_harness.pl> reports
what it is doing.

=head2 -e I<var=value>, --env I<var=value>

Each test script will inherit its environment from C<forked_harness.pl>,
which inherits its environment from the shell. You can pass
additional environment variable settings to each test by specifying
the C<-e> option with key-value pairs one or more times.

     # set $ENV{FOO}=BAR in each test
     forked_harness.pl -e FOO=BAR ...

     # unset $ENV{FOO} in each test
     forked_harness.pl -e FOO= ...

=head2 -h, --harness

When this option is used, each test is run inside the
L<ExtUtils::Command::MM/"test_harness"> function 
(the L<Test::Harness/"runtests"> function on older perls)
rather than run directly from a subshell of the C<forked_harness.pl>
script.

Running a test like this can have subtle effects on the test
environment such as running the test program in a new session
or under a different process group, which may or may not be
important to the test.

=head2 --help

Outputs a list of command-line options with brief descriptions 
of what they do. Does not run any tests.

=head2 -i I<directory>, --include I<directory>

Includes the specified directory in the test script's C<@INC>
path. May be included several times in order to specify
several directories:

    $ forked_harness.pl -i blib/foo -i blib/lib

If no C<-i> options are specified, the directories
C<./blib/lib> and C<./blib/arch> are included by default.

=head2 -m I<numproc>, --maxproc I<numproc>

Runs up to I<numproc> tests simultaneously. The default number
of tests to run simultaneously is C<2 * nc + 1>, where C<nc> is
the number of logical CPU cores on your system.

You may consider using a smaller value if you have very CPU-intensive
tests, or a larger value if your tests are not very intense (I don't
know, maybe they spend most of their times in C<sleep> statements).

You can also specify the number of tests to run simultaneously
by setting the C<MAX_PROC> environment variable before running
C<forked_harness.pl>:

     $ MAX_PROC=15 forked_harness.pl [other-options] [test-files]

=head2 -p I<option>, --popts I<option>

Passes the specified option as a command-line option to the
perl process running each test. Here are some examples of how
this option might be useful:

=head3 Apply L<Carp::Always> to get stack traces of any warnings in tests

    $ forked_harness.pl -p -MCarp::Always [test-files]

=head3 Run all tests in taint mode

    $ forked_harness.pl -p -t [test-files]

    $ forked_harness.pl -p -T [test-files]

=head3 Run each test through a C<Devel::> module

    $ forked_harness.pl -p -d:Trace::Fork [test-files]

The C<-p> option may be specified as many times as desired
to pass more than one option to the perl program running
the test.

=head2 -q, --quiet

Run in "quiet" mode. Suppresses output of successful tests
except for a single summary line (see L<"OUTPUT">).
This option hides the additional output
produced when the C<-v> (C<--verbose>) option is used.

=head2 -qq, --really-quiet

Run in a very quiet mode. Suppresses all output of successful tests,
and suppresses output of failed tests until all tests
are completed. This option hides the additional output
produced when the C<-v> (C<--verbose>) option is used.

=head2 -r I<times>, --repeat I<times>

Runs I<times> iterations of the tests, aborting if there are test
failures in any iteration. See also the C<-x> option. The default
is to run one iteration of the tests.

=head2 -s, --shuffle

If this option is included, the tests will be run in a random order.

=head2 -t I<timeout>, --timeout I<timeout>

Sets a timeout of I<timeout> seconds on each test. If possible, 
tests will be terminated (and marked as failures) if they are
still running when the timeout expires.

The default timeout is 150 seconds. Specify a timeout of 0
(C<-t 0>, C<--timeout 0>) to disable the timeout and give each
test as long as it needs to complete.

The default timeout can also be overridden by setting the 
C<TEST_TIMEOUT> environment variable.

=head2 -v, --verbose

When used with the C<-h> (harness) options, runs each test 
in verbose mode, as if you had run the test suite with the command

    make test TEST_VERBOSE=1

The results of each individual test and anything else a test
script writes to C<STDOUT> will be output with this option.

=head2 -x I<times>, --xrepeat I<times>

I<Within each iteration> (see the C<-r> option), runs each test
I<times> times. The default is to run each test one time in each 
iteration.

=head2 -z, --socket

Instructs C<forked_harness.pl> and L<Forks::Super> to use socket
based interprocess communication where possible, instead of
file based IPC. File IPC should be more flexible and
robust than socket IPC, so this option probably won't get you
anything unless you are really really really low on disk space,
or if you don't have write permission in the filesystem where
you run your tests.

=head1 OTHER ENVIRONMENT AND CONFIGURATION

=over 4

=item C<COLOR=>I<some true value> 

has the same effect as using the
C<-c> (C<--color>) flag.

=item C<MAX_PROC=>I<numprocs> 

has the same effect as using the
C<-m> I<numprocs> (C<--maxproc>) option

=item C<TEST_VERBOSE=>I<some true value> 

has the same effect as using
the C<-v> (C<--verbose>) flag.

=back

=head1 PROGRAM OUTPUT

At a minimum, C<forked_harness.pl> produces a status line
for each test that it runs:

    |= test= 49/113; status: 1024/768 time=44.643s | t/41j-filehandles.t
              A  B             C   D         E            F

=over 4

=item C<A> - the current test number

The test results are reported when a test finishes. The reports may
be out of order. If there is more than one iteration of testing planned
(see the C<-r> option), this also reports the current iteration.

=item C<B> - total number of tests

Total number of tests in this iteration. If there are multiple iterations
(see the C<-r> option), then this also reports the number of iterations
planned.

=item C<C> - status of this test

Exit status of the test script. Anything other than a zero
indicates a test failure. Normally this value is 256 times the
number of failed tests, but it could have a different value to indicate
that the test terminated abnormally.

=item C<D> - previous status

The highest exit code from any previous test.

=item C<E> - test time

Running time of the test, with millisecond resolution. When you get
in the habit of running your unit tests in parallel, the longest 
running tests in your suite can be a bottleneck in your overall test time,
and you may want to look for ways to break it into several smaller
tests.

=item C<F> - test name

The test file that this line is reporting on.

=back

Depending on which settings you are using,
output from the test may follow the test's status line.
Standard output and standard error will be separated,
and all output from the test will appear at once.

=head1 EXIT STATUS

The exit status of C<forked_harness.pl> will be the approximate
number of test failures encountered. If there were more than
254 failures, however, the exit code will be C<254>. 

This is the same behavior as L<ExtUtils::Command::MM> C<test_harness>
function.

=head1 SEE ALSO

C<forked_harness.pl> was originally developed as a proof-of-concent
for the L<Forks::Super> distribution, and there are two targets in
the C<Makefile> of L<Forks::Super> that use C<forked_harness.pl>:

    # ------ fasttest: use Forks::Super to run Forks::Super tests in parallel
    fasttest :: pure_all
	$(FULLPERL) t/forked_harness.pl $(TEST_FILES) -h -q

    # ------ stress test: run all tests in parallel 100 times
    stresstest :: pure_all
	$(FULLPERL) t/forked_harness.pl $(TEST_FILES) -r 20 -x 5 -s -q


=head1 AUTHOR

Marty O'Brien, E<lt>mob@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2017, Marty O'Brien.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

See http://dev.perl.org/licenses/ for more information.

=cut
