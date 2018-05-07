package Moose::Instrument::SpectrumAnalyzerTest;

use 5.010;
use warnings;
use strict;

use Exporter 'import';

use lib 't';

use Module::Load;
use Lab::Test import => [
    qw/is_float is_absolute_error is_relative_error set_get_test scpi_set_get_test/
];
use Test::More;
use MooseX::Params::Validate;

our @EXPORT_OK = qw/test_spectrum_analyzer/;

sub test_spectrum_analyzer {
    my %args = validated_hash(
        \@_,
        SpectrumAnalyzer => { isa => 'Lab::Moose::Instrument' },
    );

    my $s = delete $args{SpectrumAnalyzer};

    my %scpi_functions = (
        sense_frequency_start               => [ 1e6,   10e6,  100e6 ],
        sense_frequency_stop                => [ 110e6, 210e6, 310e6 ],
        sense_bandwidth_resolution          => [ 3e3,   3e4,   3e5 ],
        sense_bandwidth_video               => [ 1e3,   1e4,   1e5 ],
        sense_sweep_time                    => [ .1,    .4,    .8 ],
        display_window_trace_y_scale_rlevel => [ -30,   -10,   -20 ],
        sense_power_rf_attenuation          => [ 20,    10,    0 ],
    );

    # sort below to ensure the same keys order, which is undefined in a hash by default
    for my $func ( sort keys %scpi_functions ) {
        scpi_set_get_test(
            instr      => $s,
            func       => $func,
            values     => $scpi_functions{$func},
            is_numeric => 1,                        # this is default
        );
    }

    # non numeric results
    scpi_set_get_test(
        instr      => $s,
        func       => 'unit_power',
        values     => [ 'DBMV', 'V', 'DBM' ],
        is_numeric => 0
    );

SKIP: {
        my $cond = $s->capable_to_query_number_of_X_points_in_hardware()
            && $s->capable_to_set_number_of_X_points_in_hardware();
        if ( not $cond ) {
            skip
                "set and query the sweep number of points (hardware incable to do so)",
                1;
        }
        scpi_set_get_test(
            instr      => $s,
            func       => 'sense_sweep_points',
            values     => [ 10, 40, 100 ],
            is_numeric => 1,                      # this is default
        );
    }

    is( $s->get_UnitX, "Hz",        "the UnitX is Hz" );
    is( $s->get_NameX, "Frequency", "the NameX is 'Frequency'" );

    # trace subsystem

    my $Xpoints_number = $s->get_Xpoints_number();
    my $traceXY
        = $s->get_traceXY( trace => 1 );    # we must have at least trace one

    is_deeply(
        [ $traceXY->dims() ], [ $Xpoints_number, 2 ],
        "trace has proper dimensions"
    );
    my $freqs = $traceXY->slice(":, 0");
    is_absolute_error(
        $freqs->slice("0"), $s->sense_frequency_start_query(),
        .0001,              "frequency start matches trace start"
    );
    is_absolute_error(
        $freqs->slice("-1"), $s->sense_frequency_stop_query(),
        .0001,               "frequency stop matches trace end"
    );

}

1;
