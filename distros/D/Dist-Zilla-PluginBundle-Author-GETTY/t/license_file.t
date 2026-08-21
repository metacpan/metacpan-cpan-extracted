use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

sub plugin_names {
  my (%payload) = @_;
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => \%payload,
  );
  $bundle->configure;
  return map { $_->[1] } @{ $bundle->plugins };
}

{
  my @plugins = plugin_names();

  ok(
    (grep { $_ eq 'Dist::Zilla::Plugin::LicenseFile' } @plugins),
    'LicenseFile guards the committed LICENSE by default',
  );
  ok(
    !(grep { $_ eq 'Dist::Zilla::Plugin::License' } @plugins),
    'and @Basic does not generate a second one',
  );
}

{
  my @plugins = plugin_names(generate_license => 1);

  ok(
    (grep { $_ eq 'Dist::Zilla::Plugin::License' } @plugins),
    'generate_license restores the generated LICENSE',
  );
  ok(
    !(grep { $_ eq 'Dist::Zilla::Plugin::LicenseFile' } @plugins),
    'and drops the check, for dists that ship no committed file',
  );
}

done_testing;
