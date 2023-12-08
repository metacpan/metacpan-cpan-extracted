#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use File::chdir;
#use File::Slurper qw(write_text);
use File::Spec;
use File::Util::Symlink qw(
                              symlink_rel
                              symlink_abs
                              adjust_rel_symlink
                      );
use File::Temp qw(tempfile tempdir);

subtest basics => sub {
    my $dir;
    plan skip_all => "Symlink not supported" unless eval { symlink '', ''; 1 };

  SETUP: {
        $dir = tempdir(CLEANUP => !$ENV{DEBUG});
        local $CWD = $dir;
        mkdir "dir1";
        #write_file "dir1/a", "foo";
        mkdir "dir2";
    }

    diag "tempdir=$dir" if $ENV{DEBUG};

    subtest symlink_rel => sub {
        local $CWD = $dir;
        symlink_rel "dir1/a", "link1";
        is(readlink("link1"), File::Spec->abs2rel("dir1/a", $dir));
        symlink_rel "$dir/dir1/b", "link2";
        is(readlink("link2"), File::Spec->abs2rel("$dir/dir1/b", $dir));
    };

    subtest symlink_abs => sub {
        local $CWD = $dir;
        symlink_abs "dir1/a", "link3";
        is(readlink("link3"), File::Spec->rel2abs("dir1/a", $dir));
        symlink_abs "$dir/dir1/b", "link4";
        is(readlink("link4"), File::Spec->rel2abs("$dir/dir1/b", $dir));
    };

    subtest adjust_rel_symlink => sub {
        local $CWD = $dir;
        open my $fh, ">", "dir1/a"; close $fh;
        symlink "dir1/a", "link5";
        symlink "dir1/a", "dir2/link6";
        adjust_rel_symlink "link5", "dir2/link6";
        is(readlink("dir2/link6"), "../dir1/a");
    };
};

DONE_TESTING:
done_testing;
