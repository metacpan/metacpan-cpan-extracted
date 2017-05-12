use Test::More tests => 193 - 53 + 1;
use Test::NoWarnings;

use strict;
use Carp;

use Graphics::ColorNames 0.20, qw( hex2tuple tuple2hex );
tie my %col_www, 'Graphics::ColorNames', 'WWW';
tie my %colors, 'Graphics::ColorNames', 'IE';

my $count = 0;
foreach my $name (keys %colors)
  {
    my @RGB = hex2tuple( $colors{$name} );
    is(tuple2hex(@RGB), $col_www{$name} );
  }
