#!/usr/bin/env perl
# The one location rule of the dist ($Langertha::Holmgang::Target::LOCATION,
# k42/k44) where World cuts a trailing die location: a Perl error that names the
# line of the last read handle (", <FH> line N." or "chunk N") loses it whole, the
# text before it stays. Structure no longer cuts one: since k29 the haystack throws
# a Langertha::Holmgang::Error itself, without a location (t/haystack.t). Invented
# worlds and fields (ADR 0003).
use strict;
use warnings;
use Test::More;

use Langertha::Holmgang::World;

# a value() that fails like a Perl error after a read, with the handle's line or chunk
{
  package Holmgang::Test::BrokenValueWorld;
  use Moose;
  extends 'Langertha::Holmgang::World';
  our $TAIL;
  sub value { die "value broke at /tmp/invented/World.pm line 12$TAIL\n" }
  __PACKAGE__->meta->make_immutable;
}

my @tools = ( {
  name       => 'poke',
  parameters => { type => 'object', properties => {} },
  handlers   => [ { apply => [ { set => 'box.lid', value => 'open' } ], output => 'ok' } ],
} );

for my $tail ( '.', ', <$fh> line 2.', ', <STDIN> chunk 3.', ', <$fh> line 2' ) {
  local $Holmgang::Test::BrokenValueWorld::TAIL = $tail;

  my $w = Holmgang::Test::BrokenValueWorld->new( state => { box => { lid => 'shut' } }, tools => \@tools );
  my ( $out, undef, $ok ) = $w->call( poke => {} );
  ok( !$ok, "World apply, location '$tail': the change fails" );
  is( $out, 'Fehler: value broke', '... the error text without the location' );
}

done_testing;
