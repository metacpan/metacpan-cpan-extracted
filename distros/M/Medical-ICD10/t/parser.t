
use strict;
use warnings;

use Test::More tests => 5;

use_ok('Medical::ICD10::Parser');

my $M = 
   Medical::ICD10::Parser->new();

isa_ok( $M, 'Medical::ICD10::Parser' );

##
## _get_parent 

my $rah_parent_tests = [

   {
      'input'  => 'AAA',
      'output' => 'root',
      'text'   => 'Root node',
            
   },
   
   {
      'input'  => 'ABC1',
      'output' => 'ABC',
      'text'   => 'Tier four node',
            
   },
   
   {
      'input'  => 'ABC1A',
      'output' => 'ABC1',
      'text'   => 'Tier five node',
            
   }

];

foreach my $rh_test ( @$rah_parent_tests ) {
   
   is(
      $M->_get_parent( $rh_test->{input} ),
      $rh_test->{output},
      $rh_test->{text}    
   );
   
}