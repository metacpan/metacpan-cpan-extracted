use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => {},
  );

  is_deeply(
    $bundle->effective_gather_exclude_filename,
    ['README.md'],
    'README.md is excluded by default',
  );
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { include_readme => 1 },
  );

  is_deeply(
    $bundle->effective_gather_exclude_filename,
    [],
    'include_readme opt-in disables the default README.md exclusion',
  );
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { gather_exclude_filename => ['local/file'] },
  );

  is_deeply(
    $bundle->effective_gather_exclude_filename,
    [ 'local/file', 'README.md' ],
    'custom gather exclusions are preserved alongside the default README.md exclusion',
  );
}

done_testing;
