use strict;
use warnings;
use lib 'buildlib';

use Test::More tests => 7;
use KinoSearch::Test::TestUtils qw( test_analyzer );

my $source_text = 'Eats, shoots and leaves.';
my $case_folder = KinoSearch::Analysis::CaseFolder->new;
my $polyanalyzer
    = KinoSearch::Analysis::PolyAnalyzer->new( analyzers => [$case_folder], );
test_analyzer(
    $polyanalyzer, $source_text,
    ['eats, shoots and leaves.'],
    '"analyzers" constructor arg'
);
$polyanalyzer = KinoSearch::Analysis::PolyAnalyzer->new( language => 'en', );
test_analyzer( $polyanalyzer, $source_text, [qw( eat shoot and leav )],
    '"language" constructor arg' );

ok( $polyanalyzer->get_analyzers(), "get_analyzers method" );

