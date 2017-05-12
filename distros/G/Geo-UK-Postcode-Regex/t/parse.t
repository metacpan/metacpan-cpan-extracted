use Test::More;

use strict;
use warnings;

use lib 't/lib';
use TestGeoUKPostcode;

use Clone qw/ clone /;
use Geo::UK::Postcode::Regex;

my $pkg = 'Geo::UK::Postcode::Regex';

my @tests = (
    { 'parse'              => {} },
    { 'strict'             => { strict => 1 } },
    { 'valid'              => { valid => 1 } },
    { 'partial'            => { partial => 1 } },
    { 'strict and valid'   => { strict => 1, valid => 1 } },
    { 'strict and partial' => { strict => 1, partial => 1 } },
    { 'valid and partial'  => { valid => 1, partial => 1 } },
);

foreach (@tests) {
    my ( $note, $options ) = each %{$_};
    subtest(
        $note => sub {

            $options ||= {};

            foreach my $expected ( TestGeoUKPostcode->test_pcs($options) ) {

                note "upper case";

                my @raw_list = TestGeoUKPostcode->get_format_list($expected);

                subtest( $_ => sub { test_parse( $_, $options, $expected ) } )
                    foreach @raw_list;

                note "lower case";
                $options->{'case-insensitive'} = 1;

                @raw_list = TestGeoUKPostcode->get_lc_format_list($expected);

                subtest( $_ => sub { test_parse( $_, $options, $expected ) } )
                    foreach @raw_list;
            }
        }
    );
}

sub test_parse {
    my ( $raw, $options, $test ) = @_;

    my $parsed = $pkg->parse( $raw, $options );

    unless ( $test->{area} ) {
        ok !$parsed, "False returned from invalid postcode";
        return;
    }

    ok $parsed, "parsed successfully";

    is $parsed->{$_}, $test->{$_}, "$_ ok"
        foreach qw/ area district subdistrict sector unit outcode incode /;

    foreach (qw/ strict partial valid non_geographical bfpo /) {
        is $parsed->{$_} || 0, $test->{$_} || 0,
            $test->{$_} ? "postcode is $_" : "postcode isn't $_";
    }
}

done_testing();

