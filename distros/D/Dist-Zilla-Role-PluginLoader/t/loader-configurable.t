
use strict;
use warnings;

use Test::More tests => 6;
use Test::DZil qw( simple_ini Builder );
use Dist::Zilla::Util::ConfigDumper qw( dump_plugin );
use Test::Differences;

# ABSTRACT: Test Role::PluginLoader directly
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
      }
    );
  }
}
{
  package    #
    Dist::Zilla::Plugin::Example;
  use Moose;
  with 'Dist::Zilla::Role::PluginLoader::Configurable';

}

sub getinj {
  my ($zilla) = @_;
  return grep { $_->isa('Dist::Zilla::Plugin::Injected') } @{ $zilla->plugins };
}

sub mkdist {
  my $tz = Builder->from_config( { dist_root => 'invalid' }, { add_files => {@_} } );
  $tz->chrome->logger->set_debug(1);
  return $tz;
}

subtest 'basic, noargs' => sub {
  my $zilla = mkdist(
    'source/dist.ini' => simple_ini(
      [
        'Example' => {
          dz_plugin => 'Injected'
        }
      ]
    )
  );
  $zilla->build;
  is( scalar getinj($zilla), 1, "One plugin loads another 1" );
  eq_or_diff(
    [ map { dump_plugin($_)->{config} } getinj($zilla) ],
    [ { 'Dist::Zilla::Plugin::Injected' => { payload => {} } } ],
    'Init state ok'
  );
};

subtest 'basic, named' => sub {
  my $zilla = mkdist(
    'source/dist.ini' => simple_ini(
      [
        'Example' => {
          dz_plugin      => 'Injected',
          dz_plugin_name => 'MyName',
        }
      ]
    )
  );
  $zilla->build;
  is( scalar getinj($zilla), 1, "One plugin loads another 1" );
  eq_or_diff( [ map { dump_plugin($_)->{name} } getinj($zilla) ], ['MyName'], 'Init state ok' );
};

subtest 'basic, minversion' => sub {
  my $zilla = mkdist(
    'source/dist.ini' => simple_ini(
      [
        'Example' => {
          dz_plugin            => 'Injected',
          dz_plugin_minversion => '5',
        }
      ]
    )
  );
  $zilla->build;
  is( scalar getinj($zilla), 1, "One plugin loads another 1" );
  is_deeply(
    $zilla->distmeta->{prereqs},
    { develop => { requires => { 'Dist::Zilla::Plugin::Injected' => '5' } } },
    "develop prereqs match expected"
  );
};
subtest 'basic, minversion phasechange' => sub {
  my $zilla = mkdist(
    'source/dist.ini' => simple_ini(
      [
        'Example' => {
          dz_plugin            => 'Injected',
          dz_plugin_minversion => '5',
          prereq_to            => 'runtime.requires'
        }
      ]
    )
  );
  $zilla->build;
  is( scalar getinj($zilla), 1, "One plugin loads another 1" );
  is_deeply(
    $zilla->distmeta->{prereqs},
    { runtime => { requires => { 'Dist::Zilla::Plugin::Injected' => '5' } } },
    "runtime prereqs as expected"
  );
};
subtest 'basic, minversion hide' => sub {
  my $zilla = mkdist(
    'source/dist.ini' => simple_ini(
      [
        'Example' => {
          dz_plugin            => 'Injected',
          dz_plugin_minversion => '5',
          prereq_to            => 'none'
        }
      ]
    )
  );
  $zilla->build;
  is( scalar getinj($zilla), 1, "One plugin loads another 1" );
  is_deeply( $zilla->distmeta->{prereqs}, {}, 'Prereqs are empty' );
};

subtest 'basic, arg passthrough' => sub {
  my $zilla = mkdist(
    'source/dist.ini' => simple_ini(
      [
        'Example' => {
          dz_plugin            => 'Injected',
          dz_plugin_minversion => '5',
          dz_plugin_arguments  => [ 'key1 = value1', 'key2 = value2', ]
        }
      ]
    )
  );
  $zilla->build;
  is( scalar getinj($zilla), 1, "One plugin loads another 1" );
  eq_or_diff(
    [ map { dump_plugin($_)->{config} } getinj($zilla) ],
    [ { 'Dist::Zilla::Plugin::Injected' => { payload => { key1 => 'value1', key2 => 'value2' } } } ],
    'Value pass ok'
  );
};
