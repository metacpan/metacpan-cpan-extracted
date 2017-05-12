# check core module: File

use strict;
use warnings;

use Test::More tests => 24;

#=== Dependencies
use Konstrukt::Settings;
use Konstrukt::Cache;

#=== Current working directory
use Cwd;
my $cwd = getcwd();
$cwd .= "/" unless substr($cwd, -1, 1) eq "/";
use Konstrukt::File;
$Konstrukt::File->set_root($cwd);

#=== File
#clean path
is($Konstrukt::File->clean_path("//foo/bar\\/\\foo/bar/baz/././../baz/"), "/foo/bar/foo/bar/baz/", "clean_path unix");
is($Konstrukt::File->clean_path("foo/bar/bazc:\\foo/bar/baz"), "c:/foo/bar/baz", "clean_path ms");

#set root, get root, current dir
is($Konstrukt::File->set_root($cwd), $cwd, "set_root: slash at the end");
is($Konstrukt::File->set_root(substr($cwd, 0, length($cwd) - 1)), $cwd, "set_root: no slash at the end");
is($Konstrukt::File->get_root(), $cwd, "get_root");
is($Konstrukt::File->current_dir(), $cwd, "set_root and current_dir");

#absolute/relative path
is($Konstrukt::File->absolute_path("/foo/bar/baz"), $cwd . "foo/bar/baz", "absolute_path");
is($Konstrukt::File->relative_path($cwd . "foo/bar/baz"), "foo/bar/baz", "relative_path");
$Konstrukt::File->set_root('/some/root/dir/');
is($Konstrukt::File->relative_path("/some/foo/bar/baz"), "../../foo/bar/baz", "relative_path: dir above root");
$Konstrukt::File->set_root('C:\\some\\root\\dir\\');
is($Konstrukt::File->relative_path("C:\\some\\foo\\bar\\baz"), "../../foo/bar/baz", "relative_path: dir above root (win)");
$Konstrukt::File->set_root($cwd);

#read and track, current dir/file
is($Konstrukt::File->read_and_track("/t/data/File/test.txt"), "this\nis\na\ntest\nfile", "read_and_track: abolute path");
is($Konstrukt::File->read_and_track("somedir/foo.txt"), "bar", "read_and_track: relative path");
is($Konstrukt::File->current_dir(), $cwd . "t/data/File/somedir/", "current_dir");
is($Konstrukt::File->current_file(), $cwd . "t/data/File/somedir/foo.txt", "current_file");

#get dirs/files
is_deeply([ $Konstrukt::File->get_dirs() ], [$cwd, $cwd . "t/data/File/", $cwd . "t/data/File/somedir/"], "get_dirs");
is_deeply([ $Konstrukt::File->get_files() ], [$cwd . "t/data/File/test.txt", $cwd . "t/data/File/somedir/foo.txt"], "get_files");

#pop, read
$Konstrukt::File->pop();
$Konstrukt::File->pop();
is($Konstrukt::File->read("t/data/File/test.txt"), "this\nis\na\ntest\nfile", "pop, read: relative path");
is($Konstrukt::File->current_dir(), $cwd, "pop, current_dir");

#extract path/file
is($Konstrukt::File->extract_path("foo/bar/baz"), "foo/bar/", "extract_path");
is($Konstrukt::File->extract_file("foo/bar/baz"), "baz", "extract_file");

#write, read
is($Konstrukt::File->write("/t/data/File/writetest.tmp", "testdata"), 1, "write, raw_write");
is($Konstrukt::File->read("/t/data/File/writetest.tmp"), "testdata", "write, raw_write");
unlink($Konstrukt::File->absolute_path("/t/data/File/writetest.tmp"));

#create dirs
is($Konstrukt::File->create_dirs($Konstrukt::File->absolute_path("/t/data/File/some/test/directories")), 1, "create_dirs");
is(-d $Konstrukt::File->absolute_path("/t/data/File/some/test/directories"), 1, "create_dirs");
rmdir($Konstrukt::File->absolute_path("/t/data/File/some/test/directories"));
rmdir($Konstrukt::File->absolute_path("/t/data/File/some/test"));
rmdir($Konstrukt::File->absolute_path("/t/data/File/some"));
