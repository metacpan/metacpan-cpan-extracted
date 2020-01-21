use Test::Most;

use Font::Fontconfig::Pattern;



subtest 'contains_codepoint' => sub {
    
    my $fc_pattern = Font::Fontconfig::Pattern
        ->new_from_string(':charset=37 4b-5f');
    
    ok( $fc_pattern->contains_codepoint(55),   "single codepoint" );
    ok( ! $fc_pattern->contains_codepoint(65), "missing codepoint" );
    ok( $fc_pattern->contains_codepoint(75),   "range lower-bound" );
    ok( $fc_pattern->contains_codepoint(85),   "range inside" );
    ok( $fc_pattern->contains_codepoint(95),   "range upper-bound" );
    
};



done_testing;
