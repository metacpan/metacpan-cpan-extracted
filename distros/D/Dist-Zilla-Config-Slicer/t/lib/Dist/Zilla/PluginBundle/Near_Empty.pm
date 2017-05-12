package # no_index
  Dist::Zilla::PluginBundle::Near_Empty;
use Moose;
with qw(
  Dist::Zilla::Role::PluginBundle
);

use Dist::Zilla::Util;
sub e { Dist::Zilla::Util->expand_config_package_name($_[0]); }

sub bundle_config {
  my $name = $_[1]->{name};
  return (
    ["$name/Test::Compile"  => e('Test::Compile') => {fake_home => 1}],
    ["$name/MetaNoIndex"    => e('MetaNoIndex')   => { file => ['.secret'], directory => [qw(t xt inc)] }],
    ["$name/Scan4Prereqs"   => e('AutoPrereqs')   => { skip => $_[1]->{payload}->{prereq_skip} }],
  );
}

__PACKAGE__->meta->make_immutable;
1;
