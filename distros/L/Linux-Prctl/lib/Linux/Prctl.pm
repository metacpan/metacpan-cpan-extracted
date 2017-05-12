package Linux::Prctl;

use 5.008005;
use strict;
use warnings;

use Linux::Prctl::Securebits;
use Linux::Prctl::CapabilityBoundingSet;
use Linux::Prctl::CapabilitySet;

our $VERSION = '1.6.0';

require XSLoader;
my @noexport = keys %Linux::Prctl::;
XSLoader::load('Linux::Prctl', $VERSION);
my @from_xs = grep {$a = $_; !grep {$_ eq $a} @noexport} keys %Linux::Prctl::;

require Exporter;
our @ISA = qw(Exporter);
use Carp qw(croak);

our %EXPORT_TAGS = (
   'capabilities' => [qw(CAP_AUDIT_CONTROL CAP_AUDIT_WRITE CAP_CHOWN CAP_DAC_OVERRIDE CAP_DAC_READ_SEARCH CAP_FOWNER CAP_FSETID CAP_IPC_LOCK CAP_IPC_OWNER CAP_KILL CAP_LEASE CAP_LINUX_IMMUTABLE CAP_MAC_ADMIN CAP_MAC_OVERRIDE CAP_MKNOD CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_BROADCAST CAP_NET_RAW CAP_SETFCAP CAP_SETGID CAP_SETPCAP CAP_SETUID CAP_SYSLOG CAP_SYS_ADMIN CAP_SYS_BOOT CAP_SYS_CHROOT CAP_SYS_MODULE CAP_SYS_NICE CAP_SYS_PACCT CAP_SYS_PTRACE CAP_SYS_RAWIO CAP_SYS_RESOURCE CAP_SYS_TIME CAP_SYS_TTY_CONFIG CAP_WAKE_ALARM)],
   'constants' => [qw(ENDIAN_BIG ENDIAN_LITTLE ENDIAN_PPC_LITTLE FPEMU_NOPRINT FPEMU_SIGFPE FP_EXC_ASYNC FP_EXC_DISABLED FP_EXC_DIV FP_EXC_INV FP_EXC_NONRECOV FP_EXC_OVF FP_EXC_PRECISE FP_EXC_RES FP_EXC_SW_ENABLE FP_EXC_UND MCE_KILL_DEFAULT MCE_KILL_EARLY MCE_KILL_LATE TIMING_STATISTICAL TIMING_TIMESTAMP TSC_ENABLE TSC_SIGSEGV UNALIGN_NOPRINT UNALIGN_SIGBUS CAP_PERMITTED CAP_EFFECTIVE CAP_INHERITABLE)],
   'securebits' => [qw(SECBIT_KEEP_CAPS SECBIT_KEEP_CAPS_LOCKED SECBIT_NOROOT SECBIT_NOROOT_LOCKED SECBIT_NO_SETUID_FIXUP SECBIT_NO_SETUID_FIXUP_LOCKED SECURE_KEEP_CAPS SECURE_KEEP_CAPS_LOCKED SECURE_NOROOT SECURE_NOROOT_LOCKED SECURE_NO_SETUID_FIXUP SECURE_NO_SETUID_FIXUP_LOCKED)],
   'functions' => \@from_xs,
);

our (%securebits, %capbset, %cap_effective, %cap_inheritable, %cap_permitted);
tie %securebits, 'Linux::Prctl::Securebits';
tie %capbset, 'Linux::Prctl::CapabilityBoundingSet';
tie %cap_effective, 'Linux::Prctl::CapabilitySet', constant('CAP_EFFECTIVE');
tie %cap_inheritable, 'Linux::Prctl::CapabilitySet', constant('CAP_INHERITABLE');
tie %cap_permitted, 'Linux::Prctl::CapabilitySet', constant('CAP_PERMITTED');

our @EXPORT_OK = ( @{ $EXPORT_TAGS{constants} },
                   @{ $EXPORT_TAGS{functions} },
                   @{ $EXPORT_TAGS{securebits} },
                   @{ $EXPORT_TAGS{capabilities} } );
our @EXPORT;

sub AUTOLOAD {
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Linux::Prctl::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
    goto &$AUTOLOAD;
}

1;

__END__

=head1 NAME

Linux::Prctl - Perl extension for controlling process characteristics

=head1 SYNOPSIS

  use Linux::Prctl;

=head1 DESCRIPTION

The linux prctl function allows you to control specific characteristics of a
process' behaviour. Usage of the function is fairly messy though, due to
limitations in C and linux. This module provides a nice non-messy interface.
Most of the text in this documentation is based on text from the linux manpages
prctl(2) and capabilities(7)

Besides prctl, this library also wraps libcap for complete capability handling.

=head2 EXPORTS

There are 2 export tags: :constants and :functions. These export what you think
they will.

=head3 set_dumpable(flag)

Set the state of the flag determining whether core dumps are produced for this
process upon delivery of a signal whose default behavior is to produce a core
dump. (Normally this flag is set for a process by default, but it is cleared
when a set-user-ID or set-group-ID program is executed and also by various
system calls that manipulate process UIDs and GIDs).

=head3 get_dumpable()

Return the state of the dumpable flag.

=head3 set_endian(endiannes)

Set the endian-ness of the calling process. Valid values are ENDIAN_BIG,
ENDIAN_LITTLE and ENDIAN_PPC_LITTLE (PowerPC pseudo little endian).

This function only works on PowerPC systems.

=head3 get_endian()

Return the endian-ness of the calling process, see set_endian

=head3 set_fpemu(flag)

Set floating-point emulation control flag. Pass FPEMU_NOPRINT to silently
emulate fp operations accesses, or FPEMU_SIGFPE to not emulate fp operations
and send SIGFPE instead.

This function only works on ia64 systems.

=head3 get_fpemu()

Get floating-point emulation control flag. See set_fpemu.

=head3 set_fpexc(mode)

Set floating-point exception mode. Pass FP_EXC_SW_ENABLE to use FPEXC for FP
exception, FP_EXC_DIV for floating-point divide by zero, FP_EXC_OVF for
floating-point overflow, FP_EXC_UND for floating-point underflow, FP_EXC_RES
for floating-point inexact result, FP_EXC_INV for floating-point invalid
operation, FP_EXC_DISABLED for FP exceptions disabled, FP_EXC_NONRECOV for
async non-recoverable exception mode, FP_EXC_ASYNC for async recoverable
exception mode, FP_EXC_PRECISE for precise exception mode. Modes can be
combined with the | operator.

This function only works on PowerPC systems.

=head3 get_fpexc()

Return the floating-point exception mode as a bitmap of enabled modes. See
set_fpexc.

=head3 set_keepcaps(flag)

Set the state of the thread's "keep capabilities" flag, which determines
whether the threads's effective and permitted capability sets are cleared when
a change is made to the threads's user IDs such that the threads's real UID,
effective UID, and saved set-user-ID all become non-zero when at least one of
them previously had the value 0. (By default, these credential sets are
cleared). This value will be reset to False on subsequent calls to execve.

=head3 get_keepcaps()

Return the current state of the calling threads's "keep capabilities" flag.

=head3 set_mce_kill(policy)

Set the machine check memory corruption kill policy for the current thread.
The policy can be early kill (MCE_KILL_EARLY), late kill (MCE_KILL_LATE), or
the system-wide default (MCE_KILL_DEFAULT).  Early kill means that the task
receives a SIGBUS signal as soon as hardware memory corruption is detected
inside its address space. In late kill mode, the process is only killed when it
accesses a corrupted page.  The policy is inherited by children.  use the
system-wide default. The system-wide default is defined by
/proc/sys/vm/memory_failure_early_kill

This function is only available for kernel 2.6.32 and newer

=head3 get_mce_kill()

Return the current per-process machine check kill policy.

This function is only available for kernel 2.6.32 and newer

=head3 set_name(name)

Set the process name for the calling process, the name can be up to 16 bytes
long. This name is displayed in the output of ps and top. The initial value is
the name of the executable. For perl applications this will likely be perl. As
of perl 5.14, assigning to $0 also sets the process name.

=head3 get_name()

Return the (first 16 bytes of) the name for the calling process.

=head3 set_pdeathsig(signal)

Set the parent process death signal of the calling process (either a valid
signal value from the :mod:signal module, or 0 to clear). This is the signal
that the calling process will get when its parent dies. This value is cleared
for the child of a fork.

=head3 get_pdeathsig()

Return the current value of the parent process death signal. See set_pdeathsig.

=head3 set_ptracer(pid)

Sets the top of the process tree that is allowed to use PTRACE on the calling
process, assuming other requirements are met (matching uid, wasn't setuid,
etc). Use pid 0 to disallow all processes. For more details, see
/etc/sysctl.d/10-ptrace.conf.

This function is only available for kernel 3.4 and newer, or Ubuntu 10.10 and
newer.

=head3 get_ptracer(pid)

Returns the top of the process tree that is allowed to use PTRACE on the
calling process. See set_ptracer.

This function is only available for kernel 3.4 and newer, or Ubuntu 10.10 and
newer.

=head3 set_seccomp(mode)

Set the secure computing mode for the calling thread. In the current
implementation, mode must be True. After the secure computing mode has been set
to True, the only system calls that the thread is permitted to make are read,
write, _exit, and sigreturn. Other system calls result in the delivery of a
SIGKILL signal. Secure computing mode is useful for number-crunching
applications that may need to execute untrusted byte code, perhaps obtained by
reading from a pipe or socket. This operation is only available if the kernel
is configured with CONFIG_SECCOMP enabled.

=head3 get_seccomp()

Return the secure computing mode of the calling thread. Not very useful for the
current implementation, but may be useful for other possible future modes: if
the caller is not in secure computing mode, this operation returns False; if
the caller is in secure computing mode, then the prctl call will cause a
SIGKILL signal to be sent to the process. This operation is only available if
the kernel is configured with CONFIG_SECCOMP enabled.

=head3 set_timerslack()

Control the default "rounding" in nanoseconds that is used by select, poll and
friends.

The default value of the slack is 50 microseconds; this is significantly less
than the kernels average timing error but still allows the kernel to group
timers somewhat to preserve power behavior.

This function is only available for kernel 2.6.28 and newer

=head3 get_timerslack(value)

Return the current timing slack, see get_timing_slack

This function is only available for kernel 2.6.28 and newer

=head3 set_timing(flag)

Set whether to use (normal, traditional) statistical process timing or accurate
timestamp based process timing, by passing TIMING_STATISTICAL or
PR_TIMING_TIMESTAMP. TIMING_TIMESTAMP is not currently implemented

=head3 get_timing()

Return which process timing method is currently in use.

=head3 set_tsc(flag)

Set the state of the flag determining whether the timestamp counter can be read
by the process. Pass TSC_ENABLE to allow it to be read, or TSC_SIGSEGV to
generate a SIGSEGV when the process tries to read the timestamp counter.

This function only works on x86 systems.

=head3 get_tsc()

Return the state of the flag determining whether the timestamp counter can be
read, see set_tsc.

=head3 set_unalign(flag)

Set unaligned access control flag. Pass UNALIGN_NOPRINT to silently fix up
unaligned user accesses, or UNALIGN_SIGBUS to generate SIGBUS on unaligned user
access.

This function only works on ia64, parisc, PowerPC and Alpha systems.

=head3 get_unalign

Return unaligned access control bits, see set_unalign.

=head3 set_securebits(bitmap)

Set the "securebits" flags of the calling thread.

It is not recommended to use this function directly, use the
%Linux::Prctl::securebits hash instead.

=head3 get_securebits()

Get the "securebits" flags of the calling thread.

As with set_securebits, it is not recommended to use this function directly,
use the %Linux::Prctl::securebits hash instead.

=head3 capbset_read(capability)

Return whether the specified capability is in the calling thread's capability
bounding set. The capability bounding set dictates whether the process can
receive the capability through a file's permitted capability set on a
subsequent call to execve.

It is not recommended to use this function directly, use the
%Linux::Prctl::cap_* hashes instead.

=head3 capbset_drop(capability)

If the calling thread has the CAP_SETPCAP capability, then drop the specified
capability specified by from  the  calling  thread's capability bounding set.
Any children of the calling thread will inherit the newly reduced bounding set.

As with capbset_read, it is not recommended to use this function directly, use
the %Linux::Prctl::cap_* hashes instead.

=head2 Capabilities and the capability bounding set

For the purpose of performing permission checks, traditional Unix
implementations distinguish two categories of processes: privileged processes
(whose effective user ID is 0, referred to as superuser or root), and
unprivileged processes (whose effective UID is non-zero). Privileged processes
bypass all kernel permission checks, while unprivileged processes are subject
to full permission checking based on the process's credentials (usually:
effective UID, effective GID, and supplementary group list).

Starting with kernel 2.2, Linux divides the privileges traditionally associated
with superuser into distinct units, known as capabilities, which can be
independently enabled and disabled. Capabilities are a per-thread attribute.

Each thread has three capability sets containing zero or  more  of  the
capabilities described below

=head3 Permitted (the %Linux::Prctl::cap_permitted hash):

This is a limiting superset for the effective capabilities that the thread may
assume. It is also a limiting superset for the capabilities that may be added
to the inheritable set by a thread that does not have the setpcap capability in
its effective set.

If a thread drops a capability from its permitted set, it can never re-acquire
that capability (unless it execve s either a set-user-ID-root program, or a
program whose associated file capabilities grant that capability).

=head3 Inheritabe (the %Linux::Prctl::cap_inheritable hash):

This is a set of capabilities preserved across an execve. It provides a
mechanism for a process to assign capabilities to the permitted set of the new
program during an execve.

=head3 Effective (the %Linux::Prctl::cap_effective hash):

This is the set of capabilities used by the kernel to perform permission checks
for the thread.

A child created via fork inherits copies of its parent's capability sets. See
below for a discussion of the treatment of capabilities during :func:`execve`.

The $Linux::Prctl::capbset hash represents the current capability bounding sets
of the process.  The capability bounding set dictates whether the process can
receive the capability through a file's permitted capability set on a
subsequent call to execve. All items of this hash are true by default, unless a
parent process already removed them from the bounding set.

These four hashes have a number of keys. For the capability bounding set and
the effective capabilities, these can only be set to False, this drops them
from the corresponding set.

All details about capabilities and capability bounding sets can be found in the
capabilities(7) manpage, on which most text below is based.

These are the keys of the hashes:

=head3 audit_control

Enable and disable kernel auditing; change auditing filter rules; retrieve
auditing status and filtering rules.

=head3 audit_write

Write records to kernel auditing log.

=head3 chown

Make arbitrary changes to file UIDs and GIDs (see L<chown(2)>).

=head3 dac_override

Bypass file read, write, and execute permission checks.  (DAC is an
abbreviation of "discretionary access control".)

=head3 dac_read_search

Bypass file read permission checks and directory read and execute permission
checks.

=head3 fowner

=over 1

=item Bypass  permission  checks  on  operations  that  normally require the
file system UID of the process to match the UID of the file (e.g., chmod,
utime), excluding those operations covered by dac_override and dac_read_search.

=item Set extended file attributes (see L<chattr(1)>) on arbitrary files.

=item Set Access Control Lists (ACLs) on arbitrary files.

=item Ignore directory sticky bit on file deletion.

=item Specify O_NOATIME for arbitrary files in open and fcntl.

=back

=head3 fsetid

Don't clear set-user-ID and set-group-ID permission bits when a file is
modified; set the set-group-ID bit for a file whose  GID  does  not match the
file system or any of the supplementary GIDs of the calling process.

=head3 ipc_lock

Lock memory (mlock, mlockall, mmap, shmctl).

=head3 ipc_owner

Bypass permission checks for operations on System V IPC objects.

=head3 kill

Bypass permission checks for sending signals (see L<kill(2)>). This includes
use of the ioctl KDSIGACCEPT operation.

=head3 lease

Establish leases on arbitrary files (see L<fcntl(2)>).

=head3 linux_immutable

Set the FS_APPEND_FL and FS_IMMUTABLE_FL i-node flags (see L<chattr(1)>).

=head3 mac_admin

Override Mandatory Access Control (MAC). Implemented for the Smack Linux
Security Module (LSM).

=head3 mac_override

Allow MAC configuration or state changes. Implemented for the Smack LSM.

=for comment The above two were copied from the manpage, but they seem to be
swapped. Hmm...

=head3 mknod

Create special files using mknod.

=head3 net_admin

Perform various network-related operations (e.g., setting privileged socket
options, enabling multicasting, interface configuration, modifying routing
tables).

=head3 net_bind_service

Bind a socket to Internet domain privileged ports (port numbers less than
1024).

=head3 net_broadcast

(Unused) Make socket broadcasts, and listen to multicasts.

=head3 net_raw

Use RAW and PACKET sockets.

=head3 setgid

Make arbitrary manipulations of process GIDs and supplementary GID list; forge
GID when passing socket credentials via Unix domain sockets.

=head3 setfcap

Set file capabilities.

=head3 setpcap

If file capabilities are not supported: grant or remove any capability in the
caller's permitted capability set to or from any other process. (This property
of setpcap is not available when the kernel is configured to support file
capabilities, since setpcap has entirely different semantics for such kernels.)

If file capabilities are supported: add any capability from the calling
thread's bounding set to its  inheritable set; drop capabilities from the
bounding set (via capbset_drop); make changes to the securebits flags.

=head3 setuid

Make arbitrary manipulations of process UIDs (setuid, setreuid, setresuid,
setfsuid); make forged UID when passing socket credentials via Unix domain
sockets.

=head3 syslog

Allow configuring the kernel's syslog (printk behaviour). Before linux 2.6.38
the sys_admin capability was needed for this.

This is only available in linux 2.6.38 and newer.

=head3 sys_admin

=over 1

=item Perform a range of system administration operations including: quotactl,
mount, umount, swapon, swapoff, sethostname, and setdomainname.

=item Perform IPC_SET and IPC_RMID operations on arbitrary System V IPC
objects.

=item Perform operations on trusted and security Extended Attributes (see
L<attr(5)>).

=item Use lookup_dcookie.

=item Use ioprio_set to assign the IOPRIO_CLASS_RT scheduling class.

=item Forge UID when passing socket credentials.

=item Exceed /proc/sys/fs/file-max, the system-wide limit on the number of open
files, in system calls that open files (e.g., accept, execve, open, pipe).

=item Employ CLONE_NEWNS flag with clone and unshare.

=item Perform KEYCTL_CHOWN and KEYCTL_SETPERM keyctl operations.

=back

=head3 sys_boot

Use reboot and kexec_load.

=head3 sys_chroot

Use chroot.

=head3 sys_module

Load and unload kernel modules (see L<init_module(2)> and L<delete_module(2)>).

=head3 sys_nice

=over 1

=item Raise process nice value (nice, setpriority) and change the nice value
for arbitrary processes.

=item Set real-time scheduling policies for calling process, and set scheduling
policies and priorities for arbitrary processes (sched_setscheduler,
sched_setparam).

=item Set CPU affinity for arbitrary processes (sched_setaffinity)

=item Set I/O scheduling class and priority for arbitrary processes
(ioprio_set).

=item Apply migrate_pages to arbitrary processes and allow processes to be
migrated to arbitrary nodes.

=item Apply move_pages to arbitrary processes.

=item Use the MPOL_MF_MOVE_ALL flag with mbind and move_pages.

=back

=head3 sys_pacct

Use acct.

=head3 sys_ptrace

Trace arbitrary processes using ptrace.

=head3 sys_rawio

Perform I/O port operations (iopl and ioperm); access /proc/kcore.

=head3 sys_resource

=over 1

=item Use reserved space on ext2 file systems.

=item Make ioctl calls controlling ext3 journaling.

=item Override disk quota limits.

=item Increase resource limits (see L<setrlimit(2)>).

=item Override RLIMIT_NPROC resource limit.

=item Raise msg_qbytes limit for a System V message queue above the limit in
/proc/sys/kernel/msgmnb (see L<msgop(2)> and L<msgctl(2)>).

=back

=head3 sys_time

Set system clock (settimeofday, stime, adjtimex); set real-time (hardware)
clock.

=head3 sys_tty_config

Use vhangup.

=head3 wake_alarm

Allow triggering something that will wake the system.

This is only available in linux 3.0 and newer

The four capabilities hashes also have two additional methods, to make dropping
many capabilities at the same time easier:

=head3 drop(cap [, ...])

Drop all capabilities given as arguments from the set.

=head3 limit(cap [, ...])

Drop all but the given capabilities from the set.

These function accept both names of capabilities as given above and the CAP_
constants as defined in capabilities.h. These constants are available as
CAP_SYS_ADMIN et cetera.

=head2 Capabilities and execve

During an L<execve(2)>, the kernel calculates the new capabilities of the
process using the following algorithm:

* P'(permitted) = (P(inheritable) & F(inheritable)) | (F(permitted) & cap_bset)
* P'(effective) = F(effective) ? P'(permitted) : 0
* P'(inheritable) = P(inheritable) [i.e., unchanged]

Where:

* P denotes the value of a thread capability set before the execve
* P' denotes the value of a capability set after the execve
* F denotes a file capability set
* cap_bset is the value of the capability bounding set

The downside of this is that you need to set file capabilities if you want to
make applications capabilities-friendly via wrappers. For instance, to allow an
http daemon to listen on port 80 without it needing root privileges, you could
do the following:

 %Linux::Prctl.cap_inheritable{net_bind_service} = 1;
 $< = 1000;
 exec "/usr/sbin/httpd";

This only works if /usr/sbin/httpd has CAP_NET_BIND_SOCK in its inheritable and
effective sets. You can do this with the L<setcap(8)> tool shipped with libcap.

 $ sudo setcap cap_net_bind_service=ie /usr/sbin/httpd
 $ getcap /usr/sbin/httpd
 /usr/sbin/httpd = cap_net_bind_service+ei

Note that it only sets the capability in the inheritable set, so this
capability is only granted if the program calling execve has it in its
inheritable set too. The effective set of file capabilities does not exist in
linux, it is a single bit that specifies whether capabilities in the permitted
set are automatically raised in the effective set upon execve.

=head2 Establishing a capabilities-only environment with securebits

With a kernel in which file capabilities are enabled, Linux implements a set of
per-thread securebits flags that can be used to disable special handling of
capabilities for UID 0 (root). The securebits flags are inherited by child
processes. During an execve, all of the flags are preserved, except keep_caps
which is always cleared.

These capabilities are available via get_securebits, but are easier accessed
via the $Linux::prctl::securebits hash. This hash has keys that tell you
whether specific securebits are set, or unset.

The following keys are available:

=head3 keep_caps

Setting this flag allows a thread that has one or more 0 UIDs to retain its
capabilities when it switches all of its UIDs to a non-zero value.  If this
flag is not set, then such a UID switch causes the thread to lose all
capabilities. This flag is always cleared on an execve.

=head3 no_setuid_fixup

Setting this flag stops the kernel from adjusting capability sets when the
threads's effective and file system UIDs are switched between zero and non-zero
values. (See the subsection Effect of User ID Changes on Capabilities in
L<capabilities(7)>)

=head3 noroot

If this bit is set, then the kernel does not grant capabilities when a
set-user-ID-root program is executed, or when a process with an effective or
real UID of 0 calls execve. (See the subsection Capabilities and execution of
programs by root in L<capabilities(7)>)

=head3 keep_caps_locked

Like keep_caps, but irreversible

=head3 no_setuid_fixup_locked

Like no_setuid_fixup, but irreversible

=head3 noroot_locked

Like noroot, but irreversible

=head1 TODO

- None of the capability stuff is actually implemented at the moment

=head1 SEE ALSO

Manpages: capabilities(7) and prctl(2)

Github source: L<http://github.com/seveas/Linux-Prctl>

=head1 AUTHOR

Dennis Kaarsemaker, E<lt>dennis@kaarsemaker.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Dennis Kaarsemaker

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
