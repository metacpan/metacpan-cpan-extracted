#!perl -wT

# Check the admin 2 database is sensible

use strict;
use warnings;
use Test::Most tests => 4;

BEGIN {
	use_ok('Geo::Coder::Free::DB::admin2');
}

CITIES: {
	Geo::Coder::Free::DB::init(directory => 'lib/Geo/Coder/Free/databases');
	my $admin2 = new_ok('Geo::Coder::Free::DB::admin2' => [logger => new_ok('MyLogger')]);

	my $kent = $admin2->fetchrow_hashref({ concatenated_codes => 'GB.ENG.G5' });
	ok($kent->{asciiname} eq 'Kent');
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
