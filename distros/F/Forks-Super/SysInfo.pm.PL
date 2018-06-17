# SysInfo.pm.PL
# Create the lib/Forks/Super/SysInfo.pm file
# with information about the current system
# and some of its capabilities.
# See also: system-limits.PL

use lib qw(lib);
use strict;
use warnings;
our $VERSION = '0.94';

my $limits_file = "t/out/limits.$^O.$]";
my $limits_file2 = "t/out/limits.$^O";
print STDERR "Creating  Forks/Super/SysInfo.pm  file\n";


if ($ENV{SYSTEM_LIMITS} || ! -r $limits_file) {
    print STDERR "$0: creating system-limits file.\n";
    my $slpid = fork();
    if ($slpid == 0) {
        my $wpid = launch_system_limits("$limits_file.tmp", $limits_file2);
        sleep(1) while killzero($wpid);
        exit;
    }
    wait;
    print STDERR "system-limits.PL complete\n";
    rename "$limits_file.tmp", $limits_file;
}

my %info = load_limits_file($limits_file);

open F, '>', $ARGV[0] || 'lib/Forks/Super/SysInfo.pm';
print F <<"____;";

package Forks::Super::SysInfo;
use strict;
use warnings;

# This package contains some estimates about your
# system's capabilities that were discovered during
# the build/installation process of  Forks::Super .

# This information may not be accurate and is not
# intended for any other purpose.

## no critic (ProhibitMagicNumbers)

our \$VERSION = '$VERSION';

____;



printF('SYSTEM', "'$info{system}'", "'unknown'");
printF('PERL_VERSION', "'$info{version}'", "'unknown'");
printF('MAX_FORK', $info{maxfork}, '12.345');
printF('MAX_OPEN_FH', $info{maxfilehandle}, '123.456');
printF('TOO_MANY_FH_ERRNO', $info{maxfilehandle_errno}, '23.0');
printF('FILE_NOT_FOUND_ERRNO', $info{fnf_errno}, '2.0');
printF('SOCKET_CAPACITY', $info{socket_capacity}, '128.0');
printF('PIPE_CAPACITY', $info{pipe_capacity}, '128.0');
printF('SLEEP_ALARM_COMPATIBLE', &sleep_alarm_compat, '""');

# alternate alarm might help with timeout crashes on freebsd
print F <<"____";


# The "poor man's alarm" may be helpful on systems that cannot
# reliably send SIGALRM to a grandchild process. If you get test
# failures on t/40a, t/40d, t/40g, or t/65e, your system may
# benefit from setting \$PREFER_ALTERNATE_ALARM to a true value.
# It is set by default for freebsd since v0.79 
# and for darwin since v0.88.
____


printF('PREFER_ALTERNATE_ALARM', $info{prefer_alt_alarm}, '0');
printF("PROC_PROCESSTABLE_OK", $info{proc_processtable_ok}, "0");

printF('TIME_HIRES_TOL', $info{TimeHiRes_tol}, '0.00');

printF('ACTIVE_WAITPID_RESULT', $info{active_waitpid_result}, '0');
printF('ACTIVE_WAITPID_STATUS', $info{active_waitpid_status}, '-1');
printF('BOGUS_WAITPID_RESULT', $info{bogus_waitpid_result}, '-1');
printF('BOGUS_WAITPID_STATUS', $info{bogus_waitpid_status}, '-1');
printF('REAPED_WAITPID_RESULT', $info{reaped_waitpid_result}, '-1');
printF('REAPED_WAITPID_STATUS', $info{reaped_waitpid_status}, '-1');
printF('IGNORE_WAITPID_RESULT', $info{ignore_waitpid_result}, '-1');
printF('IGNORE_WAITPID_STATUS', $info{ignore_waitpid_status}, '-1');

if (defined $info{ncpu}) {
    printF('NUM_PROCESSORS', $info{ncpu}, '1');
}

my $sync = $info{sync_options};
$sync =~ s{/}{ }g;
print F "\n";
print F "our \@SYNC_IMPLS = qw($sync);\n";

if (length($info{test_ssh_target})) {
    print F "\n";
    print F "# indicates if we can safely run remote tests (t/49*.t)\n";
    print F "our \$TEST_SSH_TEMPLATE = q~$info{test_ssh_target}~;\n";
}


# See what core and core module functionality is available
# on this system.
my %config = ( alarm => eval { alarm 0;1 } || 0,

	       getpgrp => eval { my $z=getpgrp(0);1 } || 0,

	       getpriority => eval { my $z=getpriority(0,0);1 } || 0,

	       SIGUSR1 => exists($SIG{USR1}) || 0,

	       select4 => eval { select undef,undef,undef,0.05;1 } || 0,

	       pipe => eval {
		 my ($read,$write);
		 pipe $read, $write;
		 close $read;
		 close $write;
		 1 } || 0,

	       socketpair => eval {
		 use Socket;
		 my ($read,$write);
		 socketpair $read,$write,AF_UNIX,SOCK_STREAM,PF_UNSPEC;
		 close $read;
		 close $write;
		 1 } || 0,

	       setitimer => eval {
		 require Time::HiRes;
		 Time::HiRes::setitimer(Time::HiRes::ITIMER_REAL(), 0);
		 1 } || 0
);

print F "\nour \%CONFIG = (\n";
foreach my $key (sort keys %config) {
    printf F "    %-14s => %d,\n", "'$key'", $config{$key};
}
print F ");\n\n";

print F "\n\n1;\n";
close F;
if ($^O eq 'MSWin32') {
    unlink 'pid';
}


sub printF {
    my ($varName, $value, $defaultValue) = @_;
    $value = $defaultValue if defined($value) && $value eq "''";
    $value ||= $defaultValue;
    $value = "0" if $value eq "000";

    print F "\n";
    print F 'our $', $varName, " = $value;", "\n";
}

sub load_limits_file {
    my ($f) = @_;
    my %info;
    if (open L, '<', $f) {
	while (<L>) {
	    s/\s+$//;
	    my ($key, $value) = split /:/, $_, 2;
	    $info{$key} = $value;
	}
	close L;
    }
    return %info;
}

sub sleep_alarm_compat {
    # compute this every time. 
    # The value from load_limits_file can be unreliable.
    my $compatible = -1;
    eval {
	local $SIG{ALRM} = sub { die "Timeout\n" };
	alarm 2;
	$compatible = 1;
	sleep 5;
	$compatible = "000";
    };
    return $compatible;
}

sub killzero {  # kill 'ZERO',$pid  portable for MSWin32
    my $pid = shift;
    return kill 'ZERO', $pid;
}

sub launch_system_limits {
    my ($file, $sysfile) = @_;
    if ($^O eq 'MSWin32') {
        unlink 'pid';
        my $z1 = system 1, "$^X system-limits.PL $file $sysfile --bg > pid";
        for (1 .. 20) {
            sleep 1;
            last if -s 'pid';
        }
        open FH, '<pid'
            or die "$0: Failed to get process id of system-limits.PL: $!";
        my $pid = <FH>;
        close FH;
        unlink 'pid';
        return $pid;
    }
    return qx($^X system-limits.PL $file $sysfile);
}
