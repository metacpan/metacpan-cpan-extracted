use 5.008;
use strict;
use warnings;

package LV::Backend::Sentinel;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use Sentinel;

sub lvalue :lvalue
{
	my %args = @_;
	unless ($args{set} && $args{get})
	{
		my $caller = (caller(1))[3];
		$args{get} ||= sub { require Carp; Carp::croak("$caller is writeonly") };
		$args{set} ||= sub { require Carp; Carp::croak("$caller is readonly") };
	}
	sentinel(%args);
}

1;
