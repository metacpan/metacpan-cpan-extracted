#!/usr/bin/env perl
# t/01-combine.t - Tests for ExtUtils::XSOne->combine

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(make_path remove_tree);
use FindBin qw($Bin);

use_ok('ExtUtils::XSOne');

# Create a temporary directory for test files under t/
my $tmpdir = File::Spec->catdir($Bin, 'tmp', '01-combine');
remove_tree($tmpdir) if -d $tmpdir;
make_path($tmpdir);
END { remove_tree($tmpdir) if $tmpdir && -d $tmpdir }

my $src_dir = File::Spec->catdir($tmpdir, 'xs');
my $output = File::Spec->catfile($tmpdir, 'Combined.xs');

make_path($src_dir);

# =============================================================================
# Test basic functionality
# =============================================================================

subtest 'Basic combine' => sub {
    plan tests => 5;

    # Create test XS files
    write_file(File::Spec->catfile($src_dir, '_header.xs'), <<'XS');
/* Header content */
#include "EXTERN.h"
static int shared_var = 0;
XS

    write_file(File::Spec->catfile($src_dir, 'foo.xs'), <<'XS');
MODULE = Test    PACKAGE = Test::Foo

void
foo()
CODE:
    shared_var = 1;
XS

    write_file(File::Spec->catfile($src_dir, '_footer.xs'), <<'XS');
MODULE = Test    PACKAGE = Test

BOOT:
    shared_var = 0;
XS

    my $count = ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    is($count, 3, 'Combined 3 files');
    ok(-f $output, 'Output file created');

    my $content = read_file($output);
    like($content, qr/THIS FILE IS AUTO-GENERATED/, 'Has auto-generated header');
    # Check file order in the "Generated from:" header
    like($content, qr/Generated from:.*_header\.xs.*foo\.xs.*_footer\.xs/s,
         'Files in correct order');
    like($content, qr/#line 1 "\Q$src_dir\E/, 'Has #line directive');
};

# =============================================================================
# Test file ordering
# =============================================================================

subtest 'File ordering' => sub {
    plan tests => 3;

    # Add more files
    write_file(File::Spec->catfile($src_dir, 'bar.xs'), <<'XS');
MODULE = Test    PACKAGE = Test::Bar
XS

    write_file(File::Spec->catfile($src_dir, 'aaa.xs'), <<'XS');
MODULE = Test    PACKAGE = Test::Aaa
XS

    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    my $content = read_file($output);

    # Default order: _header, then alphabetical, then _footer
    # Check order in the "Generated from:" header
    like($content, qr/Generated from:.*_header\.xs.*aaa\.xs.*bar\.xs.*foo\.xs.*_footer\.xs/s,
         'Alphabetical ordering (default)');

    # Custom order
    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
        order   => [qw(_header foo bar aaa _footer)],
    );

    $content = read_file($output);
    like($content, qr/Generated from:.*_header\.xs.*foo\.xs.*bar\.xs.*aaa\.xs.*_footer\.xs/s,
         'Custom ordering');

    # Partial custom order (remaining files added alphabetically)
    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
        order   => [qw(_header foo _footer)],
    );

    $content = read_file($output);
    like($content, qr/Generated from:.*_header\.xs.*foo\.xs.*_footer\.xs/s,
         'Partial custom ordering');
};

# =============================================================================
# Test files_in_order
# =============================================================================

subtest 'files_in_order' => sub {
    plan tests => 2;

    my @files = ExtUtils::XSOne->files_in_order($src_dir);
    is_deeply(\@files,
              [qw(_header.xs aaa.xs bar.xs foo.xs _footer.xs)],
              'Default file order');

    @files = ExtUtils::XSOne->files_in_order($src_dir, [qw(_header foo bar)]);
    is($files[0], '_header.xs', 'Custom order respected');
};

# =============================================================================
# Test error handling
# =============================================================================

subtest 'Error handling' => sub {
    plan tests => 3;

    eval { ExtUtils::XSOne->combine(output => $output) };
    like($@, qr/src_dir is required/, 'Missing src_dir');

    eval { ExtUtils::XSOne->combine(src_dir => $src_dir) };
    like($@, qr/output is required/, 'Missing output');

    eval { ExtUtils::XSOne->combine(src_dir => '/nonexistent', output => $output) };
    like($@, qr/does not exist/, 'Nonexistent src_dir');
};

# =============================================================================
# Test underscore file handling
# =============================================================================

subtest 'Underscore files' => sub {
    plan tests => 1;

    write_file(File::Spec->catfile($src_dir, '_internal.xs'), <<'XS');
/* Internal helpers */
XS

    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
    );

    my $content = read_file($output);
    # _internal should come after regular files but before _footer
    # Check order in the "Generated from:" header
    like($content, qr/Generated from:.*foo\.xs.*_internal\.xs.*_footer\.xs/s,
         'Underscore files ordered correctly');
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
