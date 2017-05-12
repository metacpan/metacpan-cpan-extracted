package # no_index
  Dist::Zilla::PluginBundle::TestRemover;
use Moose;
with qw(
  Dist::Zilla::Role::PluginBundle
  Dist::Zilla::Role::PluginBundle::PluginRemover
);

use Dist::Zilla::Util;
sub e { Dist::Zilla::Util->expand_config_package_name($_[0]); }

sub mvp_multivalue_args { 'prefixes' }

sub bundle_config {
  my ($class, $arg) = @_;
  my $name = join '/', $arg->{name}, @{ $arg->{payload}{prefixes} || [] };
  return (
    ["$name/Scan4Prereqs"   => e('AutoPrereqs')   => { }],
    ["$name/GoodbyeGarbage" => e('PruneCruft')    => { }],
  );
}

__PACKAGE__->meta->make_immutable;
1;
