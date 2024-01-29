#! /usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Config;
use Cwd 'getcwd';
use File::Path 'rmtree';
use File::Spec::Functions;
use File::Temp 'mktemp';
use Test::More tests => 26;

use Dir::TempChdir ($Config{d_fchdir} ? () : '-IGNORE_UNSAFE_CHDIR_SECURITY_RISK');

my $basedir = canonpath(getcwd());
my $path = $basedir;
my $tcd = Dir::TempChdir->new();
my @dirs = (mktemp('XXXXXXXX'), qw(foo bar baz));

is(canonpath($tcd), $basedir, '$tcd is basedir (initially)');

my $count = 0;
my @paths;
foreach my $dir (@dirs) {
  $count++;
  ok(mkdir($dir), "mkdir($dir)");
  $tcd->pushd($dir);
  $path = catdir($path, $dir);
  is(canonpath($tcd), $path, "in $path after pushd($dir)");
  is($tcd->stack_size, $count, "stack_size is $count");
  push @paths, $path;
}

foreach my $path (reverse @paths) {
  is(canonpath($tcd), $path, "in $path before popd()");
  $tcd->popd();
  $count--;
  is($tcd->stack_size, $count, "stack_size is $count after popd()");
}

is(canonpath($tcd), $basedir, '$tcd is basedir after final popd()');

$tcd->pushd($_) for @dirs;
is(canonpath($tcd), catdir($basedir, @dirs), "\$tcd in @dirs before backout");
$tcd->backout();
is(canonpath($tcd), $basedir, '$tcd in basedir after backout');

$tcd->pushd($_) for @dirs;
is(canonpath($tcd), catdir($basedir, @dirs), "\$tcd in @dirs before undef");
undef $tcd;
is(canonpath(getcwd()), $basedir, '$tcd in basedir after undef');

END {
  if ($basedir && chdir $basedir) {
    rmtree($dirs[0]) if @dirs;
  }
}
