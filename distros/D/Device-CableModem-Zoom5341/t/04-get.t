#!usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 33;
use Device::CableModem::Zoom5341;

my $cm = Device::CableModem::Zoom5341->new;
isa_ok($cm, 'Device::CableModem::Zoom5341', "Object built OK");


# Use sample data
use Device::CableModem::Zoom5341::Test;
$cm->load_test_data;


# Setup arrays for the values we're testing
# On down, we expect index 1 to have a given value, and 2 to be undef
my %downstats = (
	'freq'   => '567.0000',
	'mod'    => '256 QAM',
	'power'  => '-1.3753',
	'snr'    => '35.780',
);

# On up, 0 should have a value, and 1 be undef
my %upstats = (
	'chanid' => 2,
	'freq'   => 27900000,
	'bw'     => 6400000,
	'power'  => '41.7500',
);

# Helper funcs
sub check_down
{
	my ($stat, $aref) = @_;
	is($aref->[1], $downstats{$stat}, "Got good down$stat");
	is($aref->[2], undef,             "Got empty down$stat");
}
sub check_up
{
	my ($stat, $aref) = @_;
	is($aref->[0], $upstats{$stat}, "Got good up$stat");
	is($aref->[1], undef,           "Got empty up$stat");
}


# Check the get-all funcs
my $downall = $cm->get_down_stats;
check_down($_, $downall->{$_}) for keys %downstats;

my $upall = $cm->get_up_stats;
check_up($_, $upall->{$_}) for keys %downstats;


# Now test the individual funcs
my $s;
$s = $cm->get_down_freq;
check_down('freq', $s);

$s = $cm->get_down_mod;
check_down('mod', $s);

$s = $cm->get_down_power;
check_down('power', $s);

$s = $cm->get_down_snr;
check_down('snr', $s);


$s = $cm->get_up_chanid;
check_up('chanid', $s);

$s = $cm->get_up_freq;
check_up('freq', $s);

$s = $cm->get_up_bw;
check_up('bw', $s);

$s = $cm->get_up_power;
check_up('power', $s);
