#!perl

use lib  'C:/Users/emma.EBI/Fuzzy/cpan-distribution/FuzzyRecogniser/lib';

use Test::More tests => 1;

BEGIN {
    use_ok( 'EBI::FGPT::FuzzyRecogniser' );
}

diag( "Testing EBI::FGPT::FuzzyRecogniser $EBI::FGPT::FuzzyRecogniser::VERSION, Perl $], $^X" );
