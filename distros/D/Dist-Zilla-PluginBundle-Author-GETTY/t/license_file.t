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

sub has_plugin {
  my ($class, @plugins) = @_;
  return scalar grep { $_ eq "Dist::Zilla::Plugin::$class" } @plugins;
}

# no_license: no LICENSE handling at all -- none generated, none demanded.
{
  my @plugins = plugin_names(no_license => 1);

  ok(!has_plugin('License', @plugins), 'no_license generates no LICENSE');
  ok(!has_plugin('LicenseFile', @plugins), 'and demands no committed one');
}

# A dist that never reaches CPAN needs no LICENSE: no_cpan implies no_license.
{
  my @plugins = plugin_names(no_cpan => 1);

  ok(!has_plugin('License', @plugins), 'no_cpan generates no LICENSE');
  ok(!has_plugin('LicenseFile', @plugins), 'no_cpan demands no committed LICENSE');
}

# ... but an explicit choice still wins over the no_cpan default.
{
  my @plugins = plugin_names(no_cpan => 1, no_license => 0);

  ok(has_plugin('LicenseFile', @plugins), 'no_license = 0 keeps the check under no_cpan');
  ok(!has_plugin('License', @plugins), 'and still generates no second LICENSE');
}

{
  my @plugins = plugin_names(no_cpan => 1, generate_license => 1);

  ok(has_plugin('License', @plugins), 'generate_license still generates under no_cpan');
  ok(!has_plugin('LicenseFile', @plugins), 'without the check');
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { no_license => 1, generate_license => 1 },
  );
  my $error = do { local $@; eval { $bundle->configure; 1 } ? '' : "$@" };

  like(
    $error,
    qr/no_license and generate_license/,
    'no_license together with generate_license is refused',
  );
}

done_testing;
