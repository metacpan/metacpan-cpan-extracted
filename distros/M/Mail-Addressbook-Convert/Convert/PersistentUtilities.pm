=head1 NAME

Mail::Addressbook::Convert::PersistentUtilities 

=head1 SYNOPSIS

This module is not designed to be used by the user.

It provides a method with values that persist between calls.

=head1 REQUIRES

Perl, version 5.001 or higher

Carp

=head1 DESCRIPTION


=head1 DEFINITIONS 
 
			

=head1 METHODS

=head2 new

no arguments needed.

=head2 makeAliasUnique

Input

	Parameter 1 :  A email alias ( string )
	Parameter 2  boolean.  if true underscores are allowed in aliases
			if false, they are eliminated
			
Returns

	An alias, which is unique among all the previous aliases called during the life of
		the object.




=head1 LIMITATIONS



=head1 REFERENCES

		

=head1  HISTORY

This code is derived from the code used on www.interguru.com/mailconv.htm .  The site 
has been up since 1996 ( but ldif was only included on 1997, when Netscape 3  started
using it.)  The site gets about 8000 unique visitors a month, many of whom make addressbook
conversions. The code has been well tested.

=head1 FUTURE DIRECTIONS




=head1 BUGS

=head1 CHANGES

Original Version 2001-Sept-09
                  
=head1 COPYRIGHT

Copyright (c) 2001 Joe Davidson. All rights reserved.
This program is free software; you can redistribute it 
and/or modify it under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html). or the
GPL copyleft license ( http://www.gnu.org/copyleft/gpl.html) 


=head1 AUTHOR

Mail::Addressbook::Convert was written by Joe Davidson  <jdavidson@interguru.com> in 2001.

=cut



package Mail::Addressbook::Convert::PersistentUtilities; 

# This class contain methods which need persistent values.

use Carp;
use Mail::Addressbook::Convert::Utilities;

use strict;

############################

sub new
{
	my $self=shift;
	my %usedAlias;
	return bless 
	{ ADDNUM=> 100,
	  USEDALIAS =>\%usedAlias
	}, $self;
}


##########################################################################3
sub makeAliasUnique
	{
	
	
	my ($self,$inputAlias,$allowUnderscores) = @_;
	
	my $alias = &cleanalias($inputAlias,$allowUnderscores);
	if (substr ($alias, -1,1) =~ /\d/) # does alias end in a number
		{
		$alias = $alias."a";
		}
	if ($self->{USEDALIAS}{$alias})
		{
		my $addNum = $self->{ADDNUM};
		$alias = $alias.$addNum;
		$self->{ADDNUM}++;
		}
	$self->{USEDALIAS}{$alias} = 1;
	return $alias;
	}

##########################################################################3

return 1;