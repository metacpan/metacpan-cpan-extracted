=head1 NAME

Mail::Addressbook::Convert::Pegasus -  convert to and from Pegasus  addressbooks

=head1 SYNOPSIS

use strict;

use Mail::Addressbook::Convert::Pegasus;

my $Pegasus = new Mail::Addressbook::Convert::Pegasus();

my $PegasusMain1File  ="PegasusMainSample.txt";  # name of a file containing the Pegasus  Addressbook data

my $PegasusMain2File  ="PegasusMainSample.txt";  # name of a file containing the Pegasus  Addressbook data

my $PegasusDist1InFile  ="PegasusDist1Sample.txt";  # name of a the file containing the a distribution list data

my $PegasusDist2InFile  ="PegasusDist2Sample.txt";  # name of a the file containing the a distribution list data


# Convert Pegasus to Standard Intermediate format

# see documentation for details on format.

my $raIntermediate = $Pegasus->scan([\$PegasusMain1File ,\PegasusMain2File],  
		[\$PegasusDist1InFile, \$PegasusDist2InFile] );  


# This will also work

#my @PegasusMain1Array  = @arrayContainingThePegasusMainAddressesData;
#my @PegasusMain2Array  = @arrayContainingThePegasusMainAddressesData;
#my @PegasusDist1Array  = @arrayContainingAPegasusDistribution1ListData;
#my @PegasusDist2Array  = @arrayContainingAPegasusDistribution2ListData;
#my @DistNames = qw(Dist1, Dist2);  

# The third parameter contains the names of the distribution lists that are in the second parameter.
# This parameter is only needed is the lists specified as references to arrays.
# if they are specified as files, the third parameter is not necessary.



#my $raIntermediate = $Pegasus->scan([\@PegasusMain1Array,\@PegasusMain2Array],
#	 [\@PegasusDist1Array , \@PegasusDist2Array],\@DistNames   );  	

#( You may put as many distribution lists  arrays in the parameters as you wish. )


# Convert back to Pegaus

my @PegaOut = $Pegasus->output($raIntermediate);

#See below for explaination of the output array, and sample code.


=head1 REQUIRES

Perl, version 5.001 or higher

Carp
File::Basename;



=head1 DESCRIPTION

This module is meant to be used as part of the Mail::Addressbook::Convert distribution.

It can convert a Pegasus addressbook to a Standard Intermediate format(STF) and a STF to Ldif
As part of the larger distribution, it will allow conversion between Pegasus and many other 
formats.

To use to convert between Pegaus and Eudora as an example, you would do the following 

use Mail::Addressbook::Convert::Pegasus;

use Mail::Addressbook::Convert::Eudora;

my $Pegasus = new Mail::Addressbook::Convert::Pegasus();

my $Eudora = new Mail::Addressbook::Convert::Eudora();

# The main addressbooks must be exported from Pegasus in tagged text format.
my $PegasusAddr1InFile  ="PegasusAddr1Sample.txt";  # name of a file containing  Pegasus  Tagged text Addressbook data

my $PegasusAddr2InFile  ="PegasusAddr2Sample.txt";  # name of a file containing Pegasus  Tagged text Addressbook data

my $PegasusDist1InFile  ="PegasusDist1Sample.txt";  # name of the file containing the a distribution list data

my $PegasusDist2InFile  ="PegasusDist2Sample.txt";  # name of the file containing the a distribution list data

my $raIntermediate = $Pegasus->scan( [\$PegasusAddr1InFile, \$PegasusAddr2InFile],  
	[\$PegasusDist1InFile, \$PegasusDist2InFile ]);  
# $raIntermediate is the intermediate (STF) format file described below.	


my $raEudora = $Eudora->output($raIntermediate);  # reference to an array containing a Eudora addressbook

##------------------------------------------------------------------------

The following code  will convert from  STF intermediate format and write out Pegasus files


#  $raIntermediate is a reference to an intermediate STF file.
my @raPegasus = $Pegasus->output($raIntermediate); 


my @mainAddressbook = @{$raPegasus[0]};
	# This array is in tagged  text format and must be imported into Pegasus


open FH , ">PegasusMainAddressBook" or die "Cannot open PegasusMainAddressBook for writing $!";
	# This file is in tagged text format and must be imported into Pegasus
foreach (@mainAddressbook)
{
	print FH $_;
}

close FH;

my @distListArrayRefs = @{$raPegasus[1]};
my $numberOfDistLists = @distListArrayRefs; # an array called in scalar context returns the number
						#of elements.
my @distListArrayNames = @{$raPegasus[2]};

foreach my $i (0..$numberOfDistLists-1)
{
	my $DistListName = $distListArrayNames[$i];
	my @DistList = @{$distListArrayRefs[$i]};
	open  FH , ">$DistListName" or die "Cannot open $DistListName $!";
		# Thes files are distribution lists and can be used directly, no conversion required
	foreach (@DistList)
	{
		print FH $_;
	}
	
	close FH;

	
}



=head1 DEFINITIONS 
 
Standard Intermediate Format(STF) :  

			The addressbook format that is used as an intermediate
			between conversions.  It is rfc822 compliant and can
			be used directly as a Eudora addressbook.  Do not use
			a Eudora addressbook as an STF. Some versions of 
			Eudora use a format, that while RFC822 compliant, will
			not work as an STF. Run the Eudora addressbook
			through $Eudora->scan()
			
Pegasus addressbook:
			  Pegausus stores its addresses in multiple files.  There are one or
			  more addressbooks, and zero or more distribution lists.  Each distribution
			  list is in a separate file.
			  
			  The addressbooks cannot be used directly, but must be exported.  Open the
			  addressbook, then use the Addressbook Menu : "Export to Tagged Text File".  The 
			  exported file(s) will be used as imput.
			  
			  The distribution lists are kept in files with a ".pml" extension.  They
			  are used as input directly -- no exporting is necessary. Pegasus does not check
			  for circular references until the distribution list is used.  Be sure that you have 
			  either used the list, or you have checked that there are no circular references.
			

=head1 METHODS

=head2 new

no arguments needed.

=head2 scan

Input  :

Parameter 1;		Required: An anonymous array. Each element of the array is either 
			a reference to an array containing the contents of a tagged text file
			 ( exported from an addressbook -- see above under definitions)  
			or a reference to a scalar containing the file name with the tagged
			text addressbook.  The array must contain at least one element.
			
Parameter 2:		Optional: An anonymous array. Each element of the array is either 
			a reference to an array containing the contents of a distribution list (.pml) 
			file or a reference to a scalar containing the distribution list
			file name.
			
Parameter 3:		Optional: A reference to an array. Each element of the array the name 
			of the corresponding distribution list in Parameter 2.  This parameter is 
			only necessary if the elements of parameter 2 are array references. 
		        When the elements are references to scalers containing
			the name of the distribution list files, the distribution 
			list name is taken from file name. 
			

Returns:  a reference to a STF ( see above).

=head2 output

Input:  a reference to a STF ( see above).
Returns an array of three items

Return 1:		A reference to an array containing the main addressbook in tagged
			text format.  This format can be imported into Pegasus.
			
Return 2:		A reference to an array.  Each element of the array is a 
			a reference an array containing a distrubution list.
			
Return 3:		A reference to an array containing the file names of the 
			distribution lists in return 2.


=head1 LIMITATIONS

This only converts email address, aliases, and mailing lists.  Phone numbers,
postal addresses and other such data are not converted.



=head1 REFERENCES

You can find information on Pegasus at http://www.pmail.com/ 
		

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

#------------------------------------------------------------------------------

use strict;


package Mail::Addressbook::Convert::Pegasus;

use Mail::Addressbook::Convert::PersistentUtilities;
use Mail::Addressbook::Convert::Utilities;
use Carp;
use File::Basename;

use  5.001;
 ###############################################################################
sub new {
	bless {},shift;
}

######################################################################


sub scan {

my $Pegasus = shift;

my $raMainAddressbookArray = shift;

my $raDistributionLists = shift;

my $raDistributionListNames = shift;
			
my $perUtil = new Mail::Addressbook::Convert::PersistentUtilities();

unless ( ref($raMainAddressbookArray) =~ /ARRAY/  and @$raMainAddressbookArray > 0 )
{
	confess "\n You must have an array reference with at least one element as a parameter\n";
}


my %aliasOfName;
my $debug = 0;

my (@outputFile, $key, $h, $alias, $oldAlias, $address, $comment);
my ($finalList, $name, $field, $value, $line, $linenumber, $member, @add);
my (@listAlias, $memberNumber, $thisIsDistributionList, $thisIsAnInternetAddress, @distList);
my ($listFileName, %listAliasByListFileName, @listTitle);

	my $numAddresses= @$raMainAddressbookArray;
	my $numLists= @$raDistributionLists;

	my $i;
	foreach  $i ( @$raMainAddressbookArray)
		{

		@add = @{ getInput($i)};
		foreach $linenumber (0..$#add)
			{
   		  	  $line= $add[$linenumber];
			  $line =~ s/\015//g; 
			  $line =~ s/:\s*/:/;
			  chomp $line;

			($field, $value) = split(/:/,$line);
			$field = "" unless $field;  # to prevent spurious warnings.
			if ($field =~ /--/)
				{
			
				if ($key) {$h = $key;}
				else 	{$h = $name;}
				undef($key);
				$alias = $h;
				$oldAlias = $alias;
				$alias = $perUtil->makeAliasUnique($alias);
				$aliasOfName{$name} = $alias;
				if ($debug) {print "$aliasOfName{$name}, $name\n";}
				push (@outputFile,
 						"alias ".$alias." \"".$name.
						"\"<".$address. ">\n") ;
				if ($comment)
					{
					push (@outputFile, 
					"note  ".$alias. " ".
					$comment."\n");
					}
					undef($comment);

				}
			elsif ($field =~ /Name/)
				{
				$name = $value;
				$name =~ s/\s+$//g;
				}
			elsif ($field =~ /Key/)
				{
				$key = $value;
				}
			elsif ($field =~ /E-mail/)
				{
				$address = $value;
				}
			elsif ($field =~ /Notes/)
				{
				$comment = $value;
				}
			}
		}
		undef(@add);

#    	START DISTRIBUTION LISTS ########################


if (( ref $raDistributionLists) =~ /ARRAY/)
	{	
	#     FIRST LOOP			 #####################	
		my $DistFileIndex = 0;
		#for ($DistFileIndex =1; $DistFileIndex <= $numLists; $DistFileIndex++)
		foreach  my $distFile1 ( @$raDistributionLists)
			{
			$DistFileIndex++;
			
			my $listFileName;
			@add = @{ getInput($distFile1)};
			
			
			if ((ref $distFile1) =~ /SCALAR/)
			{
				# use the name of the distribution list file if it is specified as a file.
				$listFileName = basename($$distFile1);
					# from File::Basename
			
			}
			elsif (ref ($raDistributionListNames) =~ /ARRAY/)
		 	{
				$listFileName = $raDistributionListNames->[$DistFileIndex];
			}
			unless ($listFileName)
			{
				confess "\n Name of distribution list not specified \n";
			}
			
			foreach $linenumber (0..$#add)
				{
	  		  	 $line= $add[$linenumber];
				  $line =~ s/\015//g;
				  chomp $line;
				if ($line =~ /TITLE/) 
					{
					($h,$listTitle[$DistFileIndex]) = split(" ",$line,2);
					$oldAlias = $listTitle[$DistFileIndex];
					$listAlias[$DistFileIndex] = $perUtil->makeAliasUnique($listTitle[$DistFileIndex]);
	
	
					$listFileName = $listFileName;
					$listFileName  =~ tr/a-z/A-Z/;  # change name to uppercase
					$listAliasByListFileName{$listFileName}= 
						$listAlias[$DistFileIndex];
					
					}
				if ($line =~ /^@/)
					{
	
					$line =~ s/\.PML//;
	
					}
				if (!($line =~ /^\\/))
					{
	
					$distList[$DistFileIndex] .= $line."::";
					}
				}
			undef(@add);
			}
	### SECOND LOOP ###########################################
		$DistFileIndex =0;
		foreach my  $distFile2 ( @$raDistributionLists)
		#for ($DistFileIndex =1; $DistFileIndex <= $numLists; $DistFileIndex++)
			{
			@add = @{ getInput($distFile2)};
			$DistFileIndex++;
			foreach $memberNumber (0..$#add )
				{
	   		  	 $member= $add[$memberNumber];
	   		  	 chomp $member;
				 if ($member =~ /([\w\-\+\.\_]+)@([\w\-\+\.]+)/)
					{
					# This is probably an Internet address
					$finalList .= $member.",";
					$thisIsAnInternetAddress  = 1;
					}
				 if ($member =~ /^@/)
					{
					 $member =~ s/^@//g;  
					 $thisIsDistributionList = 1;
					if ($listAliasByListFileName{$member})
						{
						$member = $listAliasByListFileName{$member};
	
						$finalList .= $member.",";
						}
	
					}
				if($aliasOfName{$member})
					{
					$member = $aliasOfName{$member};
					$finalList .= $member.",";
					}
	
				} #end over memberNumber
			chop($finalList);
			push (@outputFile,
				"alias ".$listAlias[$DistFileIndex].
				" ".$finalList."\n") ;
			undef($finalList);
			}

	} # end if (( ref $raDistributionLists) =~ /ARRAY/)
return \@outputFile;
}


###########################   sub output #######################
sub output

{
my $Pegasus = shift;

my $raInputArray = shift; # reference to input Input data as an array

my ($id,$k, $numberOfGroups) = (3 x 0);

my (%isGroup, @groupalias, @groupaddr, @indivalias,@holdname,$name,$address);
my (%holdname, %aliasid, @indivname, @indivaddr, %indivaddrForLists, %indivnameForLists, %note );	
my (@mainAddressBook);

foreach  (@$raInputArray )
	{ 
	chomp;
	my @line = split(" ",$_,3);
	my $alias= $line[1];
	my $aliasold = $alias;
     	$alias = cleanalias($aliasold);
	my $rest = $line[2];
		
	if ($line[0] eq "alias") # This is an alias line
		{
		$id++;	
		$aliasid{$alias} = $id;
		my $commas_outside_quotes1 = commas_outside_quotes($rest);
		if ($commas_outside_quotes1)
			{
			local $^W;
		 	# There are commas not enclosed in quotes
			#we have a group list.
                   	$isGroup{$alias} = 1;
			 $groupalias[$numberOfGroups] = $alias;
			$groupaddr[$numberOfGroups] = $rest;
           	      	$groupaddr[$numberOfGroups] =~ s/\s*//g; # get rid of all spaces
			$numberOfGroups++;
			}
		else # we have an individual address
			{
		         local $^W;
			$indivalias[$k] = $alias;
		
			if ( $rest =~ /</) 
			# compound address of form Name<Address>
			{
				($name,$address) = split(/</,$rest);
				chop ($address);
				$address  =~s/>*//g; 
				$name =~ s/\"//g;
				$name =~ s/\'//g;
				$indivalias[$k] = $alias;
				$holdname{$alias} = $name;
				$indivname[$k] = $name;
				$rest = $address;
			}
			elsif ( $rest =~ /\(/) 
			# compound address of form Address(Name)
				{
				($address,$name) = split(/\(/,$rest);
				$name  =~s/\)*|\"|\'//g; 
				#$name =~ s/\"//g;
				#$name =~ s/\'//g;
				chop($name);
				chop($address);
				$indivalias[$k] = $alias;
				$indivname[$k] = $name;
				$holdname{$alias} = $name;
				$rest = $address;
				}
			else # no name given, use the alias as a name
				{
				$indivname[$k] = $alias;
				}
			$indivaddr[$k] = $rest;
			$indivaddrForLists{$alias} = $indivaddr[$k] ;
			$indivnameForLists{$alias} = $indivname[$k] ;
			$k++;
			}
		}	
		else  #we have a note
			{
			$note{$alias} = $rest;
			}
		}

foreach my $kk (0 .. $k-1)
	{
	my $alias1 = $indivalias[$kk];



	push @mainAddressBook, "Name:            $indivname[$kk]\n";
	push @mainAddressBook, "Key:             $alias1\n";
	push @mainAddressBook, "E-mail address:  $indivaddr[$kk]\n";
	{
		local $^W;
		push @mainAddressBook, "Notes:           $note{$alias1}\n";	
	}

	}

# Write group lists section
my ($localalias, %isLongAlias );

my $raDistributionListArrayReferences = [];
my $raDistributionListNames = [];

foreach my $jj (0 .. $numberOfGroups -1)
	{
	  my $alias1 = $groupalias[$jj];
	
		push @{$raDistributionListArrayReferences->[$jj]}, "\\TITLE $alias1 \n";
		
		push @{$raDistributionListArrayReferences->[$jj]}, "\\NOSIG Y\n", "\n";
		
		$raDistributionListNames->[$jj] = $alias1.".pml";
		

      my @groupmembers = split(",",$groupaddr[$jj]);
	for (@groupmembers)
		{
		if (!/\@/) #  We do not have an internet address as a group member
			{
			$localalias = cleanalias($_);
			}
		else   #  We have a internet address -- do not modify
			{
			$localalias = $_;
			}

		if ($aliasid{$localalias}) # alias exists
			{

			if ($isGroup{$localalias}) #The alias belongs
								   # to a group
				{
				if($isLongAlias{$localalias})
					{
					$localalias = substr($localalias,0,8);
					}
				push @{$raDistributionListArrayReferences->[$jj]},"@",$localalias,"\n";

				}
			else     #An individual alias
				{
				if ($indivnameForLists{$localalias} )
					{
					push @{$raDistributionListArrayReferences->[$jj]},
						$indivnameForLists{$localalias}."\n";
					}
				else
					{
					push @{$raDistributionListArrayReferences->[$jj]},
						$localalias."\n";
					}
				

				}
			}
		
		}

	}
return \@mainAddressBook, $raDistributionListArrayReferences, $raDistributionListNames ;
}



###########################  end sub output #######################
1;