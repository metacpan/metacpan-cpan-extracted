use Test::Most;

use Font::Fontconfig;

subtest 'can list' => sub {
    
    can_ok( 'Font::Fontconfig' => 'list' )
    
};

done_testing;
