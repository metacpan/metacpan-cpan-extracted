#!usr/bin/env perl5
use strict;
use warnings;

use Test::More tests => 33;
use Device::CableModem::Zoom5341J;

my $thisdir;
BEGIN { use File::Basename; $thisdir = dirname($0); }

my $cm = Device::CableModem::Zoom5341J->new;
isa_ok($cm, 'Device::CableModem::Zoom5341J', "Object built OK");


# Use sample data
use Device::CableModem::Zoom5341J::Test;
use File::Spec;
$cm->load_test_data(File::Spec->catfile($thisdir, 'sample.html'));


# Setup arrays for the values we're testing
# On down, we expect index 0 to have a given value, and 1 to be under
my %downstats = (
	'freq'   => '125',
	'mod'    => 'QAM256',
	'power'  => '2.3',
	'snr'    => '40.3',
);

# On up, 1 should have a value, and 2 be undef
my %upstats = (
	'chanid' => 2,
	'freq'   => 900,
	'bw'     => 5120,
	'power'  => '40.3',
);

# Helper funcs
sub check_down
{
	my ($stat, $aref) = @_;
	is($aref->[0], $downstats{$stat}, "Got good down$stat");
	is($aref->[1], undef,             "Got empty down$stat");
}
sub check_up
{
	my ($stat, $aref) = @_;
	is($aref->[1], $upstats{$stat}, "Got good up$stat");
	is($aref->[2], undef,           "Got empty up$stat");
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
