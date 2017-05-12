package TestObject;

use strict;
use warnings;

## CTOR
##
sub new
{
	my $class = shift;
	my $id = shift;
	my $rawRecord = shift;

	my $self =
		{
			_id => $id,
			_name => $rawRecord->{name},
			_byear => $rawRecord->{byear},
			_siblings => $rawRecord->{siblings},
			_city => $rawRecord->{city},
			_sex => $rawRecord->{sex},
		};
		
	bless($self, $class);
	
	return $self;
}

sub get_id
{
	my $self = shift;
	
	return $self->{_id};
}

sub get_name
{
	my $self = shift;
	
	return $self->{_name};
}

sub get_byear
{
	my $self = shift;
	
	return $self->{_byear};
}

sub get_siblings
{
	my $self = shift;
	
	return $self->{_siblings};
}

sub get_city
{
	my $self = shift;
	
	return $self->{_city};
}

sub get_sex
{
	my $self = shift;
	
	return $self->{_sex};
}

sub get_age
{
	my $self = shift;

	return 2016 - $self->{_byear};

# Hardcode the year here since it was when the tests were written
# and the supplied test data is fixed... :-)
#
# In real life it would be:
#
#	return ((localtime())[5] + 1900) - $self->{_byear};
}

1;
