package # no_index
  Dist::Zilla::PluginBundle::CustomRemover;
use Moose;
extends qw(
  Dist::Zilla::PluginBundle::TestRemover
);

sub plugin_remover_attribute { 'scurvy_cur' }

__PACKAGE__->meta->make_immutable;
1;
