#new value class!
package Language::Farnsworth::Value;

use strict;
use warnings;

use Language::Farnsworth::Error;
use Data::Dumper;

use Scalar::Util qw/weaken/; 

sub setref
{
	my $self = shift;
	my $ref = shift;
	$self->{_ref} = $ref;
}

sub sethomescope
{
	my $self = shift;
	my $scope = shift; #Farnsworth::Variables type
	
	unless ($self->{_homescope})
	{
		$self->{_homescope} = $scope;
		weaken $self->{_homescope};
	}
}

sub gethomescope
{
	return $_[0]->{_homescope};
}

sub getref
{
	my $self = shift;
	return $self->{_ref};
}

sub istype
{
	my $self = shift;
	my $allow = shift; #type to allow!

	return ref($self) =~ /\Q$allow/i;
}

sub type
{
	return "Value (BUG)";
}

sub ismediumtype
{
	my $self = shift;
	my $allow = shift; #type to allow!
	$allow ||= "";
	
	if ($self->isa("Language::Farnsworth::Value::Array") && $allow ne "Array")
	{
		return 1;
	}
	elsif ($self->isa("Language::Farnsworth::Value::Boolean") && $allow ne "Boolean")
	{
		return 1;
	}
	elsif ($self->isa("Language::Farnsworth::Value::String") && $allow ne "String")
	{
		return 1;
	}
	elsif ($self->isa("Language::Farnsworth::Value::Date") && $allow ne "Date")
	{
		return 1;
	}
# promoting Lambda to a High type, so that it can capture the multiplication with other types
#	elsif ($self->isa("Language::Farnsworth::Value::Lambda") && $allow ne "Lambda")
#	{
#		return 1;
#	}
	elsif ($self->isa("Language::Farnsworth::Value::Undef") && $allow ne "Undef")
	{
		return 1;
	}
	
	return 0;
}

sub conforms
{
	my $self = shift;
	my $comparator = shift;

	if (ref($self) ne ref($comparator))
	{
		return 0;
	}
	else
	{
		if (ref($self) eq "Language::Farnsworth::Value::Pari")
		{
			my $ret = $self->getdimen()->compare($comparator->getdimen());
			return 1 if ($comparator->isvalueone()); #read the sentinal value
			return $ret;
		}
		else
		{
			return 1; #for now?
		}
	}
}

sub clone
{
	my $self = shift;
	my $class = ref($self);

	my $newself = {};
	$newself->{$_} = $self->{$_} for (keys %$self);

	bless $newself, $class;

    $newself->setref(undef);
	$newself;
}

sub getpari
{
	#error("Attempting to use ");
}

sub getarray
{
}

sub getarrayref
{
}

sub getstring
{
}

1;
