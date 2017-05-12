# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';

use Dist::Zilla::Util;
sub e { Dist::Zilla::Util->expand_config_package_name($_[0]); }

sub get_plugins {
  my ($name, $payload) = @_;
  my $mod = e($name);
  eval "require $mod" or die $@;
  return [ $mod->bundle_config({ name => $name, payload => $payload || {} }) ];
}

sub expectation {
  my ($name, $i, $e) = @_;
  my $exp = [
    ["$name/Test::Compile"  => e('Test::Compile') => {fake_home => 1}],
    ["$name/MetaNoIndex"    => e('MetaNoIndex')   => { file => ['.secret'], directory => [qw(t xt inc)] }],
    ["$name/Scan4Prereqs"   => e('AutoPrereqs')   => { skip => undef }],
  ];
  @{ $exp->[$i]->[2] }{ keys %$e } = values %$e
    if $e;
  $exp;
}

my $bundle = '@Near_Empty';
my $slice = { 'AutoPrereqs.skip' => 'FooBar' };
my $opts = { 'prereq_skip' => 'FooBar' };
my $confed = { skip => 'FooBar' };

is_deeply
  get_plugins($bundle),
  expectation($bundle),
  'got a few plugins';

is_deeply
  get_plugins($bundle, $slice),
  expectation($bundle),
  'config slice ignored';

is_deeply
  get_plugins($bundle, $opts),
  expectation($bundle, 2, $confed),
  'bundle config passed';

is_deeply
  get_plugins('@Filter', { -bundle => $bundle, %$opts }),
  expectation('@Filter', 2, $confed),
  'bundle config passed via @Filter';

is_deeply
  get_plugins('@ConfigSlicer', { -bundle => $bundle, %$opts }),
  expectation('@ConfigSlicer', 2, $confed),
  'bundle config passed via @ConfigSlicer';

is_deeply
  get_plugins('@Filter', { -bundle => $bundle, %$slice }),
  expectation('@Filter'),
  'slice not honored by @Filter';

is_deeply
  get_plugins('@ConfigSlicer', { -bundle => $bundle, %$slice }),
  expectation('@ConfigSlicer', 2, $confed),
  'slice used by @ConfigSlicer';

is_deeply
  [ map { @$_[1,2] } map { @$_ } get_plugins('@Filter', { -bundle => $bundle, %$opts }) ],
  [ map { @$_[1,2] } map { @$_ } get_plugins('@ConfigSlicer', { -bundle => $bundle, %$opts }) ],
  '@Filter == @ConfigSlicer (except for names)';

is_deeply
  [ map { @$_[1,2] } map { @$_ } get_plugins('@Filter', { -bundle => $bundle, %$opts }) ],
  [ map { @$_[1,2] } map { @$_ } get_plugins('@ConfigSlicer', { -bundle => $bundle, %$slice }) ],
  '@Filter passed config == @ConfigSlicer with slice (except for names)';

done_testing;
