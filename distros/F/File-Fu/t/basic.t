#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

my $dir = File::Fu->dir;
ok($dir, 'constructor');
is($dir, File::Fu::Dir->new('.'), 'current directory default');
is("$dir", './', 'stringify');
is("$dir\n", "./\n", 'stringify');
is($dir->part(0), '.');
is($dir->part(-1), '.');

my $root = File::Fu->dir('/');
ok(defined($root), 'root dir');
ok($root->is_absolute, 'absolute');
is($root, '/');
is($root->part(0), '');
is($root->part(-1), '');

my $file = $dir + 'Build.PL';
is("$file", "Build.PL");
ok($file->e, 'file exists');
my $abs_dir = $dir->absolute;
ok($abs_dir->is_absolute, 'dir is absolute');
my $abs_file = $abs_dir + 'Build.PL';
ok($abs_file->is_absolute, 'file is absolute');
is($abs_file, $file->absolute, 'absolute matches abs_dir->file(...)');

is($file . 'foo', 'Build.PLfoo', 'append');
is('.'.$file, '.Build.PL', 'reverse append');

my $also_file = $file->clone;

$also_file->file =~ s/\.PL/.foo/;
ok(ref($also_file), 'has ref');
is($also_file, 'Build.foo', 'whee');
is($file, 'Build.PL', 'original unchanged');

{
  my $f = File::Fu->file("foo");
  my $q = $f;
  $f &= sub {s/o/i/g};
  is($q, 'foo', 'q ok');
  is($f, 'fii', 's///');
  is(ref($f), 'File::Fu::File', 'object ok');
  is(ref($f.''), '', 'stringify');
  my $s = $q & sub {s/o/i/g};
  is($q, 'foo', 'q ok');
  is($s, 'fii', 's///');
}
# append with override
{
  my $f = File::Fu->file("foo");
  my $d = $f % 'bar';
  is($d, 'foobar', 'inner append');
  is(ref($d), 'File::Fu::File', 'object ok');
  is($f, 'foo', 'f ok');
  my $q = $f;
  $f %= 'bar';
  is(ref($f), 'File::Fu::File', 'object ok');
  is($f, 'foobar', 'f ok');
  is($q, 'foo', 'q ok');
}
# append as method
{
  my $f = File::Fu->file("foo");
  $f->append('baz');
  is($f, 'foobaz');
}
{
  my $d = File::Fu->dir("foo");
  my $q = $d;
  my $r = $d % 'foo';
  is($r, 'foofoo/', 'append');
  ok($d ne 'foofoo/', 'deref');
  $d %= 'foo';
  is($r, 'foofoo/', 'r unbroken');
  is($q, 'foo/', 'q unbroken');
  ok($d ne $q, 'unbroken');
  is(ref($q), ref($d), 'same package');
  $q += "bar";
  is($d, 'foofoo/');
  is($q, 'foo/bar');
  is(ref($q), 'File::Fu::File');
}
{

  my $d = File::Fu->dir;
  ok($d->is_cwd);
  is($d, './');
  $d /= 'foo';
  ok(!$d->is_cwd);
  is($d, 'foo/');
  $d /= 'bar';
  is($d, 'foo/bar/');
  is($d->basename, 'bar/');
  is($d->dirname, 'foo/');
  is($d->dirname->dirname, './');
  is($d->part(0), 'foo');
  is($d->part(1), 'bar');
  is($d->part(-1), 'bar');
}

# $dir + 'path/and/file'
{
  my $dir = File::Fu->dir('foo');
  my $file = $dir + 'this/and/that';
  is($file->basename, 'that');
  is($file->dirname, 'foo/this/and/');
}

# vim:ts=2:sw=2:et:sta
