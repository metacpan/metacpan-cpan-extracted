#!/usr/bin/env perl
# t/09-load-xs.t - Test that combined XS modules can be built and loaded

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use FindBin qw($Bin);
use Config;
use Cwd qw(getcwd);

use_ok('ExtUtils::XSOne');

# Skip if we can't find necessary build tools
my $make = $Config{make};
plan skip_all => "make not available" unless $make && `$make --version 2>&1`;

my $cc = $Config{cc};
plan skip_all => "C compiler not available" unless $cc && `$cc --version 2>&1`;

# Base temp directory under t/
my $base_tmpdir = File::Spec->catdir($Bin, 'tmp', '09-load-xs');
remove_tree($base_tmpdir) if -d $base_tmpdir;
make_path($base_tmpdir);
END { remove_tree($base_tmpdir) if $base_tmpdir && -d $base_tmpdir }

# =============================================================================
# Build and test a simple XS module
# =============================================================================

subtest 'Build and load SimpleModule' => sub {
    my $tmpdir = File::Spec->catdir($base_tmpdir, 'simple');
    make_path($tmpdir);
    my $orig_dir = getcwd();

    # Create module structure
    my $lib_dir = File::Spec->catdir($tmpdir, 'lib');
    make_path($lib_dir);

    # Combine XS files
    my $src_dir = File::Spec->catdir($Bin, 'lib', 'SimpleModule', 'xs');
    my $xs_file = File::Spec->catfile($tmpdir, 'SimpleModule.xs');

    my $count = ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $xs_file,
    );
    ok($count >= 1, "Combined $count XS files");

    # Create a minimal Perl module
    write_file(File::Spec->catfile($lib_dir, 'SimpleModule.pm'), <<'PM');
package SimpleModule;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('SimpleModule', $VERSION);
1;
PM

    # Create Makefile.PL
    write_file(File::Spec->catfile($tmpdir, 'Makefile.PL'), <<"MAKEFILEPL");
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SimpleModule',
    VERSION_FROM => 'lib/SimpleModule.pm',
    XS           => { 'SimpleModule.xs' => 'SimpleModule.c' },
    OBJECT       => 'SimpleModule\$(OBJ_EXT)',
);
MAKEFILEPL

    # Build the module
    chdir $tmpdir or die "Cannot chdir to $tmpdir: $!";

    my $perl_cmd = qq{"$^X" Makefile.PL 2>&1};
    my $output = `$perl_cmd`;
    my $exit = $? >> 8;

    if ($exit != 0) {
        chdir $orig_dir;
        diag("Makefile.PL failed: $output");
        fail("Makefile.PL succeeded");
        return;
    }
    pass("Makefile.PL succeeded");

    $output = `$make 2>&1`;
    $exit = $? >> 8;

    if ($exit != 0) {
        chdir $orig_dir;
        diag("make failed: $output");
        fail("make succeeded");
        return;
    }
    pass("make succeeded");

    # Find the built .so/.bundle/.dll
    my $blib_arch = File::Spec->catdir($tmpdir, 'blib', 'arch', 'auto', 'SimpleModule');
    my @so_files = glob("$blib_arch/*.$Config{dlext}");

    if (!@so_files) {
        chdir $orig_dir;
        diag("No shared library found in $blib_arch");
        fail("Shared library created");
        return;
    }
    pass("Shared library created");

    # Test loading and using the module
    my $blib_lib = File::Spec->catdir($tmpdir, 'blib', 'lib');
    my $test_script = <<'TEST';
use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use SimpleModule;

# Test SimpleModule::Foo
my $sum = SimpleModule::Foo::add(2, 3);
die "add(2,3) failed: got $sum" unless $sum == 5;

my $product = SimpleModule::Foo::multiply(4, 5);
die "multiply(4,5) failed: got $product" unless $product == 20;

# Test SimpleModule::Bar
my $reversed = SimpleModule::Bar::reverse_string("hello");
die "reverse_string failed: got $reversed" unless $reversed eq "olleh";

my $len = SimpleModule::Bar::string_length("test");
die "string_length failed: got $len" unless $len == 4;

my $is_pal = SimpleModule::Bar::is_palindrome("racecar");
die "is_palindrome failed: got $is_pal" unless $is_pal == 1;

# Test SimpleModule::Baz
my $total = SimpleModule::Baz::sum(1, 2, 3, 4, 5);
die "sum failed: got $total" unless $total == 15;

my $max = SimpleModule::Baz::max(3, 1, 4, 1, 5, 9);
die "max failed: got $max" unless $max == 9;

my $min = SimpleModule::Baz::min(3, 1, 4, 1, 5, 9);
die "min failed: got $min" unless $min == 1;

print "ALL_TESTS_PASSED\n";
TEST

    write_file(File::Spec->catfile($tmpdir, 'test_module.pl'), $test_script);

    $output = `"$^X" test_module.pl 2>&1`;
    $exit = $? >> 8;

    chdir $orig_dir;

    if ($exit != 0 || $output !~ /ALL_TESTS_PASSED/) {
        diag("Module test failed: $output");
        fail("Module functions work correctly");
        return;
    }
    pass("Module functions work correctly");

    # Verify all three packages are available
    like($output, qr/ALL_TESTS_PASSED/, 'All XS functions from all packages work');
};

# =============================================================================
# Test that shared state works across modules
# =============================================================================

subtest 'Shared state across modules' => sub {
    my $tmpdir = File::Spec->catdir($base_tmpdir, 'shared');
    make_path($tmpdir);
    my $orig_dir = getcwd();

    # Create a module with shared state
    my $xs_dir = File::Spec->catdir($tmpdir, 'xs');
    my $lib_dir = File::Spec->catdir($tmpdir, 'lib');
    make_path($xs_dir, $lib_dir);

    # _header.xs with shared state
    write_file(File::Spec->catfile($xs_dir, '_header.xs'), <<'XS');
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Shared counter across all packages */
static int shared_counter = 0;
XS

    # Module A increments counter
    write_file(File::Spec->catfile($xs_dir, 'a.xs'), <<'XS');
MODULE = SharedTest    PACKAGE = SharedTest::A

void
increment()
CODE:
    shared_counter++;

int
get_count()
CODE:
    RETVAL = shared_counter;
OUTPUT:
    RETVAL
XS

    # Module B also accesses the same counter
    write_file(File::Spec->catfile($xs_dir, 'b.xs'), <<'XS');
MODULE = SharedTest    PACKAGE = SharedTest::B

void
increment_by(int n)
CODE:
    shared_counter += n;

int
get_count()
CODE:
    RETVAL = shared_counter;
OUTPUT:
    RETVAL

void
reset()
CODE:
    shared_counter = 0;
XS

    # Combine
    my $xs_file = File::Spec->catfile($tmpdir, 'SharedTest.xs');
    my $count = ExtUtils::XSOne->combine(
        src_dir => $xs_dir,
        output  => $xs_file,
    );
    ok($count >= 2, "Combined $count XS files");

    # Create Perl module
    write_file(File::Spec->catfile($lib_dir, 'SharedTest.pm'), <<'PM');
package SharedTest;
use strict;
use warnings;
our $VERSION = '0.01';
require XSLoader;
XSLoader::load('SharedTest', $VERSION);
1;
PM

    # Create Makefile.PL
    write_file(File::Spec->catfile($tmpdir, 'Makefile.PL'), <<"MAKEFILEPL");
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'SharedTest',
    VERSION_FROM => 'lib/SharedTest.pm',
    XS           => { 'SharedTest.xs' => 'SharedTest.c' },
    OBJECT       => 'SharedTest\$(OBJ_EXT)',
);
MAKEFILEPL

    # Build
    chdir $tmpdir or die "Cannot chdir to $tmpdir: $!";

    my $output = `"$^X" Makefile.PL 2>&1`;
    if (($? >> 8) != 0) {
        chdir $orig_dir;
        diag("Makefile.PL failed: $output");
        fail("Build succeeded");
        return;
    }

    $output = `$make 2>&1`;
    if (($? >> 8) != 0) {
        chdir $orig_dir;
        diag("make failed: $output");
        fail("Build succeeded");
        return;
    }
    pass("Build succeeded");

    # Test shared state
    my $test_script = <<'TEST';
use strict;
use warnings;
use lib qw(blib/lib blib/arch);
use SharedTest;

# Start fresh
SharedTest::B::reset();
my $count = SharedTest::A::get_count();
die "Initial count should be 0, got $count" unless $count == 0;

# Increment from A
SharedTest::A::increment();
$count = SharedTest::A::get_count();
die "Count after A::increment should be 1, got $count" unless $count == 1;

# Check from B - should see the same counter!
$count = SharedTest::B::get_count();
die "B should see count=1, got $count" unless $count == 1;

# Increment from B
SharedTest::B::increment_by(5);
$count = SharedTest::B::get_count();
die "Count after B::increment_by(5) should be 6, got $count" unless $count == 6;

# A should see the updated count
$count = SharedTest::A::get_count();
die "A should see count=6, got $count" unless $count == 6;

# Reset from B, check from A
SharedTest::B::reset();
$count = SharedTest::A::get_count();
die "After reset, A should see 0, got $count" unless $count == 0;

print "SHARED_STATE_WORKS\n";
TEST

    write_file(File::Spec->catfile($tmpdir, 'test_shared.pl'), $test_script);

    $output = `"$^X" test_shared.pl 2>&1`;
    my $exit = $? >> 8;

    chdir $orig_dir;

    if ($exit != 0 || $output !~ /SHARED_STATE_WORKS/) {
        diag("Shared state test failed: $output");
        fail("Shared state works across packages");
        return;
    }
    pass("Shared state works across packages");

    like($output, qr/SHARED_STATE_WORKS/,
         'Modules share C static variables (the main purpose of XSOne!)');
};

# =============================================================================
# Helper
# =============================================================================

sub write_file {
    my ($path, $content) = @_;
    open(my $fh, '>', $path) or die "Cannot write $path: $!";
    print $fh $content;
    close($fh);
}

done_testing();
