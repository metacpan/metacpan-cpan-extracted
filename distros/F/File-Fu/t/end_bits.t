#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

my $root = File::Fu->dir('/');
is($root, '/');
is($root->basename, '/');
is($root->dirname, '/');

my $also = $root;
$also /= 'foo';
is($also, '/foo/');
is($root, '/', 'undamaged');

my $cwd = File::Fu->dir('./');
is($cwd, './');
is($cwd->basename, './');
is($cwd->dirname, './');

my $rpath = $cwd / 'foo' / 'bar' / 'baz';
is($rpath, 'foo/bar/baz/');
is($rpath->dirname, 'foo/bar/');
is($rpath->basename, 'baz/');

my $rpath2 = $cwd / 'foo/bar/baz';
is($rpath2, 'foo/bar/baz/');
is($rpath2->dirname, 'foo/bar/');
is($rpath2->basename, 'baz/');

my $apath = $root / 'foo' / 'bar' / 'baz';
is($apath, '/foo/bar/baz/');
is($apath->dirname, '/foo/bar/');
is($apath->basename, 'baz/');

is("foo:$apath", 'foo:/foo/bar/baz/');

my $afile = $apath+'bort';
is($afile, '/foo/bar/baz/bort');
is("foo:$afile", 'foo:/foo/bar/baz/bort');

my $afile2 = File::Fu->file('/foo/bar/baz/bort');
is($afile2->dir, '/foo/bar/baz/');
is($afile2, '/foo/bar/baz/bort');
is("foo:$afile2", 'foo:/foo/bar/baz/bort');

{
  my $apath2 = $root / 'foo/bar/baz';
  is($apath2, '/foo/bar/baz/');
  is($apath2->dirname, '/foo/bar/');
  is($apath2->basename, 'baz/');

  my $apath3 = $root / 'foo//bar/baz////';
  is($apath3, '/foo/bar/baz/');
  is($apath3->dirname, '/foo/bar/');
  is($apath3->basename, 'baz/');
}

# vim:ts=2:sw=2:et:sta
