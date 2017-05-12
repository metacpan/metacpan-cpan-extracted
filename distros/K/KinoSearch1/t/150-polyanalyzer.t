use strict;
use warnings;
use lib 'buildlib';

use Test::More tests => 5;
use KinoSearch1::Test::TestUtils qw( test_analyzer );

use KinoSearch1::Analysis::LCNormalizer;
use KinoSearch1::Analysis::Tokenizer;
use KinoSearch1::Analysis::Stopalizer;
use KinoSearch1::Analysis::Stemmer;
use KinoSearch1::Analysis::PolyAnalyzer;
use KinoSearch1::Analysis::TokenBatch;

my $source_text = 'Eats, shoots and leaves.';

my $lc_normalizer = KinoSearch1::Analysis::LCNormalizer->new;
my $tokenizer     = KinoSearch1::Analysis::Tokenizer->new;
my $stopalizer = KinoSearch1::Analysis::Stopalizer->new( language => 'en' );
my $stemmer = KinoSearch1::Analysis::Stemmer->new( language => 'en' );

my $polyanalyzer
    = KinoSearch1::Analysis::PolyAnalyzer->new( analyzers => [], );
test_analyzer( $polyanalyzer, $source_text, [$source_text],
    'no sub analyzers' );

$polyanalyzer
    = KinoSearch1::Analysis::PolyAnalyzer->new( analyzers => [$lc_normalizer],
    );
test_analyzer(
    $polyanalyzer, $source_text,
    ['eats, shoots and leaves.'],
    'with LCNormalizer'
);

$polyanalyzer = KinoSearch1::Analysis::PolyAnalyzer->new(
    analyzers => [ $lc_normalizer, $tokenizer ], );
test_analyzer(
    $polyanalyzer, $source_text,
    [ 'eats', 'shoots', 'and', 'leaves' ],
    'with Tokenizer'
);

$polyanalyzer = KinoSearch1::Analysis::PolyAnalyzer->new(
    analyzers => [ $lc_normalizer, $tokenizer, $stopalizer ], );
test_analyzer(
    $polyanalyzer, $source_text,
    [ 'eats', 'shoots', '', 'leaves' ],
    'with Stopalizer'
);

$polyanalyzer = KinoSearch1::Analysis::PolyAnalyzer->new(
    analyzers => [ $lc_normalizer, $tokenizer, $stopalizer, $stemmer, ], );
test_analyzer( $polyanalyzer, $source_text, [ 'eat', 'shoot', '', 'leav' ],
    'with Stemmer' );

