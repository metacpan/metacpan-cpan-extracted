#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use File::chdir;
use File::Find::Wanted qw(find_wanted);
use File::Path qw(rmtree);
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use File::Util::DirList qw(mv_files_to_dirs);

my $tempdir = tempdir(CLEANUP=>1);

sub setup_mv_files_to_dirs {
    rmtree("subd");
    mkdir "subd";
    local $CWD = "subd";
    mkdir("d1");
    mkdir("d2");
    mkdir("d3");
    mkdir("d4");
    write_text("f1", "");
    write_text("f2", "");
    write_text("f3", "");
    write_text("f4", "");
    write_text("f5", "");
    write_text("f6", "");
    write_text("f7", "");
    write_text("f8", "");
}

subtest mv_files_to_dirs => sub {
    local $CWD = $tempdir;
    mkdir "mv_files_to_dirs";
    $CWD = "mv_files_to_dirs";

    subtest basics => sub {
        setup_mv_files_to_dirs();
        local $CWD = "subd";
        my $res = mv_files_to_dirs(files_then_dirs => [qw/f1 f2 f3 f4 d1 d2 d3 d4/]);
        is($res->[0], 200) or diag explain $res;
        is_deeply([sort(find_wanted(sub {-f}, "."))], [map {"./$_"} qw(d1/f1 d2/f2 d3/f3 d4/f4 f5 f6 f7 f8)]);
    };

    subtest "arg: files_per_dir" => sub {
        setup_mv_files_to_dirs();
        local $CWD = "subd";
        my $res = mv_files_to_dirs(files_then_dirs => [qw/f1 f2 f3 f4 f5 f6 d1 d2/], files_per_dir=>3);
        is($res->[0], 200) or diag explain $res;
        is_deeply([sort(find_wanted(sub {-f}, "."))], [map {"./$_"} qw(d1/f1 d1/f2 d1/f3 d2/f4 d2/f5 d2/f6 f7 f8)]);
    };

    subtest "arg: reverse" => sub {
        setup_mv_files_to_dirs();
        local $CWD = "subd";
        my $res = mv_files_to_dirs(files_then_dirs => [qw/f1 f2 f3 f4 f5 f6 d1 d2/], files_per_dir=>3, reverse=>1);
        is($res->[0], 200) or diag explain $res;
        is_deeply([sort(find_wanted(sub {-f}, "."))], [map {"./$_"} qw(d1/f4 d1/f5 d1/f6 d2/f1 d2/f2 d2/f3 f7 f8)]);
    };
};

done_testing;
