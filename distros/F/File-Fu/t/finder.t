#!/usr/bin/perl

use warnings;
use strict;

use Test::More qw(no_plan);

use File::Fu;

my $topdir = File::Fu->dir('tmp.' . $$);
END { $topdir->remove; }

$topdir->subdir('foo')->subdir('bar')->subdir('baz')->create;
$topdir->file('file.1')->touch;
$topdir->file('file.2')->touch;
$topdir->subdir('foo')->file('file.3')->touch;
$topdir->subdir('foo')->file('file.4')->touch;
($topdir/'foo'/'bar'/'baz' + 'file.5')->touch;
($topdir/'foo'/'bar'/'baz' + 'file.6')->touch;

{
  my @files = $topdir->find(sub {1});
  is(scalar(@files), 9, 'find') or die join("\n", @files);

  my $finder = $topdir->finder(sub {1});
  my @got;
  while(defined(my $p = $finder->())) {
    $p or next;
    push(@got, $p);
  }
  is(scalar(@got), 9, 'finder');
}



# vim:ts=2:sw=2:et:sta
