use 5.008001;
use utf8;
use strict;
use warnings;

use Test::More 0.92;

use_ok( 'Locale::KeyedText' );
is( $Locale::KeyedText::VERSION, 2.001000,
    'Locale::KeyedText is the correct version' );

use_ok( 'Locale::KeyedText::Message' );
is( $Locale::KeyedText::Message::VERSION, 2.001000,
    'Locale::KeyedText::Message is the correct version' );

use_ok( 'Locale::KeyedText::Translator' );
is( $Locale::KeyedText::Translator::VERSION, 2.001000,
    'Locale::KeyedText::Translator is the correct version' );

use_ok( 'Locale::KeyedText::L::en' );
is( $Locale::KeyedText::L::en::VERSION, 2.001000,
    'Locale::KeyedText::L::en is the correct version' );

use lib 't/lib';

use_ok( 't_LKT_Util' );
can_ok( 't_LKT_Util', 'message' );
can_ok( 't_LKT_Util', 'serialize' );

use_ok( 't_LKT_A_L_Eng' );
can_ok( 't_LKT_A_L_Eng', 'get_text_by_key' );

use_ok( 't_LKT_A_L_Fre' );
can_ok( 't_LKT_A_L_Fre', 'get_text_by_key' );

use_ok( 't_LKT_B_L_Eng' );
can_ok( 't_LKT_B_L_Eng', 'get_text_by_key' );

use_ok( 't_LKT_B_L_Fre' );
can_ok( 't_LKT_B_L_Fre', 'get_text_by_key' );

done_testing();

1;
