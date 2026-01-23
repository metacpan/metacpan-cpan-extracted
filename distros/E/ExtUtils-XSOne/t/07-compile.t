#!/usr/bin/env perl
# t/07-compile.t - Test that combined XS files actually compile to C

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(make_path remove_tree);
use FindBin qw($Bin);
use Config;

use_ok('ExtUtils::XSOne');

# Create a temporary directory for test files under t/
my $tmpdir = File::Spec->catdir($Bin, 'tmp', '07-compile');
remove_tree($tmpdir) if -d $tmpdir;
make_path($tmpdir);
END { remove_tree($tmpdir) if $tmpdir && -d $tmpdir }

# Find xsubpp
my $xsubpp = $Config{installprivlib} . '/ExtUtils/xsubpp';
unless (-f $xsubpp) {
    # Try finding it via perl
    $xsubpp = `$^X -MExtUtils::ParseXS -e 'print \$INC{"ExtUtils/ParseXS.pm"}'`;
    $xsubpp =~ s/ParseXS\.pm$/xsubpp/;
}

plan skip_all => "Cannot find xsubpp" unless -f $xsubpp;

# =============================================================================
# Test SimpleModule compiles to C
# =============================================================================

subtest 'SimpleModule compiles to C' => sub {
    plan tests => 6;

    my $src_dir = File::Spec->catdir($Bin, 'lib', 'SimpleModule', 'xs');
    my $xs_file = File::Spec->catfile($tmpdir, 'SimpleModule.xs');
    my $c_file  = File::Spec->catfile($tmpdir, 'SimpleModule.c');

    # Combine
    my $count = ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $xs_file,
    );
    is($count, 3, 'Combined 3 files');
    ok(-f $xs_file, 'XS file created');

    # Run xsubpp to generate C
    my $typemap = $Config{installprivlib} . '/ExtUtils/typemap';
    my $cmd = qq{$^X "$xsubpp" -typemap "$typemap" "$xs_file" > "$c_file" 2>&1};
    my $output = `$cmd`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'xsubpp succeeded') or diag("xsubpp output: $output");
    ok(-f $c_file, 'C file generated');
    ok(-s $c_file > 1000, 'C file has substantial content');

    if (-f $c_file) {
        my $c_content = read_file($c_file);

        # Check for XS wrapper functions
        like($c_content, qr/XS_EUPXS\(XS_SimpleModule__Foo_add\)/,
             'Generated XS wrapper for Foo::add') if $exit_code == 0;
    }
};

# =============================================================================
# Test TestModule compiles to C
# =============================================================================

subtest 'TestModule compiles to C' => sub {
    plan tests => 7;

    my $src_dir = File::Spec->catdir($Bin, 'lib', 'TestModule', 'xs');
    my $xs_file = File::Spec->catfile($tmpdir, 'TestModule.xs');
    my $c_file  = File::Spec->catfile($tmpdir, 'TestModule.c');

    # Combine
    my $count = ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $xs_file,
    );
    is($count, 4, 'Combined 4 files');
    ok(-f $xs_file, 'XS file created');

    # Run xsubpp
    my $typemap = $Config{installprivlib} . '/ExtUtils/typemap';
    my $cmd = qq{$^X "$xsubpp" -typemap "$typemap" "$xs_file" > "$c_file" 2>&1};
    my $output = `$cmd`;
    my $exit_code = $? >> 8;

    is($exit_code, 0, 'xsubpp succeeded') or diag("xsubpp output: $output");
    ok(-f $c_file, 'C file generated');
    ok(-s $c_file > 1000, 'C file has substantial content');

    if (-f $c_file && $exit_code == 0) {
        my $c_content = read_file($c_file);

        # Check for XS wrapper functions
        like($c_content, qr/XS_EUPXS\(XS_TestModule__Context_new\)/,
             'Generated XS wrapper for Context::new');
        like($c_content, qr/XS_EUPXS\(XS_TestModule__Utils_registry_count\)/,
             'Generated XS wrapper for Utils::registry_count');
    }
};

# =============================================================================
# Test #line directives appear in generated C
# =============================================================================

subtest 'Line directives in generated C' => sub {
    plan tests => 3;

    my $src_dir = File::Spec->catdir($Bin, 'lib', 'SimpleModule', 'xs');
    my $xs_file = File::Spec->catfile($tmpdir, 'LineTest.xs');
    my $c_file  = File::Spec->catfile($tmpdir, 'LineTest.c');

    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $xs_file,
    );

    my $typemap = $Config{installprivlib} . '/ExtUtils/typemap';
    my $cmd = qq{$^X "$xsubpp" -typemap "$typemap" "$xs_file" > "$c_file" 2>&1};
    `$cmd`;

    SKIP: {
        skip "C file not generated", 3 unless -f $c_file && -s $c_file > 100;

        my $c_content = read_file($c_file);

        # The #line directives from our combined XS should propagate to C
        # (xsubpp preserves #line directives)
        like($c_content, qr/#line \d+ ".*SimpleModule/, 'C file contains #line reference to source');

        # Check that foo.xs functions are present
        like($c_content, qr/foo_add|XS_SimpleModule__Foo_add/, 'foo.xs content in C');
        like($c_content, qr/bar_reverse|XS_SimpleModule__Bar_reverse/, 'bar.xs content in C');
    }
};

# =============================================================================
# Test combined C code is syntactically valid (compile check)
# =============================================================================

subtest 'C syntax check' => sub {
    my $cc = $Config{cc};

    # Skip if no compiler available
    my $cc_check = `$cc --version 2>&1`;
    plan skip_all => "C compiler not available" if $? != 0;

    plan tests => 2;

    my $src_dir = File::Spec->catdir($Bin, 'lib', 'SimpleModule', 'xs');
    my $xs_file = File::Spec->catfile($tmpdir, 'SyntaxTest.xs');
    my $c_file  = File::Spec->catfile($tmpdir, 'SyntaxTest.c');

    ExtUtils::XSOne->combine(
        src_dir => $src_dir,
        output  => $xs_file,
    );

    my $typemap = $Config{installprivlib} . '/ExtUtils/typemap';
    my $cmd = qq{$^X "$xsubpp" -typemap "$typemap" "$xs_file" > "$c_file" 2>&1};
    `$cmd`;

    SKIP: {
        skip "C file not generated", 2 unless -f $c_file && -s $c_file > 100;

        # Try to compile (syntax check only, don't link)
        # Include ccflags to get necessary definitions like -D_LARGEFILE64_SOURCE
        # which are required for off64_t and other Perl-configured types
        my $perl_inc = $Config{archlibexp} . '/CORE';
        my $ccflags = $Config{ccflags} || '';
        my $compile_cmd = qq{$cc -fsyntax-only $ccflags -I"$perl_inc" "$c_file" 2>&1};
        my $compile_out = `$compile_cmd`;
        my $compile_exit = $? >> 8;

        # Some compilers don't support -fsyntax-only, try -c instead
        if ($compile_exit != 0 && $compile_out =~ /unrecognized|unknown/) {
            my $obj_file = File::Spec->catfile($tmpdir, 'SyntaxTest.o');
            $compile_cmd = qq{$cc -c $ccflags -I"$perl_inc" "$c_file" -o "$obj_file" 2>&1};
            $compile_out = `$compile_cmd`;
            $compile_exit = $? >> 8;
        }

        is($compile_exit, 0, 'C code compiles without errors')
            or diag("Compiler output: $compile_out");
        ok(1, 'Syntax check complete');
    }
};

# =============================================================================
# Helper
# =============================================================================

sub read_file {
    my ($path) = @_;
    open(my $fh, '<', $path) or return '';
    local $/;
    my $content = <$fh>;
    close($fh);
    return $content;
}

done_testing();
