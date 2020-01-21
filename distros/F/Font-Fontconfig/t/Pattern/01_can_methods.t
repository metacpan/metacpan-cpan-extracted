use Test::Most;

use Font::Fontconfig::Pattern;

subtest 'can new_from_string' => sub {
    
    can_ok( 'Font::Fontconfig::Pattern' => 'new_from_string' )
    
};

subtest 'can contains_codepoint' => sub {
    
    can_ok( 'Font::Fontconfig::Pattern' => 'contains_codepoint' )
    
};

done_testing;
