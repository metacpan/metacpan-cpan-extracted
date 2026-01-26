use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

# Test adoptme defaults to false
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => {},
  );
  ok(!$bundle->adoptme, 'adoptme defaults to false');
}

# Test adoptme can be enabled
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { adoptme => 1 },
  );
  ok($bundle->adoptme, 'adoptme can be enabled');
}

# Test adoptme can be explicitly disabled
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { adoptme => 0 },
  );
  ok(!$bundle->adoptme, 'adoptme can be explicitly disabled');
}

done_testing;
