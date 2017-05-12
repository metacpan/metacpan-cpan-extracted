# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Dist::Zilla::Config::Slicer';
eval "require $mod" or die $@;

my $slicer = new_ok($mod);

# match_package is overridden in subclass. everything else is the same
ok $slicer->match_package('Foo',  'Dist::Zilla::Plugin::Foo'), 'expand plugin package';
ok $slicer->match_package('@Foo', 'Dist::Zilla::PluginBundle::Foo'), 'expand bundle package';
ok $slicer->match_package('=Foo', 'Foo'), 'strip the no-expansion prefix';

done_testing;
