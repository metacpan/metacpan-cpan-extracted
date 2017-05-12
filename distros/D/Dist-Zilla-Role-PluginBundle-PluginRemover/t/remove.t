# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';

my $mod = 'Dist::Zilla::Role::PluginBundle::PluginRemover';
eval "require $mod" or die $@;

use Dist::Zilla::Util;
sub e { Dist::Zilla::Util->expand_config_package_name($_[0]); }

my @plugins = (
  ['@Bundle/Foo' => e('Foo')],  # default name
  ['second Foo' => e('Foo')],   # custom name
  ['@Bundle/Bar' => e('Bar')],
  ['second Bar' => e('Bar')],
);

  is_deeply
    [ $mod->remove_plugins([qw(Baz)], @plugins) ],
    [ @plugins ],
    'nothing removed';

  is_deeply
    [ $mod->remove_plugins([qw(Foo)], @plugins) ],
    [
      ['@Bundle/Bar' => e('Bar')],
      ['second Bar' => e('Bar')],
    ],
    'all Foo removed';

  is_deeply
    [ $mod->remove_plugins([qw(Bar)], @plugins) ],
    [
      ['@Bundle/Foo' => e('Foo')],
      ['second Foo' => e('Foo')],
    ],
    'all Bar removed';

  is_deeply
    [ $mod->remove_plugins([qw(Bar Foo)], @plugins) ],
    [ ],
    'nothing left';

  is_deeply
    [ $mod->remove_plugins(['second Foo'], @plugins) ],
    [
      ['@Bundle/Foo' => e('Foo')],
      ['@Bundle/Bar' => e('Bar')],
      ['second Bar' => e('Bar')],
    ],
    'one Foo removed';


done_testing;
