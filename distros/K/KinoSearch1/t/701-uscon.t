use strict;
use warnings;

use lib 'buildlib';
use Test::More tests => 10;

BEGIN {
    use_ok('KinoSearch1::Searcher');
    use_ok('KinoSearch1::Analysis::PolyAnalyzer');
}

use KinoSearch1::Test::TestUtils qw( persistent_test_index_loc );

my $tokenizer = KinoSearch1::Analysis::PolyAnalyzer->new( language => 'en' );
my $searcher = KinoSearch1::Searcher->new(
    invindex => persistent_test_index_loc(),
    analyzer => $tokenizer,
);

my %searches = (
    'United'              => 34,
    'shall'               => 50,
    'not'                 => 27,
    '"shall not"'         => 21,
    'shall not'           => 51,
    'Congress'            => 31,
    'Congress AND United' => 22,
    '(Congress AND United) OR ((Vice AND President) OR "free exercise")' =>
        28,
);

while ( my ( $qstring, $num_expected ) = each %searches ) {
    my $hits = $searcher->search($qstring);
    $hits->seek( 0, 100 );
    is( $hits->total_hits, $num_expected, $qstring );
}

