use strict;
use warnings;

use Test::More tests => 64;
use Linux::Prctl qw(:constants :securebits :capabilities);

SKIP: {
    open(my $fh, '<', '/usr/include/linux/prctl.h') or
    skip "prctl.h not available", 24;

    my %consts;
    while(<$fh>) {
        if(/^#\s*define\s+([A-Z_]+)\s+([0-9]+|0x[0-9a-fA-F]+)(?:\s|$|\/)/) {
            $consts{$1} = eval($2);
        }
    }

    is(Linux::Prctl::ENDIAN_BIG, $consts{PR_ENDIAN_BIG}, "ENDIAN_BIG correctly defined");
    is(Linux::Prctl::ENDIAN_LITTLE, $consts{PR_ENDIAN_LITTLE}, "ENDIAN_LITTLE correctly defined");
    is(Linux::Prctl::ENDIAN_PPC_LITTLE, $consts{PR_ENDIAN_PPC_LITTLE}, "ENDIAN_PPC_LITTLE correctly defined");
    is(Linux::Prctl::FPEMU_NOPRINT, $consts{PR_FPEMU_NOPRINT}, "FPEMU_NOPRINT correctly defined");
    is(Linux::Prctl::FPEMU_SIGFPE, $consts{PR_FPEMU_SIGFPE}, "FPEMU_SIGFPE correctly defined");
    is(Linux::Prctl::FP_EXC_SW_ENABLE, $consts{PR_FP_EXC_SW_ENABLE}, "FP_EXC_SW_ENABLE correctly defined");
    is(Linux::Prctl::FP_EXC_DIV, $consts{PR_FP_EXC_DIV}, "FP_EXC_DIV correctly defined");
    is(Linux::Prctl::FP_EXC_OVF, $consts{PR_FP_EXC_OVF}, "FP_EXC_OVF correctly defined");
    is(Linux::Prctl::FP_EXC_UND, $consts{PR_FP_EXC_UND}, "FP_EXC_UND correctly defined");
    is(Linux::Prctl::FP_EXC_RES, $consts{PR_FP_EXC_RES}, "FP_EXC_RES correctly defined");
    is(Linux::Prctl::FP_EXC_INV, $consts{PR_FP_EXC_INV}, "FP_EXC_INV correctly defined");
    is(Linux::Prctl::FP_EXC_DISABLED, $consts{PR_FP_EXC_DISABLED}, "FP_EXC_DISABLED correctly defined");
    is(Linux::Prctl::FP_EXC_NONRECOV, $consts{PR_FP_EXC_NONRECOV}, "FPEXC_NONRECOV correctly defined");
    is(Linux::Prctl::FP_EXC_ASYNC, $consts{PR_FP_EXC_ASYNC}, "FPEXC_ASYNC correctly defined");
    is(Linux::Prctl::FP_EXC_PRECISE, $consts{PR_FP_EXC_PRECISE}, "FPEXC_PRECISE correctly defined");
    eval{is(Linux::Prctl::MCE_KILL_DEFAULT, $consts{PR_MCE_KILL_DEFAULT}, "MCE_KILL_DEFAULT correctly defined"); 1} or pass "MCE_KILL_DEFAULT not defined";
    eval{is(Linux::Prctl::MCE_KILL_EARLY, $consts{PR_MCE_KILL_EARLY}, "MCE_KILL_EARLY correctly defined"); 1} or pass "MCE_KILL_EARLY not defined";
    eval{is(Linux::Prctl::MCE_KILL_LATE, $consts{PR_MCE_KILL_LATE}, "MCE_KILL_LATE correctly defined"); 1} or pass "MCE_KILL_LATE not defined";
    is(Linux::Prctl::TIMING_STATISTICAL, $consts{PR_TIMING_STATISTICAL}, "TIMING_STATISTICAL correctly defined");
    is(Linux::Prctl::TIMING_TIMESTAMP, $consts{PR_TIMING_TIMESTAMP}, "TIMING_TIMESTAMP correctly defined");
    eval{is(Linux::Prctl::TSC_ENABLE, $consts{PR_TSC_ENABLE}, "TSC_ENABLE correctly defined"); 1} or pass "TSC_ENABLE not defined";
    eval{is(Linux::Prctl::TSC_SIGSEGV, $consts{PR_TSC_SIGSEGV}, "TSC_SIGSEGV correctly defined"); 1} or pass "TSC_SIGSEGV not defined";
    is(Linux::Prctl::UNALIGN_NOPRINT, $consts{PR_UNALIGN_NOPRINT}, "UNALIGN_NOPRINT correctly defined");
    is(Linux::Prctl::UNALIGN_SIGBUS, $consts{PR_UNALIGN_SIGBUS}, "UNALIGN_SIGBUS correctly defined");
}
SKIP: {
    open(my $fh, '<', 'securebits.h') or
    skip "securebits.h not available", 6;

    my %consts;
    while(<$fh>) {
        if(/^#\s*define\s+([A-Z_]+)\s+([0-9]+|0x[0-9a-fA-F]+)(?:\s|$|\/)/) {
            $consts{$1} = eval($2);
        }
    }
    is(Linux::Prctl::SECURE_KEEP_CAPS, $consts{SECURE_KEEP_CAPS}, "SECURE_KEEP_CAPS correctly defined");
    is(Linux::Prctl::SECURE_KEEP_CAPS_LOCKED, $consts{SECURE_KEEP_CAPS_LOCKED}, "SECURE_KEEP_CAPS correctly defined");
    is(Linux::Prctl::SECURE_NOROOT, $consts{SECURE_NOROOT}, "SECURE_NOROOT correctly defined");
    is(Linux::Prctl::SECURE_NOROOT_LOCKED, $consts{SECURE_NOROOT_LOCKED}, "SECURE_NOROOT correctly defined");
    is(Linux::Prctl::SECURE_NO_SETUID_FIXUP, $consts{SECURE_NO_SETUID_FIXUP}, "SECURE_NO_SETUID_FIXUP correctly defined");
    is(Linux::Prctl::SECURE_NO_SETUID_FIXUP_LOCKED, $consts{SECURE_NO_SETUID_FIXUP_LOCKED}, "SECURE_NO_SETUID_FIXUP correctly defined");
}
SKIP: {
    open(my $fh, '<', '/usr/include/linux/capability.h') or
    skip "capability.h not available", 35;

    my %consts;
    while(<$fh>) {
        if(/^#\s*define\s+([A-Z_]+)\s+([0-9]+|0x[0-9a-fA-F]+)(?:\s|$|\/)/) {
            $consts{$1} = eval($2);
        }
    }

    is(Linux::Prctl::CAP_AUDIT_CONTROL, $consts{CAP_AUDIT_CONTROL}, "CAP_AUDIT_CONTROL correctly defined");
    is(Linux::Prctl::CAP_AUDIT_WRITE, $consts{CAP_AUDIT_WRITE}, "CAP_AUDIT_WRITE correctly defined");
    is(Linux::Prctl::CAP_CHOWN, $consts{CAP_CHOWN}, "CAP_CHOWN correctly defined");
    is(Linux::Prctl::CAP_DAC_OVERRIDE, $consts{CAP_DAC_OVERRIDE}, "CAP_DAC_OVERRIDE correctly defined");
    is(Linux::Prctl::CAP_DAC_READ_SEARCH, $consts{CAP_DAC_READ_SEARCH}, "CAP_DAC_READ_SEARCH correctly defined");
    is(Linux::Prctl::CAP_FOWNER, $consts{CAP_FOWNER}, "CAP_FOWNER correctly defined");
    is(Linux::Prctl::CAP_FSETID, $consts{CAP_FSETID}, "CAP_FSETID correctly defined");
    is(Linux::Prctl::CAP_IPC_LOCK, $consts{CAP_IPC_LOCK}, "CAP_IPC_LOCK correctly defined");
    is(Linux::Prctl::CAP_IPC_OWNER, $consts{CAP_IPC_OWNER}, "CAP_IPC_OWNER correctly defined");
    is(Linux::Prctl::CAP_KILL, $consts{CAP_KILL}, "CAP_KILL correctly defined");
    is(Linux::Prctl::CAP_LEASE, $consts{CAP_LEASE}, "CAP_LEASE correctly defined");
    is(Linux::Prctl::CAP_LINUX_IMMUTABLE, $consts{CAP_LINUX_IMMUTABLE}, "CAP_LINUX_IMMUTABLE correctly defined");
    eval{is(Linux::Prctl::CAP_MAC_ADMIN, $consts{CAP_MAC_ADMIN}, "CAP_MAC_ADMIN correctly defined"); 1} or pass "CAP_MAC_ADMIN not defined";
    eval{is(Linux::Prctl::CAP_MAC_OVERRIDE, $consts{CAP_MAC_OVERRIDE}, "CAP_MAC_OVERRIDE correctly defined"); 1} or pass "CAP_MAC_OVERRIDE not defined";
    is(Linux::Prctl::CAP_MKNOD, $consts{CAP_MKNOD}, "CAP_MKNOD correctly defined");
    is(Linux::Prctl::CAP_NET_ADMIN, $consts{CAP_NET_ADMIN}, "CAP_NET_ADMIN correctly defined");
    is(Linux::Prctl::CAP_NET_BIND_SERVICE, $consts{CAP_NET_BIND_SERVICE}, "CAP_NET_BIND_SERVICE correctly defined");
    is(Linux::Prctl::CAP_NET_BROADCAST, $consts{CAP_NET_BROADCAST}, "CAP_NET_BROADCAST correctly defined");
    is(Linux::Prctl::CAP_NET_RAW, $consts{CAP_NET_RAW}, "CAP_NET_RAW correctly defined");
    eval{is(Linux::Prctl::CAP_SETFCAP, $consts{CAP_SETFCAP}, "CAP_SETFCAP correctly defined"); 1} or pass "CAP_SETFCAP not defined";
    is(Linux::Prctl::CAP_SETGID, $consts{CAP_SETGID}, "CAP_SETGID correctly defined");
    is(Linux::Prctl::CAP_SETPCAP, $consts{CAP_SETPCAP}, "CAP_SETPCAP correctly defined");
    is(Linux::Prctl::CAP_SETUID, $consts{CAP_SETUID}, "CAP_SETUID correctly defined");
    is(Linux::Prctl::CAP_SYS_ADMIN, $consts{CAP_SYS_ADMIN}, "CAP_SYS_ADMIN correctly defined");
    is(Linux::Prctl::CAP_SYS_BOOT, $consts{CAP_SYS_BOOT}, "CAP_SYS_BOOT correctly defined");
    is(Linux::Prctl::CAP_SYS_CHROOT, $consts{CAP_SYS_CHROOT}, "CAP_SYS_CHROOT correctly defined");
    is(Linux::Prctl::CAP_SYS_MODULE, $consts{CAP_SYS_MODULE}, "CAP_SYS_MODULE correctly defined");
    is(Linux::Prctl::CAP_SYS_NICE, $consts{CAP_SYS_NICE}, "CAP_SYS_NICE correctly defined");
    is(Linux::Prctl::CAP_SYS_PACCT, $consts{CAP_SYS_PACCT}, "CAP_SYS_PACCT correctly defined");
    is(Linux::Prctl::CAP_SYS_PTRACE, $consts{CAP_SYS_PTRACE}, "CAP_SYS_PTRACE correctly defined");
    is(Linux::Prctl::CAP_SYS_RAWIO, $consts{CAP_SYS_RAWIO}, "CAP_SYS_RAWIO correctly defined");
    is(Linux::Prctl::CAP_SYS_RESOURCE, $consts{CAP_SYS_RESOURCE}, "CAP_SYS_RESOURCE correctly defined");
    is(Linux::Prctl::CAP_SYS_TIME, $consts{CAP_SYS_TIME}, "CAP_SYS_TIME correctly defined");
    is(Linux::Prctl::CAP_SYS_TTY_CONFIG, $consts{CAP_SYS_TTY_CONFIG}, "CAP_SYS_TTY_CONFIG correctly defined");
}
