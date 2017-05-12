use 5.008;
use strict;
use warnings;

package LV::Backend::Magic;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use Carp;
use Variable::Magic qw( wizard cast );

my $wiz = wizard(
	data => sub { $_[1] },
	set  => sub { $_[1]{set}->(${ $_[0] }); 0 },
	get  => sub { ${ $_[1]{var} } = $_[1]{get}->(); 0 },
);

sub lvalue :lvalue
{
	my %args = @_;
	unless ($args{set} && $args{get})
	{
		my $caller = (caller(1))[3];
		$args{get} ||= sub { require Carp; Carp::croak("$caller is writeonly") };
		$args{set} ||= sub { require Carp; Carp::croak("$caller is readonly") };
	}
	
	$args{var} = \(my $var);
	cast($var, $wiz, \%args);
	$var;
}

1;
