#!/usr/bin/env perl
# t/08-deduplication.t - Tests for include/define deduplication

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

use_ok('ExtUtils::XSOne');

my $tmpdir = tempdir(CLEANUP => 1);

# =============================================================================
# Test include deduplication
# =============================================================================

subtest 'Include deduplication' => sub {
    plan tests => 5;

    my $src_dir = File::Spec->catdir($tmpdir, 'includes');
    make_path($src_dir);

    # Multiple files with overlapping includes
    write_file(File::Spec->catfile($src_dir, 'foo.xs'), <<'XS');
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdio.h>
#include <stdlib.h>

MODULE = Test    PACKAGE = Test::Foo

void foo()
XS

    write_file(File::Spec->catfile($src_dir, 'bar.xs'), <<'XS');
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>
#include <stdlib.h>

MODULE = Test    PACKAGE = Test::Bar

void bar()
XS

    my $output = File::Spec->catfile($tmpdir, 'includes.xs');
    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    my $content = read_file($output);

    # Each include should appear only once
    my @extern = $content =~ /(#include "EXTERN\.h")/g;
    is(scalar(@extern), 1, 'EXTERN.h included only once');

    my @perl = $content =~ /(#include "perl\.h")/g;
    is(scalar(@perl), 1, 'perl.h included only once');

    my @stdlib = $content =~ /(#include <stdlib\.h>)/g;
    is(scalar(@stdlib), 1, 'stdlib.h included only once');

    # Both unique includes should be present (order depends on file processing order)
    like($content, qr/#include <stdio\.h>/, 'stdio.h include present');
    like($content, qr/#include <string\.h>/, 'string.h include present');
};

# =============================================================================
# Test define deduplication
# =============================================================================

subtest 'Define deduplication' => sub {
    plan tests => 3;

    my $src_dir = File::Spec->catdir($tmpdir, 'defines');
    make_path($src_dir);

    write_file(File::Spec->catfile($src_dir, 'a.xs'), <<'XS');
#define PERL_NO_GET_CONTEXT
#define MY_MACRO 42

MODULE = Test    PACKAGE = Test::A
XS

    write_file(File::Spec->catfile($src_dir, 'b.xs'), <<'XS');
#define PERL_NO_GET_CONTEXT
#define ANOTHER_MACRO 100

MODULE = Test    PACKAGE = Test::B
XS

    my $output = File::Spec->catfile($tmpdir, 'defines.xs');
    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    my $content = read_file($output);

    # PERL_NO_GET_CONTEXT should appear only once
    my @pngc = $content =~ /(#define PERL_NO_GET_CONTEXT)/g;
    is(scalar(@pngc), 1, 'PERL_NO_GET_CONTEXT defined only once');

    # Both unique defines should be present
    like($content, qr/#define MY_MACRO 42/, 'MY_MACRO present');
    like($content, qr/#define ANOTHER_MACRO 100/, 'ANOTHER_MACRO present');
};

# =============================================================================
# Test C code collection
# =============================================================================

subtest 'C code collection' => sub {
    plan tests => 4;

    my $src_dir = File::Spec->catdir($tmpdir, 'ccode');
    make_path($src_dir);

    write_file(File::Spec->catfile($src_dir, 'alpha.xs'), <<'XS');
#include <stdio.h>

static int alpha_func(void) {
    return 1;
}

MODULE = Test    PACKAGE = Test::Alpha

int get_alpha()
CODE:
    RETVAL = alpha_func();
OUTPUT:
    RETVAL
XS

    write_file(File::Spec->catfile($src_dir, 'beta.xs'), <<'XS');
#include <stdio.h>

static int beta_func(void) {
    return 2;
}

MODULE = Test    PACKAGE = Test::Beta

int get_beta()
CODE:
    RETVAL = beta_func();
OUTPUT:
    RETVAL
XS

    my $output = File::Spec->catfile($tmpdir, 'ccode.xs');
    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    my $content = read_file($output);

    # Both C functions should be present in the preamble
    like($content, qr/static int alpha_func\(void\)/, 'alpha_func present');
    like($content, qr/static int beta_func\(void\)/, 'beta_func present');

    # The preamble should have source markers
    like($content, qr/C code from: alpha\.xs/, 'Source marker for alpha.xs');
    like($content, qr/C code from: beta\.xs/, 'Source marker for beta.xs');
};

# =============================================================================
# Test combined preamble structure
# =============================================================================

subtest 'Combined preamble structure' => sub {
    plan tests => 5;

    my $src_dir = File::Spec->catdir($tmpdir, 'structure');
    make_path($src_dir);

    write_file(File::Spec->catfile($src_dir, 'mod.xs'), <<'XS');
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

typedef struct {
    int value;
} MyStruct;

static MyStruct *create_struct(int v) {
    MyStruct *s = malloc(sizeof(MyStruct));
    s->value = v;
    return s;
}

MODULE = Test    PACKAGE = Test

void test()
XS

    my $output = File::Spec->catfile($tmpdir, 'structure.xs');
    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    my $content = read_file($output);

    # Structure check: preamble comes before XS sections (MODULE declarations)
    like($content, qr/COMBINED C PREAMBLE.*END COMBINED C PREAMBLE.*MODULE = Test/s,
         'Preamble comes before XS sections');

    # Includes should be at the top of preamble
    like($content, qr/COMBINED C PREAMBLE.*#include "EXTERN\.h"/s,
         'Includes in preamble');

    # Defines should be present
    like($content, qr/#define PERL_NO_GET_CONTEXT/, 'Define in preamble');

    # C code (typedef, function) should be present
    like($content, qr/typedef struct/, 'typedef preserved');
    like($content, qr/create_struct/, 'C function preserved');
};

# =============================================================================
# Test empty preamble handling
# =============================================================================

subtest 'Empty preamble handling' => sub {
    plan tests => 2;

    my $src_dir = File::Spec->catdir($tmpdir, 'nopreamble');
    make_path($src_dir);

    # Files with no C preamble - just XS
    write_file(File::Spec->catfile($src_dir, 'pure.xs'), <<'XS');
MODULE = Test    PACKAGE = Test

void pure_xs()
CODE:
    /* Nothing */
XS

    my $output = File::Spec->catfile($tmpdir, 'nopreamble.xs');
    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    my $content = read_file($output);

    # Should still work
    like($content, qr/MODULE = Test/, 'XS code present');

    # Preamble section should be minimal or absent
    unlike($content, qr/C code from:/, 'No C code markers when no C code');
};

# =============================================================================
# Helper functions
# =============================================================================

sub write_file {
    my ($path, $content) = @_;
    open(my $fh, '>', $path) or die "Cannot write $path: $!";
    print $fh $content;
    close($fh);
}

sub read_file {
    my ($path) = @_;
    open(my $fh, '<', $path) or die "Cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close($fh);
    return $content;
}

done_testing();
