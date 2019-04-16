#!perl

use strict;
use warnings;
#use Test::Exception;
use Test::More 0.98;

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
is($res->[0], 200) or diag explain $res;
# XXX test actual results
done_testing;
