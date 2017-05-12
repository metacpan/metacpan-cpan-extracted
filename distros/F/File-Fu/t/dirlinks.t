#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use File::Fu;

my $tempdir = File::Fu->temp_dir; $tempdir->chdir;

my $this = File::Fu->dir('this')->mkdir;

# simply creating a link
{
  my $link = $this->symlink('foo');
  ok($link);
  ok($link->l);
  ok($link->e);
  $link->unlink;
  ok(! $link->e, 'gone');
  ok($this->e);
}

# links don't have to point to existing directories
{
  my $none = File::Fu->dir('bah');
  my $link = $none->symlink('deal');
  isa_ok($link, 'File::Fu::Dir');
  ok($link->l);
  ok(! $link->e, 'nothing there');
  $link->unlink;
  ok(! $link->l);
}

# make sure we can pass inputs a few ways
{
  my $dir = File::Fu->dir("dir")->mkdir;
  my $link = File::Fu->dir("what")->symlink($dir / 'link');
  ok(! $link->e);
  ok($link->l, 'is a link');
  $link->unlink;

  $link = File::Fu->dir("what")->symlink('dir/link');
  ok($link->l, 'is a link');
  $link->unlink;

  $link = File::Fu->dir("what")->symlink('dir/link/');
  ok($link->l, 'is a link');
  $link->unlink;
  $dir->rmdir;
}

# relative
{
  my $dir = File::Fu->dir("dir")->mkdir;
  my $link = $this->relative_symlink($dir / 'whee');
  ok($link->l);
  ok($link->e);
  ok($link->d);
  my $lfile = $link + 'file';
  $lfile->touch;
  my $file = $this + 'file';
  ok($file->e, 'exists');
  $file->unlink;
  ok(! $lfile->e, 'gone');
  $link->unlink;
  $dir->rmdir;
}

# relative where there is no depth involved
{
  my $link = $this->relative_symlink('whee');
  ok($link->e);
  ok($link->l);
  ok($link->d);
  my $lfile = $link + 'file';
  $lfile->touch;
  my $file = $this + 'file';
  ok($file->e, 'exists');
  $file->unlink;
  ok(! $lfile->e, 'gone');
  $link->unlink;
}
$this->rmdir;



# vim:ts=2:sw=2:et:sta
