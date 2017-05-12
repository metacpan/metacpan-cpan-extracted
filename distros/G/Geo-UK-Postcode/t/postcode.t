# postcode.t

use Test::Most;

use Geo::UK::Postcode;

use lib 't/lib';
use TestGeoUKPostcode;

my $pkg = 'Geo::UK::Postcode';

dies_ok { $pkg->new() } "dies with no argument";

note "full postcodes";

foreach my $test ( TestGeoUKPostcode->test_pcs() ) {

    foreach ( TestGeoUKPostcode->get_format_list($test)) {
        subtest( $_ => sub { test_pc( { %{$test}, raw => $_ } ) } );
    }

}

note "partial postcodes";

foreach my $test ( TestGeoUKPostcode->test_pcs({ partial => 1}) ) {

    foreach ( TestGeoUKPostcode->get_format_list($test)) {
        subtest( $_ => sub { test_pc( { %{$test}, raw => $_ } ) } );
    }

}

sub test_pc {
    my $test = shift;

    note $test->{raw};

    unless ( $test->{area} ) {

        # TODO replace with Test::Fatal
        dies_ok { $pkg->new( $test->{raw} ) } "dies ok with invalid postcode";
        return;
    }

    ok my $pc = $pkg->new( $test->{raw} ), "create pc object";
    isa_ok $pc, 'Geo::UK::Postcode';

    is $pc->$_, $test->{$_}, "$_ ok"
        foreach qw/ area district subdistrict sector unit outcode incode /;

    is $pc->outward, $test->{outcode}, 'outward ok';
    is $pc->inward,  $test->{incode},  'inward ok';

    is $pc->fixed_format, $test->{fixed_format}, "fixed format ok";

    my $str = $test->{outcode};
    $str .= ' ' . $test->{incode} if $test->{incode};
    is $pc->as_string, $str, "as_string ok";

    is "$pc", $str, "stringify ok";

    foreach (qw/ valid strict partial non_geographical bfpo /) {
        is $pc->$_, $test->{$_} || 0,
            $test->{$_} ? "postcode is $_" : "postcode isn't $_";
    }

    is_deeply [ $pc->posttowns ], $test->{posttowns} || [], "posttowns  ok";

}

done_testing();

