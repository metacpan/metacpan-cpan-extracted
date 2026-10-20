use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use ExtUtils::Depends;
use Config;

# Pick up File::Raw's published file_plugin.h via ExtUtils::Depends.
# Falls back to a sibling working copy when developing in tree.
my $pkg;
eval { $pkg = ExtUtils::Depends->new('File::Raw::Hash', 'File::Raw') };
if (!$pkg) {
    die "Cannot find File::Raw dependency (need 0.13+).\n"
      . "Install File::Raw 0.13+ or place it as a sibling directory.\n"
        unless -d '../File-Raw/include';
    $pkg = ExtUtils::Depends->new('File::Raw::Hash');
    $pkg->set_inc('-Iinclude -I../File-Raw/include');
} else {
    my %vars = $pkg->get_makefile_vars;
    $pkg->set_inc('-Iinclude ' . ($vars{INC} || ''));
}

# This dist is a provider too: frh_abi.h is the C ABI other XS
# distributions consume through File::Raw::Hash::_abi_ptr. Install the
# header and publish the config so a downstream
# ExtUtils::Depends->new('X', 'File::Raw::Hash') finds both.
$pkg->install('include/frh_abi.h');
mkdir 'Install' unless -d 'Install';
$pkg->save_config('Install/Files.pm');

my %platform_args;
if ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd'
        || $^O eq 'netbsd' || $^O eq 'dragonfly') {
    # GNU ld: allow unresolved syms, satisfied at runtime by RTLD_GLOBAL.
    $platform_args{dynamic_lib} = {
        OTHERLDFLAGS => '-Wl,--allow-shlib-undefined'
    };
}
# The ARMv8 SHA path (sha_hw.c) is used only when the CPU has it, chosen at
# run time; this checks the compiler can build it at all. A compiler that
# knows the attribute but not the instructions (or an assembler that does
# not) fails here rather than mid-build, and the dist is then portable only.
my $hw_define = '';
if ($Config{archname} =~ /aarch64|arm64/ || `uname -m 2>/dev/null` =~ /aarch64|arm64/) {
    my $src = "frh_probe_$$.c";
    open my $fh, '>', $src or die "cannot write $src: $!";
    print {$fh} <<'C';
#include <arm_neon.h>
#if defined(__ARM_FEATURE_SHA2)
#  define T
#elif defined(__clang__)
#  define T __attribute__((target("sha2")))
#else
#  define T __attribute__((target("+sha2")))
#endif
T uint32x4_t frh_probe(uint32x4_t a, uint32x4_t b, uint32x4_t c) {
    return vsha256h2q_u32(vsha256hq_u32(a, b, c), a, vsha1cq_u32(a, vgetq_lane_u32(b, 0), c));
}
C
    close $fh;
    my $ok = system("$Config{cc} $Config{ccflags} -c -o frh_probe_$$.o $src >/dev/null 2>&1") == 0;
    unlink $src, "frh_probe_$$.o";
    $hw_define = '-DFRH_NO_HW' unless $ok;
    print $ok ? "ARMv8 SHA instructions: the compiler can build them\n"
              : "ARMv8 SHA instructions: the compiler cannot; portable only\n";
}

# Windows / Cygwin / msys: nothing to do here. File::Raw 0.13+ ships a
# MinGW import library (libRaw.dll.a) and publishes its location via
# ExtUtils::Depends's set_libs(). The LIBS string flows in through
# $pkg->get_makefile_vars below, so the plugin links against Raw.dll
# automatically. This dist no longer needs to hunt for the DLL on
# disk.

my %WriteMakefileArgs = (
    NAME             => 'File::Raw::Hash',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/File/Raw/Hash.pm',
    ABSTRACT_FROM    => 'lib/File/Raw/Hash.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.008003',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'ExtUtils::Depends'   => '0.404',
        'File::Raw'           => '0.15',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'File::Raw' => '0.15',
    },
    OBJECT => 'Hash$(OBJ_EXT) hashx$(OBJ_EXT) sha2$(OBJ_EXT) sha_hw$(OBJ_EXT) '
            . 'sha1$(OBJ_EXT) md5$(OBJ_EXT) crc32$(OBJ_EXT) '
            . 'xxh64$(OBJ_EXT) blake3$(OBJ_EXT)',
    C      => ['hashx.c', 'sha2.c', 'sha_hw.c', 'sha1.c', 'md5.c', 'crc32.c',
               'xxh64.c', 'blake3.c'],
    XS     => { 'Hash.xs' => 'Hash.c' },
    ($hw_define ? (DEFINE => $hw_define) : ()),
    dist   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    depend => { 'Hash$(OBJ_EXT)'  => join(' ', glob 'include/*.h'),
                'hashx$(OBJ_EXT)' => join(' ', glob 'include/*.h') },
    clean  => { FILES => 'File-Raw-Hash-* Hash.c Hash.o '
                       . 'hashx.o sha2.o sha_hw.o sha1.o md5.o crc32.o '
                       . 'xxh64.o blake3.o Install/Files.pm' },
    %platform_args,
    $pkg->get_makefile_vars,
);

# ExtUtils::Depends' PM map (installing frh_abi.h + Files.pm) replaces
# MakeMaker's auto-detected PM, so re-add the module's own .pm files -
# without this, Hash.pm itself stops installing the moment the header
# does (house gotcha).
{
    require File::Find;
    File::Find::find(sub {
        return unless /\.pm\z/;
        (my $rel = $File::Find::name) =~ s{^lib/}{};
        $WriteMakefileArgs{PM}{$File::Find::name} = "\$(INST_LIB)/$rel";
    }, 'lib');
}

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
