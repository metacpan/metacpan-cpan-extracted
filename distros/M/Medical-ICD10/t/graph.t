use strict;
use warnings;

use Test::More tests => 2;

use_ok('Medical::ICD10::Graph');

my $G = 
   Medical::ICD10::Graph->new();

isa_ok( $G, 'Graph' );

