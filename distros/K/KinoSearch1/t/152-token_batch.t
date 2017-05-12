#!/usr/bin/perl
use strict;
use warnings;
use lib 'buildlib';

use Test::More tests => 3;
use KinoSearch1::Test::TestUtils qw( utf8_test_strings );

BEGIN { use_ok('KinoSearch1::Analysis::TokenBatch') }
use KinoSearch1::Analysis::Token;

my $batch = KinoSearch1::Analysis::TokenBatch->new;
$batch->append( "car",   0,  3 );
$batch->append( "bike",  10, 14 );
$batch->append( "truck", 20, 25 );

my @texts;
while ( $batch->next ) {
    push @texts, $batch->get_text;
}
is_deeply( \@texts, [qw( car bike truck )], "return tokens in order" );

TODO: {
    local $TODO = "Known UTF-8 bugs, fixed in KS 0.3x";
    my ( $smiley, $not_a_smiley, $frowny ) = utf8_test_strings();

    $batch = KinoSearch1::Analysis::TokenBatch->new;
    $batch->append( $smiley, 0, bytes::length($smiley) );
    $batch->next;
    is( $batch->get_text, $smiley, "TokenBatch handles UTF-8 correctly" );
}

