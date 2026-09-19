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
    ['README.md', '.karr'],
    'README.md is excluded by default, .karr is also excluded for CPAN releases (the default)',
  );
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { include_readme => 1 },
  );

  is_deeply(
    $bundle->effective_gather_exclude_filename,
    ['.karr'],
    'include_readme opt-in disables the default README.md exclusion, but not the .karr exclusion (still a CPAN release by default)',
  );
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { gather_exclude_filename => ['local/file'] },
  );

  is_deeply(
    $bundle->effective_gather_exclude_filename,
    [ 'local/file', 'README.md', '.karr' ],
    'custom gather exclusions are preserved alongside the default README.md and .karr exclusions',
  );
}

{
  # Naming .karr explicitly via gather_exclude_filename is a no-op: it is
  # already excluded for CPAN releases (the default), so this exercises the
  # dedup, not a separate config knob.
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { gather_exclude_filename => ['.karr'], include_readme => 1 },
  );

  is_deeply(
    $bundle->effective_gather_exclude_filename,
    ['.karr'],
    '.karr is excluded exactly once even if also listed explicitly',
  );
}

{
  # The regression test for the .karr exclusion itself: no_cpan = 1 means the
  # dist never reaches CPAN, so .karr should stay in the build. Without the
  # "unless $self->no_cpan" guard in effective_gather_exclude_filename this
  # would wrongly exclude .karr here too.
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { no_cpan => 1 },
  );

  is_deeply(
    $bundle->effective_gather_exclude_filename,
    ['README.md'],
    '.karr is NOT excluded when no_cpan = 1 (only README.md stays excluded by its own default)',
  );
}

done_testing;
