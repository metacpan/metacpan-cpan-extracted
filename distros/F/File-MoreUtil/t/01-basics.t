#!perl

use 5.010;
use strict;
use warnings;

use Cwd qw(abs_path);
use File::chdir;
use File::Slurp::Tiny qw(write_file);
use File::Spec;
use Test::More 0.98;

plan skip_all => "symlink() not available"
    unless eval { symlink "", ""; 1 };

use File::Temp qw(tempfile tempdir);
use File::MoreUtil qw(file_exists l_abs_path dir_empty);

subtest file_exists => sub {
    my ($fh1, $target)  = tempfile();
    my ($fh2, $symlink) = tempfile();

    ok(file_exists($target), "existing file");

    unlink($symlink);
    symlink($target, $symlink);
    ok(file_exists($symlink), "symlink to existing file");

    unlink($target);
    ok(!file_exists($target), "non-existing file");
    ok(file_exists($symlink), "symlink to non-existing file");

    unlink($symlink);
};

subtest l_abs_path => sub {
    my $dir = abs_path(tempdir(CLEANUP=>1));
    local $CWD = $dir;

    mkdir("tmp");
    write_file("tmp/file", "");
    symlink("file", "tmp/symfile");
    symlink("$dir/tmp", "tmp/symdir");
    symlink("not_exists", "tmp/symnef"); # non-existing file
    symlink("/not_exists".rand()."/1", "tmp/symnep"); # non-existing path

    is(  abs_path("tmp/file"   ), "$dir/tmp/file"   , "abs_path file");
    is(l_abs_path("tmp/file"   ), "$dir/tmp/file"   , "l_abs_path file");
    is(  abs_path("tmp/symfile"), "$dir/tmp/file"   , "abs_path symfile");
    is(l_abs_path("tmp/symfile"), "$dir/tmp/symfile", "l_abs_path symfile");
    is(  abs_path("tmp/symdir" ), "$dir/tmp"        , "abs_path symdir");
    is(l_abs_path("tmp/symdir" ), "$dir/tmp/symdir" , "l_abs_path symdir");
    is(  abs_path("tmp/symnef" ), "$dir/tmp/not_exists", "abs_path symnef");
    is(l_abs_path("tmp/symnef" ), "$dir/tmp/symnef" , "l_abs_path symnef");
    ok(! abs_path("tmp/symnep" ), "abs_path symnep");
    is(l_abs_path("tmp/symnep" ), "$dir/tmp/symnep" , "l_abs_path symnep");
};

subtest dir_empty => sub {
    my $dir = tempdir(CLEANUP=>1);
    local $CWD = $dir;

    mkdir "empty", 0755;

    mkdir "hasfiles", 0755;
    write_file("hasfiles/1", "");

    mkdir "hasdotfiles", 0755;
    write_file("hasdotfiles/.1", "");

    mkdir "hasdotdirs", 0755;
    mkdir "hasdotdirs/.1";

    mkdir "unreadable", 0000;

    ok( dir_empty("empty"), "empty");
    ok(!dir_empty("doesntexist"), "doesntexist");
    ok(!dir_empty("hasfiles"), "hasfiles");
    ok(!dir_empty("hasdotfiles"), "hasdotfiles");
    ok(!dir_empty("hasdotdirs"), "hasdotdirs");
    ok(!dir_empty("unreadable"), "unreadable") if $>;
};

DONE_TESTING:
done_testing();
