#!/usr/bin/env perl
# t/06-simple-module.t - Tests using t/lib/SimpleModule fixtures (plain XS with C)

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use FindBin;

use_ok('ExtUtils::XSOne');

my $src_dir = File::Spec->catdir($FindBin::Bin, 'lib', 'SimpleModule', 'xs');
my $tmpdir  = tempdir(CLEANUP => 1);
my $output  = File::Spec->catfile($tmpdir, 'SimpleModule.xs');

# =============================================================================
# Test combining plain XS files with C code at top
# =============================================================================

subtest 'Combine SimpleModule fixtures' => sub {
    plan tests => 5;

    ok(-d $src_dir, "Source directory exists: $src_dir");

    my $count = ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
        verbose => 0,
    );

    is($count, 3, 'Combined 3 files (foo, bar, baz)');
    ok(-f $output, 'Output file created');

    my @files = ExtUtils::XSOne->files_in_order($src_dir);
    is_deeply(\@files, [qw(bar.xs baz.xs foo.xs)], 'Files in alphabetical order');

    my $content = read_file($output);
    like($content, qr/Generated from:.*bar\.xs.*baz\.xs.*foo\.xs/s,
         'Files combined in alphabetical order');
};

# =============================================================================
# Test C code preservation
# =============================================================================

subtest 'C code at top of files preserved' => sub {
    plan tests => 6;

    my $content = read_file($output);

    # foo.xs C code
    like($content, qr/static int foo_add\(int a, int b\)/, 'foo_add function preserved');
    like($content, qr/static int foo_multiply\(int a, int b\)/, 'foo_multiply function preserved');

    # bar.xs C code
    like($content, qr/static char \*bar_reverse\(const char \*str\)/, 'bar_reverse function preserved');
    like($content, qr/static int bar_is_palindrome\(const char \*str\)/, 'bar_is_palindrome function preserved');

    # baz.xs C code
    like($content, qr/static int baz_sum_array\(int \*arr, int len\)/, 'baz_sum_array function preserved');
    like($content, qr/static int baz_max_array\(int \*arr, int len\)/, 'baz_max_array function preserved');
};

# =============================================================================
# Test includes preserved
# =============================================================================

subtest 'Include directives preserved' => sub {
    plan tests => 4;

    my $content = read_file($output);

    like($content, qr/#include <math\.h>/, 'math.h include preserved');
    like($content, qr/#include <string\.h>/, 'string.h include preserved');
    like($content, qr/#include <stdlib\.h>/, 'stdlib.h include preserved');
    like($content, qr/#include "XSUB\.h"/, 'XSUB.h include preserved');
};

# =============================================================================
# Test MODULE declarations
# =============================================================================

subtest 'MODULE declarations' => sub {
    plan tests => 3;

    my $content = read_file($output);

    like($content, qr/MODULE = SimpleModule\s+PACKAGE = SimpleModule::Foo/, 'Foo module declaration');
    like($content, qr/MODULE = SimpleModule\s+PACKAGE = SimpleModule::Bar/, 'Bar module declaration');
    like($content, qr/MODULE = SimpleModule\s+PACKAGE = SimpleModule::Baz/, 'Baz module declaration');
};

# =============================================================================
# Test XS function definitions preserved
# =============================================================================

subtest 'XS functions preserved' => sub {
    plan tests => 6;

    my $content = read_file($output);

    # Foo functions
    like($content, qr/^int\nadd\(a, b\)/m, 'Foo::add function');
    like($content, qr/^int\nmultiply\(a, b\)/m, 'Foo::multiply function');

    # Bar functions
    like($content, qr/^SV \*\nreverse_string\(str\)/m, 'Bar::reverse_string function');
    like($content, qr/^int\nis_palindrome\(str\)/m, 'Bar::is_palindrome function');

    # Baz functions
    like($content, qr/^int\nsum\(\.\.\.\)/m, 'Baz::sum function');
    like($content, qr/^int\nmax\(\.\.\.\)/m, 'Baz::max function');
};

# =============================================================================
# Test no header/footer requirement
# =============================================================================

subtest 'Works without _header.xs and _footer.xs' => sub {
    plan tests => 2;

    my $content = read_file($output);

    # Should NOT contain _header or _footer references in "Generated from:" header
    unlike($content, qr/Generated from:.*_header\.xs/s, 'No _header.xs (not present in SimpleModule)');
    unlike($content, qr/Generated from:.*_footer\.xs/s, 'No _footer.xs (not present in SimpleModule)');
};

# =============================================================================
# Helper
# =============================================================================

sub read_file {
    my ($path) = @_;
    open(my $fh, '<', $path) or die "Cannot read $path: $!";
    local $/;
    my $content = <$fh>;
    close($fh);
    return $content;
}

done_testing();
