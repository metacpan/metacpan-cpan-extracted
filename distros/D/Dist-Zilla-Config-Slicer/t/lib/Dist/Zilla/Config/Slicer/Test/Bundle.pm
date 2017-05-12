package # no_index
  Dist::Zilla::Config::Slicer::Test::Bundle;
use Moose;
with qw(
  Dist::Zilla::Role::PluginBundle
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);

use Dist::Zilla::Util;
sub e { Dist::Zilla::Util->expand_config_package_name($_[0]); }

sub bundle_config {
  my $name = $_[1]->{name};
  return (
    ["$name/Test::Compile"  => e('Test::Compile') => {fake_home => 1}],
    ["$name/MetaNoIndex"    => e('MetaNoIndex')   => { file => ['.secret'], directory => [qw(t xt inc)] }],
    ["$name/Scan4Prereqs"   => e('AutoPrereqs')   => { }],
    ["$name/GoodbyeGarbage" => e('PruneCruft')    => { }],
    ["$name/DontNeedThese"  => e('PruneCruft')    => { }],
  );
}

__PACKAGE__->meta->make_immutable;
1;
