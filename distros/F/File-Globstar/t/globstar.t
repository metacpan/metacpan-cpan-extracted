# Copyright (C) 2016-2019 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This file is distributed under the same terms and conditions as
# Perl itself.

use common::sense;

use Test::More tests => 9;

use File::Globstar qw(globstar);

my $dir = __FILE__;
$dir =~ s{[-_a-zA-Z0-9.]+$}{globstar};
ok chdir $dir;

my @files = globstar '*.empty';
is_deeply [sort @files],
          [('one.empty', 'three.empty', 'two.empty')];

@files = globstar '**';
is_deeply [sort @files],
          [qw (
               first
               first/one.empty
               first/second
               first/second/one.empty
               first/second/third
               first/second/third/one.empty
               first/second/third/three.empty
               first/second/third/two.empty
               first/second/three.empty
               first/second/two.empty
               first/three.empty
               first/two.empty
               one.empty
               three.empty
               two.empty
              )];

@files = globstar '**/';
is_deeply [sort @files],
          [qw (
               first/
               first/second/
               first/second/third/
              )];

@files = globstar 'first/**';
is_deeply [sort @files],
          [qw (
               first/
               first/one.empty
               first/second
               first/second/one.empty
               first/second/third
               first/second/third/one.empty
               first/second/third/three.empty
               first/second/third/two.empty
               first/second/three.empty
               first/second/two.empty
               first/three.empty
               first/two.empty
              )];

@files = globstar 'first/**/';
is_deeply [sort @files],
          [qw (
               first/
               first/second/
               first/second/third/
              )];

@files = globstar 'first/**/*.empty';
is_deeply [sort @files],
          [qw (
               first/one.empty
               first/second/one.empty
               first/second/third/one.empty
               first/second/third/three.empty
               first/second/third/two.empty
               first/second/three.empty
               first/second/two.empty
               first/three.empty
               first/two.empty
              )];

@files = globstar '**/t*.*';
is_deeply [sort @files],
          [qw (
               first/second/third/three.empty
               first/second/third/two.empty
               first/second/three.empty
               first/second/two.empty
               first/three.empty
               first/two.empty
               three.empty
               two.empty
              )];

@files = globstar 'first/second/third/**';
is_deeply [sort @files],
          [qw(
              first/second/third/
              first/second/third/one.empty
              first/second/third/three.empty
              first/second/third/two.empty
          )];
