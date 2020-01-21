use Test::Most;

use Font::Selector qw/grep_from_fontnames/;



subtest 'can grep_from_fontnames' => sub {
    
    can_ok( 'Font::Selector' => 'grep_from_fontnames' );
    
    can_ok( __PACKAGE__, 'grep_from_fontnames' );
};



done_testing;
