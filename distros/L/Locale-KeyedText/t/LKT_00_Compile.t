#!perl
use 5.008001;
use utf8;
use strict;
use warnings;

use Test::More;
use version;

plan( 'tests' => 4 );

use_ok( 'Locale::KeyedText' );
is( $Locale::KeyedText::VERSION, qv('1.73.0'),
    'Locale::KeyedText is the correct version' );

use_ok( 'Locale::KeyedText::L::en' );
is( $Locale::KeyedText::L::en::VERSION, qv('1.0.1'),
    'Locale::KeyedText::L::en is the correct version' );

1; # Magic true value required at end of a reuseable file's code.
