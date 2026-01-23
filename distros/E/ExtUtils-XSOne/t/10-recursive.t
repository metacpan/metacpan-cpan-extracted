#!/usr/bin/env perl
# t/10-recursive.t - Test recursive XS file discovery

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(make_path remove_tree);
use FindBin qw($Bin);

use_ok('ExtUtils::XSOne');

# Create a temporary directory structure mimicking Better-Calculator layout
my $tempdir = File::Spec->catdir($Bin, 'tmp', '10-recursive');
remove_tree($tempdir) if -d $tempdir;
make_path($tempdir);
END { remove_tree($tempdir) if $tempdir && -d $tempdir }

# Structure:
# lib/
#   Test/
#     _header.xs          (depth 1)
#     _footer.xs          (depth 1)
#     Calculator/
#       xs/
#         _header.xs      (depth 3)
#         _footer.xs      (depth 3)
#       Basic.xs          (depth 2)
#       Scientific.xs     (depth 2)
#       Memory.xs         (depth 2)

my $lib_dir = File::Spec->catdir($tempdir, 'lib');
my $test_dir = File::Spec->catdir($lib_dir, 'Test');
my $calc_dir = File::Spec->catdir($test_dir, 'Calculator');
my $xs_dir = File::Spec->catdir($calc_dir, 'xs');

make_path($xs_dir);

# Create test files with identifiable content

# Top-level header (depth 1)
write_file(File::Spec->catfile($test_dir, '_header.xs'), <<'XS');
/* Top-level shared C code */
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

static int top_level_var = 42;
XS

# Top-level footer (depth 1)
write_file(File::Spec->catfile($test_dir, '_footer.xs'), <<'XS');
MODULE = Test::Calculator    PACKAGE = Test::Calculator

BOOT:
    /* Top-level initialization */
    top_level_var = 100;
XS

# Calculator-level header (depth 3, in xs/ subdir)
write_file(File::Spec->catfile($xs_dir, '_header.xs'), <<'XS');
/* Calculator-specific shared state */
static double memory_slots[10];
static int memory_initialized = 0;

static void init_memory(void) {
    if (!memory_initialized) {
        memory_initialized = 1;
    }
}
XS

# Calculator-level footer (depth 3, in xs/ subdir)
write_file(File::Spec->catfile($xs_dir, '_footer.xs'), <<'XS');
MODULE = Test::Calculator    PACKAGE = Test::Calculator::Internal

double
get_memory_slot(slot)
    int slot
CODE:
    RETVAL = memory_slots[slot];
OUTPUT:
    RETVAL
XS

# Package XS files (depth 2)
write_file(File::Spec->catfile($calc_dir, 'Basic.xs'), <<'XS');
#include <math.h>

MODULE = Test::Calculator    PACKAGE = Test::Calculator::Basic

double
add(a, b)
    double a
    double b
CODE:
    RETVAL = a + b;
OUTPUT:
    RETVAL
XS

write_file(File::Spec->catfile($calc_dir, 'Memory.xs'), <<'XS');
MODULE = Test::Calculator    PACKAGE = Test::Calculator::Memory

int
store(slot, value)
    int slot
    double value
CODE:
    init_memory();
    memory_slots[slot] = value;
    RETVAL = 1;
OUTPUT:
    RETVAL
XS

write_file(File::Spec->catfile($calc_dir, 'Scientific.xs'), <<'XS');
#include <math.h>

MODULE = Test::Calculator    PACKAGE = Test::Calculator::Scientific

double
power(base, exp)
    double base
    double exp
CODE:
    RETVAL = pow(base, exp);
OUTPUT:
    RETVAL
XS

# Test recursive file discovery
subtest 'Recursive file discovery' => sub {
    plan tests => 1;

    my @files = ExtUtils::XSOne->_find_xs_files_recursive($test_dir);

    # Expected order:
    # 1. Headers (shallow to deep): _header.xs, Calculator/xs/_header.xs
    # 2. Packages (alphabetically): Calculator/Basic.xs, Calculator/Memory.xs, Calculator/Scientific.xs
    # 3. Footers (deep to shallow): Calculator/xs/_footer.xs, _footer.xs

    my @expected = (
        '_header.xs',
        File::Spec->catfile('Calculator', 'xs', '_header.xs'),
        File::Spec->catfile('Calculator', 'Basic.xs'),
        File::Spec->catfile('Calculator', 'Memory.xs'),
        File::Spec->catfile('Calculator', 'Scientific.xs'),
        File::Spec->catfile('Calculator', 'xs', '_footer.xs'),
        '_footer.xs',
    );

    is_deeply(\@files, \@expected, 'Files discovered in correct order');
};

# Test combine with recursive option
subtest 'Combine with recursive option' => sub {
    plan tests => 6;

    my $output = File::Spec->catfile($tempdir, 'Calculator.xs');

    my $count = ExtUtils::XSOne->combine(
        src_dir   => $test_dir,
        output    => $output,
        recursive => 1,
        verbose   => 0,
    );

    is($count, 7, 'Combined 7 files');
    ok(-f $output, 'Output file created');

    # Read and verify content order
    open(my $fh, '<', $output) or die "Cannot read $output: $!";
    my $content = do { local $/; <$fh> };
    close($fh);

    # Verify top-level header comes first (after generated header comment)
    like($content, qr/Top-level shared C code/, 'Contains top-level header');

    # Verify Calculator header comes after top-level header
    my $top_header_pos = index($content, 'top_level_var = 42');
    my $calc_header_pos = index($content, 'memory_slots[10]');
    ok($top_header_pos < $calc_header_pos, 'Top-level header before Calculator header');

    # Verify package files come after headers
    my $basic_pos = index($content, 'Test::Calculator::Basic');
    ok($calc_header_pos < $basic_pos, 'Headers before package files');

    # Verify footers come at the end
    my $top_footer_pos = index($content, 'top_level_var = 100');
    ok($basic_pos < $top_footer_pos, 'Package files before footers');
};

done_testing();

sub write_file {
    my ($path, $content) = @_;
    open(my $fh, '>', $path) or die "Cannot write $path: $!";
    print $fh $content;
    close($fh);
}
