#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

my $tmp = File::Fu->dir('tmp');
mkdir($tmp);

# make a file
my $file = $tmp + 'file';
is($file, 'tmp/file');
my $fh = $file->open('>');
print $fh "yay\n";
close($fh) or die "cannot write '$file' $!";
ok($file->e);

# hardlink
my $link = $file->link($tmp->file('link')->stringify);
is($link, 'tmp/link');

$file->unlink;
ok(! $file->e);
ok($link->e, 'link still there');

# TODO stat
{
  my $fh = $link->open;
  chomp(my $line = <$fh>);
  is($line, 'yay');
}

my $sl = $link->symlink($tmp->file('symlink')->stringify);
is($sl, 'tmp/symlink');
ok($sl->l, 'is a link');
is($sl->readlink, 'tmp/link');
ok(! $sl->e, 'target does not exist (relativity)');
$sl->unlink;
ok(! $sl->l, 'gone');
$sl = $link->basename->symlink($sl);
ok($sl->e, 'exists');
ok($sl->l, 'is a link');

# renaming
my $linknow = $link->rename('tmp/linknow');
is($linknow, 'tmp/linknow');
ok(! $link->e);
ok(! $sl->e);
is($link, 'tmp/link');
$linknow->rename($link);
ok($link->e);
ok($sl->e);
ok(!$linknow->e);
is($linknow, 'tmp/linknow');

$link->unlink;
ok(! $link->e);
ok(! $sl->e);
$sl->unlink;
ok(! $sl->l);

# symlink->symlink->symlink
{
  my $tmp = File::Fu->dir('tmp.links.' . $$);
  $tmp->mkdir;

  my $file = $tmp->file('file')->touch;
  is($file->resolve, $file);
  my $link = $file->basename->symlink($tmp + 'link1');
  is($link->resolve, $file);

  $tmp->remove;
}

# relative symlink
{
  my $file = $tmp->file('file')->touch;
  ok($file->e);
  my $dir = $tmp->subdir('dir')->mkdir;
  ok($dir->d);
  my $link = $file->relative_symlink($dir + 'and');
  ok($link->l);
  ok($link->e);
  $file->unlink;
  ok(! $file->e);
  ok(! $link->e);
  $link->unlink;
  $dir->rmdir;
}

rmdir($tmp) or die "cannot delete '$tmp'";

# vim:ts=2:sw=2:et:sta
