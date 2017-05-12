
use strict;
use warnings;

use GD::3DBarGrapher qw(creategraph);
        
my @data = (
      ['Apples', 28],
      ['Pears',  43],
      ['Oranges',49],
      ['Peaches',21],
      ['Melons', 14]
);

my %options = (
      'file' => 'mygraph.jpg',
);

my $imagemap = creategraph(\@data, \%options);
