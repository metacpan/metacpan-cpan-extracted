package Language::Farnsworth::Output;

use strict;
use warnings;

use overload '""' => \&tostring, "eq" => \&eq;


use Data::Dumper;
use Language::Farnsworth::Error;

our %combos;
our %displays;

#these primarily are used for display purposes
sub addcombo
{
	my $name = shift;
	my $value = shift; #this is a valueless list of dimensions

	$combos{$name} = $value;
}

#this returns the name of the combo that matches the current dimensions of a Language::Farnsworth::Value::Pari
sub findcombo
{
	my $self = shift;
	my $value = shift;

	for my $combo (keys %combos)
	{
		#print "TRY COMBO: $combo\n";
		my $cv = $combos{$combo}; #grab the value
		return $combo if ($value->getdimen()->compare($cv->getdimen()));
	}

	return undef; #none found
}

#this sets a display for a combo first, then for a dimension
sub setdisplay
{
	my $self = shift;
	my $name = shift; #this only works on things created by =!= or |||, i might try to extend that later but i don't think i need to, since you can just create a name with ||| when you need it
	my $branch = shift;

	#I SHOULD CHECK FOR THE NAME!!!!!
	#print Dumper($name, $branch);

	if (exists($combos{$name}))
	{
		$displays{$name} = $branch;
	}
	else
	{
		error "No such dimension/combination as $name\n";
	}
}

sub getdisplay
{
	my $self = shift;
	my $name = shift;

	debug 2, "GETDISP: ",$name, "\n";

	if (defined($name) && exists($displays{$name}))
	{
		debug 4, "GETDISP:", (Dumper($displays{$name})), "\n";
		if (ref($displays{$name}) eq "Fetch" && $displays{$name}[0] eq "undef")
		{
			return undef;
		}	

		return $displays{$name}; #guess i'll just do the rest in there?
	}

	return undef;
}

sub new
{
  shift; #remove the class
  my $self = {};
  $self->{units} = shift;
  $self->{obj} = shift;
  $self->{eval} = shift;

  #warn Dumper($self->{obj});

  #when we get an error, pass it through, HACK, this is a HACK! the code needs to handle these directly but i need to rewrite the code for output anyway
  error $self->{obj} if ref($self->{obj}) =~ /Language::Farnsworth::Error/;
  
  #warn Dumper($self->{obj});
  error "Attempting to make output class of non Language::Farnsworth::Value" unless ref($self->{obj}) =~ /Language::Farnsworth::Value/;
  error "Forgot to add \$eval to params!" unless ref($self->{eval}) eq "Language::Farnsworth::Evaluate";

 
  bless $self;
}

sub tostring
{
  my $self = shift;
  my $value = $self->{obj};

  return $self->getoutstring($value);
}

sub eq
{
  my $one = shift;
  my $two = shift;
  my $order = shift;

  my $string = $one->tostring();
  return $string eq $two;
}

#this takes a set of dimensions and returns what to display
sub getoutstring
{
	my $self = shift; #i'll implement this later too
#	my $dimen = shift; #i take a Language::Farnsworth::Dimension object!
    my $value = shift; #the value so we can stringify it

    my @returns;

	if (defined($value->{outmagic}))
	{
		if (ref($value->{outmagic}[1]) eq "Language::Farnsworth::Value::String")
		{
			#ok we were given a string!
			my $number = $value->{outmagic}[0];
			my $string = $value->{outmagic}[1];
			return $self->getoutstring($number) . " ".$string->getstring();
		}
		elsif (exists($value->{outmagic}[0]) && (ref($value->{outmagic}[0]) ne "Language::Farnsworth::Value::Array"))
		{
			#ok we were given a value without the string
			my $number = $value->{outmagic}[0];
			return $self->getoutstring($number);
		}
		else
		{
			print Dumper($value);
			error "Unhandled output magic, this IS A BUG!";
		}
	}
	elsif (ref($value) eq "Language::Farnsworth::Value::Boolean")
	{
		return $value ? "True" : "False"
		#these should do something!
	}
	elsif (ref($value) eq "Language::Farnsworth::Value::String")
	{
		#I NEED FUNCTIONS TO HANDLE ESCAPING AND UNESCAPING!!!!
		my $val = $value->getstring();
		$val =~ s/\\/\\\\/g; 
		$val =~ s/"/\\"/g;
		return '"'.$val.'"';
	}
	elsif (ref($value) eq "Language::Farnsworth::Value::Array")
	{
		my @array; #this will be used to build the output
		for my $v ($value->getarray())
		{
			#print Dumper($v);
			push @array, $self->getoutstring($v);
		}

		return '['.(join ' , ', @array).']';
	}
	elsif (ref($value) eq "Language::Farnsworth::Value::Date")
	{
		return $value->getdate()->strftime("# %F %H:%M:%S.%3N %Z #");#UnixDate($value->{pari}, "# %C #"); #output in ISO format for now
	}
	elsif (ref($value) eq "Language::Farnsworth::Value::Lambda")
	{
		return $value->tostring();
	}
	elsif (ref($value) eq "Language::Farnsworth::Value::Undef")
	{
		return "undef";
	}
	elsif (ref($value) eq "HASH")
	{
		warn "RED ALERT!!!! WE've got a BAD CASE HERE. We've got an UNBLESSED HASH";
		warn Dumper($value);

		return "undef";
	}
	elsif (my $disp = $self->getdisplay($self->findcombo($value)))
	{
		#$disp should now contain the branches to be used on the RIGHT side of the ->
		#wtf do i put on the left? i'm going to send over the Language::Farnsworth::Value, this generates a warning but i can remove that after i decide that its correct

		print "SUPERDISPLAY:\n";
		my $branch = bless [$value, $disp], 'Trans';
		#print Dumper($branch);
		my $newvalue = eval {$self->{eval}->evalbranch($branch);};
		return $self->getoutstring($newvalue);
	}
	else
	{
		my $dimen = $value->getdimen();
		#added a sort so its stable, i'll need this...
		for my $d (sort {$a cmp $b} keys %{$dimen->{dimen}})
		{
			my $exp = "";
			#print Dumper($dimen->{dimen}, $exp);
			my $dv = "".($dimen->{dimen}{$d});
			my $realdv = "".(0.0+$dimen->{dimen}{$d}); #use this for comparing below, that way i can keep rational exponents when possible

			$dv =~ s/([.]\d+?)0+$/$1/;
			$dv =~ s/E/e/; #make floating points clearer

			$exp = "^".($dv =~ /^[\d\.]+$/? $dv :"(".$dv.")") unless ($realdv eq "1");
			
			push @returns, $self->{units}->getdimen($d).$exp;
		}
		
		if (my $combo = $self->findcombo($value)) #this should be a method?
		{
			push @returns, "/* $combo */";
		}


		my $prec = Math::Pari::setprecision();
		Math::Pari::setprecision(15); #set it to 15?
		my $pv = "".(Math::Pari::pari_print($value->getpari()));
		my $parenflag = $pv =~ /^[\d\.e]+$/i;
		my $rational = $pv =~ m|/|;

		$pv =~ s/E/e/; #make floating points clearer

		if ($pv =~ m|/|) #check for rationality
		{
			my $nv = "".Math::Pari::pari_print($value->getpari() * 1.0); #attempt to force a floating value
			$nv =~ s/([.]\d+?)0+$/$1/ ;
			$pv .= "  /* apx ($nv) */";
		}

		$pv = ($parenflag? $pv :"(".$pv.")"); #check if its a simple value, or complex, if it is complex, add parens
		$pv =~ s/([.]\d+?)0+$/$1/ ;

		Math::Pari::setprecision($prec); #restore it before calcs
		return $pv." ".join " ", @returns;
	}
}

sub makevalue
{
	error "MAKEVALUE WAS CALLED!\n";
}

1;
__END__

=encoding utf8

=head1 NAME

Language::Farnsworth::Output - Wrapper class for making output simpler

=head1 DESCRIPTION

This class is just a wrapper for some code to convert the data into a format more usable for perl.  Eventually all the code will be spun off into the Language::Farnsworth::Value subclasses so that the code can be used for serialization and loading.

=head1 SYNOPSIS

  use Language::Farnsworth;
  
  my $hubert = Language::Farnsworth->new();
  
  my $result = $hubert->runString("10 km -> miles"); # $result here is an object of Language::Farnsworth::Output 
  
  my $result = $hubert->runFile("file.frns");
  
  print $result;

=head1 METHODS

This has only one method that a user should be aware of, C<tostring>; you can call this directly on the object, e.g. $result->tostring() 

=head1 AUTHOR

Ryan Voots E<lt>simcop@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ryan Voots

This library is free software; It is licensed exclusively under the Artistic License version 2.0 only.

=cut
