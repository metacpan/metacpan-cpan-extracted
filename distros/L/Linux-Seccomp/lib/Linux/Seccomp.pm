package Linux::Seccomp;

use 5.014000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	functions => [
		qw/arch_native
		   arch_resolve_name
		   syscall_resolve_name
		   syscall_resolve_name_arch
		   syscall_resolve_name_rewrite
		   syscall_resolve_num_arch
		   version/ ],

	macros => [
		qw/SCMP_ACT_ALLOW
		   SCMP_ACT_ERRNO
		   SCMP_ACT_KILL
		   SCMP_ACT_TRACE
		   SCMP_ACT_TRAP
		   SCMP_ARCH_AARCH64
		   SCMP_ARCH_ARM
		   SCMP_ARCH_MIPS
		   SCMP_ARCH_MIPS64
		   SCMP_ARCH_MIPS64N32
		   SCMP_ARCH_MIPSEL
		   SCMP_ARCH_MIPSEL64
		   SCMP_ARCH_MIPSEL64N32
		   SCMP_ARCH_NATIVE
		   SCMP_ARCH_PPC
		   SCMP_ARCH_PPC64
		   SCMP_ARCH_PPC64LE
		   SCMP_ARCH_S390
		   SCMP_ARCH_S390X
		   SCMP_ARCH_X32
		   SCMP_ARCH_X86
		   SCMP_ARCH_X86_64
		   SCMP_CMP_EQ
		   SCMP_CMP_GE
		   SCMP_CMP_GT
		   SCMP_CMP_LE
		   SCMP_CMP_LT
		   SCMP_CMP_MASKED_EQ
		   SCMP_CMP_NE
		   SCMP_FLTATR_ACT_BADARCH
		   SCMP_FLTATR_ACT_DEFAULT
		   SCMP_FLTATR_CTL_NNP
		   SCMP_FLTATR_CTL_TSYNC
		   SCMP_VER_MAJOR
		   SCMP_VER_MICRO
		   SCMP_VER_MINOR
		   _SCMP_CMP_MAX
		   _SCMP_CMP_MIN
		   _SCMP_FLTATR_MAX
		   _SCMP_FLTATR_MIN
		   __NR_SCMP_ERROR
		   __NR_SCMP_UNDEF
		   __NR__llseek
		   __NR__newselect
		   __NR__sysctl
		   __NR_accept
		   __NR_accept4
		   __NR_access
		   __NR_afs_syscall
		   __NR_alarm
		   __NR_arch_prctl
		   __NR_arm_fadvise64_64
		   __NR_arm_sync_file_range
		   __NR_bdflush
		   __NR_bind
		   __NR_break
		   __NR_breakpoint
		   __NR_cachectl
		   __NR_cacheflush
		   __NR_chmod
		   __NR_chown
		   __NR_chown32
		   __NR_connect
		   __NR_creat
		   __NR_create_module
		   __NR_dup2
		   __NR_epoll_create
		   __NR_epoll_ctl_old
		   __NR_epoll_wait
		   __NR_epoll_wait_old
		   __NR_eventfd
		   __NR_fadvise64
		   __NR_fadvise64_64
		   __NR_fchown32
		   __NR_fcntl64
		   __NR_fork
		   __NR_fstat64
		   __NR_fstatat64
		   __NR_fstatfs64
		   __NR_ftime
		   __NR_ftruncate64
		   __NR_futimesat
		   __NR_get_kernel_syms
		   __NR_get_mempolicy
		   __NR_get_thread_area
		   __NR_getdents
		   __NR_getegid32
		   __NR_geteuid32
		   __NR_getgid32
		   __NR_getgroups32
		   __NR_getpeername
		   __NR_getpgrp
		   __NR_getpmsg
		   __NR_getrandom
		   __NR_getresgid32
		   __NR_getresuid32
		   __NR_getrlimit
		   __NR_getsockname
		   __NR_getsockopt
		   __NR_getuid32
		   __NR_gtty
		   __NR_idle
		   __NR_inotify_init
		   __NR_ioperm
		   __NR_iopl
		   __NR_ipc
		   __NR_kexec_file_load
		   __NR_lchown
		   __NR_lchown32
		   __NR_link
		   __NR_listen
		   __NR_lock
		   __NR_lstat
		   __NR_lstat64
		   __NR_mbind
		   __NR_membarrier
		   __NR_memfd_create
		   __NR_migrate_pages
		   __NR_mkdir
		   __NR_mknod
		   __NR_mmap
		   __NR_mmap2
		   __NR_modify_ldt
		   __NR_move_pages
		   __NR_mpx
		   __NR_msgctl
		   __NR_msgget
		   __NR_msgrcv
		   __NR_msgsnd
		   __NR_multiplexer
		   __NR_newfstatat
		   __NR_nfsservctl
		   __NR_nice
		   __NR_oldfstat
		   __NR_oldlstat
		   __NR_oldolduname
		   __NR_oldstat
		   __NR_olduname
		   __NR_oldwait4
		   __NR_open
		   __NR_pause
		   __NR_pciconfig_iobase
		   __NR_pciconfig_read
		   __NR_pciconfig_write
		   __NR_pipe
		   __NR_poll
		   __NR_prof
		   __NR_profil
		   __NR_putpmsg
		   __NR_query_module
		   __NR_readdir
		   __NR_readlink
		   __NR_recv
		   __NR_recvfrom
		   __NR_recvmmsg
		   __NR_recvmsg
		   __NR_rename
		   __NR_rmdir
		   __NR_rtas
		   __NR_s390_pci_mmio_read
		   __NR_s390_pci_mmio_write
		   __NR_s390_runtime_instr
		   __NR_security
		   __NR_select
		   __NR_semctl
		   __NR_semget
		   __NR_semop
		   __NR_semtimedop
		   __NR_send
		   __NR_sendfile64
		   __NR_sendmmsg
		   __NR_sendmsg
		   __NR_sendto
		   __NR_set_mempolicy
		   __NR_set_thread_area
		   __NR_set_tls
		   __NR_setfsgid32
		   __NR_setfsuid32
		   __NR_setgid32
		   __NR_setgroups32
		   __NR_setregid32
		   __NR_setresgid32
		   __NR_setresuid32
		   __NR_setreuid32
		   __NR_setsockopt
		   __NR_setuid32
		   __NR_sgetmask
		   __NR_shmat
		   __NR_shmctl
		   __NR_shmdt
		   __NR_shmget
		   __NR_shutdown
		   __NR_sigaction
		   __NR_signal
		   __NR_signalfd
		   __NR_sigpending
		   __NR_sigprocmask
		   __NR_sigreturn
		   __NR_sigsuspend
		   __NR_socket
		   __NR_socketcall
		   __NR_socketpair
		   __NR_spu_create
		   __NR_spu_run
		   __NR_ssetmask
		   __NR_stat
		   __NR_stat64
		   __NR_statfs64
		   __NR_stime
		   __NR_stty
		   __NR_subpage_prot
		   __NR_swapcontext
		   __NR_switch_endian
		   __NR_symlink
		   __NR_sync_file_range
		   __NR_sync_file_range2
		   __NR_sys_debug_setcontext
		   __NR_syscall
		   __NR_sysfs
		   __NR_sysmips
		   __NR_time
		   __NR_timerfd
		   __NR_truncate64
		   __NR_tuxcall
		   __NR_ugetrlimit
		   __NR_ulimit
		   __NR_umount
		   __NR_unlink
		   __NR_uselib
		   __NR_userfaultfd
		   __NR_usr26
		   __NR_usr32
		   __NR_ustat
		   __NR_utime
		   __NR_utimes
		   __NR_vfork
		   __NR_vm86
		   __NR_vm86old
		   __NR_vserver
		   __NR_waitpid
		   __PNR__llseek
		   __PNR__newselect
		   __PNR__sysctl
		   __PNR_accept
		   __PNR_accept4
		   __PNR_access
		   __PNR_afs_syscall
		   __PNR_alarm
		   __PNR_arch_prctl
		   __PNR_arm_fadvise64_64
		   __PNR_arm_sync_file_range
		   __PNR_bdflush
		   __PNR_bind
		   __PNR_break
		   __PNR_breakpoint
		   __PNR_cachectl
		   __PNR_cacheflush
		   __PNR_chmod
		   __PNR_chown
		   __PNR_chown32
		   __PNR_connect
		   __PNR_creat
		   __PNR_create_module
		   __PNR_dup2
		   __PNR_epoll_create
		   __PNR_epoll_ctl_old
		   __PNR_epoll_wait
		   __PNR_epoll_wait_old
		   __PNR_eventfd
		   __PNR_fadvise64
		   __PNR_fadvise64_64
		   __PNR_fchown32
		   __PNR_fcntl64
		   __PNR_fork
		   __PNR_fstat64
		   __PNR_fstatat64
		   __PNR_fstatfs64
		   __PNR_ftime
		   __PNR_ftruncate64
		   __PNR_futimesat
		   __PNR_get_kernel_syms
		   __PNR_get_mempolicy
		   __PNR_get_thread_area
		   __PNR_getdents
		   __PNR_getegid32
		   __PNR_geteuid32
		   __PNR_getgid32
		   __PNR_getgroups32
		   __PNR_getpeername
		   __PNR_getpgrp
		   __PNR_getpmsg
		   __PNR_getrandom
		   __PNR_getresgid32
		   __PNR_getresuid32
		   __PNR_getrlimit
		   __PNR_getsockname
		   __PNR_getsockopt
		   __PNR_getuid32
		   __PNR_gtty
		   __PNR_idle
		   __PNR_inotify_init
		   __PNR_ioperm
		   __PNR_iopl
		   __PNR_ipc
		   __PNR_kexec_file_load
		   __PNR_lchown
		   __PNR_lchown32
		   __PNR_link
		   __PNR_listen
		   __PNR_lock
		   __PNR_lstat
		   __PNR_lstat64
		   __PNR_mbind
		   __PNR_membarrier
		   __PNR_memfd_create
		   __PNR_migrate_pages
		   __PNR_mkdir
		   __PNR_mknod
		   __PNR_mmap
		   __PNR_mmap2
		   __PNR_modify_ldt
		   __PNR_move_pages
		   __PNR_mpx
		   __PNR_msgctl
		   __PNR_msgget
		   __PNR_msgrcv
		   __PNR_msgsnd
		   __PNR_multiplexer
		   __PNR_newfstatat
		   __PNR_nfsservctl
		   __PNR_nice
		   __PNR_oldfstat
		   __PNR_oldlstat
		   __PNR_oldolduname
		   __PNR_oldstat
		   __PNR_olduname
		   __PNR_oldwait4
		   __PNR_open
		   __PNR_pause
		   __PNR_pciconfig_iobase
		   __PNR_pciconfig_read
		   __PNR_pciconfig_write
		   __PNR_pipe
		   __PNR_poll
		   __PNR_prof
		   __PNR_profil
		   __PNR_putpmsg
		   __PNR_query_module
		   __PNR_readdir
		   __PNR_readlink
		   __PNR_recv
		   __PNR_recvfrom
		   __PNR_recvmmsg
		   __PNR_recvmsg
		   __PNR_rename
		   __PNR_rmdir
		   __PNR_rtas
		   __PNR_s390_pci_mmio_read
		   __PNR_s390_pci_mmio_write
		   __PNR_s390_runtime_instr
		   __PNR_security
		   __PNR_select
		   __PNR_semctl
		   __PNR_semget
		   __PNR_semop
		   __PNR_semtimedop
		   __PNR_send
		   __PNR_sendfile64
		   __PNR_sendmmsg
		   __PNR_sendmsg
		   __PNR_sendto
		   __PNR_set_mempolicy
		   __PNR_set_thread_area
		   __PNR_set_tls
		   __PNR_setfsgid32
		   __PNR_setfsuid32
		   __PNR_setgid32
		   __PNR_setgroups32
		   __PNR_setregid32
		   __PNR_setresgid32
		   __PNR_setresuid32
		   __PNR_setreuid32
		   __PNR_setsockopt
		   __PNR_setuid32
		   __PNR_sgetmask
		   __PNR_shmat
		   __PNR_shmctl
		   __PNR_shmdt
		   __PNR_shmget
		   __PNR_shutdown
		   __PNR_sigaction
		   __PNR_signal
		   __PNR_signalfd
		   __PNR_sigpending
		   __PNR_sigprocmask
		   __PNR_sigreturn
		   __PNR_sigsuspend
		   __PNR_socket
		   __PNR_socketcall
		   __PNR_socketpair
		   __PNR_spu_create
		   __PNR_spu_run
		   __PNR_ssetmask
		   __PNR_stat
		   __PNR_stat64
		   __PNR_statfs64
		   __PNR_stime
		   __PNR_stty
		   __PNR_subpage_prot
		   __PNR_swapcontext
		   __PNR_switch_endian
		   __PNR_symlink
		   __PNR_sync_file_range
		   __PNR_sync_file_range2
		   __PNR_sys_debug_setcontext
		   __PNR_syscall
		   __PNR_sysfs
		   __PNR_sysmips
		   __PNR_time
		   __PNR_timerfd
		   __PNR_truncate64
		   __PNR_tuxcall
		   __PNR_ugetrlimit
		   __PNR_ulimit
		   __PNR_umount
		   __PNR_unlink
		   __PNR_uselib
		   __PNR_userfaultfd
		   __PNR_usr26
		   __PNR_usr32
		   __PNR_ustat
		   __PNR_utime
		   __PNR_utimes
		   __PNR_vfork
		   __PNR_vm86
		   __PNR_vm86old
		   __PNR_vserver
		   __PNR_waitpid/]
);

$EXPORT_TAGS{all} = [@{$EXPORT_TAGS{functions}}, @{$EXPORT_TAGS{macros}}];
our @EXPORT_OK = @{$EXPORT_TAGS{all}};
our @EXPORT = @{$EXPORT_TAGS{macros}};

our $VERSION;
BEGIN{
	$VERSION = '0.002001';
}

sub AUTOLOAD {
	my $constname;
	our $AUTOLOAD;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak "&Linux::Seccomp::constant not defined" if $constname eq 'constant';
	my ($error, $val) = constant($constname);
	if ($error) { croak $error; }
	{
		no strict 'refs';
		*$AUTOLOAD = sub { $val };
	}
	goto &$AUTOLOAD;
}

BEGIN {
	require XSLoader;
	XSLoader::load('Linux::Seccomp', $VERSION);
}

sub new {
	my ($ign, $def_action) = @_;
	init $def_action
}

sub DESTROY {
	shift->release
}

my %COMPARE_OP_TBL = (
	'!=' => SCMP_CMP_NE(),
	ne   => SCMP_CMP_NE(),
	'<'  => SCMP_CMP_LT(),
	lt   => SCMP_CMP_LT(),
	'<=' => SCMP_CMP_LE(),
	le   => SCMP_CMP_LE(),
	'==' => SCMP_CMP_EQ(),
	eq   => SCMP_CMP_EQ(),
	'>=' => SCMP_CMP_GE(),
	ge   => SCMP_CMP_GE(),
    '>'  => SCMP_CMP_GT(),
	gt   => SCMP_CMP_GT(),
	'=~' => SCMP_CMP_MASKED_EQ(),
	me   => SCMP_CMP_MASKED_EQ(),

	SCMP_CMP_NE() => SCMP_CMP_NE(),
	SCMP_CMP_LT() => SCMP_CMP_LT(),
	SCMP_CMP_LE() => SCMP_CMP_LE(),
	SCMP_CMP_EQ() => SCMP_CMP_EQ(),
	SCMP_CMP_GE() => SCMP_CMP_GE(),
	SCMP_CMP_GT() => SCMP_CMP_GT(),
	SCMP_CMP_MASKED_EQ() => SCMP_CMP_MASKED_EQ(),
);

sub _mangle_rule_add_args {
	my @args = map {
		my $op = $_->[1];
		$_->[1] = $COMPARE_OP_TBL{$op} or croak "No mapping for compare operator '$op'";
		make_arg_cmp (@$_)
	} @_;
	\@args
}

sub rule_add {
	rule_add_array (shift, shift, shift, _mangle_rule_add_args (@_));
}

sub rule_add_exact {
	rule_add_exact_array (shift, shift, shift, _mangle_rule_add_args (@_));
}

1;
__END__

=encoding utf-8

=head1 NAME

Linux::Seccomp - Interface to libseccomp Linux syscall filtering library

=head1 SYNOPSIS

  use Linux::Seccomp ':all';
  my $ctx = Linux::Seccomp->new(SCMP_ACT_ALLOW);
  # Block writes to STDERR
  $ctx->rule_add(SCMP_ACT_KILL, syscall_resolve_name('write'), [0, '==', 2]);
  $ctx->load;
  $| = 1;
  print STDOUT "Hello world!\n";       # works
  print STDERR "Goodbye world!\n";     # Killed
  print STDOUT "Hello again world!\n"; # never reached

=head1 DESCRIPTION

Secure Computing (seccomp) is Linux's system call filtering mechanism.
This system can operate in two modes: I<strict>, where only a very
small number of system calls are allowed and the more modern I<filter>
(or seccomp mode 2) which permits advanced filtering of system calls.
This module is only concerned with the latter.

Linux::Seccomp is a Perl interface to the
L<libseccomp|https://github.com/seccomp/libseccomp> library which
provides a simple way to use seccomp mode 2.

It should be mentioned that this module is not production-ready at the
moment -- work needs to be done to port the libseccomp testsuite and
the documentation needs to be improved.

Basic usage of this module is straightforward: Create a filter using
the B<new> method, add rules to it using the B<rule_add> method
several times, and finally load the filter into the kernel using the
B<load> method. An example of this can be seen in the SYNOPSIS.

=head1 METHODS

Most methods die on error.

=over

=item I<$ctx> = Linux::Seccomp->B<new>(I<$def_action>)

Creates a new C<Linux::Seccomp> filter, with the default action for
unhandled syscalls being I<$def_action>. Possible values for
I<$def_action> are:

=over

=item SCMP_ACT_KILL

The thread will be terminated by the kernel with SIGSYS when it calls
a syscall that does not match any of the configured seccomp filter
rules. The thread will not be able to catch the signal.

=item SCMP_ACT_TRAP

The thread will be sent a SIGSYS signal when it calls a syscall that
does not match any of the configured seccomp filter rules. It may
catch this and change its behavior accordingly. When using SA_SIGINFO
with L<sigaction(2)>, si_code will be set to SYS_SECCOMP, si_syscall
will be set to the syscall that failed the rules, and si_arch will be
set to the AUDIT_ARCH for the active ABI.

=item SCMP_ACT_ERRNO(I<$errno>)

The thread will receive a return value of I<$errno> when it calls a
syscall that does not match any of the configured seccomp filter
rules.

=item SCMP_ACT_TRACE(I<$msg_num>)

If the thread is being traced and the tracing process specified the
PTRACE_O_TRACESECCOMP option in the call to L<ptrace(2)>, the tracing
process will be notified, via PTRACE_EVENT_SECCOMP, and the value
provided in msg_num can be retrieved using the PTRACE_GETEVENTMSG
option.

=item SCMP_ACT_ALLOW

The seccomp filter will have no effect on the thread calling the
syscall if it does not match any of the configured seccomp filter
rules.

=back

See L<seccomp_init(3)>.

=item I<$ctx>->B<rule_add>(I<$action>, I<$syscall>, I<@args>)

Adds a rule to the filter. If a system call with number I<$syscall>
whose arguments match I<@args> is called, I<$action> will be taken.

I<$action> can be any of the C<SCMP_ACT_*> macros listed above.

I<@args> is a list of 0 or more constraints on the arguments to the
syscall. Each constraint is an arrayref with 3 or 4 elements: C<[$arg,
$op, $datum_a, $datum_b]> where I<$arg> is the index of the argument
we are comparing. I<$op> is as follows:

=over

=item SCMP_CMP_NE

=item '!='

=item 'ne'

Matches when the argument value is not equal to I<$datum_a>.

=item SCMP_CMP_LT

=item '<'

=item 'lt'

Matches when the argument value is less than I<$datum_a>.

=item SCMP_CMP_LE

=item '<='

=item 'le'

Matches when the argument value is less than or equal to I<$datum_a>.

=item SCMP_CMP_EQ

=item '=='

=item 'eq'

Matches when the argument value is equal to I<$datum_a>.

=item SCMP_CMP_GE

=item '>='

=item 'ge'

Matches when the argument value is greater than or equal to I<$datum_a>.

=item SCMP_CMP_GT

=item '>'

=item 'gt'

Matches when the argument value is greater than I<$datum_a>.

=item SCMP_CMP_MASKED_EQ

=item '=~'

=item 'me'

Matches when the argument value masked with I<$datum_a> is equal to I<$datum_b> masked with I<$datum_a>.

=back

See L<seccomp_rule_add(3)>.

=item I<$ctx>->B<arch_add>(I<$arch_token>)

Add an architecture to the filter. The native architecture is added by
default.
See L<seccomp_arch_add(3)>.

=item I<$ctx>->B<arch_exists>(I<$arch_token>)

Returns true if the given architecture is in the filter, false
otherwise.
See L<seccomp_arch_add(3)>.

=item I<$ctx>->B<arch_remove>(I<$arch_token>)

Removes an architecture from the filter.
See L<seccomp_arch_add(3)>.

=item I<$ctx>->B<attr_get>(I<$attr>)

Returns the value of an attribute. The attributes are:

=over

=item SCMP_FLTATR_ACT_DEFAULT

The default filter action as specified in the call to B<new>. Read-only.

=item SCMP_FLTATR_ACT_BADARCH

The filter action taken when the loaded filter does not match the
architecture of the executing application. Defaults to SCMP_ACT_KILL.

=item SCMP_FLTATR_CTL_NNP

Specifies whether to turn on NO_NEW_PRIVS functionality when B<load>
is called. Defaults to 1 (on). If this flag is turned off then the
calling process must have CAP_SYS_ADMIN (or else the call to B<load>
will fail).

=item SCMP_FLTATR_CTL_TSYNC

Specifies whether the kernel should synchronize the filters accross
all threads when B<load> is called. Defaults to 0 (off).

=back

See L<seccomp_attr_get(3)>.

=item I<$ctx>->B<attr_set>(I<$attr>, I<$value>)

Sets an attribute to the given value. The attributes are the ones from
the list above except for SCMP_FLTATR_ACT_DEFAULT which is read-only.
See L<seccomp_attr_get(3)>.

=item I<$ctx>->B<export_bpf>(I<$fh>)

Writes the BPF (Berkeley Packet Filter) representation of the filter
to the given file handle.
See L<seccomp_export_bpf(3)>.

=item I<$ctx>->B<export_pfc>(I<$fh>)

Writes the PFC (Pseudo Filter Code) representation of the filter to
the given file handle.
See L<seccomp_export_bpf(3)>.

=item I<$ctx>->B<load>

Loads the filter into the kernel.
See L<seccomp_load(3)>.

=back

=head1 FUNCTIONS

None exported by default. These functions die on error.

=over

=item B<arch_native>

Returns the arch token for the native architecture.
See L<seccomp_arch_add(3)>.

=item B<arch_resolve_name>(I<$arch_name>)

Returns the arch token for a named architecture.
See L<seccomp_arch_add(3)>.

=item B<syscall_resolve_name>(I<$name>)

Resolves a system call name to its number for the native architecture. A negative pseudo syscall number is returned if the architecture does not have the given syscall.
See L<seccomp_syscall_resolve_name(3)>.

=item B<syscall_resolve_name_arch>(I<$arch_token>, I<$name>)

Resolves a system call name to its number for a given architecture. A negative pseudo syscall number is returned if the architecture does not have the given syscall.
See L<seccomp_syscall_resolve_name(3)>.

=item B<syscall_resolve_name_rewrite>(I<$arch_token>, I<$name>)

Resolves a system call name to its number for a given architecture. A negative pseudo syscall number is returned if the architecture does not have the given syscall. In contrast to the previous function, this function tries to obtain the actual syscall number in cases where the previous function would return a pseudo syscall number.
See L<seccomp_syscall_resolve_name(3)>.

=item B<syscall_resolve_num_arch>(I<$arch_token>, I<$num>)

Returns the name of the system call with the given number on the given architecture.
See L<seccomp_syscall_resolve_name(3)>.

=item B<version>

Returns the version of libseccomp as a three-element arrayref:
[$major_version, $minor_version, $micro_version].

=back

=head1 CONSTANTS

All exported by default. Most of the SCMP_ constants were seen above.
Here is a list of all of them:

  SCMP_ACT_ALLOW
  SCMP_ACT_KILL
  SCMP_ACT_TRAP
  SCMP_ARCH_AARCH64
  SCMP_ARCH_ARM
  SCMP_ARCH_MIPS
  SCMP_ARCH_MIPS64
  SCMP_ARCH_MIPS64N32
  SCMP_ARCH_MIPSEL
  SCMP_ARCH_MIPSEL64
  SCMP_ARCH_MIPSEL64N32
  SCMP_ARCH_NATIVE
  SCMP_ARCH_PPC
  SCMP_ARCH_PPC64
  SCMP_ARCH_PPC64LE
  SCMP_ARCH_S390
  SCMP_ARCH_S390X
  SCMP_ARCH_X32
  SCMP_ARCH_X86
  SCMP_ARCH_X86_64
  SCMP_CMP_EQ
  SCMP_CMP_GE
  SCMP_CMP_GT
  SCMP_CMP_LE
  SCMP_CMP_LT
  SCMP_CMP_MASKED_EQ
  SCMP_CMP_NE
  SCMP_FLTATR_ACT_BADARCH
  SCMP_FLTATR_ACT_DEFAULT
  SCMP_FLTATR_CTL_NNP
  SCMP_FLTATR_CTL_TSYNC
  SCMP_VER_MAJOR
  SCMP_VER_MICRO
  SCMP_VER_MINOR

Besides the SCMP_ constants, the module also provides a long list of
__NR_syscall and __PNR_syscall constants that represent real and
pseudo syscall numbers for many common system calls. A full list can
be found in the source code of this module. See also the
B<syscall_resolve_name> family of functions above which is more
flexible than this set of constants.

=head1 SEE ALSO

L<https://github.com/seccomp/libseccomp>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
