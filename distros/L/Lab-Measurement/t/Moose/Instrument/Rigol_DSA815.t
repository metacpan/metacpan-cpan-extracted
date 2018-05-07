#!perl

# Do not connect anything to the input ports when running this!!!

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import =>
    [qw/is_float is_absolute_error is_relative_error set_get_test/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;
use MooseX::Params::Validate;
use Moose::Instrument::SpectrumAnalyzerTest qw/test_spectrum_analyzer/;

use File::Spec::Functions 'catfile';
use Module::Load 'autoload';

eval {
    autoload 'PDL::Graphics::Gnuplot';
    1;
} or do {
    plan skip_all => "test requires PDL::Graphics::Gnuplot";
};

my $log_file = catfile(qw/t Moose Instrument Rigol_DSA815.yml/);

my $inst = mock_instrument(
    type     => 'Rigol_DSA815',
    log_file => $log_file,
);

isa_ok( $inst, 'Lab::Moose::Instrument::Rigol_DSA815' );

is_absolute_error(
    $inst->get_Xpoints_number(), 601, .01,
    "built-in number of points in a trace"
);

# generic tests for any Spectrum analyzer.
test_spectrum_analyzer( SpectrumAnalyzer => $inst );

done_testing();

