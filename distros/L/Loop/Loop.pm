package Loop;

require 5.005_62;
use strict;
use warnings;
use Carp;

our $VERSION = '1.00';

##############################################################################
sub Array(\@&)
##############################################################################
{
	my $arrayref = shift(@_);
	my $callback = shift(@_);

	my $index;
	my @return;

	my $wantarray = (defined(wantarray()) and wantarray()) ? 1 : 0;
	#print "wantarray is $wantarray \n";

	ARRAY_LABEL:for(my $index=0; $index<scalar(@$arrayref); $index++)
		{
		my $control=undef;		
		my @temp;
		if($wantarray)
			{
			@temp = 
			$callback->($index,$arrayref->[$index],$control);
			}
		else
			{
			$callback->($index,$arrayref->[$index],$control);
			}

		if(defined($control))
			{ 
			if($control eq 'last')
				{
				last ARRAY_LABEL;
				}
			elsif($control eq 'redo')
				{
				redo ARRAY_LABEL;
				}
			else
				{
				croak "bad control value '$control'";
				}
			}
		else
			{
			push(@return,@temp);
			}
		}

	if($wantarray)
		{ return (@return); }
	else
		{return;}
}



##############################################################################
sub Hash(\%&)
##############################################################################
{
	my $hashref = shift(@_);
	my $callback = shift(@_);

	my $arrayref = [keys(%$hashref)];
	my $index;
	my @return;

	my $wantarray = (defined(wantarray()) and wantarray()) ? 1 : 0;
	#print "wantarray is $wantarray \n";

	HASH_LABEL:for(my $index=0; $index<scalar(@$arrayref); $index++)
		{
		my $control=undef;		
		my @temp;
		if($wantarray)
			{
			@temp = $callback->
				(
				$arrayref->[$index],
				$hashref->{$arrayref->[$index]}, 
				$index,
				$control
				);
			}
		else
			{
			$callback->
				(
				$arrayref->[$index], 
				$hashref->{$arrayref->[$index]}, 
				$index,
				$control
				);
			}

		if(defined($control))
			{ 
			if($control eq 'last')
				{
				last HASH_LABEL;
				}
			elsif($control eq 'redo')
				{
				redo HASH_LABEL;
				}
			else
				{
				croak "bad control value '$control'";
				}
			}
		else
			{
			push(@return,@temp);
			}
		}

	if($wantarray)
		{ return (@return); }
	else
		{return;}
}



##############################################################################
sub File($&)
##############################################################################
{
	my $filename = shift(@_);
	my $callback = shift(@_);

	my @return;

	my $wantarray = (defined(wantarray()) and wantarray()) ? 1 : 0;
	#print "wantarray is $wantarray \n";

	open ( my $filehandle, $filename ) or 
		croak "Error: cannot open $filename";

	my $linenumber=0;
	FILE_LABEL:while(<$filehandle>)
		{
		$linenumber++;
		my $control=undef;		
		my @temp;

		if($wantarray)
			{
			@temp = $callback->($linenumber,$_, $control);
			}
		else
			{
			$callback->($linenumber,$_, $control);
			}

		if(defined($control))
			{ 
			if($control eq 'last')
				{
				last FILE_LABEL;
				}
			elsif($control eq 'redo')
				{
				redo FILE_LABEL;
				}
			else
				{
				croak "bad control value '$control'";
				}
			}
		else
			{
			push(@return,@temp);
			}
		}

	close($filehandle) or croak "Error: cannot close $filename";
	if($wantarray)
		{ return (@return); }
	else
		{return;}	
}


1;
__END__

=head1 NAME

Loop -  Smart, Simple, Recursive Iterators for Perl programming.

=head1 SYNOPSIS

  use Loop;
  
  Loop::Array @array, sub
	{
	my ($index,$value)=@_;
	print "at index '$index', value='$value'\n";
	}

=head1 ABSTRACT

This module is intended to implement simple iterators on perl variables 
with little code required of the programmer using them.

Some additional advantages over standard perl iterators:

Array iterators give access to the current index within the array.
Hash iterators can be nested upon the same hash without conflicts.
File iterators allow simple file munging in a few lines of code.

=head1 DESCRIPTION

=head2 Loop on an Array

  # loop on an array, at index 3, change the value in the array to "three"
  my @array = qw (alpha bravo charlie delta echo);

  Loop::Array @array, sub
	{
	my($index,$val)=@_;
	if($index == 3)
		{
		# modify the element in the original array
		# note that when you want to change the original array,
		# you must assign to the parameter array @_
		$_[1] = 'three'; 
		}
	}

=head2 Loop on a Hash

  # loop on a hash, perform nested iteration on the same hash.

  my %hash = 
	(
	blue => 'moon',
	green => 'egg',
	red => 'baron',
	);
 
  Loop::Hash (%hash, sub
	{
	my($key1,$val1)=@_;

	print "checking key1 $key1, val1 $val1 for collisions \n";

	Loop::Hash (%hash, sub
		{
		my($key2,$val2)=@_;

		print "\tchecking key2 $key2, val2 $val2 for collisions \n";

		print "\t $val2 is not $key1\n"
			unless($key1 eq $key2);
		return;
		});
	});

=head2 Loop on a File

  # loop through a file, read it line by line, and grep for a string.
  Loop::File "tfile.pl", sub
	{
	my($linenum,$linestr)=@_;

	if($linestr =~ /search/)
		{
		print "found at line $linenum: $linestr";
		}
	};


=head2 EXPORT

none

=head1 SEE ALSO


=head1 AUTHOR

Greg London, http://www.greglondon.com

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Greg London, All Rights Reserved

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

