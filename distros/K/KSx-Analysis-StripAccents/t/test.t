# This test was stolen from KinoSearch’s LCNormalizer (now called
# CaseFolder) tests and KinoTestUtils (now KinoSearch::Search::TestUtils)
# (with the appropriate modifications).

use warnings;
use utf8;

my $old;
BEGIN { $old = !eval{require KinoSearch::Analysis::Inversion}}

use Test::More tests => 4 + $old;

use_ok 'KSx::Analysis::StripAccents';

my $stripper = KSx::Analysis::StripAccents->new;

(test_analyzer . '_old' x $old )
 ->(
    $stripper,      "căPîTāl ofḞḕnsE | Σὺ ἔσωσας",
    ['capital offense | συ εσωσασ'], 'lc plain text'
 );

# Verify an Analyzer's analyze_batch, analyze_field, analyze_text, and analyze_raw methods.
sub test_analyzer_old {
    my ( $analyzer, $source, $expected, $message ) = @_;

    require KinoSearch::Analysis::TokenBatch;
    my $batch = KinoSearch::Analysis::TokenBatch->new( text => $source );
    $batch = $analyzer->analyze_batch($batch);
    my @got;
    while ( my $token = $batch->next ) {
        push @got, $token->get_text;
    }
    Test::More::is_deeply( \@got, $expected, "analyze: $message" );

    $batch = $analyzer->analyze_text($source);
    @got   = ();
    while ( my $token = $batch->next ) {
        push @got, $token->get_text;
    }
    Test::More::is_deeply( \@got, $expected, "analyze_text: $message" );

    @got = $analyzer->analyze_raw($source);
    Test::More::is_deeply( \@got, $expected, "analyze_raw: $message" );

    $batch = $analyzer->analyze_field( { content => $source }, 'content' );
    @got = ();
    while ( my $token = $batch->next ) {
        push @got, $token->get_text;
    }
    Test::More::is_deeply( \@got, $expected, "analyze_field: $message" );
}

# Verify an Analyzer's transform, transform_text, and split methods.
sub test_analyzer {
    my ( $analyzer, $source, $expected, $message ) = @_;

    my $inversion = KinoSearch::Analysis::Inversion->new( text => $source );
    $inversion = $analyzer->transform($inversion);
    my @got;
    while ( my $token = $inversion->next ) {
        push @got, $token->get_text;
    }
    Test::More::is_deeply( \@got, $expected, "analyze: $message" );

    $inversion = $analyzer->transform_text($source);
    @got       = ();
    while ( my $token = $inversion->next ) {
        push @got, $token->get_text;
    }
    Test::More::is_deeply( \@got, $expected, "transform_text: $message" );

    @got = @{ $analyzer->split($source) };
    Test::More::is_deeply( \@got, $expected, "split: $message" );
}
