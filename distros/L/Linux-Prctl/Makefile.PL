use 5.008005;
use strict;
use warnings;

use ExtUtils::MakeMaker;
use ExtUtils::Constant qw(WriteConstants);
use Fcntl qw(SEEK_SET);

my @constants = qw(
        CAP_EFFECTIVE
        CAP_INHERITABLE
        CAP_PERMITTED
        CAP_AUDIT_CONTROL
        CAP_AUDIT_WRITE
        CAP_CHOWN
        CAP_DAC_OVERRIDE
        CAP_DAC_READ_SEARCH
        CAP_FOWNER
        CAP_FSETID
        CAP_IPC_LOCK
        CAP_IPC_OWNER
        CAP_KILL
        CAP_LEASE
        CAP_LINUX_IMMUTABLE
        CAP_MAC_ADMIN
        CAP_MAC_OVERRIDE
        CAP_MKNOD
        CAP_NET_ADMIN
        CAP_NET_BIND_SERVICE
        CAP_NET_BROADCAST
        CAP_NET_RAW
        CAP_SETFCAP
        CAP_SETGID
        CAP_SETPCAP
        CAP_SETUID
        CAP_SYSLOG
        CAP_SYS_ADMIN
        CAP_SYS_BOOT
        CAP_SYS_CHROOT
        CAP_SYS_MODULE
        CAP_SYS_NICE
        CAP_SYS_PACCT
        CAP_SYS_PTRACE
        CAP_SYS_RAWIO
        CAP_SYS_RESOURCE
        CAP_SYS_TIME
        CAP_SYS_TTY_CONFIG
        CAP_WAKE_ALARM
        ENDIAN_BIG
        ENDIAN_LITTLE
        ENDIAN_PPC_LITTLE
        FPEMU_NOPRINT
        FPEMU_SIGFPE
        FP_EXC_ASYNC
        FP_EXC_DISABLED
        FP_EXC_DIV
        FP_EXC_INV
        FP_EXC_NONRECOV
        FP_EXC_OVF
        FP_EXC_PRECISE
        FP_EXC_RES
        FP_EXC_SW_ENABLE
        FP_EXC_UND
        MCE_KILL_DEFAULT
        MCE_KILL_EARLY
        MCE_KILL_LATE
        SECBIT_KEEP_CAPS
        SECBIT_KEEP_CAPS_LOCKED
        SECBIT_NOROOT
        SECBIT_NOROOT_LOCKED
        SECBIT_NO_SETUID_FIXUP
        SECBIT_NO_SETUID_FIXUP_LOCKED
        SECURE_KEEP_CAPS
        SECURE_KEEP_CAPS_LOCKED
        SECURE_NOROOT
        SECURE_NOROOT_LOCKED
        SECURE_NO_SETUID_FIXUP
        SECURE_NO_SETUID_FIXUP_LOCKED
        TIMING_STATISTICAL
        TIMING_TIMESTAMP
        TSC_ENABLE
        TSC_SIGSEGV
        UNALIGN_NOPRINT
        UNALIGN_SIGBUS
);

WriteConstants(
    NAME => 'Linux::Prctl',
    NAMES => [@constants],
);

WriteMakefile(
    NAME              => 'Linux::Prctl',
    VERSION_FROM      => 'lib/Linux/Prctl.pm',
    PREREQ_PM         => {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Linux/Prctl.pm',
       AUTHOR         => 'Dennis Kaarsemaker <dennis@kaarsemaker.net>') : ()),
    LIBS              => ['-L/lib -lcap'],
    DEFINE            => '',
    INC               => '',
);

# Patch up const-c.inc
my ($fh, $content);
open($fh, '+<', 'const-c.inc');
read($fh, $content, 100_000_000);

$content =~ s/#ifdef (?!(CAP|SEC))/#ifdef PR_/g;
$content =~ s/iv_return = (?!(CAP|SEC))/iv_return = PR_/g;

truncate $fh, 0;
seek $fh, 0, SEEK_SET;
print $fh $content;
close $fh;

# Make sure all constants are known to Prctl.pm

my $securebits = join(' ', grep(/^SEC/, @constants));
my $capabilities = join(' ', grep(/^CAP_(?!PERMITTED|EFFECTIVE|INHERITABLE)/, @constants));
my $constants = join(' ', grep { $_ !~ /^(SEC|CAP)/} @constants) . ' CAP_PERMITTED CAP_EFFECTIVE CAP_INHERITABLE';

open($fh, '+<', 'lib/Linux/Prctl.pm');
read($fh, $content, 100_000_000);

$content =~ s/'capabilities' => .*/'capabilities' => [qw($capabilities)],/;
$content =~ s/'securebits' => .*/'securebits' => [qw($securebits)],/;
$content =~ s/'constants' => .*/'constants' => [qw($constants)],/;

truncate $fh, 0;
seek $fh, 0, SEEK_SET;
print $fh $content;
close $fh;
