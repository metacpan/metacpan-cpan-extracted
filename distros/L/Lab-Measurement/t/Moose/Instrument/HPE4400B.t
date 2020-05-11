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

my $log_file = catfile(qw/t Moose Instrument HPE4400B.yml/);

my $inst = mock_instrument(
    type     => 'HPE4400B',
    log_file => $log_file,
);

isa_ok( $inst, 'Lab::Moose::Instrument::HPE4400B' );

# generic tests for any Spectrum analyzer.
test_spectrum_analyzer( SpectrumAnalyzer => $inst );

done_testing();

