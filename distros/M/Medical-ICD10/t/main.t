use strict;
use warnings;

use Test::More;
use Test::Deep;

###################################################################

my $filename = './t/testdata.tsv';

if ( ! -e $filename ) {
    plan 'skip_all' => 'Test data file could not be read';
    done_testing();
}

use_ok('Medical::ICD10');

my $MI = Medical::ICD10->new;

isa_ok( $MI, "Medical::ICD10" );

ok( 
   $MI->parse( $filename ), 
   'parse() - ontology parsed OK' 
);

my $ra_all_terms = 
   $MI->get_all_terms;

is( 
   scalar(@$ra_all_terms), 
   22, 
   'get_all_terms()' 
);

my $rh_all_terms =  
   $MI->get_all_terms_hashref;

my $rh_all_terms_expected =   {
   'AAA4'  => 'This is term AAA4',
   'AAA40' => 'This is term AAA40',
   'CCV'   => 'This is term CCV',
   'AAA1'  => 'This is term AAA1',
   'CCV5'  => 'This is term CCV5',
   'AAA5'  => 'This is term AAA5',
   'AAA42' => 'This is term AAA42',
   'CCV30' => 'This is term CCV30',
   'root'  => 'This is the root node.',
   'CCV50' => 'This is term CCV50',
   'AAA20' => 'This is term AAA20',
   'AAA22' => 'This is term AAA22',
   'AAA50' => 'This is term AAA50',
   'CCV51' => 'This is term CCV51',
   'AAA2'  => 'This is term AAA2',
   'CCV4'  => 'This is term CCV4',
   'CCV1'  => 'This is term CCV1',
   'AAA3'  => 'This is term AAA3',
   'CCV52' => 'This is term CCV52',
   'AAA'   => 'This is term AAA',
   'CCV2'  => 'This is term CCV2',
   'CCV3'  => 'This is term CCV3'
};


cmp_deeply(
   $rh_all_terms_expected,
   $rh_all_terms,
   'get_all_terms_expected()'   
);

##
## Get a specific term

my $Term = 
   $MI->get_term('CCV30');

isa_ok( $Term, 'Medical::ICD10::Term' );

is( $Term->term, 'CCV30', 'get_term()' );

is( $Term->description, 'This is term CCV30', 'get_term()' );

my $NonExisting =
   $MI->get_term('AVVC');

ok( ! $NonExisting, 'get_term() non existing term');

#####################################################################

my $rah_tests = [

   {
      'term'     => 'AAA',
      'text'     => 'Top level term.',
      'parent'   => 'root',
      'parents'  => [ qw( root ) ],
      'children' => [ qw( AAA1 AAA2 AAA3 AAA4 AAA5 AAA20 AAA22 AAA40 AAA42 AAA50 ) ],
      
   },
   
   {
      'term'     => 'AAA2',
      'text'     => 'Third level term.',
      'parent'   => 'AAA',
      'parents'  => [ qw( AAA root ) ],
      'children' => [ qw( AAA20 AAA22) ],
      
   },
   
   {
      'term'     => 'CCV52',
      'text'     => 'Fourth level term.',
      'parent'   => 'CCV5',
      'parents'  => [ qw( CCV5 CCV root ) ],
      'children' => [ ],
      
   },   
   
];

foreach my $rh ( @$rah_tests ) {
   
   my $TermObject = 
      $MI->get_term( $rh->{term} );
   
   my $parent_term =
      $MI->get_parent_term_string( $TermObject );
   
   is(
      $parent_term,
      $rh->{parent},
      $rh->{text},      
      );
      
   $parent_term =
     $MI->get_parent_term_string( $rh->{term} );

   is(
        $parent_term,
        $rh->{parent},
        $rh->{text},      
        );
              
   my $ra_parent_terms = 
       $MI->get_parent_terms_string( $TermObject );
    
    my $ra_child_terms =
       $MI->get_child_terms_string( $TermObject );
    
    my $ra_expected_parent_terms =
       $rh->{parents};
             
    my $ra_expected_child_terms =
       $rh->{children};
    
    cmp_bag(
       $ra_child_terms,
       $ra_expected_child_terms,
       $rh->{text}      
       );
    
    cmp_bag(
       $ra_parent_terms,
       $ra_expected_parent_terms,
       $rh->{text}      
       );
   
}

done_testing();