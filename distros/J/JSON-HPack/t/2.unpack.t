use strict;
use Test::More 'no_plan';
use Test::Deep;

use JSON::HPack;

my $unpacked = [
  { 
    name => 'Peter Parker',
    superhero => 'Spiderman',
    label => 'Marvel'
  },

  {
    name => 'Bruce Wayne',
    superhero => 'Batman',
    label => 'DC'
  },

  {
    name => 'Bruce Banter',
    superhero => "Hulk",
    label => "Marvel"
  },

  { 
    name => 'John Logan',
    superhero => "Wolverine",
    label => "Marvel"
  }
];

my $packed = [ 3, qw/name superhero label/, "Peter Parker", qw/Spiderman Marvel/, "Bruce Wayne", qw/Batman DC/, "Bruce Banter", qw/Hulk Marvel/, "John Logan", qw/Wolverine Marvel/ ];

my $up = JSON::HPack->unpack( $packed );
my $pa = JSON::HPack->pack( $unpacked );

ok( @$packed == @$pa ); 
cmp_deeply( $packed, $pa );
cmp_deeply( $unpacked, $up );




