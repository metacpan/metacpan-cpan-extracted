use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => {},
  );

  is(
    $bundle->tag_format,
    '%v',
    'tag_format defaults to %v',
  );
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { tag_format => 'v%v' },
  );

  is(
    $bundle->tag_format,
    'v%v',
    'tag_format passes through when set',
  );
}

done_testing;
