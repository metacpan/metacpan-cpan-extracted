#
# Forks::Super::Job::OS::Cygwin - operating system manipulation for
#          Windows (and sometimes Cygwin)
#

package Forks::Super::Job::OS::Cygwin;
use Forks::Super::Config qw(:all);
use Forks::Super::Debug qw(:all);
use Forks::Super::Util qw(IS_CYGWIN);
use Forks::Super::Job::OS::Win32;
use Carp;
use strict;
use warnings;

our $VERSION = '0.96';

if (!&IS_CYGWIN) {
    Carp::confess "Loaded Cygwin-only module into \$^O=$^O!\n";
}
if (!defined &Cygwin::pid_to_winpid) {
    *Cygwin::pid_to_winpid = *poor_mans_pid_to_winpid;
}
if (!defined &Cygwin::winpid_to_pid) {
    *Cygwin::winpid_to_pid = *poor_mans_winpid_to_pid;
}


# CORE::kill $signal, $cygwin_pid   is not that reliable, 
# especially under a heavy CPU or heavy stream of signals
#
# In particular, it is better to implement  Forks::Super::Job::suspend
# and  Forks::Super::Job::resume  in terms of the Windows API
# than to send  SIGSTOP  and  SIGCONT  signals to a Cygwn process
# with Perl's builtin  kill .

sub pid_to_winpid {
    my $cygpid = shift;
    return Cygwin::pid_to_winpid($cygpid)
	|| poor_mans_pid_to_winpid($cygpid)
	|| poor_mans_pgid_to_winpid($cygpid);
}

sub poor_mans_pid_to_winpid ($) {
    my $pid = shift;
    my @ps = qx(/bin/ps -lp $pid 2>/dev/null);
    if (@ps < 1) {
	# no such process
	return;
    }
    $ps[-1] =~ s/^.\s*//;
    my ($cygpid,$ppid,$pgid,$winpid) = split /\s+/, $ps[-1];
    $winpid = undef if $winpid eq 'WINPID';
    return $winpid;
}

sub poor_mans_pgid_to_winpid ($) {
    my $pid = shift;
    my @ps = qx(/bin/ps -lW 2>/dev/null);
    my $keep = undef;
    foreach my $ps (@ps) {
	my ($cygpid,$ppid,$pgid,$winpid) = split /\s+/, substr($ps,2);
	if ($winpid == $pid) {
	    return $cygpid;
	} elsif ($winpid == $pgid) {
	    $keep = $winpid;
	}
    }
    return $keep;
}

sub poor_mans_winpid_to_pid ($) {
    my $pid = shift;
    my @ps = qx(/bin/ps -l 2>/dev/null);
    foreach my $ps (@ps) {
	my ($cygpid,$ppid,$pgid,$winpid) = split /\s+/, substr($ps,2);
	return $cygpid if $winpid == $pid;
    }
    return;
}

sub suspend {
    # suspend a Cygwin process with the given pid.
    # this should NOT be a Forks::Super::Job object
    my $cygpid = shift;
    my $winpid = Cygwin::pid_to_winpid($cygpid);
    if (!defined $winpid) {
	carp "Forks::Super::Job::suspend: no winpid found for cygpid $cygpid";
	return;
    }
    return Forks::Super::Job::OS::Win32::suspend_process($winpid);
}

sub resume {
    my $cygpid = shift;
    my $winpid = Cygwin::pid_to_winpid($cygpid);
    if (!defined $winpid) {
	carp "Forks::Super::Job::suspend: no winpid found for cygpid $cygpid";
	return;
    }
    return Forks::Super::Job::OS::Win32::resume_process($winpid);
}

sub terminate {
    my $cygpid = shift;
    my $winpid = Cygwin::pid_to_winpid($cygpid);
    return Forks::Super::Job::OS::Win32::terminate_process($winpid, 9);
}

1;
