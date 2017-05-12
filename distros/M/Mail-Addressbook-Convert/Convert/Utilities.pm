=head1 NAME

Mail::Addressbook::Convert::Utilities 

=head1 SYNOPSIS

This module is not designed to be used by the user.

It provides utility methods with for Mail::Addressbook::Convert

=head1 REQUIRES

Perl, version 5.001 or higher

Carp

=head1 DESCRIPTION


=head1 DEFINITIONS 
 
			

=head1 METHODS


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

package Mail::Addressbook::Convert::Utilities; 

use Carp;

use Exporter ();
@ISA       = qw(Exporter);
@EXPORT    = qw( cleanalias commas_outside_quotes getInput isValidInternetAddress  );

use strict;
use vars qw(%usedAlias  );




##########################################################################3


sub cleanalias  
	{
	my($a2,$allowUnderscores)= @_;
	$a2 =~ tr/A-Z0-9/a-z0-9/;  #make sure alias is lowercase
	if ($allowUnderscores)
		{
		$a2 =~ tr/a-z0-9_//cd;  # underscores, letters and numbers only
		}
	else	
		{
		$a2 =~ tr/a-z0-9//cd;  	# letters and numbers only
		}
	return($a2);
	}
##########################################################################3

sub commas_outside_quotes
	{
	my($test_string) = $_[0];
	my($inside_quote,$num_chars,$s);
	$inside_quote = 0; #false;
	$num_chars = length($test_string);
	foreach $s (0..$num_chars)
		{
		my($char) = substr($test_string,$s,1);
		if ($char eq "\"")
				{$inside_quote =!$inside_quote;}
		if ($char eq "\," && !$inside_quote) 
			{
			return 1;  # we found a comma outside a quote
			}
		}
	return 0;  # no commas outside quotes.
	}

##########################################################################

sub getInput {

my $parm = shift;

	if ((ref $parm) =~ /ARRAY/) 
	{
		return $parm;
	}
	elsif ( (ref $parm)  =~ /SCALAR/)
	{
		local *FH;
		my $fileName = $$parm;
		open 	(FH, "<$fileName") or confess "Utilities.pm getInput: could not open $fileName: $!\n";
		my @ary = <FH>;
		close FH;
		return \@ary;
		
	}
	
	else 
	{
		croak " Utilities.pm getInput: Input parameter must be a reference to an array or scalar\n";
	}
	
}

########################  begin sub isValidInternetAddress ######################

sub isValidInternetAddress
{


my $member = $_[0];
return $member =~m/\s*^<?[^@<>]+@[^@.<>]+(\.[^@.<>]+)+>?\s*$/;

if (0)
{
unless ($member =~ /([\w\-\+\.\_]+)@([\w\-\+\.]+)/)
	{
	return 0;
	}
my $hst = $2;
my @domains = split(/\./,$hst );
if ($#domains < 1)
	{
	return 0;
	}
my $topLevelDomain = $domains[$#domains];
my $lengthTopLevelDomain = length($topLevelDomain );
if ($lengthTopLevelDomain > 3 or $lengthTopLevelDomain <2)
	{
	return 0;
	}
return 1;
} end of (0)	
}
########################  end sub isValidInternetAddress ######################


1;