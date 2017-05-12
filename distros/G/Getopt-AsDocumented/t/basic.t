#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;#<

use Getopt::AsDocumented;

my $go = Getopt::AsDocumented->new(from_file => 'examples/basic.pod');
ok($go, 'constructor');

{
  my $o = $go->process([]);
  ok($o, 'object');
  can_ok($o, 'config_file');
  can_ok($o, 'index');
  can_ok($o, 'foo');
  can_ok($o, 'bar');
  is($o->foo, 20);
}
{
  my $o = $go->process([qw(
    --index 72
    --foo   19.8
    --bar   baz
    --bar   bort
  )]);
  is($o->index, 72);
  is($o->foo, 19.8);
  is_deeply([$o->bar], ['baz', 'bort']);
}
{
  my $o = $go->process([qw(
    --config-file examples/basic_config-file.yml
  )]);
  is($o->foo, 17);
}

# TODO ensure that default config file loads

# vim:ts=2:sw=2:et:sta
