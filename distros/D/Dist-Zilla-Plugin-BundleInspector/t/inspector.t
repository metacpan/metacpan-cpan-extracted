use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use TestBundles;
use Test::Differences;

my $mod = 'Dist::Zilla::Config::BundleInspector';
eval "require $mod" or die $@;

subtest pod_weaver => sub {
  my $bundle = 'Pod::Weaver::PluginBundle::RoundHere';
  my $bi = new_ok($mod, [
    bundle_class => $bundle,
  ]);

  local *pkg  = sub { 'Pod::Weaver::' . $_[0] };
  eq_or_diff $bi->plugin_specs, [
    [Omaha   => pkg('Plugin::Jones'),         { salutation => 'mr' }],
    [Perfect => pkg('Section::BlueBuildings'), { ':version' => '0.003' }],

  ], 'plugin_specs';

  eq_or_diff $bi->prereqs->as_string_hash, {
    'Pod::Weaver::Plugin::Jones'          => 0,
    'Pod::Weaver::Section::BlueBuildings' => '0.003',
  }, 'simplified prereqs with version';

  eq_or_diff $bi->ini_string, <<INI, 'ini_string';
[-Jones / Omaha]
salutation = mr

[BlueBuildings / Perfect]
:version = 0.003
INI
};

subtest bundle_config => sub {
  my $bundle = 'TestBundles::AnnaBegins';
  my $bi = new_ok($mod, [
    bundle_class => $bundle,
    # bundle_method should be determined automatically
  ]);

  local *pkg  = sub { $bundle . '::' . $_[0] };
  eq_or_diff $bi->plugin_specs, [
    [Time      => pkg('Time'), {':version' => '1.2', needs_feature => 'b',}],
    [TimeAgain => pkg('Time'), {':version' => '1.1', only_needs => ['feature', 'a'] }],
    [Rain      => pkg('King')],

  ], 'plugin_specs';

  eq_or_diff $bi->prereqs->as_string_hash, {
    $bundle . '::Time' => '1.2',
    $bundle . '::King' => 0,
  }, 'prereqs with latest version';

  eq_or_diff $bi->ini_string, <<INI, 'ini_string';
[${bundle}::Time / Time]
:version      = 1.2
needs_feature = b

[${bundle}::Time / TimeAgain]
:version   = 1.1
only_needs = feature
only_needs = a

[${bundle}::King / Rain]
INI
};

foreach my $easy ( 0, 1 ){

subtest "dzil_bundle (easy: $easy)" => sub {
  my $bundle = 'Dist::Zilla::PluginBundle::SullivanStreet';
  my $bi = new_ok($mod, [
    bundle_class  => $bundle,
    # bundle_method and ini_opts should be determined automatically
  ]);

  $bundle->does_easy($easy);

  local *pkg  = sub { 'Dist::Zilla::' . $_[0] };
  eq_or_diff $bi->plugin_specs, [
    [Ghost   => pkg('Plugin::Train')],
    [Raining => 'In::Baltimore', { ':version' => 'v1.23.45' }],
    [Murder  => pkg('PluginBundle::Of::One'),  { 'version'  => 'not :version' }],
$easy ? (
    ['@EverythingAfter' => pkg('PluginBundle::EverythingAfter'), {}],
) : (
    [August  => pkg('Plugin::Everything')],
    [After   => pkg('Plugin::Everything')],
)
  ], 'plugin_specs';

  eq_or_diff $bi->prereqs->as_string_hash, {
    pkg('Plugin::Train')         => 0,
    'In::Baltimore'              => 'v1.23.45',
    pkg('PluginBundle::Of::One') => 0,
$easy ? (
    pkg('PluginBundle::EverythingAfter')    => 0,
) : (
    pkg('Plugin::Everything')    => 0,
)
  }, 'prereqs';

  eq_or_diff $bi->ini_string, <<INI, 'ini_string';
[Train / Ghost]

[=In::Baltimore / Raining]
:version = v1.23.45

[\@Of::One / Murder]
version = not :version

${\ ($easy ? '[@EverythingAfter]' : "[Everything / August]\n[Everything / After]") }
INI
};

}

done_testing;
