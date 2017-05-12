use Test::More tests => 147;
use Test::NoWarnings;

use strict;
use Carp;

SKIP: {
  eval { require Graphics::ColorNames::Mozilla; };
  skip ("Graphics::ColorNames::Mozilla not installed", 146) if $@;

  use Graphics::ColorNames 0.20, qw( hex2tuple tuple2hex );
  tie my %col_www, 'Graphics::ColorNames', 'WWW';
  tie my %colors, 'Graphics::ColorNames', 'Mozilla';

  foreach my $name (keys %colors)
  {
    my @RGB = hex2tuple( $colors{$name} );
    is(tuple2hex(@RGB), $col_www{$name} );
  }
}
