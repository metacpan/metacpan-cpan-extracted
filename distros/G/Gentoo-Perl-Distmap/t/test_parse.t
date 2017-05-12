use strict;
use warnings;

use Test::More;
use 5.10.0;
use FindBin;
use Path::Tiny;
my $corpus = Path::Tiny::path($FindBin::Bin)->parent->child('corpus');

use Gentoo::Perl::Distmap;

my $dm = Gentoo::Perl::Distmap->load( file => $corpus->child('distmap.json') );
pass("loaded without failing");

my $dmx = Gentoo::Perl::Distmap->new();
for my $i ( 0 .. 200 ) {
  $dmx->add_version(
    distribution => Test       =>,
    category     => fake       =>,
    package      => fake       =>,
    version      => '0.0' . $i =>,
    repository   => 'fake',
  );
}
pass("added 200 new versions successfully");
is( length $dmx->save( string => ), 4483, "Saved JSON is expected 4483 chars long" );

my $h = $dm->map->hash;
is( $h, 'pzV95dIOgbtiZUkQN6q4NeKv43c', "Generated Hash is consistent" );

done_testing();
