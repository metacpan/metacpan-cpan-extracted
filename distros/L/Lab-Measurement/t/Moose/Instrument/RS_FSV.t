#!perl
use warnings;
use strict;
use 5.010;

use lib 't';

use PDL::Ufunc qw/all/;
use Lab::Test import => [qw/is_float is_absolute_error scpi_set_get_test/];
use Test::More;
use MooseX::Params::Validate 'validated_list';
use Moose::Instrument::MockTest 'mock_instrument';
use File::Spec::Functions 'catfile';

my $log_file = catfile(qw/t Moose Instrument RS_FSV.yml/);

my $fsv = mock_instrument(
    type     => 'RS_FSV',
    log_file => $log_file
);

isa_ok( $fsv, 'Lab::Moose::Instrument::RS_FSV' );

$fsv->rst( timeout => 10 );

$fsv->sense_sweep_points( value => 101 );

for my $i ( 1 .. 3 ) {
    my $data = $fsv->get_spectrum( timeout => 10 );

    is_deeply( [ $data->dims() ], [ 101, 2 ], "data PDL has dims 102 x 2" );

    my $freqs = $data->slice(":,0")->squeeze();
    is_float( $freqs->at(0),  0,   "sweep starts at 0 Hz" );
    is_float( $freqs->at(-1), 7e9, "sweep stops at 7GHZ" );

    $data = $data->slice(":,1")->squeeze();
    ok(
        all( ( $data > -100 ) & ( $data < 0 ) ),
        "real or imaginary part of s-param is in [-100, 0]"
    ) || diag("pdl: $data");
}

# Test getters and setters

scpi_set_get_test(
    instr  => $fsv,
    func   => 'sense_bandwidth_resolution',
    values => [qw/1 100 1000/],
);

done_testing();
