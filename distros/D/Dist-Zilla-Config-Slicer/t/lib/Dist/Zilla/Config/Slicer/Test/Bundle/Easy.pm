package # no_index
  Dist::Zilla::Config::Slicer::Test::Bundle::Easy;
use Moose;
with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);

sub configure {
  $_[0]->add_plugins(
    ['Test::Compile' => {fake_home => 1}],
    [MetaNoIndex     => { file => ['.secret'], directory => [qw(t xt inc)] }],
    # ::Easy takes these name/package in reverse order
    [AutoPrereqs     => 'Scan4Prereqs'],
    [PruneCruft      => 'GoodbyeGarbage'],
    [PruneCruft      => 'DontNeedThese'],
  );
}

__PACKAGE__->meta->make_immutable;
1;
