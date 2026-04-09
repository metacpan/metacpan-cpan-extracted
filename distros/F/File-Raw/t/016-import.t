#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);

my $tmpdir = tempdir(CLEANUP => 1);

# Test 1: Selective import of specific functions
{
    package TestSelectiveImport;
    use File::Raw qw(slurp spew);
    use Test::More;
    
    my $file = "$tmpdir/selective.txt";
    
    ok(defined &file_slurp, 'file_slurp imported');
    ok(defined &file_spew, 'file_spew imported');
    ok(!defined &file_exists, 'file_exists not imported');
    ok(!defined &file_lines, 'file_lines not imported');
    
    # Test they work
    file_spew($file, "hello world");
    is(file_slurp($file), "hello world", 'selective import functions work');
}

# Test 2: Import :all
{
    package TestImportAll;
    use File::Raw qw(:all);
    use Test::More;
    
    my $file = "$tmpdir/all.txt";
    
    ok(defined &file_slurp, 'file_slurp imported via :all');
    ok(defined &file_spew, 'file_spew imported via :all');
    ok(defined &file_exists, 'file_exists imported via :all');
    ok(defined &file_lines, 'file_lines imported via :all');
    ok(defined &file_copy, 'file_copy imported via :all');
    ok(defined &file_move, 'file_move imported via :all');
    ok(defined &file_chmod, 'file_chmod imported via :all');
    ok(defined &file_basename, 'file_basename imported via :all');
    ok(defined &file_dirname, 'file_dirname imported via :all');
    
    file_spew($file, "test content");
    ok(file_exists($file), 'file_exists works');
    is(file_size($file), 12, 'file_size works');
}

# Test 3: Backwards compat - 'import' tag
{
    package TestImportBackwardsCompat;
    use File::Raw qw(import);
    use Test::More;
    
    ok(defined &file_slurp, 'file_slurp imported via import tag');
    ok(defined &file_spew, 'file_spew imported via import tag');
    ok(defined &file_exists, 'file_exists imported via import tag');
}

# Test 4: No import args = no imports
{
    package TestNoImport;
    use File::Raw;
    use Test::More;
    
    ok(!defined &file_slurp, 'file_slurp NOT imported with no args');
    ok(!defined &file_spew, 'file_spew NOT imported with no args');
    
    # But fully qualified still works
    my $file = "$tmpdir/noexport.txt";
    File::Raw::spew($file, "test");
    is(File::Raw::slurp($file), "test", 'fully qualified still works');
}

# Test 5: Multiple selective imports
{
    package TestMultipleSelective;
    use File::Raw qw(exists size mtime basename dirname);
    use Test::More;
    
    ok(defined &file_exists, 'file_exists imported');
    ok(defined &file_size, 'file_size imported');
    ok(defined &file_mtime, 'file_mtime imported');
    ok(defined &file_basename, 'file_basename imported');
    ok(defined &file_dirname, 'file_dirname imported');
    ok(!defined &file_slurp, 'file_slurp NOT imported');
    ok(!defined &file_spew, 'file_spew NOT imported');
    
    is(file_basename('/foo/bar/baz.txt'), 'baz.txt', 'basename works');
    is(file_dirname('/foo/bar/baz.txt'), '/foo/bar', 'dirname works');
}

# Test 6: 2-arg functions
{
    package TestTwoArgFuncs;
    use File::Raw qw(copy move append atomic_spew);
    use Test::More;
    
    ok(defined &file_copy, 'file_copy imported');
    ok(defined &file_move, 'file_move imported');
    ok(defined &file_append, 'file_append imported');
    ok(defined &file_atomic_spew, 'file_atomic_spew imported');
    
    my $src = "$tmpdir/src.txt";
    my $dst = "$tmpdir/dst.txt";
    
    File::Raw::spew($src, "content");
    file_copy($src, $dst);
    is(File::Raw::slurp($dst), "content", 'file_copy works');
    
    file_append($dst, " more");
    is(File::Raw::slurp($dst), "content more", 'file_append works');
}

# Test 7: Variadic functions (join, mkpath, rm_rf)
{
    package TestVariadicImport;
    use File::Raw qw(join mkpath rm_rf is_dir);
    use Test::More;

    ok(defined &file_join, 'file_join imported selectively');
    ok(defined &file_mkpath, 'file_mkpath imported selectively');
    ok(defined &file_rm_rf, 'file_rm_rf imported selectively');
    ok(!defined &file_slurp, 'file_slurp NOT imported');
    ok(!defined &file_spew, 'file_spew NOT imported');

    my $sep = $^O eq 'MSWin32' ? '\\' : '/';
    is(file_join('x', 'y'), "x${sep}y", 'file_join works via selective import');

    my $d = file_join($tmpdir, 'variadic_test', 'deep');
    file_mkpath($d);
    ok(file_is_dir($d), 'file_mkpath works via selective import');
    file_rm_rf(file_join($tmpdir, 'variadic_test'));
    ok(!file_is_dir(file_join($tmpdir, 'variadic_test')), 'file_rm_rf works via selective import');
}

# Test 8: Variadic functions via :all
{
    package TestVariadicAll;
    use File::Raw qw(:all);
    use Test::More;

    ok(defined &file_join, 'file_join imported via :all');
    ok(defined &file_mkpath, 'file_mkpath imported via :all');
    ok(defined &file_rm_rf, 'file_rm_rf imported via :all');
}

done_testing;
