#!perl

# Do not connect anything to the input ports when running this!!!

use warnings;
use strict;
use 5.010;

use lib 't';

use Lab::Test import => [qw/is_absolute_error/];
use Test::More;
use Moose::Instrument::MockTest qw/mock_instrument/;

use File::Spec::Functions 'catfile';
my $log_file = catfile(qw/t Moose Instrument ZI_MFIA.yml/);

my $mfia = mock_instrument(
    type     => 'ZI_MFIA',
    log_file => $log_file,
);

isa_ok( $mfia, 'Lab::Moose::Instrument::ZI_MFIA' );

$mfia->set_frequency( value => 100 );
is_absolute_error( $mfia->get_frequency(), 100, 0.01, "set_frequency" );

my $sample = $mfia->get_impedance_sample( timeout => 1 );
ok( exists $sample->{realz}, "impedance sample contains real part" );

done_testing();
