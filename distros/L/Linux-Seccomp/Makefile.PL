use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Linux::Seccomp',
	VERSION_FROM      => 'lib/Linux/Seccomp.pm',
	ABSTRACT_FROM     => 'lib/Linux/Seccomp.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM          => {},
	INC                => '-Ilibseccomp/include',
	MYEXTLIB           => 'libseccomp/src/.libs/libseccomp$(LIB_EXT)',
	clean              => { FILES => 'libseccomp/src/.libs/libseccomp$(LIB_EXT)' },
	META_ADD           => {
		dynamic_config => 1,
		resources      => {
			repository => 'https://git.ieval.ro/?p=linux-seccomp.git',
		},
	}
);

sub MY::postamble {
'
$(MYEXTLIB): libseccomp/configure
	cd libseccomp && ./configure && `which gmake || echo $(MAKE)` all
'
}

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw(AUDIT_ARCH_AARCH64 AUDIT_ARCH_MIPS AUDIT_ARCH_MIPS64
		 AUDIT_ARCH_MIPS64N32 AUDIT_ARCH_MIPSEL64N32 AUDIT_ARCH_PPC64LE
		 EM_AARCH64 EM_MIPS SCMP_ACT_ALLOW SCMP_ACT_KILL SCMP_ACT_TRAP
		 SCMP_ARCH_AARCH64 SCMP_ARCH_ARM SCMP_ARCH_MIPS
		 SCMP_ARCH_MIPS64 SCMP_ARCH_MIPS64N32 SCMP_ARCH_MIPSEL
		 SCMP_ARCH_MIPSEL64 SCMP_ARCH_MIPSEL64N32 SCMP_ARCH_NATIVE
		 SCMP_ARCH_PPC SCMP_ARCH_PPC64 SCMP_ARCH_PPC64LE SCMP_ARCH_S390
		 SCMP_ARCH_S390X SCMP_ARCH_X32 SCMP_ARCH_X86 SCMP_ARCH_X86_64
		 SCMP_VER_MAJOR SCMP_VER_MICRO SCMP_VER_MINOR
		 __AUDIT_ARCH_CONVENTION_MIPS64_N32 __NR_SCMP_ERROR
		 __NR_SCMP_UNDEF __NR__llseek __NR__newselect __NR__sysctl
		 __NR_accept __NR_accept4 __NR_access __NR_afs_syscall
		 __NR_alarm __NR_arch_prctl __NR_arm_fadvise64_64
		 __NR_arm_sync_file_range __NR_bdflush __NR_bind __NR_break
		 __NR_breakpoint __NR_cachectl __NR_cacheflush __NR_chmod
		 __NR_chown __NR_chown32 __NR_connect __NR_creat
		 __NR_create_module __NR_dup2 __NR_epoll_create
		 __NR_epoll_ctl_old __NR_epoll_wait __NR_epoll_wait_old
		 __NR_eventfd __NR_fadvise64 __NR_fadvise64_64 __NR_fchown32
		 __NR_fcntl64 __NR_fork __NR_fstat64 __NR_fstatat64
		 __NR_fstatfs64 __NR_ftime __NR_ftruncate64 __NR_futimesat
		 __NR_get_kernel_syms __NR_get_mempolicy __NR_get_thread_area
		 __NR_getdents __NR_getegid32 __NR_geteuid32 __NR_getgid32
		 __NR_getgroups32 __NR_getpeername __NR_getpgrp __NR_getpmsg
		 __NR_getrandom __NR_getresgid32 __NR_getresuid32
		 __NR_getrlimit __NR_getsockname __NR_getsockopt __NR_getuid32
		 __NR_gtty __NR_idle __NR_inotify_init __NR_ioperm __NR_iopl
		 __NR_ipc __NR_kexec_file_load __NR_lchown __NR_lchown32
		 __NR_link __NR_listen __NR_lock __NR_lstat __NR_lstat64
		 __NR_mbind __NR_membarrier __NR_memfd_create
		 __NR_migrate_pages __NR_mkdir __NR_mknod __NR_mmap __NR_mmap2
		 __NR_modify_ldt __NR_move_pages __NR_mpx __NR_msgctl
		 __NR_msgget __NR_msgrcv __NR_msgsnd __NR_multiplexer
		 __NR_newfstatat __NR_nfsservctl __NR_nice __NR_oldfstat
		 __NR_oldlstat __NR_oldolduname __NR_oldstat __NR_olduname
		 __NR_oldwait4 __NR_open __NR_pause __NR_pciconfig_iobase
		 __NR_pciconfig_read __NR_pciconfig_write __NR_pipe __NR_poll
		 __NR_prof __NR_profil __NR_putpmsg __NR_query_module
		 __NR_readdir __NR_readlink __NR_recv __NR_recvfrom
		 __NR_recvmmsg __NR_recvmsg __NR_rename __NR_rmdir __NR_rtas
		 __NR_s390_pci_mmio_read __NR_s390_pci_mmio_write
		 __NR_s390_runtime_instr __NR_security __NR_select __NR_semctl
		 __NR_semget __NR_semop __NR_semtimedop __NR_send
		 __NR_sendfile64 __NR_sendmmsg __NR_sendmsg __NR_sendto
		 __NR_set_mempolicy __NR_set_thread_area __NR_set_tls
		 __NR_setfsgid32 __NR_setfsuid32 __NR_setgid32 __NR_setgroups32
		 __NR_setregid32 __NR_setresgid32 __NR_setresuid32
		 __NR_setreuid32 __NR_setsockopt __NR_setuid32 __NR_sgetmask
		 __NR_shmat __NR_shmctl __NR_shmdt __NR_shmget __NR_shutdown
		 __NR_sigaction __NR_signal __NR_signalfd __NR_sigpending
		 __NR_sigprocmask __NR_sigreturn __NR_sigsuspend __NR_socket
		 __NR_socketcall __NR_socketpair __NR_spu_create __NR_spu_run
		 __NR_ssetmask __NR_stat __NR_stat64 __NR_statfs64 __NR_stime
		 __NR_stty __NR_subpage_prot __NR_swapcontext
		 __NR_switch_endian __NR_symlink __NR_sync_file_range
		 __NR_sync_file_range2 __NR_sys_debug_setcontext __NR_syscall
		 __NR_sysfs __NR_sysmips __NR_time __NR_timerfd __NR_truncate64
		 __NR_tuxcall __NR_ugetrlimit __NR_ulimit __NR_umount
		 __NR_unlink __NR_uselib __NR_userfaultfd __NR_usr26 __NR_usr32
		 __NR_ustat __NR_utime __NR_utimes __NR_vfork __NR_vm86
		 __NR_vm86old __NR_vserver __NR_waitpid __PNR__llseek
		 __PNR__newselect __PNR__sysctl __PNR_accept __PNR_accept4
		 __PNR_access __PNR_afs_syscall __PNR_alarm __PNR_arch_prctl
		 __PNR_arm_fadvise64_64 __PNR_arm_sync_file_range __PNR_bdflush
		 __PNR_bind __PNR_break __PNR_breakpoint __PNR_cachectl
		 __PNR_cacheflush __PNR_chmod __PNR_chown __PNR_chown32
		 __PNR_connect __PNR_creat __PNR_create_module __PNR_dup2
		 __PNR_epoll_create __PNR_epoll_ctl_old __PNR_epoll_wait
		 __PNR_epoll_wait_old __PNR_eventfd __PNR_fadvise64
		 __PNR_fadvise64_64 __PNR_fchown32 __PNR_fcntl64 __PNR_fork
		 __PNR_fstat64 __PNR_fstatat64 __PNR_fstatfs64 __PNR_ftime
		 __PNR_ftruncate64 __PNR_futimesat __PNR_get_kernel_syms
		 __PNR_get_mempolicy __PNR_get_thread_area __PNR_getdents
		 __PNR_getegid32 __PNR_geteuid32 __PNR_getgid32
		 __PNR_getgroups32 __PNR_getpeername __PNR_getpgrp
		 __PNR_getpmsg __PNR_getrandom __PNR_getresgid32
		 __PNR_getresuid32 __PNR_getrlimit __PNR_getsockname
		 __PNR_getsockopt __PNR_getuid32 __PNR_gtty __PNR_idle
		 __PNR_inotify_init __PNR_ioperm __PNR_iopl __PNR_ipc
		 __PNR_kexec_file_load __PNR_lchown __PNR_lchown32 __PNR_link
		 __PNR_listen __PNR_lock __PNR_lstat __PNR_lstat64 __PNR_mbind
		 __PNR_membarrier __PNR_memfd_create __PNR_migrate_pages
		 __PNR_mkdir __PNR_mknod __PNR_mmap __PNR_mmap2
		 __PNR_modify_ldt __PNR_move_pages __PNR_mpx __PNR_msgctl
		 __PNR_msgget __PNR_msgrcv __PNR_msgsnd __PNR_multiplexer
		 __PNR_newfstatat __PNR_nfsservctl __PNR_nice __PNR_oldfstat
		 __PNR_oldlstat __PNR_oldolduname __PNR_oldstat __PNR_olduname
		 __PNR_oldwait4 __PNR_open __PNR_pause __PNR_pciconfig_iobase
		 __PNR_pciconfig_read __PNR_pciconfig_write __PNR_pipe
		 __PNR_poll __PNR_prof __PNR_profil __PNR_putpmsg
		 __PNR_query_module __PNR_readdir __PNR_readlink __PNR_recv
		 __PNR_recvfrom __PNR_recvmmsg __PNR_recvmsg __PNR_rename
		 __PNR_rmdir __PNR_rtas __PNR_s390_pci_mmio_read
		 __PNR_s390_pci_mmio_write __PNR_s390_runtime_instr
		 __PNR_security __PNR_select __PNR_semctl __PNR_semget
		 __PNR_semop __PNR_semtimedop __PNR_send __PNR_sendfile64
		 __PNR_sendmmsg __PNR_sendmsg __PNR_sendto __PNR_set_mempolicy
		 __PNR_set_thread_area __PNR_set_tls __PNR_setfsgid32
		 __PNR_setfsuid32 __PNR_setgid32 __PNR_setgroups32
		 __PNR_setregid32 __PNR_setresgid32 __PNR_setresuid32
		 __PNR_setreuid32 __PNR_setsockopt __PNR_setuid32
		 __PNR_sgetmask __PNR_shmat __PNR_shmctl __PNR_shmdt
		 __PNR_shmget __PNR_shutdown __PNR_sigaction __PNR_signal
		 __PNR_signalfd __PNR_sigpending __PNR_sigprocmask
		 __PNR_sigreturn __PNR_sigsuspend __PNR_socket __PNR_socketcall
		 __PNR_socketpair __PNR_spu_create __PNR_spu_run __PNR_ssetmask
		 __PNR_stat __PNR_stat64 __PNR_statfs64 __PNR_stime __PNR_stty
		 __PNR_subpage_prot __PNR_swapcontext __PNR_switch_endian
		 __PNR_symlink __PNR_sync_file_range __PNR_sync_file_range2
		 __PNR_sys_debug_setcontext __PNR_syscall __PNR_sysfs
		 __PNR_sysmips __PNR_time __PNR_timerfd __PNR_truncate64
		 __PNR_tuxcall __PNR_ugetrlimit __PNR_ulimit __PNR_umount
		 __PNR_unlink __PNR_uselib __PNR_userfaultfd __PNR_usr26
		 __PNR_usr32 __PNR_ustat __PNR_utime __PNR_utimes __PNR_vfork
		 __PNR_vm86 __PNR_vm86old __PNR_vserver __PNR_waitpid),
              {name=>"SCMP_CMP_EQ", macro=>"1"},
              {name=>"SCMP_CMP_GE", macro=>"1"},
              {name=>"SCMP_CMP_GT", macro=>"1"},
              {name=>"SCMP_CMP_LE", macro=>"1"},
              {name=>"SCMP_CMP_LT", macro=>"1"},
              {name=>"SCMP_CMP_MASKED_EQ", macro=>"1"},
              {name=>"SCMP_CMP_NE", macro=>"1"},
              {name=>"SCMP_FLTATR_ACT_BADARCH", macro=>"1"},
              {name=>"SCMP_FLTATR_ACT_DEFAULT", macro=>"1"},
              {name=>"SCMP_FLTATR_CTL_NNP", macro=>"1"},
              {name=>"SCMP_FLTATR_CTL_TSYNC", macro=>"1"},
              {name=>"_SCMP_CMP_MAX", macro=>"1"},
              {name=>"_SCMP_CMP_MIN", macro=>"1"},
              {name=>"_SCMP_FLTATR_MAX", macro=>"1"},
              {name=>"_SCMP_FLTATR_MIN", macro=>"1"});
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Linux::Seccomp',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );

}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
