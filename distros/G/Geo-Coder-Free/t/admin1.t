#!perl -wT

# Check the admin 1 database is sensible

use strict;
use warnings;
use Test::Most tests => 5;

BEGIN {
	use_ok('Geo::Coder::Free::DB::admin1');
}

CITIES: {
	Geo::Coder::Free::DB::init(directory => 'lib/Geo/Coder/Free/databases');
	my $admin1 = new_ok('Geo::Coder::Free::DB::admin1' => [logger => new_ok('MyLogger')]);

	my $england = $admin1->fetchrow_hashref({ concatenated_codes => 'GB.ENG' });
	ok($england->{asciiname} eq 'England');

	$england = $admin1->fetchrow_hashref({ asciiname => 'England' });
	ok($england->{concatenated_codes} eq 'GB.ENG');
};

package MyLogger;

sub new {
	my ($proto, %args) = @_;

	my $class = ref($proto) || $proto;

	return bless { }, $class;
}

sub info {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}

sub trace {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}

sub debug {
	my $self = shift;
	my $message = shift;

	if($ENV{'TEST_VERBOSE'}) {
		::diag($message);
	}
}

sub AUTOLOAD {
	our $AUTOLOAD;
	my $param = $AUTOLOAD;

	unless($param eq 'MyLogger::DESTROY') {
		::diag("Need to define $param");
	}
}
