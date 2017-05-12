=head1 NAME

Mail::Addressbook::Convert::Pine -  convert to and from Pine formatted addressbooks

=head1 SYNOPSIS

use strict;

use Mail::Addressbook::Convert::Pine;

my $pine = new Mail::Addressbook::Convert::Pine();

my $PineInFile  ="pineSample.txt";  # name of the file containing the Ldif data

# Convert Pine to Standard Intermediate format

# see documentation for details on format.

my $raIntermediate = $pine->scan(\$PineInFile);  

# This will also work

#my @PineInArray  = @arrayContainingThePineData;

#my $raIntermediate = $pine->scan(\@PineInArray);  	


# Convert back to Pine

my $raPineOut = $pine->output($raIntermediate);

print join "", @$raIntermediate;  

print "\n\n\n\n";

print join "", @$raPineOut;

=head1 REQUIRES

Perl, version 5.001 or higher

Carp

=head1 DESCRIPTION

This module is meant to be used as part of the Mail::Addressbook::Convert distribution.

It can convert a Pine addressbook to a Standard Intermediate format(STF) and a STF to Pine
As part of the larger distribution, it will allow conversion between Pine and many other 
formats.

To use to convert between Pine and Eudora as an example, you would do the following 

use Mail::Addressbook::Convert::Pine;

use Mail::Addressbook::Convert::Eudora;

my $Pine = new Mail::Addressbook::Convert::Pine();

my $Eudora = new Mail::Addressbook::Convert::Eudora();

my $PineInFile  ="pineSample.txt";  # name of the file containing the Pine data

my $raIntermediate = $Pine->scan(\$PineInFile); 

my $raEudora = $Eudora->output($raIntermediate);  # reference to an array containing a Eudora addressbook


=head1 DEFINITIONS 
 
Standard Intermediate Format(STF) :  

			The addressbook format that is used as an intermediate
			between conversions.  It is rfc822 compliant and can
			be used directly as a Eudora addressbook.  Do not use
			a Eudora addressbook as an STF. Some versions of 
			Eudora use a format, that while RFC822 compliant, will
			not work as an STF. Run the Eudora addressbook
			through $Eudora->scan()
			
Pine addressbook:
			  A Pine addressbook. 
			  This module works on pine 
			 .
			  You can find information on pine by searching
			  for B<pine> on google.com or going to http://www.washington.edu/pine/.
			

=head1 METHODS

=head2 new

no arguments needed.

=head2 scan

Input : a reference to an array containing a pine file or a reference to a scalar containing
	the file name with the pine data.
Returns:  a reference to a STF ( see above).

=head2 output

Input:  a reference to a STF ( see above).
Returns : a reference to an array containing a pine file.


=head1 LIMITATIONS

This only converts email address, aliases, and mailing lists.  Phone numbers,
postal addresses and other such data are not converted.



=head1 REFERENCES

You can find information on Pine at http://www.washington.edu/pine/
		

=head1  HISTORY

This code is derived from the code used on www.interguru.com/mailconv.htm .  The site 
has been up since 1996  The site gets about 8000 unique visitors a month, many of whom make addressbook
conversions. The code has been well tested.

=head1 FUTURE DIRECTIONS



=head1 SEE ALSO

http://www.washington.edu/pine/


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

#------------------------------------------------------------------------------

use strict;


package Mail::Addressbook::Convert::Pine;

use Mail::Addressbook::Convert::Utilities;
use  5.001;

sub new {
	bless {},shift;
}

######################################################################


sub scan {

local $^W;  #turn off warnings.  This code was written without the -w flag, and is too difficult to patch it in.
	#
my $Pine = shift;
my $inputParm = shift; # reference to input ldif data as an array or reference to a 
			# scalar containing the name of a file containing the Pine addresses.

my $raPineArray= getInput($inputParm);
my ($alias,$name,$address,$fcc,$comment);
my ($lastname , @names, @outputFile);

my @pineArray = @$raPineArray;

foreach my $k (0..$#pineArray)
	{
	next if $pineArray[$k] =~/^#/;
	 undef $comment;
         ($alias,$name,$address,$fcc,$comment) = split(/\t/, $pineArray[$k]);
	 if ($address =~ /</)
		{
		(my $junk,$address) = split("<",$address);
		$address =~ s/>//;
		}
#   Thanks to Erich Schraer <erich@wubiosas.wustl.edu>
#   for suggestions to improve processing of names     
   	 if ($name =~ /,/) 
		 { # If name doesn't have a comma, leave alone
	       	 @names = split(/,/, $name); # Split on the comma
              	$lastname = shift(@names);
              	$name = join(" ",@names,$lastname);
	        $name =~ s/^ //; # get rid of space at beginning.
      	 	}
	 if ($address !~ /\,/)
		{
		if ($name)
			{
		 	push (@outputFile, "alias ".$alias.
			" \"".$name."\"<".$address. "\>\n") ;
			}
		else
			{
		 	push (@outputFile, "alias ".$alias.
			" ".$address. "\n") ;
			}
		}
	 else
		{
		$address =~s/\(|\)//g;
	 	push (@outputFile, "alias ".$alias." ".$address. "\n") ;
		}
	 if ($comment)
		{
		push (@outputFile, "note  ".$alias." ".$comment."\n");
		}

	}
foreach (@outputFile)
	{
	 s/\r|\015|\013//;
	 }

return \@outputFile;
}


###########################   sub output #######################
sub output

{

local $^W;  #turn off warnings.  This code was written without the -w flag, and is too difficult to patch it in.
my $Pine = shift;
my $raInputArray = shift; # reference to input Input data as an array

my @inputArray = @$raInputArray;

my (@outputFile, @indivalias, @middle,@indivaddr, %note, $i, $j, $k );
my ( @hold1, @lines, $alias, $rest, $commas, $name, @groupalias );
my (@groupaddr, $address);

my $kk = 0;
foreach $i (0..$#inputArray  )
	{
	$inputArray[$i] =~ s/\r//g;
	if ($inputArray[$i] =~/^note/)
		{
		@hold1 = split (" ",$inputArray[$i],3);
		$note{"$hold1[1]"} = $hold1[2];
		$note{"$hold1[1]"} =~ s/\n|\r//g;
		}
	else
		{
		$lines[$kk] = $inputArray[$i];
		$lines[$kk] =~ s/alias //g;
		$kk++;
		}
	}

foreach $i (0..$#lines  )
	{
	if ($lines[$i] =~/^\"/)   #alais starts with quote.
		{
		$lines[$i]=substr($lines[$i],1) ; # get rid of first quote.
		$lines[$i] =~ /(.+[^\"])\"(.*)/;
		$alias = $1;
		$rest = $2;
		$alias =~ s/\s//g; # get rid of spaces
		}
		else
		{
		$lines[$i] =~ /(\S+)(.+)/;# match the alias and the rest
		$alias = $1;
		$rest = $2;
		}
	my $commas_outside_quotes = &commas_outside_quotes($rest);
	if ($commas_outside_quotes)
		 # There are commas not enclosed in quotes
		{ #we have a group list.
		$groupalias[$j] = $alias;
		$groupaddr[$j] = $rest;
                $groupaddr[$j] =~ s/\s*//g; # get rid of all spaces  
		$j++
		}
	else # an individual address
		{
		$indivalias[$k] = $alias;
		$middle[$k] = "\t\t";
		if ( $rest =~ /</) # compound address
			{
			($name,$address) = split(/</,$rest);
			$address  =~s/>//;
			$name =~ s/\"//g;
			$name =~ s/\'//g;
			$name .= ",";
			if ($name =~/(\S+)\s+(\S+)/)# name in form of
				# two words (I assume firstname, lastname )
				{
				$name = $2.",".$1;
				}
			$middle[$k] = "\t".$name."\t";
			$middle[$k] =~ s/,,/,/;
			$rest = $address;
			}
		$indivaddr[$k] = $rest;
		$k++
		}
	}

foreach $i (0..$k-1)
	{ 
	push (@outputFile, $indivalias[$i]."$middle[$i]".$indivaddr[$i]
	."\t\t".$note{"$indivalias[$i]"}."\n");
	}
foreach $i (0..$j -1)
	{
	push( @outputFile, $groupalias[$i]."\t".$groupalias[$i]
	."\t(".$groupaddr[$i].")\t\t".$note{"$groupalias[$i]"}."\n");
	}
	


return \@outputFile;
}



###########################  end sub output #######################
1;