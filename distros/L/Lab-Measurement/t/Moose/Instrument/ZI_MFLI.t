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

use File::Spec::Functions 'catfile';
my $log_file = catfile(qw/t Moose Instrument ZI_MFLI.yml/);

my $mfli = mock_instrument(
    type     => 'ZI_MFLI',
    log_file => $log_file,
);

isa_ok( $mfli, 'Lab::Moose::Instrument::ZI_MFLI' );

$mfli->set_frequency( value => 100 );
is_absolute_error( $mfli->get_frequency(), 100, 0.01, "set_frequency" );

my $xy = $mfli->get_xy( demod => 0 );
is_absolute_error( $xy->{x}, 0, 1e-3, "x is 0" );
is_absolute_error( $xy->{y}, 0, 1e-3, "y is 0" );

done_testing();
