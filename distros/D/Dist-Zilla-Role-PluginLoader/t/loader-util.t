
use strict;
use warnings;

use Test::More tests => 1;
use Test::DZil qw( simple_ini Builder );
use Dist::Zilla::Util::ConfigDumper qw( dump_plugin );
use Dist::Zilla::Util::PluginLoader;

{
  package    #
    Dist::Zilla::Plugin::Injected;
  use Moose;
  with 'Dist::Zilla::Role::Plugin';
  use Dist::Zilla::Util::ConfigDumper qw( dump_plugin config_dumper );

  has payload => ( is => ro => );
  has section => ( is => ro => );

  around dump_config => config_dumper( __PACKAGE__, { attrs => [qw( payload section )] } );

  sub plugin_from_config {
    my ( $class, $name, $arg, $section ) = @_;

    return $class->new(
      {
        %{$arg},
        plugin_name => $name,
        zilla       => $section->sequence->assembler->zilla,
        payload     => $arg,
        section     => $section,
      }
    );
  }
}
{
  package    #
    Dist::Zilla::Plugin::InjectedB;
  use Moose;
  extends    #
    @{ ['Dist::Zilla::Plugin::Injected'] };
}
{
  package    #
    Dist::Zilla::Plugin::InjectedC;
  use Moose;
  extends    #
    @{ ['Dist::Zilla::Plugin::Injected'] };
}

my $expected_plugins = 0;
{
  package    #
    Dist::Zilla::Plugin::Example;
  use Moose;
  with 'Dist::Zilla::Role::Plugin';

  my $levels = 0;

  around plugin_from_config => sub {
    my ( $orig, $plugin_class, $name, $arg, $own_section ) = @_;
    my $own_object = $plugin_class->$orig( $name, $arg, $own_section );
    my $loader = Dist::Zilla::Util::PluginLoader->new( sequence => $own_section->sequence );
    $expected_plugins++;
    $loader->load( 'Injected', 'InjectedName', [ key => 'value', key2 => 'value' ] );
    $expected_plugins++;
    $loader->load_ini( 'Injected', 'InjectedIni', [ 'key = value', 'key2 = value ' ] );
    $expected_plugins++;
    $loader->load( 'Injected', [ key => 'value', key2 => 'value' ] );
    $expected_plugins++;
    $loader->load('InjectedB');
    $expected_plugins++;
    $loader->load( 'InjectedC', undef, [ key => 'value', key2 => 'value' ] );

    return $own_object;
  };

}

my $zilla = Builder->from_config({ dist_root => 'invalid'}, { add_files => { 'source/dist.ini' => simple_ini('Example')}});
$zilla->chrome->logger->set_debug(1);
$zilla->build;
is(
  ( scalar grep { $_->isa('Dist::Zilla::Plugin::Injected') } @{ $zilla->plugins } ),
  $expected_plugins, "One plugin loads $expected_plugins"
);
for my $plugin ( @{ $zilla->plugins } ) {
  note explain dump_plugin($plugin);
}
