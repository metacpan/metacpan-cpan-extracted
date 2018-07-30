use 5.014;
use strict;
use warnings;

package Kavorka::TraitFor::Parameter::alias;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo::Role;

around _injection_assignment => sub
{
	my $next = shift;
	my $self = shift;
	my ($sig, $var, $val) = @_;
	
	if ($] >= 5.022)
	{
		# in some future version of Perl, should be able to set $pragma=''
		my $pragma = "use experimental 'refaliasing';no warnings 'experimental::refaliasing';";
		my $kind   = $self->kind;
		$kind = 'local' unless $kind eq 'my' || $kind eq 'our';
		return sprintf('%s %s; { %s\\%s = \\ do { %s } };', $kind, $var, $pragma, $var, $val);
	}
	elsif ($self->kind eq 'my')
	{
		require Data::Alias;
		return sprintf('Data::Alias::alias(my %s = do { %s });', $var, $val);
	}
	elsif ($self->kind eq 'our')
	{
		(my $glob = $var) =~ s/\A./*/;
		return sprintf('our %s; local %s = \\do { %s };', $var, $glob, $val);
	}
	else
	{
		(my $glob = $var) =~ s/\A./*/;
		return sprintf('local %s = \\do { %s };', $glob, $val);
	}
};

after sanity_check => sub
{
	my $self = shift;
	
	my $traits = $self->traits;
	my $name   = $self->name;
	
	croak("Parameter $name cannot be an alias and coerce") if $traits->{coerce};
	croak("Parameter $name cannot be an alias and a copy") if $traits->{copy};
	croak("Parameter $name cannot be an alias and locked") if $traits->{locked};
};

1;
