#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use File::Common qw(list_common_files);
use File::Create::Layout qw(create_files_using_layout);
use File::Temp qw(tempdir);

my $DEBUG = $ENV{DEBUG};
my $tempdir = tempdir(CLEANUP => !$DEBUG);
note "tempdir=$tempdir";

my $layout = <<'_';
dir1/
  a
  b
  d
  sub1/
    g
    h
    j
  sub2/
    m
    n

dir2/
  a
  b
  c
  e
  sub1/
    g
    h
    i
    l
  sub2/
    m
    o

dir3/
  a
  c
  f
  sub1/
    g
    i
    m
  sub2
_
my $res = create_files_using_layout(layout=>$layout, prefix=>$tempdir);
$res->[0] == 200 or die "Can't create files: $res->[0] - $res->[1]";

subtest "basics" => sub {
    is_deeply(
        list_common_files(
            dirs => ["$tempdir/dir1", "$tempdir/dir2", "$tempdir/dir3"]),
        [qw(a sub1/g)],
    );
};

subtest "opt: min_occurrence" => sub {
    is_deeply(
        list_common_files(
            dirs => ["$tempdir/dir1", "$tempdir/dir2", "$tempdir/dir3"],
            min_occurrence => 2),
        [qw(a b c sub1/g sub1/h sub1/i sub2/m)],
    );
};

subtest "opt: detail" => sub {
    my $dirs = ["$tempdir/dir1", "$tempdir/dir2", "$tempdir/dir3"];

    is_deeply(
        list_common_files(
            dirs => $dirs,
            detail => 1),
        {
            a => {dirs=>$dirs},
            "sub1/g" => {dirs=>$dirs},
        },
    );

    is_deeply(
        list_common_files(
            dirs => $dirs,
            min_occurrence => 2,
            detail => 1),
        {
            a => {dirs=>$dirs},
            b => {dirs=>["$tempdir/dir1", "$tempdir/dir2"]},
            c => {dirs=>["$tempdir/dir2", "$tempdir/dir3"]},
            "sub1/g" => {dirs=>$dirs},
            "sub1/h" => {dirs=>["$tempdir/dir1", "$tempdir/dir2"]},
            "sub1/i" => {dirs=>["$tempdir/dir2", "$tempdir/dir3"]},
            "sub2/m" => {dirs=>["$tempdir/dir1", "$tempdir/dir2"]},
        },
    );
};

done_testing;
