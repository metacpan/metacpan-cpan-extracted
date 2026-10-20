#!perl -wT

# Test ua can be set and get

use strict;
use warnings;

use LWP;
use Test::Most tests => 6;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::Postcodes');
}

UA: {
	SKIP: {
		skip('Test requires Internet access', 4) unless(-e 't/online.enabled');

		my $coder = new_ok('Geo::Coder::Postcodes');

		my $ua = new_ok('Tester');
		$coder->ua($ua);
		cmp_ok($coder->ua(), 'eq', $ua, 'Setting UA works');

		$coder->geocode(location => '10 Downing St, Westminster, London');
		cmp_ok($ua->count(), '==', 1, 'Used the correct ua');
	}
}

1;

package Tester;

# our @ISA = ('LWP::UserAgent');

sub new {
	my $class = shift;

	return bless { count => 0 }, $class;
}

sub get {
	my $self = shift;

	$self->{count}++;
	return bless { }, __PACKAGE__;
}

sub is_error { return 0 }
sub decoded_content { return '{}' }

sub count {
	my $self = shift;

	return $self->{count};
}
