#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use File::Spec;

# What broke Frozen 0.01 on the Strawberry 5.42 smoker.
#
# A perl built with PERL_IMPLICIT_SYS - which every Strawberry is - has XSUB.h
# redefine a list of CRT names as function-like macros: `close` becomes
# PerlLIO_close, `open` becomes PerlLIO_open, and so on for read, write, link,
# select, socket, free and forty more. The ABI table has members called `open`
# and `close`, and `A->close(c)` puts the member name immediately in front of
# `(`, which is where a function-like macro fires. The declaration is safe
# because the name is followed by `)`, so the header compiles everywhere and
# only the CALL SITES break - which is why this reached CPAN.
#
# This perl is almost certainly not an IMPLICIT_SYS one, so the test creates
# the condition rather than waiting for a smoker to: it leaves the two names
# defined as function-like macros exactly where XSUB.h leaves them, then
# includes the real headers in Frozen.xs's order. Nothing here is a copy of
# the dist's code, so a new member or call site with a colliding name is
# caught the same way.

plan skip_all => 'no compiler recorded in Config' unless $Config{cc};

my $inc = File::Spec->catdir('include');
plan skip_all => "run from the dist root: no $inc" unless -d $inc;

my $core = File::Spec->catdir($Config{archlibexp}, 'CORE');
plan skip_all => "no perl headers at $core" unless -f File::Spec->catfile($core, 'perl.h');

my $dir = tempdir(CLEANUP => 1);
my $c   = File::Spec->catfile($dir, 'implicit.c');
my $o   = File::Spec->catfile($dir, 'implicit' . ($Config{obj_ext} || '.o'));

open my $fh, '>', $c or plan skip_all => "cannot write $c: $!";
print {$fh} <<'C';
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* What XSUB.h leaves live under PERL_IMPLICIT_SYS. Stubs rather than the real
 * PerlLIO_* so this compiles on a perl that has no implicit-sys layer at all;
 * the SHAPE is what matters, because the shape is what fires. */
static int fz_probe_lio_close(int fd) { return fd; }
static int fz_probe_lio_open(const char *f, int fl) { (void)f; return fl; }
#undef close
#undef open
#define close(fd)   fz_probe_lio_close(fd)
#define open(f, fl) fz_probe_lio_open((f), (fl))

#include "fz/fz_compat.h"
#include "fz_abi.h"
#include "fz/fz_format.h"
#include "fz/fz_build.h"
#include "fz/fz_map.h"
#include "fz/fz_read.h"
#include "fz/fz_sv.h"
#include "fz/fz_abi_impl.h"

int main(void) { return (int)FZ_ABI.abi_version - FZ_ABI_VERSION; }
C
close $fh;

my $cmd = join ' ', $Config{cc}, $Config{ccflags} || (), '-c',
          "-I.", "-Iinclude", "-I\"$core\"", "-o", "\"$o\"", "\"$c\"";
my $log = `$cmd 2>&1`;
my $rc  = $?;

ok($rc == 0, 'the ABI compiles with open and close live as function-like macros')
    or diag("a member or call site collides with a name XSUB.h redefines under\n"
          . "PERL_IMPLICIT_SYS. Parenthesise the call - (FZ->close)(...) - so the\n"
          . "name is followed by ')' where a function-like macro cannot fire.\n\n"
          . "$cmd\n\n$log");

done_testing;
