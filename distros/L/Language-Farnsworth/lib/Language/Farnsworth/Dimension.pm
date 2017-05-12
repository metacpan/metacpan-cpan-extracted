package Language::Farnsworth::Dimension;

use strict;
use warnings;

use Data::Dumper;
use Language::Farnsworth::Output;

use List::MoreUtils qw(uniq);

sub new
{
	my $class = shift;
    my $dimers = shift;
	my $scope = shift;

	my $dims;
	{
		if (defined($dimers))
		{
			$dims = +{%{$dimers}}; #make a shallow copy, i don't feel like debugging this later if somehow i ended up with two objects blessing the same hashref
		}
		else
		{
			#none, use empty hash
			$dims = {};
		}
	}

	my $self = {dimen =>$dims, scope => $scope}; #so i don't have to rewrite a lot of code... NTS: this should probably go away later

	bless $self;
}

sub compare
{
  my $self = shift;
  my $target = shift;

#  print "DIMENWARN: ".join("::", caller())."\n";
#  print Dumper($self, $target);

  if ((!ref($target)) && keys %{$self->{dimen}} == 0)
  {
	  return 1;
  }

  if (keys %{$target->{dimen}} == keys %{$self->{dimen}}) #check lengths of keys
  {
     my $v = 1;
     for my $k (keys %{$self->{dimen}})
     {
       return 0 if (!exists($target->{dimen}{$k})); #optimization fixes bug!
       $v = 0 if (($self->{dimen}{$k} != $target->{dimen}{$k}) && ($k ne "string"));
     }

     if ($v) #also check if there are no dimensions
     {
        return 1;
     }
  }

  return 0;
}

sub invert
{
	my $self = shift;
	#i CAN'T modify myself in this!
	my $atom = $self->new($self->{dimen});

	for (keys %{$atom->{dimen}})
	{
		#turn all positives to negatives and vice versa
		$atom->{dimen}{$_} = -$atom->{dimen}{$_};
	}

	return $atom->prune();
}

sub merge
{
	my $self = shift;
	#i CAN'T modify myself in this!
	my $atom = Language::Farnsworth::Dimension->new($self->{dimen});
	
	my $partner = shift;
	my $pd = {};

	if (ref($partner) eq "Language::Farnsworth::Dimension")
	{
		$pd = $partner->{dimen};
	}

    for (uniq (keys %{$atom->{dimen}}, keys %{$pd}))
	{
		no warnings 'uninitialized';
		$atom->{dimen}{$_} += $partner->{dimen}{$_};
	}

	return $atom->prune();
}

sub mult
{
	my $self = shift;
	#i CAN'T modify myself in this!
	my $atom = Language::Farnsworth::Dimension->new($self->{dimen});
	
	my $value = shift;

	for (keys %{$atom->{dimen}})
	{
		no warnings 'uninitialized';
		$atom->{dimen}{$_} *= $value; #this might turn them into Math::PARI objects? does it matter?
	}

	return $atom->prune();
}


sub prune
{
	my $self = shift;
	
	for (keys %{$self->{dimen}})
	{
		if (!$self->{dimen}{$_})
		{
			delete $self->{dimen}{$_};
		}
	}

	return $self;
}

sub Dump
{
	my $self = shift;
	my $scope = shift;
	my @returns;
	
		#added a sort so its stable, i'll need this...
		for my $d (sort {$a cmp $b} keys %{$self->{dimen}})
		{
			my $exp = "";
			#print Dumper($dimen->{dimen}, $exp);
			my $dv = "".($self->{dimen}{$d});
			my $realdv = "".(0.0+$self->{dimen}{$d}); #use this for comparing below, that way i can keep rational exponents when possible

			$dv =~ s/([.]\d+?)0+$/$1/;
			$dv =~ s/E/e/; #make floating points clearer

			$exp = "^".($dv =~ /^[\d\.]+$/? $dv :"(".$dv.")") unless ($realdv eq "1");
			
			push @returns, $scope->{units}->getdimen($d).$exp;
		}
		
		if (my $combo = $self->findcombo($scope)) #this should be a method?
		{
			@returns = $combo;
		}
		
		my $return =join " ", @returns;
		
		$return = "($return)"if ($return =~ /\s/);
		
		$return = "dimensionless value" if ($return =~ /^\s*$/); 
		 
		return $return; 
}

sub findcombo
{
	my $self = shift;
	my $scope = shift;

	#HACK: THIS NEEDS TO MOVE SOMEWHERE MORE APPROPRIATE AS I DEPRECIATE THE OUTPUT CLASS!
    my $combos = \%Language::Farnsworth::Output::combos;

	for my $combo (keys %$combos)
	{
		#print "TRY COMBO: $combo\n";
		my $cv = $combos->{$combo}; #grab the value
		return $combo if ($self->compare($cv->getdimen()));
	}

	return undef; #none found
}

1;

# vim: filetype=perl
