use 5.006;
use strict;
use warnings;

package LV::Backend::Tie;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

sub lvalue :lvalue
{
	my %args = @_;
	tie(my $var, 'LV::Backend::Tie::TiedScalar', $args{get}, $args{set});
	$var;
}

package LV::Backend::Tie::TiedScalar;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';
our @CARP_NOT  = qw( LV LV::Backend::Tie );

sub TIESCALAR
{
	my $class = shift;
	my ($get, $set) = @_;

	unless ($set && $get)
	{
		my $caller = (caller(2))[3];
		$get ||= sub { require Carp; Carp::croak("$caller is writeonly") };
		$set ||= sub { require Carp; Carp::croak("$caller is readonly") };
	}
	
	bless [$get, $set] => $class;
}

sub FETCH
{
	&{shift->[0]};
}

sub STORE
{
	&{shift->[1]};
}

1;
