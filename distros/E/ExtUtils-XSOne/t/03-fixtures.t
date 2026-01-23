#!/usr/bin/env perl
# t/03-fixtures.t - Tests using t/lib/TestModule fixtures

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(make_path remove_tree);
use FindBin qw($Bin);

use_ok('ExtUtils::XSOne');

my $src_dir = File::Spec->catdir($Bin, 'lib', 'TestModule', 'xs');

# Create a temporary directory for test files under t/
my $tmpdir = File::Spec->catdir($Bin, 'tmp', '03-fixtures');
remove_tree($tmpdir) if -d $tmpdir;
make_path($tmpdir);
END { remove_tree($tmpdir) if $tmpdir && -d $tmpdir }

my $output  = File::Spec->catfile($tmpdir, 'TestModule.xs');

# =============================================================================
# Test combining the fixture files
# =============================================================================

subtest 'Combine TestModule fixtures' => sub {
    plan tests => 6;

    ok(-d $src_dir, "Source directory exists: $src_dir");

    my $count = ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $output,
        verbose => 0,
    );

    is($count, 4, 'Combined 4 files');
    ok(-f $output, 'Output file created');

    my $content = read_file($output);

    # Check file order in "Generated from:" header
    like($content, qr/Generated from:.*_header\.xs.*context\.xs.*utils\.xs.*_footer\.xs/s,
         'Files in correct order (header, alpha, footer)');

    # Check shared state is present
    like($content, qr/static TestItem \*item_registry/, 'Shared registry declaration present');
    like($content, qr/register_item.*get_item.*unregister_item/s, 'Helper functions present');
};

# =============================================================================
# Test that shared state references work
# =============================================================================

subtest 'Shared state accessibility' => sub {
    plan tests => 4;

    my $content = read_file($output);

    # Context module uses shared registry
    like($content, qr/MODULE = TestModule\s+PACKAGE = TestModule::Context.*register_item/s,
         'Context module calls register_item');

    # Utils module accesses same registry
    like($content, qr/MODULE = TestModule\s+PACKAGE = TestModule::Utils.*get_registry_count/s,
         'Utils module calls get_registry_count');

    # Both use the same static variable
    my @registry_refs = $content =~ /(item_registry)/g;
    ok(@registry_refs >= 3, 'Multiple references to shared item_registry');

    # BOOT section initializes
    like($content, qr/BOOT:.*init_registry/s, 'BOOT section initializes registry');
};

# =============================================================================
# Test #line directives point to fixture files
# =============================================================================

subtest 'Line directives reference fixtures' => sub {
    plan tests => 4;

    my $content = read_file($output);

    like($content, qr{#line 1 ".*TestModule/xs/_header\.xs"}, '_header.xs #line directive');
    like($content, qr{#line 1 ".*TestModule/xs/context\.xs"}, 'context.xs #line directive');
    like($content, qr{#line 1 ".*TestModule/xs/utils\.xs"}, 'utils.xs #line directive');
    like($content, qr{#line 1 ".*TestModule/xs/_footer\.xs"}, '_footer.xs #line directive');
};

# =============================================================================
# Test files_in_order with fixtures
# =============================================================================

subtest 'files_in_order with fixtures' => sub {
    plan tests => 2;

    my @files = ExtUtils::XSOne->files_in_order($src_dir);

    is_deeply(\@files,
              [qw(_header.xs context.xs utils.xs _footer.xs)],
              'Correct default order');

    # Custom order
    @files = ExtUtils::XSOne->files_in_order($src_dir, [qw(_header utils context _footer)]);
    is_deeply(\@files,
              [qw(_header.xs utils.xs context.xs _footer.xs)],
              'Custom order respected');
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
