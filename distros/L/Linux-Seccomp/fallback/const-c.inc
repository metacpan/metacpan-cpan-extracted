#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     __NR_bind __NR_dup2 __NR_fork __NR_gtty __NR_idle __NR_iopl __NR_link
     __NR_lock __NR_mmap __NR_nice __NR_open __NR_pipe __NR_poll __NR_prof
     __NR_recv __NR_rtas __NR_send __NR_stat __NR_stty __NR_time __NR_vm86
     __PNR_ipc __PNR_mpx */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case '_':
    if (memEQ(name, "__PNR_ipc", 9)) {
    /*                    ^         */
#ifdef __PNR_ipc
      *iv_return = __PNR_ipc;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_mpx", 9)) {
    /*                    ^         */
#ifdef __PNR_mpx
      *iv_return = __PNR_mpx;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'b':
    if (memEQ(name, "__NR_bind", 9)) {
    /*                    ^         */
#ifdef __NR_bind
      *iv_return = __NR_bind;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'd':
    if (memEQ(name, "__NR_dup2", 9)) {
    /*                    ^         */
#ifdef __NR_dup2
      *iv_return = __NR_dup2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__NR_fork", 9)) {
    /*                    ^         */
#ifdef __NR_fork
      *iv_return = __NR_fork;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__NR_gtty", 9)) {
    /*                    ^         */
#ifdef __NR_gtty
      *iv_return = __NR_gtty;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__NR_idle", 9)) {
    /*                    ^         */
#ifdef __NR_idle
      *iv_return = __NR_idle;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_iopl", 9)) {
    /*                    ^         */
#ifdef __NR_iopl
      *iv_return = __NR_iopl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__NR_link", 9)) {
    /*                    ^         */
#ifdef __NR_link
      *iv_return = __NR_link;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_lock", 9)) {
    /*                    ^         */
#ifdef __NR_lock
      *iv_return = __NR_lock;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__NR_mmap", 9)) {
    /*                    ^         */
#ifdef __NR_mmap
      *iv_return = __NR_mmap;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__NR_nice", 9)) {
    /*                    ^         */
#ifdef __NR_nice
      *iv_return = __NR_nice;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "__NR_open", 9)) {
    /*                    ^         */
#ifdef __NR_open
      *iv_return = __NR_open;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "__NR_pipe", 9)) {
    /*                    ^         */
#ifdef __NR_pipe
      *iv_return = __NR_pipe;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_poll", 9)) {
    /*                    ^         */
#ifdef __NR_poll
      *iv_return = __NR_poll;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_prof", 9)) {
    /*                    ^         */
#ifdef __NR_prof
      *iv_return = __NR_prof;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "__NR_recv", 9)) {
    /*                    ^         */
#ifdef __NR_recv
      *iv_return = __NR_recv;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_rtas", 9)) {
    /*                    ^         */
#ifdef __NR_rtas
      *iv_return = __NR_rtas;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__NR_send", 9)) {
    /*                    ^         */
#ifdef __NR_send
      *iv_return = __NR_send;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_stat", 9)) {
    /*                    ^         */
#ifdef __NR_stat
      *iv_return = __NR_stat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_stty", 9)) {
    /*                    ^         */
#ifdef __NR_stty
      *iv_return = __NR_stty;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__NR_time", 9)) {
    /*                    ^         */
#ifdef __NR_time
      *iv_return = __NR_time;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'v':
    if (memEQ(name, "__NR_vm86", 9)) {
    /*                    ^         */
#ifdef __NR_vm86
      *iv_return = __NR_vm86;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     EM_AARCH64 __NR_alarm __NR_break __NR_chmod __NR_chown __NR_creat
     __NR_ftime __NR_lstat __NR_mbind __NR_mkdir __NR_mknod __NR_mmap2
     __NR_pause __NR_rmdir __NR_semop __NR_shmat __NR_shmdt __NR_stime
     __NR_sysfs __NR_usr26 __NR_usr32 __NR_ustat __NR_utime __NR_vfork
     __PNR_bind __PNR_dup2 __PNR_fork __PNR_gtty __PNR_idle __PNR_iopl
     __PNR_link __PNR_lock __PNR_mmap __PNR_nice __PNR_open __PNR_pipe
     __PNR_poll __PNR_prof __PNR_recv __PNR_rtas __PNR_send __PNR_stat
     __PNR_stty __PNR_time __PNR_vm86 */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'C':
    if (memEQ(name, "EM_AARCH64", 10)) {
    /*                     ^          */
#ifdef EM_AARCH64
      *iv_return = EM_AARCH64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "__NR_pause", 10)) {
    /*                     ^          */
#ifdef __NR_pause
      *iv_return = __NR_pause;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'b':
    if (memEQ(name, "__NR_mbind", 10)) {
    /*                     ^          */
#ifdef __NR_mbind
      *iv_return = __NR_mbind;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_bind", 10)) {
    /*                     ^          */
#ifdef __PNR_bind
      *iv_return = __PNR_bind;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'd':
    if (memEQ(name, "__PNR_dup2", 10)) {
    /*                     ^          */
#ifdef __PNR_dup2
      *iv_return = __PNR_dup2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__NR_semop", 10)) {
    /*                     ^          */
#ifdef __NR_semop
      *iv_return = __NR_semop;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__NR_vfork", 10)) {
    /*                     ^          */
#ifdef __NR_vfork
      *iv_return = __NR_vfork;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_fork", 10)) {
    /*                     ^          */
#ifdef __PNR_fork
      *iv_return = __PNR_fork;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__PNR_gtty", 10)) {
    /*                     ^          */
#ifdef __PNR_gtty
      *iv_return = __PNR_gtty;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'h':
    if (memEQ(name, "__NR_chmod", 10)) {
    /*                     ^          */
#ifdef __NR_chmod
      *iv_return = __NR_chmod;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_chown", 10)) {
    /*                     ^          */
#ifdef __NR_chown
      *iv_return = __NR_chown;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_shmat", 10)) {
    /*                     ^          */
#ifdef __NR_shmat
      *iv_return = __NR_shmat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_shmdt", 10)) {
    /*                     ^          */
#ifdef __NR_shmdt
      *iv_return = __NR_shmdt;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__PNR_idle", 10)) {
    /*                     ^          */
#ifdef __PNR_idle
      *iv_return = __PNR_idle;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_iopl", 10)) {
    /*                     ^          */
#ifdef __PNR_iopl
      *iv_return = __PNR_iopl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'k':
    if (memEQ(name, "__NR_mkdir", 10)) {
    /*                     ^          */
#ifdef __NR_mkdir
      *iv_return = __NR_mkdir;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_mknod", 10)) {
    /*                     ^          */
#ifdef __NR_mknod
      *iv_return = __NR_mknod;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__NR_alarm", 10)) {
    /*                     ^          */
#ifdef __NR_alarm
      *iv_return = __NR_alarm;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_link", 10)) {
    /*                     ^          */
#ifdef __PNR_link
      *iv_return = __PNR_link;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_lock", 10)) {
    /*                     ^          */
#ifdef __PNR_lock
      *iv_return = __PNR_lock;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__NR_mmap2", 10)) {
    /*                     ^          */
#ifdef __NR_mmap2
      *iv_return = __NR_mmap2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_rmdir", 10)) {
    /*                     ^          */
#ifdef __NR_rmdir
      *iv_return = __NR_rmdir;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_mmap", 10)) {
    /*                     ^          */
#ifdef __PNR_mmap
      *iv_return = __PNR_mmap;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__PNR_nice", 10)) {
    /*                     ^          */
#ifdef __PNR_nice
      *iv_return = __PNR_nice;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "__PNR_open", 10)) {
    /*                     ^          */
#ifdef __PNR_open
      *iv_return = __PNR_open;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "__PNR_pipe", 10)) {
    /*                     ^          */
#ifdef __PNR_pipe
      *iv_return = __PNR_pipe;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_poll", 10)) {
    /*                     ^          */
#ifdef __PNR_poll
      *iv_return = __PNR_poll;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_prof", 10)) {
    /*                     ^          */
#ifdef __PNR_prof
      *iv_return = __PNR_prof;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "__NR_break", 10)) {
    /*                     ^          */
#ifdef __NR_break
      *iv_return = __NR_break;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_creat", 10)) {
    /*                     ^          */
#ifdef __NR_creat
      *iv_return = __NR_creat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_recv", 10)) {
    /*                     ^          */
#ifdef __PNR_recv
      *iv_return = __PNR_recv;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_rtas", 10)) {
    /*                     ^          */
#ifdef __PNR_rtas
      *iv_return = __PNR_rtas;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__NR_lstat", 10)) {
    /*                     ^          */
#ifdef __NR_lstat
      *iv_return = __NR_lstat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_usr26", 10)) {
    /*                     ^          */
#ifdef __NR_usr26
      *iv_return = __NR_usr26;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_usr32", 10)) {
    /*                     ^          */
#ifdef __NR_usr32
      *iv_return = __NR_usr32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_ustat", 10)) {
    /*                     ^          */
#ifdef __NR_ustat
      *iv_return = __NR_ustat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_send", 10)) {
    /*                     ^          */
#ifdef __PNR_send
      *iv_return = __PNR_send;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_stat", 10)) {
    /*                     ^          */
#ifdef __PNR_stat
      *iv_return = __PNR_stat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_stty", 10)) {
    /*                     ^          */
#ifdef __PNR_stty
      *iv_return = __PNR_stty;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__NR_ftime", 10)) {
    /*                     ^          */
#ifdef __NR_ftime
      *iv_return = __NR_ftime;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_stime", 10)) {
    /*                     ^          */
#ifdef __NR_stime
      *iv_return = __NR_stime;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_utime", 10)) {
    /*                     ^          */
#ifdef __NR_utime
      *iv_return = __NR_utime;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_time", 10)) {
    /*                     ^          */
#ifdef __PNR_time
      *iv_return = __PNR_time;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'v':
    if (memEQ(name, "__PNR_vm86", 10)) {
    /*                     ^          */
#ifdef __PNR_vm86
      *iv_return = __PNR_vm86;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'y':
    if (memEQ(name, "__NR_sysfs", 10)) {
    /*                     ^          */
#ifdef __NR_sysfs
      *iv_return = __NR_sysfs;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SCMP_CMP_EQ SCMP_CMP_GE SCMP_CMP_GT SCMP_CMP_LE SCMP_CMP_LT SCMP_CMP_NE
     __NR_accept __NR_access __NR_ioperm __NR_lchown __NR_listen __NR_msgctl
     __NR_msgget __NR_msgrcv __NR_msgsnd __NR_profil __NR_rename __NR_select
     __NR_semctl __NR_semget __NR_sendto __NR_shmctl __NR_shmget __NR_signal
     __NR_socket __NR_stat64 __NR_ulimit __NR_umount __NR_unlink __NR_uselib
     __NR_utimes __PNR_alarm __PNR_break __PNR_chmod __PNR_chown __PNR_creat
     __PNR_ftime __PNR_lstat __PNR_mbind __PNR_mkdir __PNR_mknod __PNR_mmap2
     __PNR_pause __PNR_rmdir __PNR_semop __PNR_shmat __PNR_shmdt __PNR_stime
     __PNR_sysfs __PNR_usr26 __PNR_usr32 __PNR_ustat __PNR_utime __PNR_vfork */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case '2':
    if (memEQ(name, "__PNR_usr26", 11)) {
    /*                        ^        */
#ifdef __PNR_usr26
      *iv_return = __PNR_usr26;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "__PNR_usr32", 11)) {
    /*                        ^        */
#ifdef __PNR_usr32
      *iv_return = __PNR_usr32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "__NR_stat64", 11)) {
    /*                        ^        */
#ifdef __NR_stat64
      *iv_return = __NR_stat64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "SCMP_CMP_EQ", 11)) {
    /*                        ^        */
      *iv_return = SCMP_CMP_EQ;
      return PERL_constant_ISIV;
    }
    break;
  case 'G':
    if (memEQ(name, "SCMP_CMP_GE", 11)) {
    /*                        ^        */
      *iv_return = SCMP_CMP_GE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "SCMP_CMP_GT", 11)) {
    /*                        ^        */
      *iv_return = SCMP_CMP_GT;
      return PERL_constant_ISIV;
    }
    break;
  case 'L':
    if (memEQ(name, "SCMP_CMP_LE", 11)) {
    /*                        ^        */
      *iv_return = SCMP_CMP_LE;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "SCMP_CMP_LT", 11)) {
    /*                        ^        */
      *iv_return = SCMP_CMP_LT;
      return PERL_constant_ISIV;
    }
    break;
  case 'N':
    if (memEQ(name, "SCMP_CMP_NE", 11)) {
    /*                        ^        */
      *iv_return = SCMP_CMP_NE;
      return PERL_constant_ISIV;
    }
    break;
  case 'a':
    if (memEQ(name, "__NR_signal", 11)) {
    /*                        ^        */
#ifdef __NR_signal
      *iv_return = __NR_signal;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_break", 11)) {
    /*                        ^        */
#ifdef __PNR_break
      *iv_return = __PNR_break;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_creat", 11)) {
    /*                        ^        */
#ifdef __PNR_creat
      *iv_return = __PNR_creat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_lstat", 11)) {
    /*                        ^        */
#ifdef __PNR_lstat
      *iv_return = __PNR_lstat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_shmat", 11)) {
    /*                        ^        */
#ifdef __PNR_shmat
      *iv_return = __PNR_shmat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_ustat", 11)) {
    /*                        ^        */
#ifdef __PNR_ustat
      *iv_return = __PNR_ustat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "__NR_msgrcv", 11)) {
    /*                        ^        */
#ifdef __NR_msgrcv
      *iv_return = __NR_msgrcv;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_select", 11)) {
    /*                        ^        */
#ifdef __NR_select
      *iv_return = __NR_select;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'd':
    if (memEQ(name, "__PNR_shmdt", 11)) {
    /*                        ^        */
#ifdef __PNR_shmdt
      *iv_return = __PNR_shmdt;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__NR_listen", 11)) {
    /*                        ^        */
#ifdef __NR_listen
      *iv_return = __NR_listen;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_msgget", 11)) {
    /*                        ^        */
#ifdef __NR_msgget
      *iv_return = __NR_msgget;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_semget", 11)) {
    /*                        ^        */
#ifdef __NR_semget
      *iv_return = __NR_semget;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_shmget", 11)) {
    /*                        ^        */
#ifdef __NR_shmget
      *iv_return = __NR_shmget;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_socket", 11)) {
    /*                        ^        */
#ifdef __NR_socket
      *iv_return = __NR_socket;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_utimes", 11)) {
    /*                        ^        */
#ifdef __NR_utimes
      *iv_return = __NR_utimes;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__PNR_sysfs", 11)) {
    /*                        ^        */
#ifdef __PNR_sysfs
      *iv_return = __PNR_sysfs;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__NR_profil", 11)) {
    /*                        ^        */
#ifdef __NR_profil
      *iv_return = __NR_profil;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_ulimit", 11)) {
    /*                        ^        */
#ifdef __NR_ulimit
      *iv_return = __NR_ulimit;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_uselib", 11)) {
    /*                        ^        */
#ifdef __NR_uselib
      *iv_return = __NR_uselib;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_mkdir", 11)) {
    /*                        ^        */
#ifdef __PNR_mkdir
      *iv_return = __PNR_mkdir;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_rmdir", 11)) {
    /*                        ^        */
#ifdef __PNR_rmdir
      *iv_return = __PNR_rmdir;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__NR_rename", 11)) {
    /*                        ^        */
#ifdef __NR_rename
      *iv_return = __NR_rename;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_ftime", 11)) {
    /*                        ^        */
#ifdef __PNR_ftime
      *iv_return = __PNR_ftime;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_stime", 11)) {
    /*                        ^        */
#ifdef __PNR_stime
      *iv_return = __PNR_stime;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_utime", 11)) {
    /*                        ^        */
#ifdef __PNR_utime
      *iv_return = __PNR_utime;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__NR_msgsnd", 11)) {
    /*                        ^        */
#ifdef __NR_msgsnd
      *iv_return = __NR_msgsnd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_umount", 11)) {
    /*                        ^        */
#ifdef __NR_umount
      *iv_return = __NR_umount;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_unlink", 11)) {
    /*                        ^        */
#ifdef __NR_unlink
      *iv_return = __NR_unlink;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_mbind", 11)) {
    /*                        ^        */
#ifdef __PNR_mbind
      *iv_return = __PNR_mbind;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "__PNR_chmod", 11)) {
    /*                        ^        */
#ifdef __PNR_chmod
      *iv_return = __PNR_chmod;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_mknod", 11)) {
    /*                        ^        */
#ifdef __PNR_mknod
      *iv_return = __PNR_mknod;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_semop", 11)) {
    /*                        ^        */
#ifdef __PNR_semop
      *iv_return = __PNR_semop;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "__NR_accept", 11)) {
    /*                        ^        */
#ifdef __NR_accept
      *iv_return = __NR_accept;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_mmap2", 11)) {
    /*                        ^        */
#ifdef __PNR_mmap2
      *iv_return = __PNR_mmap2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "__NR_ioperm", 11)) {
    /*                        ^        */
#ifdef __NR_ioperm
      *iv_return = __NR_ioperm;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_alarm", 11)) {
    /*                        ^        */
#ifdef __PNR_alarm
      *iv_return = __PNR_alarm;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_vfork", 11)) {
    /*                        ^        */
#ifdef __PNR_vfork
      *iv_return = __PNR_vfork;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__NR_access", 11)) {
    /*                        ^        */
#ifdef __NR_access
      *iv_return = __NR_access;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_pause", 11)) {
    /*                        ^        */
#ifdef __PNR_pause
      *iv_return = __PNR_pause;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__NR_msgctl", 11)) {
    /*                        ^        */
#ifdef __NR_msgctl
      *iv_return = __NR_msgctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_semctl", 11)) {
    /*                        ^        */
#ifdef __NR_semctl
      *iv_return = __NR_semctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_sendto", 11)) {
    /*                        ^        */
#ifdef __NR_sendto
      *iv_return = __NR_sendto;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_shmctl", 11)) {
    /*                        ^        */
#ifdef __NR_shmctl
      *iv_return = __NR_shmctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'w':
    if (memEQ(name, "__NR_lchown", 11)) {
    /*                        ^        */
#ifdef __NR_lchown
      *iv_return = __NR_lchown;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_chown", 11)) {
    /*                        ^        */
#ifdef __PNR_chown
      *iv_return = __PNR_chown;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     __NR__llseek __NR__sysctl __NR_accept4 __NR_bdflush __NR_chown32
     __NR_connect __NR_eventfd __NR_fcntl64 __NR_fstat64 __NR_getpgrp
     __NR_getpmsg __NR_lstat64 __NR_oldstat __NR_putpmsg __NR_readdir
     __NR_recvmsg __NR_sendmsg __NR_set_tls __NR_spu_run __NR_symlink
     __NR_syscall __NR_sysmips __NR_timerfd __NR_tuxcall __NR_vm86old
     __NR_vserver __NR_waitpid __PNR_accept __PNR_access __PNR_ioperm
     __PNR_lchown __PNR_listen __PNR_msgctl __PNR_msgget __PNR_msgrcv
     __PNR_msgsnd __PNR_profil __PNR_rename __PNR_select __PNR_semctl
     __PNR_semget __PNR_sendto __PNR_shmctl __PNR_shmget __PNR_signal
     __PNR_socket __PNR_stat64 __PNR_ulimit __PNR_umount __PNR_unlink
     __PNR_uselib __PNR_utimes */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case '6':
    if (memEQ(name, "__NR_vm86old", 12)) {
    /*                       ^          */
#ifdef __NR_vm86old
      *iv_return = __NR_vm86old;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "__NR_set_tls", 12)) {
    /*                       ^          */
#ifdef __NR_set_tls
      *iv_return = __NR_set_tls;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_spu_run", 12)) {
    /*                       ^          */
#ifdef __NR_spu_run
      *iv_return = __NR_spu_run;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "__NR_fstat64", 12)) {
    /*                       ^          */
#ifdef __NR_fstat64
      *iv_return = __NR_fstat64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_lstat64", 12)) {
    /*                       ^          */
#ifdef __NR_lstat64
      *iv_return = __NR_lstat64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_stat64", 12)) {
    /*                       ^          */
#ifdef __PNR_stat64
      *iv_return = __PNR_stat64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "__NR_syscall", 12)) {
    /*                       ^          */
#ifdef __NR_syscall
      *iv_return = __NR_syscall;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_tuxcall", 12)) {
    /*                       ^          */
#ifdef __NR_tuxcall
      *iv_return = __NR_tuxcall;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_accept", 12)) {
    /*                       ^          */
#ifdef __PNR_accept
      *iv_return = __PNR_accept;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_access", 12)) {
    /*                       ^          */
#ifdef __PNR_access
      *iv_return = __PNR_access;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_socket", 12)) {
    /*                       ^          */
#ifdef __PNR_socket
      *iv_return = __PNR_socket;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'd':
    if (memEQ(name, "__NR_readdir", 12)) {
    /*                       ^          */
#ifdef __NR_readdir
      *iv_return = __NR_readdir;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_sendmsg", 12)) {
    /*                       ^          */
#ifdef __NR_sendmsg
      *iv_return = __NR_sendmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__NR_accept4", 12)) {
    /*                       ^          */
#ifdef __NR_accept4
      *iv_return = __NR_accept4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_timerfd", 12)) {
    /*                       ^          */
#ifdef __NR_timerfd
      *iv_return = __NR_timerfd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_uselib", 12)) {
    /*                       ^          */
#ifdef __PNR_uselib
      *iv_return = __PNR_uselib;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__PNR_msgctl", 12)) {
    /*                       ^          */
#ifdef __PNR_msgctl
      *iv_return = __PNR_msgctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_msgget", 12)) {
    /*                       ^          */
#ifdef __PNR_msgget
      *iv_return = __PNR_msgget;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_msgrcv", 12)) {
    /*                       ^          */
#ifdef __PNR_msgrcv
      *iv_return = __PNR_msgrcv;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_msgsnd", 12)) {
    /*                       ^          */
#ifdef __PNR_msgsnd
      *iv_return = __PNR_msgsnd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_signal", 12)) {
    /*                       ^          */
#ifdef __PNR_signal
      *iv_return = __PNR_signal;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'h':
    if (memEQ(name, "__PNR_lchown", 12)) {
    /*                       ^          */
#ifdef __PNR_lchown
      *iv_return = __PNR_lchown;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__PNR_ulimit", 12)) {
    /*                       ^          */
#ifdef __PNR_ulimit
      *iv_return = __PNR_ulimit;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_utimes", 12)) {
    /*                       ^          */
#ifdef __PNR_utimes
      *iv_return = __PNR_utimes;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__NR_bdflush", 12)) {
    /*                       ^          */
#ifdef __NR_bdflush
      *iv_return = __NR_bdflush;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_symlink", 12)) {
    /*                       ^          */
#ifdef __NR_symlink
      *iv_return = __NR_symlink;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_select", 12)) {
    /*                       ^          */
#ifdef __PNR_select
      *iv_return = __PNR_select;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_unlink", 12)) {
    /*                       ^          */
#ifdef __PNR_unlink
      *iv_return = __PNR_unlink;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__NR_sysmips", 12)) {
    /*                       ^          */
#ifdef __NR_sysmips
      *iv_return = __NR_sysmips;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_semctl", 12)) {
    /*                       ^          */
#ifdef __PNR_semctl
      *iv_return = __PNR_semctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_semget", 12)) {
    /*                       ^          */
#ifdef __PNR_semget
      *iv_return = __PNR_semget;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_shmctl", 12)) {
    /*                       ^          */
#ifdef __PNR_shmctl
      *iv_return = __PNR_shmctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_shmget", 12)) {
    /*                       ^          */
#ifdef __PNR_shmget
      *iv_return = __PNR_shmget;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__NR_connect", 12)) {
    /*                       ^          */
#ifdef __NR_connect
      *iv_return = __NR_connect;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_eventfd", 12)) {
    /*                       ^          */
#ifdef __NR_eventfd
      *iv_return = __NR_eventfd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_rename", 12)) {
    /*                       ^          */
#ifdef __PNR_rename
      *iv_return = __PNR_rename;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_sendto", 12)) {
    /*                       ^          */
#ifdef __PNR_sendto
      *iv_return = __PNR_sendto;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "__PNR_profil", 12)) {
    /*                       ^          */
#ifdef __PNR_profil
      *iv_return = __PNR_profil;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_umount", 12)) {
    /*                       ^          */
#ifdef __PNR_umount
      *iv_return = __PNR_umount;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "__NR_getpgrp", 12)) {
    /*                       ^          */
#ifdef __NR_getpgrp
      *iv_return = __NR_getpgrp;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_getpmsg", 12)) {
    /*                       ^          */
#ifdef __NR_getpmsg
      *iv_return = __NR_getpmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_putpmsg", 12)) {
    /*                       ^          */
#ifdef __NR_putpmsg
      *iv_return = __NR_putpmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_ioperm", 12)) {
    /*                       ^          */
#ifdef __PNR_ioperm
      *iv_return = __PNR_ioperm;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "__NR_vserver", 12)) {
    /*                       ^          */
#ifdef __NR_vserver
      *iv_return = __NR_vserver;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__NR__llseek", 12)) {
    /*                       ^          */
#ifdef __NR__llseek
      *iv_return = __NR__llseek;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR__sysctl", 12)) {
    /*                       ^          */
#ifdef __NR__sysctl
      *iv_return = __NR__sysctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_oldstat", 12)) {
    /*                       ^          */
#ifdef __NR_oldstat
      *iv_return = __NR_oldstat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_listen", 12)) {
    /*                       ^          */
#ifdef __PNR_listen
      *iv_return = __PNR_listen;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__NR_fcntl64", 12)) {
    /*                       ^          */
#ifdef __NR_fcntl64
      *iv_return = __NR_fcntl64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_waitpid", 12)) {
    /*                       ^          */
#ifdef __NR_waitpid
      *iv_return = __NR_waitpid;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'v':
    if (memEQ(name, "__NR_recvmsg", 12)) {
    /*                       ^          */
#ifdef __NR_recvmsg
      *iv_return = __NR_recvmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'w':
    if (memEQ(name, "__NR_chown32", 12)) {
    /*                       ^          */
#ifdef __NR_chown32
      *iv_return = __NR_chown32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SCMP_ACT_KILL SCMP_ACT_TRAP SCMP_ARCH_ARM SCMP_ARCH_PPC SCMP_ARCH_X32
     SCMP_ARCH_X86 _SCMP_CMP_MAX _SCMP_CMP_MIN __NR_cachectl __NR_fchown32
     __NR_getdents __NR_getgid32 __NR_getuid32 __NR_lchown32 __NR_oldfstat
     __NR_oldlstat __NR_olduname __NR_oldwait4 __NR_readlink __NR_recvfrom
     __NR_recvmmsg __NR_security __NR_sendmmsg __NR_setgid32 __NR_setuid32
     __NR_sgetmask __NR_shutdown __NR_signalfd __NR_ssetmask __NR_statfs64
     __PNR__llseek __PNR__sysctl __PNR_accept4 __PNR_bdflush __PNR_chown32
     __PNR_connect __PNR_eventfd __PNR_fcntl64 __PNR_fstat64 __PNR_getpgrp
     __PNR_getpmsg __PNR_lstat64 __PNR_oldstat __PNR_putpmsg __PNR_readdir
     __PNR_recvmsg __PNR_sendmsg __PNR_set_tls __PNR_spu_run __PNR_symlink
     __PNR_syscall __PNR_sysmips __PNR_timerfd __PNR_tuxcall __PNR_vm86old
     __PNR_vserver __PNR_waitpid */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case '8':
    if (memEQ(name, "__PNR_vm86old", 13)) {
    /*                       ^           */
#ifdef __PNR_vm86old
      *iv_return = __PNR_vm86old;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "SCMP_ARCH_ARM", 13)) {
    /*                       ^           */
#ifdef SCMP_ARCH_ARM
      *iv_return = SCMP_ARCH_ARM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SCMP_ARCH_PPC", 13)) {
    /*                       ^           */
#ifdef SCMP_ARCH_PPC
      *iv_return = SCMP_ARCH_PPC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SCMP_ARCH_X32", 13)) {
    /*                       ^           */
#ifdef SCMP_ARCH_X32
      *iv_return = SCMP_ARCH_X32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SCMP_ARCH_X86", 13)) {
    /*                       ^           */
#ifdef SCMP_ARCH_X86
      *iv_return = SCMP_ARCH_X86;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "_SCMP_CMP_MAX", 13)) {
    /*                       ^           */
      *iv_return = _SCMP_CMP_MAX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "_SCMP_CMP_MIN", 13)) {
    /*                       ^           */
      *iv_return = _SCMP_CMP_MIN;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "SCMP_ACT_KILL", 13)) {
    /*                       ^           */
#ifdef SCMP_ACT_KILL
      *iv_return = SCMP_ACT_KILL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SCMP_ACT_TRAP", 13)) {
    /*                       ^           */
#ifdef SCMP_ACT_TRAP
      *iv_return = SCMP_ACT_TRAP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "__PNR_readdir", 13)) {
    /*                       ^           */
#ifdef __PNR_readdir
      *iv_return = __PNR_readdir;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "__PNR_accept4", 13)) {
    /*                       ^           */
#ifdef __PNR_accept4
      *iv_return = __PNR_accept4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_recvmsg", 13)) {
    /*                       ^           */
#ifdef __PNR_recvmsg
      *iv_return = __PNR_recvmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'd':
    if (memEQ(name, "__NR_getdents", 13)) {
    /*                       ^           */
#ifdef __NR_getdents
      *iv_return = __NR_getdents;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_readlink", 13)) {
    /*                       ^           */
#ifdef __NR_readlink
      *iv_return = __NR_readlink;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_sendmmsg", 13)) {
    /*                       ^           */
#ifdef __NR_sendmmsg
      *iv_return = __NR_sendmmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_oldstat", 13)) {
    /*                       ^           */
#ifdef __PNR_oldstat
      *iv_return = __PNR_oldstat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__PNR_eventfd", 13)) {
    /*                       ^           */
#ifdef __PNR_eventfd
      *iv_return = __PNR_eventfd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_vserver", 13)) {
    /*                       ^           */
#ifdef __PNR_vserver
      *iv_return = __PNR_vserver;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__NR_oldfstat", 13)) {
    /*                       ^           */
#ifdef __NR_oldfstat
      *iv_return = __NR_oldfstat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_bdflush", 13)) {
    /*                       ^           */
#ifdef __PNR_bdflush
      *iv_return = __PNR_bdflush;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__NR_getgid32", 13)) {
    /*                       ^           */
#ifdef __NR_getgid32
      *iv_return = __NR_getgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_setgid32", 13)) {
    /*                       ^           */
#ifdef __NR_setgid32
      *iv_return = __NR_setgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'h':
    if (memEQ(name, "__NR_cachectl", 13)) {
    /*                       ^           */
#ifdef __NR_cachectl
      *iv_return = __NR_cachectl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__PNR_waitpid", 13)) {
    /*                       ^           */
#ifdef __PNR_waitpid
      *iv_return = __PNR_waitpid;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__NR_oldlstat", 13)) {
    /*                       ^           */
#ifdef __NR_oldlstat
      *iv_return = __NR_oldlstat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR__llseek", 13)) {
    /*                       ^           */
#ifdef __PNR__llseek
      *iv_return = __PNR__llseek;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__PNR_symlink", 13)) {
    /*                       ^           */
#ifdef __PNR_symlink
      *iv_return = __PNR_symlink;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_timerfd", 13)) {
    /*                       ^           */
#ifdef __PNR_timerfd
      *iv_return = __PNR_timerfd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__NR_signalfd", 13)) {
    /*                       ^           */
#ifdef __NR_signalfd
      *iv_return = __NR_signalfd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_connect", 13)) {
    /*                       ^           */
#ifdef __PNR_connect
      *iv_return = __PNR_connect;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_fcntl64", 13)) {
    /*                       ^           */
#ifdef __PNR_fcntl64
      *iv_return = __PNR_fcntl64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_sendmsg", 13)) {
    /*                       ^           */
#ifdef __PNR_sendmsg
      *iv_return = __PNR_sendmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "__NR_fchown32", 13)) {
    /*                       ^           */
#ifdef __NR_fchown32
      *iv_return = __NR_fchown32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_lchown32", 13)) {
    /*                       ^           */
#ifdef __NR_lchown32
      *iv_return = __NR_lchown32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_chown32", 13)) {
    /*                       ^           */
#ifdef __PNR_chown32
      *iv_return = __PNR_chown32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__PNR_syscall", 13)) {
    /*                       ^           */
#ifdef __PNR_syscall
      *iv_return = __PNR_syscall;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_sysmips", 13)) {
    /*                       ^           */
#ifdef __PNR_sysmips
      *iv_return = __PNR_sysmips;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__NR_sgetmask", 13)) {
    /*                       ^           */
#ifdef __NR_sgetmask
      *iv_return = __NR_sgetmask;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_shutdown", 13)) {
    /*                       ^           */
#ifdef __NR_shutdown
      *iv_return = __NR_shutdown;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_ssetmask", 13)) {
    /*                       ^           */
#ifdef __NR_ssetmask
      *iv_return = __NR_ssetmask;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_statfs64", 13)) {
    /*                       ^           */
#ifdef __NR_statfs64
      *iv_return = __NR_statfs64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_fstat64", 13)) {
    /*                       ^           */
#ifdef __PNR_fstat64
      *iv_return = __PNR_fstat64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getpgrp", 13)) {
    /*                       ^           */
#ifdef __PNR_getpgrp
      *iv_return = __PNR_getpgrp;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getpmsg", 13)) {
    /*                       ^           */
#ifdef __PNR_getpmsg
      *iv_return = __PNR_getpmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_lstat64", 13)) {
    /*                       ^           */
#ifdef __PNR_lstat64
      *iv_return = __PNR_lstat64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_putpmsg", 13)) {
    /*                       ^           */
#ifdef __PNR_putpmsg
      *iv_return = __PNR_putpmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_set_tls", 13)) {
    /*                       ^           */
#ifdef __PNR_set_tls
      *iv_return = __PNR_set_tls;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'u':
    if (memEQ(name, "__NR_getuid32", 13)) {
    /*                       ^           */
#ifdef __NR_getuid32
      *iv_return = __NR_getuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_olduname", 13)) {
    /*                       ^           */
#ifdef __NR_olduname
      *iv_return = __NR_olduname;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_security", 13)) {
    /*                       ^           */
#ifdef __NR_security
      *iv_return = __NR_security;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_setuid32", 13)) {
    /*                       ^           */
#ifdef __NR_setuid32
      *iv_return = __NR_setuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_spu_run", 13)) {
    /*                       ^           */
#ifdef __PNR_spu_run
      *iv_return = __PNR_spu_run;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'v':
    if (memEQ(name, "__NR_recvfrom", 13)) {
    /*                       ^           */
#ifdef __NR_recvfrom
      *iv_return = __NR_recvfrom;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_recvmmsg", 13)) {
    /*                       ^           */
#ifdef __NR_recvmmsg
      *iv_return = __NR_recvmmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'w':
    if (memEQ(name, "__NR_oldwait4", 13)) {
    /*                       ^           */
#ifdef __NR_oldwait4
      *iv_return = __NR_oldwait4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'x':
    if (memEQ(name, "__PNR_tuxcall", 13)) {
    /*                       ^           */
#ifdef __PNR_tuxcall
      *iv_return = __PNR_tuxcall;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'y':
    if (memEQ(name, "__PNR__sysctl", 13)) {
    /*                       ^           */
#ifdef __PNR__sysctl
      *iv_return = __PNR__sysctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SCMP_ACT_ALLOW SCMP_ARCH_MIPS SCMP_ARCH_S390 SCMP_VER_MAJOR SCMP_VER_MICRO
     SCMP_VER_MINOR __NR_fadvise64 __NR_fstatat64 __NR_fstatfs64 __NR_futimesat
     __NR_getegid32 __NR_geteuid32 __NR_getrandom __NR_getrlimit __NR_sigaction
     __NR_sigreturn __PNR_cachectl __PNR_fchown32 __PNR_getdents __PNR_getgid32
     __PNR_getuid32 __PNR_lchown32 __PNR_oldfstat __PNR_oldlstat __PNR_olduname
     __PNR_oldwait4 __PNR_readlink __PNR_recvfrom __PNR_recvmmsg __PNR_security
     __PNR_sendmmsg __PNR_setgid32 __PNR_setuid32 __PNR_sgetmask __PNR_shutdown
     __PNR_signalfd __PNR_ssetmask __PNR_statfs64 */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'A':
    if (memEQ(name, "SCMP_ACT_ALLOW", 14)) {
    /*                        ^           */
#ifdef SCMP_ACT_ALLOW
      *iv_return = SCMP_ACT_ALLOW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SCMP_VER_MAJOR", 14)) {
    /*                        ^           */
#ifdef SCMP_VER_MAJOR
      *iv_return = SCMP_VER_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SCMP_VER_MICRO", 14)) {
    /*                        ^           */
#ifdef SCMP_VER_MICRO
      *iv_return = SCMP_VER_MICRO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SCMP_VER_MINOR", 14)) {
    /*                        ^           */
#ifdef SCMP_VER_MINOR
      *iv_return = SCMP_VER_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "SCMP_ARCH_MIPS", 14)) {
    /*                        ^           */
#ifdef SCMP_ARCH_MIPS
      *iv_return = SCMP_ARCH_MIPS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SCMP_ARCH_S390", 14)) {
    /*                        ^           */
#ifdef SCMP_ARCH_S390
      *iv_return = SCMP_ARCH_S390;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "__NR_getrandom", 14)) {
    /*                        ^           */
#ifdef __NR_getrandom
      *iv_return = __NR_getrandom;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "__NR_sigaction", 14)) {
    /*                        ^           */
#ifdef __NR_sigaction
      *iv_return = __NR_sigaction;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'd':
    if (memEQ(name, "__PNR_getdents", 14)) {
    /*                        ^           */
#ifdef __PNR_getdents
      *iv_return = __PNR_getdents;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_readlink", 14)) {
    /*                        ^           */
#ifdef __PNR_readlink
      *iv_return = __PNR_readlink;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_sendmmsg", 14)) {
    /*                        ^           */
#ifdef __PNR_sendmmsg
      *iv_return = __PNR_sendmmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__NR_sigreturn", 14)) {
    /*                        ^           */
#ifdef __NR_sigreturn
      *iv_return = __NR_sigreturn;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__PNR_oldfstat", 14)) {
    /*                        ^           */
#ifdef __PNR_oldfstat
      *iv_return = __PNR_oldfstat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__NR_getegid32", 14)) {
    /*                        ^           */
#ifdef __NR_getegid32
      *iv_return = __NR_getegid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getgid32", 14)) {
    /*                        ^           */
#ifdef __PNR_getgid32
      *iv_return = __PNR_getgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setgid32", 14)) {
    /*                        ^           */
#ifdef __PNR_setgid32
      *iv_return = __PNR_setgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'h':
    if (memEQ(name, "__PNR_cachectl", 14)) {
    /*                        ^           */
#ifdef __PNR_cachectl
      *iv_return = __PNR_cachectl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__NR_fadvise64", 14)) {
    /*                        ^           */
#ifdef __NR_fadvise64
      *iv_return = __NR_fadvise64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__NR_getrlimit", 14)) {
    /*                        ^           */
#ifdef __NR_getrlimit
      *iv_return = __NR_getrlimit;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_oldlstat", 14)) {
    /*                        ^           */
#ifdef __PNR_oldlstat
      *iv_return = __PNR_oldlstat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__NR_futimesat", 14)) {
    /*                        ^           */
#ifdef __NR_futimesat
      *iv_return = __NR_futimesat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__PNR_signalfd", 14)) {
    /*                        ^           */
#ifdef __PNR_signalfd
      *iv_return = __PNR_signalfd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "__PNR_fchown32", 14)) {
    /*                        ^           */
#ifdef __PNR_fchown32
      *iv_return = __PNR_fchown32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_lchown32", 14)) {
    /*                        ^           */
#ifdef __PNR_lchown32
      *iv_return = __PNR_lchown32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__NR_fstatat64", 14)) {
    /*                        ^           */
#ifdef __NR_fstatat64
      *iv_return = __NR_fstatat64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_fstatfs64", 14)) {
    /*                        ^           */
#ifdef __NR_fstatfs64
      *iv_return = __NR_fstatfs64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_sgetmask", 14)) {
    /*                        ^           */
#ifdef __PNR_sgetmask
      *iv_return = __PNR_sgetmask;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_shutdown", 14)) {
    /*                        ^           */
#ifdef __PNR_shutdown
      *iv_return = __PNR_shutdown;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_ssetmask", 14)) {
    /*                        ^           */
#ifdef __PNR_ssetmask
      *iv_return = __PNR_ssetmask;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_statfs64", 14)) {
    /*                        ^           */
#ifdef __PNR_statfs64
      *iv_return = __PNR_statfs64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'u':
    if (memEQ(name, "__NR_geteuid32", 14)) {
    /*                        ^           */
#ifdef __NR_geteuid32
      *iv_return = __NR_geteuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getuid32", 14)) {
    /*                        ^           */
#ifdef __PNR_getuid32
      *iv_return = __PNR_getuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_olduname", 14)) {
    /*                        ^           */
#ifdef __PNR_olduname
      *iv_return = __PNR_olduname;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_security", 14)) {
    /*                        ^           */
#ifdef __PNR_security
      *iv_return = __PNR_security;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setuid32", 14)) {
    /*                        ^           */
#ifdef __PNR_setuid32
      *iv_return = __PNR_setuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'v':
    if (memEQ(name, "__PNR_recvfrom", 14)) {
    /*                        ^           */
#ifdef __PNR_recvfrom
      *iv_return = __PNR_recvfrom;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_recvmmsg", 14)) {
    /*                        ^           */
#ifdef __PNR_recvmmsg
      *iv_return = __PNR_recvmmsg;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'w':
    if (memEQ(name, "__PNR_oldwait4", 14)) {
    /*                        ^           */
#ifdef __PNR_oldwait4
      *iv_return = __PNR_oldwait4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_15 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AUDIT_ARCH_MIPS SCMP_ARCH_PPC64 SCMP_ARCH_S390X __NR_SCMP_ERROR
     __NR_SCMP_UNDEF __NR__newselect __NR_arch_prctl __NR_breakpoint
     __NR_cacheflush __NR_epoll_wait __NR_getsockopt __NR_membarrier
     __NR_modify_ldt __NR_move_pages __NR_newfstatat __NR_nfsservctl
     __NR_semtimedop __NR_sendfile64 __NR_setfsgid32 __NR_setfsuid32
     __NR_setregid32 __NR_setreuid32 __NR_setsockopt __NR_sigpending
     __NR_sigsuspend __NR_socketcall __NR_socketpair __NR_spu_create
     __NR_truncate64 __NR_ugetrlimit __PNR_fadvise64 __PNR_fstatat64
     __PNR_fstatfs64 __PNR_futimesat __PNR_getegid32 __PNR_geteuid32
     __PNR_getrandom __PNR_getrlimit __PNR_sigaction __PNR_sigreturn */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'E':
    if (memEQ(name, "__NR_SCMP_ERROR", 15)) {
    /*                         ^           */
#ifdef __NR_SCMP_ERROR
      *iv_return = __NR_SCMP_ERROR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "SCMP_ARCH_PPC64", 15)) {
    /*                         ^           */
#ifdef SCMP_ARCH_PPC64
      *iv_return = SCMP_ARCH_PPC64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "SCMP_ARCH_S390X", 15)) {
    /*                         ^           */
#ifdef SCMP_ARCH_S390X
      *iv_return = SCMP_ARCH_S390X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "__NR_SCMP_UNDEF", 15)) {
    /*                         ^           */
#ifdef __NR_SCMP_UNDEF
      *iv_return = __NR_SCMP_UNDEF;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "AUDIT_ARCH_MIPS", 15)) {
    /*                         ^           */
#ifdef AUDIT_ARCH_MIPS
      *iv_return = AUDIT_ARCH_MIPS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_epoll_wait", 15)) {
    /*                         ^           */
#ifdef __NR_epoll_wait
      *iv_return = __NR_epoll_wait;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "__NR_truncate64", 15)) {
    /*                         ^           */
#ifdef __NR_truncate64
      *iv_return = __NR_truncate64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getrandom", 15)) {
    /*                         ^           */
#ifdef __PNR_getrandom
      *iv_return = __PNR_getrandom;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "__NR_getsockopt", 15)) {
    /*                         ^           */
#ifdef __NR_getsockopt
      *iv_return = __NR_getsockopt;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_setsockopt", 15)) {
    /*                         ^           */
#ifdef __NR_setsockopt
      *iv_return = __NR_setsockopt;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_sigaction", 15)) {
    /*                         ^           */
#ifdef __PNR_sigaction
      *iv_return = __PNR_sigaction;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__NR__newselect", 15)) {
    /*                         ^           */
#ifdef __NR__newselect
      *iv_return = __NR__newselect;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_sigreturn", 15)) {
    /*                         ^           */
#ifdef __PNR_sigreturn
      *iv_return = __PNR_sigreturn;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__NR_cacheflush", 15)) {
    /*                         ^           */
#ifdef __NR_cacheflush
      *iv_return = __NR_cacheflush;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__NR_setfsgid32", 15)) {
    /*                         ^           */
#ifdef __NR_setfsgid32
      *iv_return = __NR_setfsgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_setregid32", 15)) {
    /*                         ^           */
#ifdef __NR_setregid32
      *iv_return = __NR_setregid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getegid32", 15)) {
    /*                         ^           */
#ifdef __PNR_getegid32
      *iv_return = __PNR_getegid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__NR_sendfile64", 15)) {
    /*                         ^           */
#ifdef __NR_sendfile64
      *iv_return = __NR_sendfile64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_fadvise64", 15)) {
    /*                         ^           */
#ifdef __PNR_fadvise64
      *iv_return = __PNR_fadvise64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__NR_ugetrlimit", 15)) {
    /*                         ^           */
#ifdef __NR_ugetrlimit
      *iv_return = __NR_ugetrlimit;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getrlimit", 15)) {
    /*                         ^           */
#ifdef __PNR_getrlimit
      *iv_return = __PNR_getrlimit;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__NR_semtimedop", 15)) {
    /*                         ^           */
#ifdef __NR_semtimedop
      *iv_return = __NR_semtimedop;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_futimesat", 15)) {
    /*                         ^           */
#ifdef __PNR_futimesat
      *iv_return = __PNR_futimesat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__NR_sigpending", 15)) {
    /*                         ^           */
#ifdef __NR_sigpending
      *iv_return = __NR_sigpending;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "__NR_arch_prctl", 15)) {
    /*                         ^           */
#ifdef __NR_arch_prctl
      *iv_return = __NR_arch_prctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_breakpoint", 15)) {
    /*                         ^           */
#ifdef __NR_breakpoint
      *iv_return = __NR_breakpoint;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_move_pages", 15)) {
    /*                         ^           */
#ifdef __NR_move_pages
      *iv_return = __NR_move_pages;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "__NR_membarrier", 15)) {
    /*                         ^           */
#ifdef __NR_membarrier
      *iv_return = __NR_membarrier;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_nfsservctl", 15)) {
    /*                         ^           */
#ifdef __NR_nfsservctl
      *iv_return = __NR_nfsservctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_spu_create", 15)) {
    /*                         ^           */
#ifdef __NR_spu_create
      *iv_return = __NR_spu_create;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__NR_sigsuspend", 15)) {
    /*                         ^           */
#ifdef __NR_sigsuspend
      *iv_return = __NR_sigsuspend;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__NR_newfstatat", 15)) {
    /*                         ^           */
#ifdef __NR_newfstatat
      *iv_return = __NR_newfstatat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_socketcall", 15)) {
    /*                         ^           */
#ifdef __NR_socketcall
      *iv_return = __NR_socketcall;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_socketpair", 15)) {
    /*                         ^           */
#ifdef __NR_socketpair
      *iv_return = __NR_socketpair;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_fstatat64", 15)) {
    /*                         ^           */
#ifdef __PNR_fstatat64
      *iv_return = __PNR_fstatat64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_fstatfs64", 15)) {
    /*                         ^           */
#ifdef __PNR_fstatfs64
      *iv_return = __PNR_fstatfs64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'u':
    if (memEQ(name, "__NR_setfsuid32", 15)) {
    /*                         ^           */
#ifdef __NR_setfsuid32
      *iv_return = __NR_setfsuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_setreuid32", 15)) {
    /*                         ^           */
#ifdef __NR_setreuid32
      *iv_return = __NR_setreuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_geteuid32", 15)) {
    /*                         ^           */
#ifdef __PNR_geteuid32
      *iv_return = __PNR_geteuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'y':
    if (memEQ(name, "__NR_modify_ldt", 15)) {
    /*                         ^           */
#ifdef __NR_modify_ldt
      *iv_return = __NR_modify_ldt;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SCMP_ARCH_MIPS64 SCMP_ARCH_MIPSEL SCMP_ARCH_NATIVE SCMP_ARCH_X86_64
     _SCMP_FLTATR_MAX _SCMP_FLTATR_MIN __NR_afs_syscall __NR_ftruncate64
     __NR_getgroups32 __NR_getpeername __NR_getresgid32 __NR_getresuid32
     __NR_getsockname __NR_multiplexer __NR_oldolduname __NR_setgroups32
     __NR_setresgid32 __NR_setresuid32 __NR_sigprocmask __NR_swapcontext
     __NR_userfaultfd __PNR__newselect __PNR_arch_prctl __PNR_breakpoint
     __PNR_cacheflush __PNR_epoll_wait __PNR_getsockopt __PNR_membarrier
     __PNR_modify_ldt __PNR_move_pages __PNR_newfstatat __PNR_nfsservctl
     __PNR_semtimedop __PNR_sendfile64 __PNR_setfsgid32 __PNR_setfsuid32
     __PNR_setregid32 __PNR_setreuid32 __PNR_setsockopt __PNR_sigpending
     __PNR_sigsuspend __PNR_socketcall __PNR_socketpair __PNR_spu_create
     __PNR_truncate64 __PNR_ugetrlimit */
  /* Offset 11 gives the best switch position.  */
  switch (name[11]) {
  case '8':
    if (memEQ(name, "SCMP_ARCH_X86_64", 16)) {
    /*                          ^           */
#ifdef SCMP_ARCH_X86_64
      *iv_return = SCMP_ARCH_X86_64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "SCMP_ARCH_NATIVE", 16)) {
    /*                          ^           */
#ifdef SCMP_ARCH_NATIVE
      *iv_return = SCMP_ARCH_NATIVE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "SCMP_ARCH_MIPS64", 16)) {
    /*                          ^           */
#ifdef SCMP_ARCH_MIPS64
      *iv_return = SCMP_ARCH_MIPS64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "SCMP_ARCH_MIPSEL", 16)) {
    /*                          ^           */
#ifdef SCMP_ARCH_MIPSEL
      *iv_return = SCMP_ARCH_MIPSEL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "_SCMP_FLTATR_MAX", 16)) {
    /*                          ^           */
      *iv_return = _SCMP_FLTATR_MAX;
      return PERL_constant_ISIV;
    }
    if (memEQ(name, "_SCMP_FLTATR_MIN", 16)) {
    /*                          ^           */
      *iv_return = _SCMP_FLTATR_MIN;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "__PNR_epoll_wait", 16)) {
    /*                          ^           */
#ifdef __PNR_epoll_wait
      *iv_return = __PNR_epoll_wait;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "__NR_ftruncate64", 16)) {
    /*                          ^           */
#ifdef __NR_ftruncate64
      *iv_return = __NR_ftruncate64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_truncate64", 16)) {
    /*                          ^           */
#ifdef __PNR_truncate64
      *iv_return = __PNR_truncate64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "__NR_sigprocmask", 16)) {
    /*                          ^           */
#ifdef __NR_sigprocmask
      *iv_return = __NR_sigprocmask;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getsockopt", 16)) {
    /*                          ^           */
#ifdef __PNR_getsockopt
      *iv_return = __PNR_getsockopt;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setsockopt", 16)) {
    /*                          ^           */
#ifdef __PNR_setsockopt
      *iv_return = __PNR_setsockopt;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__PNR__newselect", 16)) {
    /*                          ^           */
#ifdef __PNR__newselect
      *iv_return = __PNR__newselect;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__PNR_cacheflush", 16)) {
    /*                          ^           */
#ifdef __PNR_cacheflush
      *iv_return = __PNR_cacheflush;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__NR_getresgid32", 16)) {
    /*                          ^           */
#ifdef __NR_getresgid32
      *iv_return = __NR_getresgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_setresgid32", 16)) {
    /*                          ^           */
#ifdef __NR_setresgid32
      *iv_return = __NR_setresgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setfsgid32", 16)) {
    /*                          ^           */
#ifdef __PNR_setfsgid32
      *iv_return = __PNR_setfsgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setregid32", 16)) {
    /*                          ^           */
#ifdef __PNR_setregid32
      *iv_return = __PNR_setregid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__PNR_sendfile64", 16)) {
    /*                          ^           */
#ifdef __PNR_sendfile64
      *iv_return = __PNR_sendfile64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'k':
    if (memEQ(name, "__NR_getsockname", 16)) {
    /*                          ^           */
#ifdef __NR_getsockname
      *iv_return = __NR_getsockname;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__NR_multiplexer", 16)) {
    /*                          ^           */
#ifdef __NR_multiplexer
      *iv_return = __NR_multiplexer;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_ugetrlimit", 16)) {
    /*                          ^           */
#ifdef __PNR_ugetrlimit
      *iv_return = __PNR_ugetrlimit;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__PNR_semtimedop", 16)) {
    /*                          ^           */
#ifdef __PNR_semtimedop
      *iv_return = __PNR_semtimedop;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__NR_swapcontext", 16)) {
    /*                          ^           */
#ifdef __NR_swapcontext
      *iv_return = __NR_swapcontext;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_sigpending", 16)) {
    /*                          ^           */
#ifdef __PNR_sigpending
      *iv_return = __PNR_sigpending;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "__PNR_arch_prctl", 16)) {
    /*                          ^           */
#ifdef __PNR_arch_prctl
      *iv_return = __PNR_arch_prctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_breakpoint", 16)) {
    /*                          ^           */
#ifdef __PNR_breakpoint
      *iv_return = __PNR_breakpoint;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_move_pages", 16)) {
    /*                          ^           */
#ifdef __PNR_move_pages
      *iv_return = __PNR_move_pages;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "__NR_getpeername", 16)) {
    /*                          ^           */
#ifdef __NR_getpeername
      *iv_return = __NR_getpeername;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_membarrier", 16)) {
    /*                          ^           */
#ifdef __PNR_membarrier
      *iv_return = __PNR_membarrier;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_nfsservctl", 16)) {
    /*                          ^           */
#ifdef __PNR_nfsservctl
      *iv_return = __PNR_nfsservctl;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_spu_create", 16)) {
    /*                          ^           */
#ifdef __PNR_spu_create
      *iv_return = __PNR_spu_create;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__NR_afs_syscall", 16)) {
    /*                          ^           */
#ifdef __NR_afs_syscall
      *iv_return = __NR_afs_syscall;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_sigsuspend", 16)) {
    /*                          ^           */
#ifdef __PNR_sigsuspend
      *iv_return = __PNR_sigsuspend;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__PNR_newfstatat", 16)) {
    /*                          ^           */
#ifdef __PNR_newfstatat
      *iv_return = __PNR_newfstatat;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_socketcall", 16)) {
    /*                          ^           */
#ifdef __PNR_socketcall
      *iv_return = __PNR_socketcall;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_socketpair", 16)) {
    /*                          ^           */
#ifdef __PNR_socketpair
      *iv_return = __PNR_socketpair;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'u':
    if (memEQ(name, "__NR_getgroups32", 16)) {
    /*                          ^           */
#ifdef __NR_getgroups32
      *iv_return = __NR_getgroups32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_getresuid32", 16)) {
    /*                          ^           */
#ifdef __NR_getresuid32
      *iv_return = __NR_getresuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_oldolduname", 16)) {
    /*                          ^           */
#ifdef __NR_oldolduname
      *iv_return = __NR_oldolduname;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_setgroups32", 16)) {
    /*                          ^           */
#ifdef __NR_setgroups32
      *iv_return = __NR_setgroups32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_setresuid32", 16)) {
    /*                          ^           */
#ifdef __NR_setresuid32
      *iv_return = __NR_setresuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_userfaultfd", 16)) {
    /*                          ^           */
#ifdef __NR_userfaultfd
      *iv_return = __NR_userfaultfd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setfsuid32", 16)) {
    /*                          ^           */
#ifdef __PNR_setfsuid32
      *iv_return = __PNR_setfsuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setreuid32", 16)) {
    /*                          ^           */
#ifdef __PNR_setreuid32
      *iv_return = __PNR_setreuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'y':
    if (memEQ(name, "__PNR_modify_ldt", 16)) {
    /*                          ^           */
#ifdef __PNR_modify_ldt
      *iv_return = __PNR_modify_ldt;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AUDIT_ARCH_MIPS64 SCMP_ARCH_AARCH64 SCMP_ARCH_PPC64LE __NR_epoll_create
     __NR_fadvise64_64 __NR_inotify_init __NR_memfd_create __NR_query_module
     __NR_subpage_prot __PNR_afs_syscall __PNR_ftruncate64 __PNR_getgroups32
     __PNR_getpeername __PNR_getresgid32 __PNR_getresuid32 __PNR_getsockname
     __PNR_multiplexer __PNR_oldolduname __PNR_setgroups32 __PNR_setresgid32
     __PNR_setresuid32 __PNR_sigprocmask __PNR_swapcontext __PNR_userfaultfd */
  /* Offset 12 gives the best switch position.  */
  switch (name[12]) {
  case '6':
    if (memEQ(name, "__NR_fadvise64_64", 17)) {
    /*                           ^           */
#ifdef __NR_fadvise64_64
      *iv_return = __NR_fadvise64_64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "SCMP_ARCH_PPC64LE", 17)) {
    /*                           ^           */
#ifdef SCMP_ARCH_PPC64LE
      *iv_return = SCMP_ARCH_PPC64LE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "AUDIT_ARCH_MIPS64", 17)) {
    /*                           ^           */
#ifdef AUDIT_ARCH_MIPS64
      *iv_return = AUDIT_ARCH_MIPS64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SCMP_ARCH_AARCH64", 17)) {
    /*                           ^           */
#ifdef SCMP_ARCH_AARCH64
      *iv_return = SCMP_ARCH_AARCH64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "__NR_inotify_init", 17)) {
    /*                           ^           */
#ifdef __NR_inotify_init
      *iv_return = __NR_inotify_init;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_subpage_prot", 17)) {
    /*                           ^           */
#ifdef __NR_subpage_prot
      *iv_return = __NR_subpage_prot;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "__PNR_ftruncate64", 17)) {
    /*                           ^           */
#ifdef __PNR_ftruncate64
      *iv_return = __PNR_ftruncate64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "__PNR_sigprocmask", 17)) {
    /*                           ^           */
#ifdef __PNR_sigprocmask
      *iv_return = __PNR_sigprocmask;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__PNR_getresgid32", 17)) {
    /*                           ^           */
#ifdef __PNR_getresgid32
      *iv_return = __PNR_getresgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setresgid32", 17)) {
    /*                           ^           */
#ifdef __PNR_setresgid32
      *iv_return = __PNR_setresgid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'k':
    if (memEQ(name, "__PNR_getsockname", 17)) {
    /*                           ^           */
#ifdef __PNR_getsockname
      *iv_return = __PNR_getsockname;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__PNR_multiplexer", 17)) {
    /*                           ^           */
#ifdef __PNR_multiplexer
      *iv_return = __PNR_multiplexer;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__PNR_swapcontext", 17)) {
    /*                           ^           */
#ifdef __PNR_swapcontext
      *iv_return = __PNR_swapcontext;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "__NR_query_module", 17)) {
    /*                           ^           */
#ifdef __NR_query_module
      *iv_return = __NR_query_module;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "__NR_epoll_create", 17)) {
    /*                           ^           */
#ifdef __NR_epoll_create
      *iv_return = __NR_epoll_create;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_memfd_create", 17)) {
    /*                           ^           */
#ifdef __NR_memfd_create
      *iv_return = __NR_memfd_create;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getpeername", 17)) {
    /*                           ^           */
#ifdef __PNR_getpeername
      *iv_return = __PNR_getpeername;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__PNR_afs_syscall", 17)) {
    /*                           ^           */
#ifdef __PNR_afs_syscall
      *iv_return = __PNR_afs_syscall;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'u':
    if (memEQ(name, "__PNR_getgroups32", 17)) {
    /*                           ^           */
#ifdef __PNR_getgroups32
      *iv_return = __PNR_getgroups32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_getresuid32", 17)) {
    /*                           ^           */
#ifdef __PNR_getresuid32
      *iv_return = __PNR_getresuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_oldolduname", 17)) {
    /*                           ^           */
#ifdef __PNR_oldolduname
      *iv_return = __PNR_oldolduname;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setgroups32", 17)) {
    /*                           ^           */
#ifdef __PNR_setgroups32
      *iv_return = __PNR_setgroups32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_setresuid32", 17)) {
    /*                           ^           */
#ifdef __PNR_setresuid32
      *iv_return = __PNR_setresuid32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_userfaultfd", 17)) {
    /*                           ^           */
#ifdef __PNR_userfaultfd
      *iv_return = __PNR_userfaultfd;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AUDIT_ARCH_AARCH64 AUDIT_ARCH_PPC64LE SCMP_ARCH_MIPSEL64
     SCMP_CMP_MASKED_EQ __NR_create_module __NR_epoll_ctl_old
     __NR_get_mempolicy __NR_migrate_pages __NR_set_mempolicy
     __NR_switch_endian __PNR_epoll_create __PNR_fadvise64_64
     __PNR_inotify_init __PNR_memfd_create __PNR_query_module
     __PNR_subpage_prot */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'H':
    if (memEQ(name, "AUDIT_ARCH_AARCH64", 18)) {
    /*                        ^               */
#ifdef AUDIT_ARCH_AARCH64
      *iv_return = AUDIT_ARCH_AARCH64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "AUDIT_ARCH_PPC64LE", 18)) {
    /*                        ^               */
#ifdef AUDIT_ARCH_PPC64LE
      *iv_return = AUDIT_ARCH_PPC64LE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "SCMP_CMP_MASKED_EQ", 18)) {
    /*                        ^               */
      *iv_return = SCMP_CMP_MASKED_EQ;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "SCMP_ARCH_MIPSEL64", 18)) {
    /*                        ^               */
#ifdef SCMP_ARCH_MIPSEL64
      *iv_return = SCMP_ARCH_MIPSEL64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "__NR_migrate_pages", 18)) {
    /*                        ^               */
#ifdef __NR_migrate_pages
      *iv_return = __NR_migrate_pages;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "__NR_switch_endian", 18)) {
    /*                        ^               */
#ifdef __NR_switch_endian
      *iv_return = __NR_switch_endian;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__PNR_memfd_create", 18)) {
    /*                        ^               */
#ifdef __PNR_memfd_create
      *iv_return = __PNR_memfd_create;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__NR_epoll_ctl_old", 18)) {
    /*                        ^               */
#ifdef __NR_epoll_ctl_old
      *iv_return = __NR_epoll_ctl_old;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_epoll_create", 18)) {
    /*                        ^               */
#ifdef __PNR_epoll_create
      *iv_return = __PNR_epoll_create;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__NR_get_mempolicy", 18)) {
    /*                        ^               */
#ifdef __NR_get_mempolicy
      *iv_return = __NR_get_mempolicy;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_set_mempolicy", 18)) {
    /*                        ^               */
#ifdef __NR_set_mempolicy
      *iv_return = __NR_set_mempolicy;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "__PNR_subpage_prot", 18)) {
    /*                        ^               */
#ifdef __PNR_subpage_prot
      *iv_return = __PNR_subpage_prot;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'r':
    if (memEQ(name, "__PNR_query_module", 18)) {
    /*                        ^               */
#ifdef __PNR_query_module
      *iv_return = __PNR_query_module;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__NR_create_module", 18)) {
    /*                        ^               */
#ifdef __NR_create_module
      *iv_return = __NR_create_module;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_inotify_init", 18)) {
    /*                        ^               */
#ifdef __PNR_inotify_init
      *iv_return = __PNR_inotify_init;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'v':
    if (memEQ(name, "__PNR_fadvise64_64", 18)) {
    /*                        ^               */
#ifdef __PNR_fadvise64_64
      *iv_return = __PNR_fadvise64_64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_19 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SCMP_ARCH_MIPS64N32 SCMP_FLTATR_CTL_NNP __NR_epoll_wait_old
     __NR_pciconfig_read __PNR_create_module __PNR_epoll_ctl_old
     __PNR_get_mempolicy __PNR_migrate_pages __PNR_set_mempolicy
     __PNR_switch_endian */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'S':
    if (memEQ(name, "SCMP_ARCH_MIPS64N32", 19)) {
    /*                            ^            */
#ifdef SCMP_ARCH_MIPS64N32
      *iv_return = SCMP_ARCH_MIPS64N32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "SCMP_FLTATR_CTL_NNP", 19)) {
    /*                            ^            */
      *iv_return = SCMP_FLTATR_CTL_NNP;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "__PNR_migrate_pages", 19)) {
    /*                            ^            */
#ifdef __PNR_migrate_pages
      *iv_return = __PNR_migrate_pages;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__PNR_switch_endian", 19)) {
    /*                            ^            */
#ifdef __PNR_switch_endian
      *iv_return = __PNR_switch_endian;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__NR_pciconfig_read", 19)) {
    /*                            ^            */
#ifdef __NR_pciconfig_read
      *iv_return = __NR_pciconfig_read;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__NR_epoll_wait_old", 19)) {
    /*                            ^            */
#ifdef __NR_epoll_wait_old
      *iv_return = __NR_epoll_wait_old;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'm':
    if (memEQ(name, "__PNR_create_module", 19)) {
    /*                            ^            */
#ifdef __PNR_create_module
      *iv_return = __PNR_create_module;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'p':
    if (memEQ(name, "__PNR_get_mempolicy", 19)) {
    /*                            ^            */
#ifdef __PNR_get_mempolicy
      *iv_return = __PNR_get_mempolicy;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_set_mempolicy", 19)) {
    /*                            ^            */
#ifdef __PNR_set_mempolicy
      *iv_return = __PNR_set_mempolicy;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__PNR_epoll_ctl_old", 19)) {
    /*                            ^            */
#ifdef __PNR_epoll_ctl_old
      *iv_return = __PNR_epoll_ctl_old;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_20 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AUDIT_ARCH_MIPS64N32 __NR_get_kernel_syms __NR_get_thread_area
     __NR_kexec_file_load __NR_pciconfig_write __NR_set_thread_area
     __NR_sync_file_range __PNR_epoll_wait_old __PNR_pciconfig_read */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case '_':
    if (memEQ(name, "AUDIT_ARCH_MIPS64N32", 20)) {
    /*                         ^                */
#ifdef AUDIT_ARCH_MIPS64N32
      *iv_return = AUDIT_ARCH_MIPS64N32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_kexec_file_load", 20)) {
    /*                         ^                */
#ifdef __NR_kexec_file_load
      *iv_return = __NR_kexec_file_load;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__NR_get_kernel_syms", 20)) {
    /*                         ^                */
#ifdef __NR_get_kernel_syms
      *iv_return = __NR_get_kernel_syms;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__NR_sync_file_range", 20)) {
    /*                         ^                */
#ifdef __NR_sync_file_range
      *iv_return = __NR_sync_file_range;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'h':
    if (memEQ(name, "__NR_get_thread_area", 20)) {
    /*                         ^                */
#ifdef __NR_get_thread_area
      *iv_return = __NR_get_thread_area;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__NR_set_thread_area", 20)) {
    /*                         ^                */
#ifdef __NR_set_thread_area
      *iv_return = __NR_set_thread_area;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'l':
    if (memEQ(name, "__PNR_epoll_wait_old", 20)) {
    /*                         ^                */
#ifdef __PNR_epoll_wait_old
      *iv_return = __PNR_epoll_wait_old;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__NR_pciconfig_write", 20)) {
    /*                         ^                */
#ifdef __NR_pciconfig_write
      *iv_return = __NR_pciconfig_write;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "__PNR_pciconfig_read", 20)) {
    /*                         ^                */
#ifdef __PNR_pciconfig_read
      *iv_return = __PNR_pciconfig_read;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_21 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SCMP_ARCH_MIPSEL64N32 SCMP_FLTATR_CTL_TSYNC __NR_arm_fadvise64_64
     __NR_pciconfig_iobase __NR_sync_file_range2 __PNR_get_kernel_syms
     __PNR_get_thread_area __PNR_kexec_file_load __PNR_pciconfig_write
     __PNR_set_thread_area __PNR_sync_file_range */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'M':
    if (memEQ(name, "SCMP_ARCH_MIPSEL64N32", 21)) {
    /*                         ^                 */
#ifdef SCMP_ARCH_MIPSEL64N32
      *iv_return = SCMP_ARCH_MIPSEL64N32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "SCMP_FLTATR_CTL_TSYNC", 21)) {
    /*                         ^                 */
      *iv_return = SCMP_FLTATR_CTL_TSYNC;
      return PERL_constant_ISIV;
    }
    break;
  case '_':
    if (memEQ(name, "__PNR_sync_file_range", 21)) {
    /*                         ^                 */
#ifdef __PNR_sync_file_range
      *iv_return = __PNR_sync_file_range;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'a':
    if (memEQ(name, "__NR_arm_fadvise64_64", 21)) {
    /*                         ^                 */
#ifdef __NR_arm_fadvise64_64
      *iv_return = __NR_arm_fadvise64_64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'c':
    if (memEQ(name, "__PNR_kexec_file_load", 21)) {
    /*                         ^                 */
#ifdef __PNR_kexec_file_load
      *iv_return = __PNR_kexec_file_load;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'f':
    if (memEQ(name, "__NR_sync_file_range2", 21)) {
    /*                         ^                 */
#ifdef __NR_sync_file_range2
      *iv_return = __NR_sync_file_range2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'k':
    if (memEQ(name, "__PNR_get_kernel_syms", 21)) {
    /*                         ^                 */
#ifdef __PNR_get_kernel_syms
      *iv_return = __PNR_get_kernel_syms;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__NR_pciconfig_iobase", 21)) {
    /*                         ^                 */
#ifdef __NR_pciconfig_iobase
      *iv_return = __NR_pciconfig_iobase;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'o':
    if (memEQ(name, "__PNR_pciconfig_write", 21)) {
    /*                         ^                 */
#ifdef __PNR_pciconfig_write
      *iv_return = __PNR_pciconfig_write;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 't':
    if (memEQ(name, "__PNR_get_thread_area", 21)) {
    /*                         ^                 */
#ifdef __PNR_get_thread_area
      *iv_return = __PNR_get_thread_area;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "__PNR_set_thread_area", 21)) {
    /*                         ^                 */
#ifdef __PNR_set_thread_area
      *iv_return = __PNR_set_thread_area;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_22 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     AUDIT_ARCH_MIPSEL64N32 __PNR_arm_fadvise64_64 __PNR_pciconfig_iobase
     __PNR_sync_file_range2 */
  /* Offset 14 gives the best switch position.  */
  switch (name[14]) {
  case 'S':
    if (memEQ(name, "AUDIT_ARCH_MIPSEL64N32", 22)) {
    /*                             ^              */
#ifdef AUDIT_ARCH_MIPSEL64N32
      *iv_return = AUDIT_ARCH_MIPSEL64N32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'e':
    if (memEQ(name, "__PNR_sync_file_range2", 22)) {
    /*                             ^              */
#ifdef __PNR_sync_file_range2
      *iv_return = __PNR_sync_file_range2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__PNR_pciconfig_iobase", 22)) {
    /*                             ^              */
#ifdef __PNR_pciconfig_iobase
      *iv_return = __PNR_pciconfig_iobase;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__PNR_arm_fadvise64_64", 22)) {
    /*                             ^              */
#ifdef __PNR_arm_fadvise64_64
      *iv_return = __PNR_arm_fadvise64_64;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_23 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     SCMP_FLTATR_ACT_BADARCH SCMP_FLTATR_ACT_DEFAULT __NR_s390_pci_mmio_read
     __NR_s390_runtime_instr */
  /* Offset 20 gives the best switch position.  */
  switch (name[20]) {
  case 'R':
    if (memEQ(name, "SCMP_FLTATR_ACT_BADARCH", 23)) {
    /*                                   ^         */
      *iv_return = SCMP_FLTATR_ACT_BADARCH;
      return PERL_constant_ISIV;
    }
    break;
  case 'U':
    if (memEQ(name, "SCMP_FLTATR_ACT_DEFAULT", 23)) {
    /*                                   ^         */
      *iv_return = SCMP_FLTATR_ACT_DEFAULT;
      return PERL_constant_ISIV;
    }
    break;
  case 'e':
    if (memEQ(name, "__NR_s390_pci_mmio_read", 23)) {
    /*                                   ^         */
#ifdef __NR_s390_pci_mmio_read
      *iv_return = __NR_s390_pci_mmio_read;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__NR_s390_runtime_instr", 23)) {
    /*                                   ^         */
#ifdef __NR_s390_runtime_instr
      *iv_return = __NR_s390_runtime_instr;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_24 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     __NR_arm_sync_file_range __NR_s390_pci_mmio_write __PNR_s390_pci_mmio_read
     __PNR_s390_runtime_instr */
  /* Offset 21 gives the best switch position.  */
  switch (name[21]) {
  case 'e':
    if (memEQ(name, "__PNR_s390_pci_mmio_read", 24)) {
    /*                                    ^         */
#ifdef __PNR_s390_pci_mmio_read
      *iv_return = __PNR_s390_pci_mmio_read;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__NR_s390_pci_mmio_write", 24)) {
    /*                                    ^         */
#ifdef __NR_s390_pci_mmio_write
      *iv_return = __NR_s390_pci_mmio_write;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'n':
    if (memEQ(name, "__NR_arm_sync_file_range", 24)) {
    /*                                    ^         */
#ifdef __NR_arm_sync_file_range
      *iv_return = __NR_arm_sync_file_range;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 's':
    if (memEQ(name, "__PNR_s390_runtime_instr", 24)) {
    /*                                    ^         */
#ifdef __PNR_s390_runtime_instr
      *iv_return = __PNR_s390_runtime_instr;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_25 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     __NR_sys_debug_setcontext __PNR_arm_sync_file_range
     __PNR_s390_pci_mmio_write */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'c':
    if (memEQ(name, "__PNR_arm_sync_file_range", 25)) {
    /*                            ^                  */
#ifdef __PNR_arm_sync_file_range
      *iv_return = __PNR_arm_sync_file_range;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'g':
    if (memEQ(name, "__NR_sys_debug_setcontext", 25)) {
    /*                            ^                  */
#ifdef __NR_sys_debug_setcontext
      *iv_return = __NR_sys_debug_setcontext;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'i':
    if (memEQ(name, "__PNR_s390_pci_mmio_write", 25)) {
    /*                            ^                  */
#ifdef __PNR_s390_pci_mmio_write
      *iv_return = __PNR_s390_pci_mmio_write;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(AUDIT_ARCH_AARCH64 AUDIT_ARCH_MIPS AUDIT_ARCH_MIPS64
	       AUDIT_ARCH_MIPS64N32 AUDIT_ARCH_MIPSEL64N32 AUDIT_ARCH_PPC64LE
	       EM_AARCH64 EM_MIPS SCMP_ACT_ALLOW SCMP_ACT_KILL SCMP_ACT_TRAP
	       SCMP_ARCH_AARCH64 SCMP_ARCH_ARM SCMP_ARCH_MIPS SCMP_ARCH_MIPS64
	       SCMP_ARCH_MIPS64N32 SCMP_ARCH_MIPSEL SCMP_ARCH_MIPSEL64
	       SCMP_ARCH_MIPSEL64N32 SCMP_ARCH_NATIVE SCMP_ARCH_PPC
	       SCMP_ARCH_PPC64 SCMP_ARCH_PPC64LE SCMP_ARCH_S390 SCMP_ARCH_S390X
	       SCMP_ARCH_X32 SCMP_ARCH_X86 SCMP_ARCH_X86_64 SCMP_VER_MAJOR
	       SCMP_VER_MICRO SCMP_VER_MINOR __AUDIT_ARCH_CONVENTION_MIPS64_N32
	       __NR_SCMP_ERROR __NR_SCMP_UNDEF __NR__llseek __NR__newselect
	       __NR__sysctl __NR_accept __NR_accept4 __NR_access
	       __NR_afs_syscall __NR_alarm __NR_arch_prctl
	       __NR_arm_fadvise64_64 __NR_arm_sync_file_range __NR_bdflush
	       __NR_bind __NR_break __NR_breakpoint __NR_cachectl
	       __NR_cacheflush __NR_chmod __NR_chown __NR_chown32 __NR_connect
	       __NR_creat __NR_create_module __NR_dup2 __NR_epoll_create
	       __NR_epoll_ctl_old __NR_epoll_wait __NR_epoll_wait_old
	       __NR_eventfd __NR_fadvise64 __NR_fadvise64_64 __NR_fchown32
	       __NR_fcntl64 __NR_fork __NR_fstat64 __NR_fstatat64
	       __NR_fstatfs64 __NR_ftime __NR_ftruncate64 __NR_futimesat
	       __NR_get_kernel_syms __NR_get_mempolicy __NR_get_thread_area
	       __NR_getdents __NR_getegid32 __NR_geteuid32 __NR_getgid32
	       __NR_getgroups32 __NR_getpeername __NR_getpgrp __NR_getpmsg
	       __NR_getrandom __NR_getresgid32 __NR_getresuid32 __NR_getrlimit
	       __NR_getsockname __NR_getsockopt __NR_getuid32 __NR_gtty
	       __NR_idle __NR_inotify_init __NR_ioperm __NR_iopl __NR_ipc
	       __NR_kexec_file_load __NR_lchown __NR_lchown32 __NR_link
	       __NR_listen __NR_lock __NR_lstat __NR_lstat64 __NR_mbind
	       __NR_membarrier __NR_memfd_create __NR_migrate_pages __NR_mkdir
	       __NR_mknod __NR_mmap __NR_mmap2 __NR_modify_ldt __NR_move_pages
	       __NR_mpx __NR_msgctl __NR_msgget __NR_msgrcv __NR_msgsnd
	       __NR_multiplexer __NR_newfstatat __NR_nfsservctl __NR_nice
	       __NR_oldfstat __NR_oldlstat __NR_oldolduname __NR_oldstat
	       __NR_olduname __NR_oldwait4 __NR_open __NR_pause
	       __NR_pciconfig_iobase __NR_pciconfig_read __NR_pciconfig_write
	       __NR_pipe __NR_poll __NR_prof __NR_profil __NR_putpmsg
	       __NR_query_module __NR_readdir __NR_readlink __NR_recv
	       __NR_recvfrom __NR_recvmmsg __NR_recvmsg __NR_rename __NR_rmdir
	       __NR_rtas __NR_s390_pci_mmio_read __NR_s390_pci_mmio_write
	       __NR_s390_runtime_instr __NR_security __NR_select __NR_semctl
	       __NR_semget __NR_semop __NR_semtimedop __NR_send __NR_sendfile64
	       __NR_sendmmsg __NR_sendmsg __NR_sendto __NR_set_mempolicy
	       __NR_set_thread_area __NR_set_tls __NR_setfsgid32
	       __NR_setfsuid32 __NR_setgid32 __NR_setgroups32 __NR_setregid32
	       __NR_setresgid32 __NR_setresuid32 __NR_setreuid32
	       __NR_setsockopt __NR_setuid32 __NR_sgetmask __NR_shmat
	       __NR_shmctl __NR_shmdt __NR_shmget __NR_shutdown __NR_sigaction
	       __NR_signal __NR_signalfd __NR_sigpending __NR_sigprocmask
	       __NR_sigreturn __NR_sigsuspend __NR_socket __NR_socketcall
	       __NR_socketpair __NR_spu_create __NR_spu_run __NR_ssetmask
	       __NR_stat __NR_stat64 __NR_statfs64 __NR_stime __NR_stty
	       __NR_subpage_prot __NR_swapcontext __NR_switch_endian
	       __NR_symlink __NR_sync_file_range __NR_sync_file_range2
	       __NR_sys_debug_setcontext __NR_syscall __NR_sysfs __NR_sysmips
	       __NR_time __NR_timerfd __NR_truncate64 __NR_tuxcall
	       __NR_ugetrlimit __NR_ulimit __NR_umount __NR_unlink __NR_uselib
	       __NR_userfaultfd __NR_usr26 __NR_usr32 __NR_ustat __NR_utime
	       __NR_utimes __NR_vfork __NR_vm86 __NR_vm86old __NR_vserver
	       __NR_waitpid __PNR__llseek __PNR__newselect __PNR__sysctl
	       __PNR_accept __PNR_accept4 __PNR_access __PNR_afs_syscall
	       __PNR_alarm __PNR_arch_prctl __PNR_arm_fadvise64_64
	       __PNR_arm_sync_file_range __PNR_bdflush __PNR_bind __PNR_break
	       __PNR_breakpoint __PNR_cachectl __PNR_cacheflush __PNR_chmod
	       __PNR_chown __PNR_chown32 __PNR_connect __PNR_creat
	       __PNR_create_module __PNR_dup2 __PNR_epoll_create
	       __PNR_epoll_ctl_old __PNR_epoll_wait __PNR_epoll_wait_old
	       __PNR_eventfd __PNR_fadvise64 __PNR_fadvise64_64 __PNR_fchown32
	       __PNR_fcntl64 __PNR_fork __PNR_fstat64 __PNR_fstatat64
	       __PNR_fstatfs64 __PNR_ftime __PNR_ftruncate64 __PNR_futimesat
	       __PNR_get_kernel_syms __PNR_get_mempolicy __PNR_get_thread_area
	       __PNR_getdents __PNR_getegid32 __PNR_geteuid32 __PNR_getgid32
	       __PNR_getgroups32 __PNR_getpeername __PNR_getpgrp __PNR_getpmsg
	       __PNR_getrandom __PNR_getresgid32 __PNR_getresuid32
	       __PNR_getrlimit __PNR_getsockname __PNR_getsockopt
	       __PNR_getuid32 __PNR_gtty __PNR_idle __PNR_inotify_init
	       __PNR_ioperm __PNR_iopl __PNR_ipc __PNR_kexec_file_load
	       __PNR_lchown __PNR_lchown32 __PNR_link __PNR_listen __PNR_lock
	       __PNR_lstat __PNR_lstat64 __PNR_mbind __PNR_membarrier
	       __PNR_memfd_create __PNR_migrate_pages __PNR_mkdir __PNR_mknod
	       __PNR_mmap __PNR_mmap2 __PNR_modify_ldt __PNR_move_pages
	       __PNR_mpx __PNR_msgctl __PNR_msgget __PNR_msgrcv __PNR_msgsnd
	       __PNR_multiplexer __PNR_newfstatat __PNR_nfsservctl __PNR_nice
	       __PNR_oldfstat __PNR_oldlstat __PNR_oldolduname __PNR_oldstat
	       __PNR_olduname __PNR_oldwait4 __PNR_open __PNR_pause
	       __PNR_pciconfig_iobase __PNR_pciconfig_read
	       __PNR_pciconfig_write __PNR_pipe __PNR_poll __PNR_prof
	       __PNR_profil __PNR_putpmsg __PNR_query_module __PNR_readdir
	       __PNR_readlink __PNR_recv __PNR_recvfrom __PNR_recvmmsg
	       __PNR_recvmsg __PNR_rename __PNR_rmdir __PNR_rtas
	       __PNR_s390_pci_mmio_read __PNR_s390_pci_mmio_write
	       __PNR_s390_runtime_instr __PNR_security __PNR_select
	       __PNR_semctl __PNR_semget __PNR_semop __PNR_semtimedop
	       __PNR_send __PNR_sendfile64 __PNR_sendmmsg __PNR_sendmsg
	       __PNR_sendto __PNR_set_mempolicy __PNR_set_thread_area
	       __PNR_set_tls __PNR_setfsgid32 __PNR_setfsuid32 __PNR_setgid32
	       __PNR_setgroups32 __PNR_setregid32 __PNR_setresgid32
	       __PNR_setresuid32 __PNR_setreuid32 __PNR_setsockopt
	       __PNR_setuid32 __PNR_sgetmask __PNR_shmat __PNR_shmctl
	       __PNR_shmdt __PNR_shmget __PNR_shutdown __PNR_sigaction
	       __PNR_signal __PNR_signalfd __PNR_sigpending __PNR_sigprocmask
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
            {name=>"SCMP_CMP_EQ", type=>"IV", macro=>"1"},
            {name=>"SCMP_CMP_GE", type=>"IV", macro=>"1"},
            {name=>"SCMP_CMP_GT", type=>"IV", macro=>"1"},
            {name=>"SCMP_CMP_LE", type=>"IV", macro=>"1"},
            {name=>"SCMP_CMP_LT", type=>"IV", macro=>"1"},
            {name=>"SCMP_CMP_MASKED_EQ", type=>"IV", macro=>"1"},
            {name=>"SCMP_CMP_NE", type=>"IV", macro=>"1"},
            {name=>"SCMP_FLTATR_ACT_BADARCH", type=>"IV", macro=>"1"},
            {name=>"SCMP_FLTATR_ACT_DEFAULT", type=>"IV", macro=>"1"},
            {name=>"SCMP_FLTATR_CTL_NNP", type=>"IV", macro=>"1"},
            {name=>"SCMP_FLTATR_CTL_TSYNC", type=>"IV", macro=>"1"},
            {name=>"_SCMP_CMP_MAX", type=>"IV", macro=>"1"},
            {name=>"_SCMP_CMP_MIN", type=>"IV", macro=>"1"},
            {name=>"_SCMP_FLTATR_MAX", type=>"IV", macro=>"1"},
            {name=>"_SCMP_FLTATR_MIN", type=>"IV", macro=>"1"});

print constant_types(), "\n"; # macro defs
foreach (C_constant ("Linux::Seccomp", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "\n#### XS Section:\n";
print XS_constant ("Linux::Seccomp", $types);
__END__
   */

  switch (len) {
  case 7:
    if (memEQ(name, "EM_MIPS", 7)) {
#ifdef EM_MIPS
      *iv_return = EM_MIPS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 8:
    /* Names all of length 8.  */
    /* __NR_ipc __NR_mpx */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'i':
      if (memEQ(name, "__NR_ipc", 8)) {
      /*                    ^        */
#ifdef __NR_ipc
        *iv_return = __NR_ipc;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'm':
      if (memEQ(name, "__NR_mpx", 8)) {
      /*                    ^        */
#ifdef __NR_mpx
        *iv_return = __NR_mpx;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    return constant_15 (aTHX_ name, iv_return);
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    return constant_19 (aTHX_ name, iv_return);
    break;
  case 20:
    return constant_20 (aTHX_ name, iv_return);
    break;
  case 21:
    return constant_21 (aTHX_ name, iv_return);
    break;
  case 22:
    return constant_22 (aTHX_ name, iv_return);
    break;
  case 23:
    return constant_23 (aTHX_ name, iv_return);
    break;
  case 24:
    return constant_24 (aTHX_ name, iv_return);
    break;
  case 25:
    return constant_25 (aTHX_ name, iv_return);
    break;
  case 26:
    if (memEQ(name, "__PNR_sys_debug_setcontext", 26)) {
#ifdef __PNR_sys_debug_setcontext
      *iv_return = __PNR_sys_debug_setcontext;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 34:
    if (memEQ(name, "__AUDIT_ARCH_CONVENTION_MIPS64_N32", 34)) {
#ifdef __AUDIT_ARCH_CONVENTION_MIPS64_N32
      *iv_return = __AUDIT_ARCH_CONVENTION_MIPS64_N32;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

