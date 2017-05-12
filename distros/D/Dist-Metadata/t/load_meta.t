use strict;
use warnings;
use Test::More 0.96;
use Test::MockObject 1.09;

my ( $default, $loaded, $created ) = (-1) x 3;

Test::MockObject->new->fake_module('CPAN::Meta',
  VERSION  => sub { 2 },
  new      => sub { bless { %{ $_[1] } }, $_[0] },
  create   => sub { $created = $_[1]; shift->new(@_) },
  #as_struct => sub { +{ %{ $_[0] } } }, # unbless
  (map { ( $_ => sub { undef } ) } qw(name version provides)),
  map {
    ( "load_${_}_string" => sub { $loaded = $_[1]; $_[0]->new({loaded => $_[1]}); } )
  } qw(json yaml)
);

my $mod = 'Dist::Metadata';
eval "require $mod" or die $@;
$Dist::Metadata::VERSION ||= 0; # quiet warnings

foreach my $test (
  [ json => j => { 'META.json' => 'j' } ],
  [ yaml => y => { 'META.yml'  => 'y' } ],

  # usually it's spelled .yml but yaml spec suggests .yaml
  [ yaml => y => { 'tar/META.yaml' => 'y' } ],

  # json preferred
  [ json => j => { 'tar/META.json' => 'j', 'tar/META.yaml' => 'y' } ],
  )
{
  my ( $type, $content, $files ) = @$test;
  my $struct = { files => $files };

  new_ok( $mod, [ struct => $struct, determine_packages => 0 ] )->load_meta;
  is( $loaded, $content, "loaded $type" );
  is( $created, $default, "loaded not created" );
}

reset_vars();

new_ok( $mod,
  [ struct => { files => { 'README' => 'nevermind' } }, determine_packages => 0 ]
)->load_meta;

is( $loaded, $default, 'meta file not found, not loaded' );
is( ref($created), 'HASH', 'hash passed to create()' );

done_testing;

sub reset_vars {
  ( $loaded, $created ) = ($default) x 2;
}
