use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

# Test irc_user defaults to 'Getty' when author is 'GETTY'
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => {},
  );
  is($bundle->author, 'GETTY', 'author defaults to GETTY');
  is($bundle->irc_user, 'Getty', 'irc_user defaults to Getty when author is GETTY');
}

# Test irc_user is empty when author is not GETTY
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { author => 'SOMEONE' },
  );
  is($bundle->author, 'SOMEONE', 'author is SOMEONE');
  is($bundle->irc_user, '', 'irc_user is empty when author is not GETTY');
}

# Test irc_user can be set explicitly
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { author => 'SOMEONE', irc_user => 'Getty or ether' },
  );
  is($bundle->author, 'SOMEONE', 'author is SOMEONE');
  is($bundle->irc_user, 'Getty or ether', 'irc_user can be set explicitly');
}

# Test irc_user can override default for GETTY
{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { irc_user => 'Getty and friends' },
  );
  is($bundle->author, 'GETTY', 'author defaults to GETTY');
  is($bundle->irc_user, 'Getty and friends', 'irc_user can override default');
}

done_testing;
