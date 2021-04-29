#!perl -w

use warnings;
use strict;
use Test::Most tests => 5;

BEGIN {
	use_ok('LWP::UserAgent::Throttled');
	use_ok('Time::HiRes');
}

UA: {
	my $ua = new_ok('LWP::UserAgent::Throttled');
	my $t = Tester->new();

	is($t->count(), 0, 'Initialised correctly');

	$ua->ua($t);

	$ua->get('https://www.perl.org/');

	is($t->count(), 1, 'Used the correct ua');
}

1;

package Tester;

# our @ISA = ('LWP::UserAgent');

sub new {
	my $class = shift;

	return bless { count => 0 }, $class;
}

sub send_request {
	my $self = shift;

	$self->{count}++;
	return bless { };
}

sub redirects { return 0; }
sub code { return 0; }

sub count {
	my $self = shift;

	return $self->{count};
}
