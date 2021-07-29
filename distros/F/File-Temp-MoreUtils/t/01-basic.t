#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use File::Temp qw(tempdir);
use File::Temp::MoreUtils qw(tempfile_named tempdir_named);

my $tempdir = tempdir(CLEANUP => !$ENV{DEBUG});
subtest tempfile_named => sub {
    chdir $tempdir or die;

    my $fh;
    open $fh, ">", "a" or die;
    open $fh, ">", "b.txt" or die;
    open $fh, ">", "c." or die;
    mkdir "d1" or die;

    dies_ok { tempfile_named() } "no name arg -> dies";
    is_deeply([tempfile_named(name => "a")]->[1], "a.1");
    ok(-f "a.1");
    is_deeply([tempfile_named(name => "a")]->[1], "a.2");

    is_deeply([tempfile_named(name => "b.txt")]->[1], "b.1.txt");
    is_deeply([tempfile_named(name => "b.txt")]->[1], "b.2.txt");

    is_deeply([tempfile_named(name => "c.")]->[1], "c..1");
    is_deeply([tempfile_named(name => "c.")]->[1], "c..2");

    is_deeply([tempfile_named(name => "d1")]->[1], "d1.1");

    subtest "dir arg" => sub {
        is_deeply([tempfile_named(name => "a", dir=>"d1")]->[1], "d1/a");
        is_deeply([tempfile_named(name => "a", dir=>"d1")]->[1], "d1/a.1");

        like([tempfile_named(name => "a", dir=>undef)]->[1], qr{[/\\]a\z});
        like([tempfile_named(name => "a", dir=>undef)]->[1], qr{[/\\]a\.1\z});

        dies_ok { tempfile_named(name => "a", dir=>"$tempdir/noexist") } "dir doesn't exist -> dies";
    };

    subtest "suffix_start arg" => sub {
        is_deeply([tempfile_named(name => "a", suffix_start=>"tmp1")]->[1], "a.tmp1");
        is_deeply([tempfile_named(name => "a", suffix_start=>"tmp1")]->[1], "a.tmp2");
    };
};

subtest tempdir_named => sub {
    chdir $tempdir or die;

    my $fh;
    open $fh, ">", "j" or die;
    open $fh, ">", "k.dir" or die;
    open $fh, ">", "l." or die;
    mkdir "d2" or die;

    dies_ok { tempdir_named() } "no name arg -> dies";
    is_deeply(tempdir_named(name => "j"), "j.1");
    ok(-d "j.1");
    is_deeply(tempdir_named(name => "j"), "j.2");

    is_deeply(tempdir_named(name => "k.dir"), "k.1.dir");
    is_deeply(tempdir_named(name => "k.dir"), "k.2.dir");

    is_deeply(tempdir_named(name => "l."), "l..1");
    is_deeply(tempdir_named(name => "l."), "l..2");

    is_deeply(tempdir_named(name => "d2"), "d2.1");

    subtest "dir arg" => sub {
        is_deeply(tempdir_named(name => "j", dir=>"d1"), "d1/j");
        is_deeply(tempdir_named(name => "j", dir=>"d1"), "d1/j.1");

        like(tempdir_named(name => "j", dir=>undef), qr{[/\\]j\z});
        like(tempdir_named(name => "j", dir=>undef), qr{[/\\]j\.1\z});

        dies_ok { tempdir_named(name => "j", dir=>"$tempdir/noexist") } "dir doesn't exist -> dies";
    };

    subtest "suffix_start arg" => sub {
        is_deeply(tempdir_named(name => "j", suffix_start=>"tmp1"), "j.tmp1");
        is_deeply(tempdir_named(name => "j", suffix_start=>"tmp1"), "j.tmp2");
    };
};

done_testing;
