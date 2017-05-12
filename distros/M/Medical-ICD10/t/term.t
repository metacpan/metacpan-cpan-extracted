
use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'Medical::ICD10::Term' );

my $rh_params = {
   'term'        => 'ABC1',
   'description' => 'This is a test term.',
};

my $term = 
   Medical::ICD10::Term->new( $rh_params );

isa_ok( $term, 'Medical::ICD10::Term' );

is(
   $term->term,
   'ABC1',
   'term()'   
);

is(
   $term->description,
   'This is a test term.',
   'description()'
);