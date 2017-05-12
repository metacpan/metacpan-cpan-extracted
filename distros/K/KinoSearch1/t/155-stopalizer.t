#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('KinoSearch1::Analysis::Stopalizer') }
use KinoSearch1::Analysis::TokenBatch;
use KinoSearch1::Analysis::Tokenizer;

my $tokenizer = KinoSearch1::Analysis::Tokenizer->new;

my $batch = KinoSearch1::Analysis::TokenBatch->new;
$batch->append( "i am the walrus", 0, 5 );
$batch = $tokenizer->analyze($batch);

my $stopalizer = KinoSearch1::Analysis::Stopalizer->new( language => 'en' );
$batch = $stopalizer->analyze($batch);

my @token_texts;
while ( $batch->next ) {
    push @token_texts, $batch->get_text;
}
is_deeply( \@token_texts, [ '', '', '', 'walrus' ], "stopwords stopalized" );

