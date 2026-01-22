#!/usr/bin/env perl
# t/02-line-directives.t - Tests for #line directive handling

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);

use_ok('ExtUtils::XSOne');

my $tmpdir = tempdir(CLEANUP => 1);
my $src_dir = File::Spec->catdir($tmpdir, 'xs');
my $output = File::Spec->catfile($tmpdir, 'Test.xs');

make_path($src_dir);

# =============================================================================
# Test #line directives for debugging
# =============================================================================

subtest 'Line directives' => sub {
    plan tests => 4;

    # Create files with known line counts
    write_file(File::Spec->catfile($src_dir, '_header.xs'), <<'XS');
/* Line 1 */
/* Line 2 */
/* Line 3 */
XS

    write_file(File::Spec->catfile($src_dir, 'module.xs'), <<'XS');
/* Module line 1 */
/* Module line 2 */
MODULE = Test    PACKAGE = Test

void
test_func()
CODE:
    /* Some code */
XS

    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    my $content = read_file($output);

    # Each file should have a #line directive in the XS sections
    my @line_directives = $content =~ /(#line \d+ "[^"]+")/g;
    ok(@line_directives >= 2, 'Multiple #line directives present');

    # Check paths are correct
    like($content, qr/#line \d+ "\Q$src_dir\E[\/\\]_header\.xs"/, 'Header #line path correct');
    like($content, qr/#line \d+ "\Q$src_dir\E[\/\\]module\.xs"/, 'Module #line path correct');

    # The directives should come right after BEGIN markers
    like($content, qr/BEGIN: _header\.xs.*\n#line/s, '#line follows BEGIN marker');
};

# =============================================================================
# Test content preservation with deduplication
# =============================================================================

subtest 'Content preserved with deduplication' => sub {
    plan tests => 4;

    my $complex_content = <<'XS';
/* Multi-line comment
   with indentation
   and special chars: $@ % & */

#define MACRO(x) ((x) + 1)

static int function(void) {
    return 42;
}

MODULE = Test    PACKAGE = Test

SV *
new(class)
    char *class
CODE:
    RETVAL = newSVpv("test", 0);
OUTPUT:
    RETVAL
XS

    write_file(File::Spec->catfile($src_dir, 'complex.xs'), $complex_content);

    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    my $combined = read_file($output);

    # The define should be in the preamble
    like($combined, qr/MACRO\(x\).*\(\(x\) \+ 1\)/, 'Macro definition preserved');

    # The C function should be present
    like($combined, qr/static int function\(void\)/, 'C function preserved');

    # The XS code should be present
    like($combined, qr/MODULE = Test\s+PACKAGE = Test/, 'MODULE declaration preserved');
    like($combined, qr/RETVAL = newSVpv/, 'XS CODE block preserved');
};

# =============================================================================
# Test deduplication disabled
# =============================================================================

subtest 'Deduplication disabled' => sub {
    plan tests => 2;

    my $no_dedup_dir = File::Spec->catdir($tmpdir, 'nodedup');
    make_path($no_dedup_dir);

    write_file(File::Spec->catfile($no_dedup_dir, 'a.xs'), <<'XS');
#include <stdio.h>
MODULE = Test  PACKAGE = Test::A
XS

    write_file(File::Spec->catfile($no_dedup_dir, 'b.xs'), <<'XS');
#include <stdio.h>
MODULE = Test  PACKAGE = Test::B
XS

    my $no_dedup_out = File::Spec->catfile($tmpdir, 'nodedup.xs');

    ExtUtils::XSOne->combine(
        src_dir     => $no_dedup_dir,
        output      => $no_dedup_out,
        deduplicate => 0,
    );

    my $content = read_file($no_dedup_out);

    # Should have both includes (not deduplicated)
    my @includes = $content =~ /(#include <stdio\.h>)/g;
    is(scalar(@includes), 2, 'Both includes present when deduplication disabled');

    # Should NOT have combined preamble section
    unlike($content, qr/COMBINED C PREAMBLE/, 'No combined preamble section');
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
