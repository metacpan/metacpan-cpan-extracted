
use strict;
use warnings;

use Test::More tests => 1;
use Test::DZil qw( simple_ini Builder );
use Dist::Zilla::Util::ConfigDumper qw( dump_plugin );

# ABSTRACT: Test Role::PluginLoader directly

{
  package    #
    Dist::Zilla::Plugin::Example;
  use Moose;
  with 'Dist::Zilla::Role::Plugin', 'Dist::Zilla::Role::PluginLoader';

  my $levels = 0;

  sub load_plugins {
    my ( $self, $loader ) = @_;
    return if $levels > 5;
    $levels++;
    $loader->load( 'Example', 'LoaderExample' . $levels );
  }
}

my $zilla = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => { 'source/dist.ini' => simple_ini('Example') },
  }
);
$zilla->chrome->logger->set_debug(1);
$zilla->build;
is(

  ( scalar grep { $_->isa('Dist::Zilla::Plugin::Example') } @{ $zilla->plugins } ),
  7, "One plugin recursively loads 7"
);
for my $plugin ( @{ $zilla->plugins } ) {
  note explain dump_plugin($plugin);
}
