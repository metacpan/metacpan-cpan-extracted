use Test::More;
use Test::Exception;

use strict;
use warnings;

use lib 't/lib';
use TestGeoUKPostcode;

use Geo::UK::Postcode::Regex::Simple ':all';

{
    local $Geo::UK::Postcode::Regex::Simple::MODE = 'foo';
    dies_ok {postcode_re} "dies with invalid mode";
    dies_ok {validate_pc} "dies with invalid mode";
}

my @test_pcs = TestGeoUKPostcode->test_pcs();
my @test_pcs_partial = TestGeoUKPostcode->test_pcs( { partial => 1 } );

foreach my $mode (qw( valid strict lax )) {

    foreach my $length (qw( full partial )) {

        foreach my $case (qw( case-insensitive case-sensitive )) {

            subtest "$mode-$length-$case" => sub {

                foreach my $captures (qw( nocaptures captures )) {

                    foreach my $anchored (qw( anchored unanchored )) {

                        subtest "postcode_re $captures $anchored" => sub {

                            Geo::UK::Postcode::Regex::Simple->import(    #
                                "-$mode",
                                "-$case",
                                "-$length",
                                "-$captures",
                                "-$anchored",
                            );

                            ok my $re = postcode_re, "got postcode regex";

                            foreach my $pc ( @test_pcs, @test_pcs_partial ) {

                                subtest $pc->{raw} => sub {
                                     test_postcode_against_regex(
                                         $pc => {
                                             mode     => $mode,
                                             length   => $length,
                                             case     => $case,
                                             captures => $captures,
                                             anchored => $anchored,
                                             re       => $re,
                                         }
                                     );
                                };
                            }
                        };
                    }
                }
            };
        }
    }
}

done_testing();

sub test_postcode_against_regex {
    my %pc   = %{ +shift };
    my $test = shift;

    my ( $mode, $length, $case, $anchored, $re )
        = @{$test}{qw( mode length case anchored re )};

    if ( $anchored eq 'unanchored' && $pc{unanchored} ) {
        %pc = ( %pc, %{ $pc{unanchored} } ) if $pc{unanchored}->{$mode} && $length eq 'partial';
    }

    my @strings = TestGeoUKPostcode->get_format_list( \%pc );

    my $match = 1;
    $match = 0 unless $pc{$mode};

    $match = 0 if $pc{partial} && $length eq 'full';

    test_string( \%pc, $test, $match, $_ ) foreach @strings;

    my @strings_lc = TestGeoUKPostcode->get_lc_format_list( \%pc );

    $match = 0 if $case eq 'case-sensitive';

    test_string( \%pc, $test, $match, $_ ) foreach @strings_lc;
}

sub test_string {
    my ( $pc, $test, $match, $str ) = @_;

    my ( $mode, $length, $case, $captures, $anchored, $re )
        = @{$test}{qw( mode length case captures anchored re )};

    if ($match) {

        if ( $captures eq 'captures' ) {
            ok my @matches = $str =~ $re, "$str matches $mode, $length, $case";

            test_postcode_captures( $pc, $test, @matches );

        } else {
            ok $str=~ $re, "$str matches $mode, $length, $case";

        }

        ok validate_pc($str), "validate_pc ok (true)";

        if ( $anchored eq 'anchored' ) {
            ok my $parsed = parse_pc($str), "parse_pc returns true";

            test_parsed_pc( $pc, $parsed );
        }

        if ( $length ne 'partial' ) {
            is_deeply [ extract_pc("foo bar $str baz") ], [ uc $str ],
                "extract_pc ok";
        }

    } else {

        ok $str !~ $re, "$str doesn't match $mode, $length, $case";

        ok !validate_pc($str), "validate_pc ok (false)";

        if ( $anchored eq 'anchored' ) {
            ok !parse_pc($str), "parse_pc returns false";
        }

        if ( $length ne 'partial' ) {
            is_deeply [ extract_pc("foo bar $str baz") ], [],
                "extract_pc ok (found none)";
        }
    }
}

sub test_postcode_captures {
    my ( $pc, $test, @matches ) = @_;

    my ( $outcode, $area, $district, $sector, $unit );

    if ( $test->{case} eq 'case-insensitive' ) {
        $outcode  = uc $outcode  if $outcode;
        $area     = uc $area     if $area;
        $district = uc $district if $district;
        $sector   = uc $sector   if $sector;
        $unit     = uc $unit     if $unit;
    }

    if ( $test->{mode} eq 'valid' ) {
        ( $outcode, $sector, $unit ) = @matches;

        if ( $test->{case} eq 'case-insensitive' ) {
            $outcode = uc $outcode if $outcode;
            $sector  = uc $sector  if $sector;
            $unit    = uc $unit    if $unit;
        }

        if ( $pc->{outcode} ) {
            is $outcode, $pc->{outcode}, "Outcode matched ok";
        } else {
            ok !$outcode, "Outcode not matched";
        }

    } else {
        ( $area, $district, $sector, $unit ) = @matches;

        if ( $test->{case} eq 'case-insensitive' ) {
            $area     = uc $area     if $area;
            $district = uc $district if $district;
            $sector   = uc $sector   if $sector;
            $unit     = uc $unit     if $unit;
        }

        if ( $pc->{area} ) {
            is $area, $pc->{area}, "Area matched ok";
        } else {
            ok !$area, "Area not matched";
        }

        if ( $pc->{subdistrict} ) {
            is $district, $pc->{district} . $pc->{subdistrict},
                "District (including subdistrict) matched ok";
        } elsif ( $pc->{district} ) {
            is $district, $pc->{district}, "District matched ok";
        } else {
            ok !$district, "District not matched";
        }
    }

    if ( $pc->{sector} ) {
        is $sector, $pc->{sector}, "Sector matched ok";
    } else {
        ok !$sector, "Sector not matched";
    }

    if ( $pc->{unit} ) {
        is $unit, $pc->{unit}, "Unit matched ok";
    } else {
        ok !$unit, "Unit not matched";
    }

}

sub test_parsed_pc {
    my ( $pc, $parsed ) = @_;

    foreach (qw( area district subdistrict sector unit outcode incode )) {
        is $parsed->{$_}, $pc->{$_}, "$_ ok";
    }

    foreach (qw( valid partial full )) {
        ok $pc->{$_} ? $parsed->{$_} : !$parsed->{$_}, "$_ ok";
    }
}

