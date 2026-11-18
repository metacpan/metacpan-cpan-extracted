#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

my @phases = qw( after_build before_build before_release release after_release test );
my @ways   = qw( run run_if_trial run_no_trial run_if_release run_no_release );

sub camel { join '', map { ucfirst } split /_/, shift }

# The payload of every Run::* plugin the bundle assembles, by plugin name.
sub run_plugins {
  my (%payload) = @_;
  my @plugins = Dist::Zilla::PluginBundle::Author::GETTY->bundle_config({
    name    => '@Author::GETTY',
    package => 'Dist::Zilla::PluginBundle::Author::GETTY',
    payload => \%payload,
  });
  my %run;
  for my $p (@plugins) {
    my ($name) = $p->[1] =~ /^Dist::Zilla::Plugin::(Run::.+)$/ or next;
    $run{$name} = $p->[2];
  }
  return \%run;
}

# One test per run way: the way is set in a phase of its own, and arrives
# at that phase's Run plugin under its own name without the phase suffix.
my %phase_of = (
  run             => 'after_build',
  run_if_trial    => 'before_build',
  run_no_trial    => 'before_release',
  run_if_release  => 'after_release',
  run_no_release  => 'test',
);
for my $way (@ways) {
  my $phase = $phase_of{$way};
  my $run = run_plugins("${way}_$phase" => ["a $way", "b $way"]);
  is_deeply $run, { 'Run::'.camel($phase) => { $way => ["a $way", "b $way"] } },
    "${way}_$phase reaches Run::".camel($phase)." as $way, and nothing else";
}

# Every way in every phase: six plugins with five options each, none mixed up.
{
  my (%payload, %want);
  for my $phase (@phases) {
    for my $way (@ways) {
      $payload{"${way}_$phase"} = ["$way in $phase"];
      $want{'Run::'.camel($phase)}{$way} = ["$way in $phase"];
    }
  }
  is_deeply run_plugins(%payload), \%want,
    'all ways in all phases land on the right plugin under the right option';
}

is_deeply run_plugins(run_test => ['x']), { 'Run::Test' => { run => ['x'] } },
  'run_test alone stays a plain run, nothing else added';

is_deeply run_plugins(), {}, 'no run way set, no Run plugin';

is_deeply run_plugins(
  run_test            => ['x'],
  run_if_release_test => ['./Build install', 'make install'],
), { 'Run::Test' => {
       run            => ['x'],
       run_if_release => ['./Build install', 'make install'],
     } },
  'the POD example: run and run_if_release_test share one Run::Test';

# The build level: a repeated key survives mvp_multivalue_args.
SKIP: {
  skip 'Dist::Zilla::Tester not available', 2
    unless eval { require Dist::Zilla::Tester; require Dist::Zilla::Chrome::Term; 1 };
  require Path::Tiny; require File::Temp;

  my $tmp  = File::Temp::tempdir(CLEANUP => 1);
  my $root = Path::Tiny::path($tmp, 'dist');
  $root->child('lib')->mkpath;
  $root->child('lib', 'Foo.pm')->spew("package Foo;\n1;\n");
  $root->child('dist.ini')->spew(<<'CONF');
name = Test-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
run_if_release_test = ./Build install
run_if_release_test = make install
CONF

  my $tzil = Dist::Zilla::Tester->from_config(
    { dist_root => "$root" },
    { tempdir_root => $tmp, chrome => Dist::Zilla::Chrome::Term->new },
  );
  my ($test) = grep { $_->isa('Dist::Zilla::Plugin::Run::Test') } @{ $tzil->plugins };
  ok $test, 'Run::Test is in the built plugin list' or skip 'no Run::Test', 1;
  is_deeply [ sort @{ $test->run_if_release } ], ['./Build install', 'make install'],
    'both run_if_release_test values survive in the Run::Test object';
}

done_testing;
