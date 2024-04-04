#!perl -w

use warnings;
use strict;
use Test::Most tests => 6;

BEGIN {
	use_ok('LWP::UserAgent::Throttled');
}

UA: {
	my $ua = new_ok('LWP::UserAgent::Throttled');
	my $t = Tester->new();

	cmp_ok($t->count(), '==', 0, 'Initialised correctly');

	cmp_ok($ua->ua($t), 'eq', $t, 'Setting the useragent returns the useragent');
	cmp_ok($ua->ua(), 'eq', $t, 'Getting the useragent returns the useragent');

	$ua->get('http://www.perl.org/');

	cmp_ok($t->count(), '==', 1, 'Used the correct ua');
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
	return bless { }, __PACKAGE__;
}

sub code { return 0; }
sub header { return 0; }	# http://www.cpantesters.org/cpan/report/55bb4f64-8d7e-11ec-adcf-8cefa471f67a
sub redirects { return 0; }

sub count {
	my $self = shift;

	return $self->{count};
}
