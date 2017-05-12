#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use File::Fu;

my $topdir = File::Fu->dir('tmp.' . $$);
END { $topdir->remove; }

$topdir->mkdir;
($topdir+$_)->touch for('a'..'z');
my $foo = $topdir->subdir("foo");
$foo->mkdir;
$foo->basename->symlink($topdir/'link');
($foo+$_)->touch for('a'..'z');

# TODO multiple runs / fs order permutation?
my $x = 'j';

{ # without prune => recurse
  my @files = $topdir->find(sub {
    $_->basename eq $x
  });

  is(join('|', sort @files), join('|', sort
    $foo + $x,
    $topdir + $x
  ));
}
{ # with prune
  my @files = $topdir->find(sub {
    return shift->prune if $_->is_dir;
    $_->basename eq $x
  });

  is(join('|', sort @files), $topdir + $x);
}

# vim:ts=2:sw=2:et:sta
