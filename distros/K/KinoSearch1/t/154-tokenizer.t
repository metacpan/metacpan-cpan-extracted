#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok('KinoSearch1::Analysis::Tokenizer') }
use KinoSearch1::Analysis::TokenBatch;

my $tokenizer = KinoSearch1::Analysis::Tokenizer->new;

my $batch = KinoSearch1::Analysis::TokenBatch->new;
$batch->append( "a b c", 0, 5 );
$batch = $tokenizer->analyze($batch);

my ( @token_texts, @start_offsets, @end_offsets );
while ( $batch->next ) {
    push @token_texts,   $batch->get_text;
    push @start_offsets, $batch->get_start_offset;
    push @end_offsets,   $batch->get_end_offset;
}
is_deeply( \@token_texts, [qw( a b c )], "correct texts" );
is_deeply( \@start_offsets, [ 0, 2, 4, ], "correct start offsets" );
is_deeply( \@end_offsets,   [ 1, 3, 5, ], "correct end offsets" );

$tokenizer = KinoSearch1::Analysis::Tokenizer->new( token_re => qr/./ );
$batch = KinoSearch1::Analysis::TokenBatch->new;
$batch->append( "a b c", 0, 5 );
$batch = $tokenizer->analyze($batch);

@token_texts   = ();
@start_offsets = ();
@end_offsets   = ();
while ( $batch->next ) {
    push @token_texts,   $batch->get_text;
    push @start_offsets, $batch->get_start_offset;
    push @end_offsets,   $batch->get_end_offset;
}
is_deeply( \@token_texts, [ 'a', ' ', 'b', ' ', 'c' ], "texts: custom re" );
is_deeply( \@start_offsets, [ 0 .. 4 ], "starts: custom re" );
is_deeply( \@end_offsets,   [ 1 .. 5 ], "ends: custom re" );
