package Language::Farnsworth::Variables;

use strict;
use warnings;

use Language::Farnsworth::Error;

use Data::Dumper;

#this is very simple right now but i'll need to make a way to inherit
#variables from an old Language::Farnsworth::Variables class so that i can do
#functions with "scoping"

sub new
{
	my $class = shift;
	my $state = shift;
	my $self = {parent => undef, vars => {}};
	$self->{parent} = $state if (ref($state) eq "Language::Farnsworth::Variables");
	bless $self;
}

sub DESTROY
{
	debug 2,"VARIABLES DIE: $_[0]";
}

sub setvar
{
	my $self = shift;
	my $name = shift;
	my $value = shift;

	if ((exists($self->{vars}{$name})) || !defined($self->{parent}))
	{
		if (exists($self->{vars}{$name}) && ref($self->{vars}{$name}) eq "REF")
	    {
			#we've got a reference
			${$self->{vars}{$name}} = $value;
		}
		else
		{
		  $self->{vars}{$name} = $value;
		}
	}
	else
	{
		$self->{parent}->setvar($name, $value); #set it in the previous scope
	}
}

sub declare
{
	my $self = shift;
	my $name = shift;
	my $value = shift;

	if (!defined($name))
	{
		error "NAME UNDEFINED!\n".Dumper([$self, $name, $value, @_]);
	}

	#really all we need to do is just set it in this scope to see it
	$self->{vars}{$name} = $value;
}

sub setref
{
	my $self = shift;
	my $name = shift;

	if (!defined($name))
	{
		error "NAME UNDEFINED!\n".Dumper([$self, $name, @_]);
	}

	#really all we need to do is just set it in this scope to see it
	$self->{vars}{$name} = $_[0]; #can't set things myself with shift, HAVE to use @_ directly
}

sub getref
{
	my $self = shift;
	my $name = shift;
	my $val;

	error "DEPRECIATED CALL TO Variables->getref()";

	if (exists($self->{vars}{$name}))
	{
		$val = \$self->{vars}{$name};
	}
	elsif (defined($self->{parent}))
	{
		$val = $self->{parent}->getref($name);
	}

	return $val;
}

sub getvar
{
	my $self = shift;
	my $name = shift;
	my $val;

	if (exists($self->{vars}{$name}))
	{
		$val = $self->{vars}{$name};
		$val->setref(\$self->{vars}{$name}) unless (ref($val) eq "REF");
		#$val->sethomescope($self);
	}
	elsif (defined($self->{parent}))
	{
		$val = $self->{parent}->getvar($name);
	}

	if (ref $val eq "REF")
	{ #we've got one set by reference
		$val = $$val; #deref it for getting its value
	}

	return $val;
}

sub isvar
{
	my $self = shift;
	my $name = shift;

	my $r = exists($self->{vars}{$name});

	if (!exists($self->{vars}{$name}) && defined($self->{parent}))
	{
		$r = $self->{parent}->isvar($name);
	}

	return $r;
}
1;
