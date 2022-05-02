#!/usr/bin/env perl

# A lot of this is cargo-culted from CryptX which has already gone through a lot of working around platform
# incompatibilities which we're grateful to take advantage of here -- thanks cpan:MIK!

use warnings;
use strict;

use Config;
use ExtUtils::MakeMaker;



my (@EUMM_INC_LIB, $myarflags, $mycflags);

# use bundled libtomcrypt
my @myobjs = map { /^(.*)\.c$/ ? "$1$Config{obj_ext}" : () } qw(
    libtomcrypt/src/ciphers/aes/aes.c
    libtomcrypt/src/misc/compare_testvector.c
    libtomcrypt/src/misc/crypt/crypt_argchk.c
    libtomcrypt/src/misc/zeromem.c
);
$mycflags = " $Config{ccflags} $Config{cccdlflags} $Config{optimize} "; # keep leading + trailing spaces

#FIX: this is particularly useful for Debian https://github.com/DCIT/perl-CryptX/pull/39
$mycflags .= " $ENV{CFLAGS} "   if $ENV{CFLAGS};
$mycflags .= " $ENV{CPPFLAGS} " if $ENV{CPPFLAGS};

#### remove all lto hacks - https://github.com/DCIT/perl-CryptX/issues/70
## #FIX: gcc with -flto is a trouble maker see https://github.com/DCIT/perl-CryptX/issues/32
## #FIX: another issue with "-flto=auto" see https://github.com/DCIT/perl-CryptX/pull/66
## $mycflags =~ s/\s-flto\S+\s/ /g; # -flto -flto=auto -flto=jobserver -flto=N ...

#FIX: avoid -Wwrite-strings -Wcast-qual -pedantic -pedantic-errors -ansi -std=c89
$mycflags =~ s/\s-pedantic-errors\s/ /g;
$mycflags =~ s/\s-pedantic\s/ /g;
$mycflags =~ s/\s-std=c89\s/ /g;
$mycflags =~ s/\s-ansi\s/ /g;
$mycflags =~ s/\s-Wwrite-strings\s/ /g;
$mycflags =~ s/\s-Wcast-qual\s/ /g;

#FIX: avoid "ar: fatal: Numeric group ID too large" see https://github.com/DCIT/perl-CryptX/issues/33
$myarflags = '$(AR_STATIC_ARGS)';
if ($^O ne 'MSWin32' && $Config{ar}) {
    # for ar's "deterministic mode" we need GNU binutils 2.20+ (2009-10-16)
    my $arver = `$Config{ar} --version 2>/dev/null`;
    my ($maj, $min) = $arver =~ /^GNU ar [^\d]*(\d)\.(\d+)\.\d+/s;
    $myarflags = 'rcD' if ($maj && $min && $maj >= 2 && $min >= 20) || $arver=~ /^BSD ar /;
}

# turn on extra warnings in AUTHOR_MODE (it is gcc only!!)
$mycflags = "$mycflags -Wall -Werror -Wextra" if $ENV{AUTHOR_MODE};

@EUMM_INC_LIB = (
    INC         => $ENV{AUTHOR_MODE} ? '-DLTM_DESC -Ilibtomcrypt/src/headers -Wall -Werror -Wextra' # gcc only
                                                                : '-DLTM_DESC -Ilibtomcrypt/src/headers',
    MYEXTLIB    => "libtomcrypt/libonlyaes$Config{lib_ext}",
    clean       => { FILES => join(' ', @myobjs, "libtomcrypt/libonlyaes$Config{lib_ext}") },
    realclean   => { FILES => join(' ', qw{cover_db *.gcda *.gcno *.gcov})},
);

#FIX: https://github.com/DCIT/perl-CryptX/pull/79
# not needed on MS Windows
# does not work on macos - Apple LLVM 12.0.5 (clang-1205.0.22.9) ld: unknown option: --exclude-libs
# does not work on solaris - gcc 9.3.0 - ld: fatal: unrecognized option '--exclude-libs'
if ($^O !~ /^(MSWin32|darwin|solaris)$/ && ($Config{ld} =~ /gcc|g\+\+/ || $Config{gccversion})) {
     push @EUMM_INC_LIB, (LDDLFLAGS => "$Config{lddlflags} -Wl,--exclude-libs,ALL");
}

my %eumm_args = (
  'NAME' => 'File::KDBX::XS',
  'VERSION' => '999.999',
  'ABSTRACT' => 'Speed up File::KDBX',
  'AUTHOR' => 'Charles McGarvey <ccm@cpan.org>',
  'DISTNAME' => 'File-KDBX-XS',
  'LICENSE' => 'perl',
  'MIN_PERL_VERSION' => '5.006',
  'VERSION' => '0.900',
  'test' => {
    'TESTS' => 't/*.t'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '0'
  },
  'PREREQ_PM' => {
    'XSLoader' => '0',
    'strict' => '0',
    'warnings' => '0'
  },
  'TEST_REQUIRES' => {
    'ExtUtils::MakeMaker' => '0',
    'File::Spec' => '0',
    'IO::Handle' => '0',
    'IPC::Open3' => '0',
    'Test::More' => '0'
  },
    @EUMM_INC_LIB,
);

my $eumm_ver = eval $ExtUtils::MakeMaker::VERSION;
delete $eumm_args{MIN_PERL_VERSION}     if $eumm_ver < 6.48;
delete $eumm_args{META_ADD}             if $eumm_ver < 6.46;
delete $eumm_args{META_MERGE}           if $eumm_ver < 6.46;
delete $eumm_args{LICENSE}              if $eumm_ver < 6.31;
delete $eumm_args{CONFIGURE_REQUIRES}   if $eumm_ver < 6.52;
delete $eumm_args{BUILD_REQUIRES}       if $eumm_ver < 6.56;
delete $eumm_args{TEST_REQUIRES}        if $eumm_ver < 6.64;

WriteMakefile(%eumm_args);

sub MY::postamble {
    return "" unless $mycflags && $myarflags;

    my $extra_targets = qq{
\$(MYEXTLIB): libtomcrypt/Makefile
\tcd libtomcrypt && \$(MAKE) ARFLAGS="$myarflags" RANLIB="\$(RANLIB)" AR="\$(AR)" CC="\$(CC)" LIB_EXT=\$(LIB_EXT) OBJ_EXT=\$(OBJ_EXT) CFLAGS="$mycflags"
};

    $extra_targets = qq{
\$(MYEXTLIB): libtomcrypt/Makefile.nmake
\tcd libtomcrypt && \$(MAKE) -f Makefile.nmake CFLAGS="$mycflags"
} if $^O eq 'MSWin32' && $Config{make} =~ /nmake/ && $Config{cc} =~ /cl/;

    $extra_targets = qq{
\$(MYEXTLIB): libtomcrypt/Makefile
\tcd libtomcrypt && \$(MAKE) CC="$Config{cc}" CFLAGS="$mycflags"
} if $^O eq 'MSWin32' && $Config{cc} =~ /gcc/;

    return $extra_targets;
}


