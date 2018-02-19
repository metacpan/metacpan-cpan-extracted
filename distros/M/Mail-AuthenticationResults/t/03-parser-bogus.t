#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't';
use Test::More;
use Test::Exception;

use lib 'lib';
use Mail::AuthenticationResults::Parser;

my $Parsed;

my @GoodStrings = (
    'test.example.com foo;',
    'test.example.com foo ',
    'test.example.com; foo = ',
);

my @BadStrings = (
    'test.example.com = = test;',
    'test.example.com foo = = bar;',
    'test.example.com . bar = test;',
    'test.example.com foo . bar = test;',
    'test.example.com foo / bar = test;',
    'test.example.com foo bar = test;',
    'test.example.com; foo = = bar;',
    'test.example.com; foo / bar = test;',
    'test.example.com; foo . . bar = test;',
    'test.example.com; foo / . bar = test;',
    'test.example.com; foo . / bar = test;',

);

foreach my $String ( @GoodStrings ) {
    lives_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $String ) }, $String );
}

foreach my $String ( @BadStrings ) {
    dies_ok( sub{ $Parsed = Mail::AuthenticationResults::Parser->new()->parse( $String ) }, $String );
}

done_testing();

