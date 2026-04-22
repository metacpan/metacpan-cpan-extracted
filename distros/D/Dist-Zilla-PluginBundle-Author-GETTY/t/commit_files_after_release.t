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
    $bundle->commit_files_after_release,
    [],
    'commit_files_after_release defaults to an empty arrayref',
  );
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { commit_files_after_release => [ 'python/locale_simple.py', 'js/package.json' ] },
  );

  is_deeply(
    $bundle->commit_files_after_release,
    [ 'python/locale_simple.py', 'js/package.json' ],
    'commit_files_after_release passes through as a multi-value list',
  );
}

ok(
  ( grep { $_ eq 'commit_files_after_release' } Dist::Zilla::PluginBundle::Author::GETTY->mvp_multivalue_args ),
  'commit_files_after_release is declared as a multi-value argument',
);

done_testing;
