#!perl -w

# Geo::Address::Parser and Geo::libpostal are optional: OpenAddresses uses
# them when they are installed and must carry on without them.  0.49 died
# with "Can't locate Geo/Address/Parser.pm" on a US address when the parser
# wasn't installed, and no test noticed, because the timed tests in
# t/edge_cases.t only looked for a timeout.
#
# This runs in a process of its own, so neither module has been loaded by
# another test before it is hidden.

use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::Most;
use Test::Without::Module qw(Geo::Address::Parser);

use Geo::Coder::Free::OpenAddresses;

# An empty directory: the lookup reaches the parsers and finds nothing
my $dir = tempdir(CLEANUP => 1);

# A US address that the earlier steps can't answer, so geocode() goes on to
# the Geo::Address::Parser step and then to the libpostal one
my $address = '1600 Pennsylvania Ave, Springfield, IL 12345';

subtest 'Geo::Address::Parser not installed' => sub {
	my $oa = Geo::Coder::Free::OpenAddresses->new(openaddr => $dir, libpostal => 0);
	my $rc;

	lives_ok { $rc = $oa->geocode(location => $address) } 'a US address does not die without Geo::Address::Parser';
	is($rc, undef, 'and finds nothing in an empty database');
	ok(!exists($INC{'Geo/Address/Parser.pm'}), 'Geo::Address::Parser was not loaded');
};

subtest 'libpostal => 0' => sub {
	my $oa = Geo::Coder::Free::OpenAddresses->new(openaddr => $dir, libpostal => 0);

	$oa->geocode(location => $address);
	ok(!exists($INC{'Geo/libpostal.pm'}), 'Geo::libpostal is not loaded when libpostal is turned off');
};

done_testing();
