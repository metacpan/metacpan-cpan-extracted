#!/usr/bin/env perl
# t/05-edge-cases.t - Edge case tests

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use_ok('ExtUtils::XSOne');

my $tmpdir = tempdir(CLEANUP => 1);

# =============================================================================
# Test empty directory
# =============================================================================

subtest 'Empty directory' => sub {
    plan tests => 1;

    my $empty_dir = File::Spec->catdir($tmpdir, 'empty');
    make_path($empty_dir);

    eval {
        ExtUtils::XSOne->combine(
            src_dir => $empty_dir,
            output  => File::Spec->catfile($tmpdir, 'empty.xs'),
        );
    };
    like($@, qr/No \.xs files found/, 'Dies on empty directory');
};

# =============================================================================
# Test single file
# =============================================================================

subtest 'Single file' => sub {
    plan tests => 3;

    my $single_dir = File::Spec->catdir($tmpdir, 'single');
    make_path($single_dir);

    write_file(File::Spec->catfile($single_dir, 'only.xs'), <<'XS');
MODULE = Only    PACKAGE = Only

void test()
CODE:
    /* nothing */
XS

    my $output = File::Spec->catfile($tmpdir, 'single.xs');
    my $count = ExtUtils::XSOne->combine(
        src_dir => $single_dir,
        output  => $output,
    );

    is($count, 1, 'Combined 1 file');
    ok(-f $output, 'Output created');

    my $content = read_file($output);
    like($content, qr/MODULE = Only/, 'Content preserved');
};

# =============================================================================
# Test files with special characters in content
# =============================================================================

subtest 'Special characters in content' => sub {
    plan tests => 4;

    my $special_dir = File::Spec->catdir($tmpdir, 'special');
    make_path($special_dir);

    # Content with regex-special characters, quotes, etc.
    write_file(File::Spec->catfile($special_dir, 'special.xs'), <<'XS');
/* Special chars: $foo @bar %hash [brackets] (parens) {braces} */
/* More: * + ? | ^ $ . \ */
#define PATTERN "([a-z]+)"
static char *msg = "Hello \"World\"!";
static char *path = "C:\\path\\to\\file";

MODULE = Special    PACKAGE = Special

const char *
get_pattern()
CODE:
    RETVAL = PATTERN;
OUTPUT:
    RETVAL
XS

    my $output = File::Spec->catfile($tmpdir, 'special.xs');
    my $count = ExtUtils::XSOne->combine(
        src_dir => $special_dir,
        output  => $output,
    );

    is($count, 1, 'Combined file with special chars');

    my $content = read_file($output);
    like($content, qr/\$foo \@bar %hash/, 'Perl sigils preserved');
    like($content, qr/PATTERN "\(\[a-z\]\+\)"/, 'Regex pattern preserved');
    like($content, qr{C:\\\\path\\\\to\\\\file}, 'Backslashes preserved');
};

# =============================================================================
# Test no _header or _footer
# =============================================================================

subtest 'No header or footer' => sub {
    plan tests => 3;

    my $noheader_dir = File::Spec->catdir($tmpdir, 'noheader');
    make_path($noheader_dir);

    write_file(File::Spec->catfile($noheader_dir, 'aaa.xs'), "/* aaa */\n");
    write_file(File::Spec->catfile($noheader_dir, 'bbb.xs'), "/* bbb */\n");
    write_file(File::Spec->catfile($noheader_dir, 'ccc.xs'), "/* ccc */\n");

    my $output = File::Spec->catfile($tmpdir, 'noheader.xs');
    my $count = ExtUtils::XSOne->combine(
        src_dir => $noheader_dir,
        output  => $output,
    );

    is($count, 3, 'Combined 3 files');

    my $content = read_file($output);
    like($content, qr/BEGIN: aaa\.xs.*BEGIN: bbb\.xs.*BEGIN: ccc\.xs/s,
         'Alphabetical order without header/footer');

    # No _header or _footer markers
    unlike($content, qr/_header\.xs|_footer\.xs/, 'No header/footer files referenced');
};

# =============================================================================
# Test multiple underscore files
# =============================================================================

subtest 'Multiple underscore files' => sub {
    plan tests => 2;

    my $under_dir = File::Spec->catdir($tmpdir, 'underscore');
    make_path($under_dir);

    write_file(File::Spec->catfile($under_dir, '_header.xs'), "/* header */\n");
    write_file(File::Spec->catfile($under_dir, '_internal.xs'), "/* internal */\n");
    write_file(File::Spec->catfile($under_dir, '_private.xs'), "/* private */\n");
    write_file(File::Spec->catfile($under_dir, 'public.xs'), "/* public */\n");
    write_file(File::Spec->catfile($under_dir, '_footer.xs'), "/* footer */\n");

    my $output = File::Spec->catfile($tmpdir, 'underscore.xs');
    ExtUtils::XSOne->combine(
        src_dir => $under_dir,
        output  => $output,
    );

    my $content = read_file($output);

    # Order: _header, public (regular), _internal, _private (underscore alpha), _footer
    like($content, qr/BEGIN: _header\.xs.*BEGIN: public\.xs.*BEGIN: _internal\.xs.*BEGIN: _private\.xs.*BEGIN: _footer\.xs/s,
         'Underscore files ordered correctly');

    my @files = ExtUtils::XSOne->files_in_order($under_dir);
    is_deeply(\@files,
              [qw(_header.xs public.xs _internal.xs _private.xs _footer.xs)],
              'files_in_order returns correct order');
};

# =============================================================================
# Test output directory creation
# =============================================================================

subtest 'Output directory creation' => sub {
    plan tests => 2;

    my $src_dir = File::Spec->catdir($tmpdir, 'src_for_mkdir');
    make_path($src_dir);
    write_file(File::Spec->catfile($src_dir, 'test.xs'), "/* test */\n");

    my $deep_output = File::Spec->catfile($tmpdir, 'deep', 'nested', 'dir', 'out.xs');

    my $count = ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $deep_output,
    );

    is($count, 1, 'Combine succeeded');
    ok(-f $deep_output, 'Output file created in nested directory');
};

# =============================================================================
# Test large file handling
# =============================================================================

subtest 'Large content' => sub {
    plan tests => 2;

    my $large_dir = File::Spec->catdir($tmpdir, 'large');
    make_path($large_dir);

    # Generate a large file (~100KB)
    my $large_content = "/* Large file test */\n";
    $large_content .= "static int data_$_  = $_;\n" for (1..3000);

    write_file(File::Spec->catfile($large_dir, 'large.xs'), $large_content);

    my $output = File::Spec->catfile($tmpdir, 'large.xs');
    my $count = ExtUtils::XSOne->combine(
        src_dir => $large_dir,
        output  => $output,
    );

    is($count, 1, 'Combined large file');
    ok(-s $output > 50000, 'Output file is large (> 50KB)');
};

# =============================================================================
# Helpers
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
