=head1 NAME

Mail::Addressbook::Convert::Ldif -  convert to and from Ldif formatted addressbooks

=head1 SYNOPSIS

use strict;

use Mail::Addressbook::Convert::Ldif;

my $LDIF = new Mail::Addressbook::Convert::Ldif();

my $LdifInFile  ="ldifSample.txt";  # name of the file containing the Ldif data

# Convert Ldif to Standard Intermediate format

# see documentation for details on format.

my $raIntermediate = $LDIF->scan(\$LdifInFile);  

# This will also work

#my @LdifInArray  = @arrayContainingTheLdifData;

#my $raIntermediate = $LDIF->scan(\@LdifInArray);  	


# Convert back to Ldif

my $raLdifOut = $LDIF->output($raIntermediate);

print join "", @$raIntermediate;  

print "\n\n\n\n";

print join "", @$raLdifOut;

=head1 REQUIRES

Perl, version 5.001 or higher

Carp

=head1 DESCRIPTION

This module is meant to be used as part of the Mail::Addressbook::Convert distribution.

It can convert a Ldif addressbook to a Standard Intermediate format(STF) and a STF to Ldif
As part of the larger distribution, it will allow conversion between Ldif and many other 
formats.

To use to convert between Ldif and Eudora as an example, you would do the following 

use Mail::Addressbook::Convert::Ldif;

use Mail::Addressbook::Convert::Eudora;

my $Ldif = new Mail::Addressbook::Convert::Ldif();

my $Eudora = new Mail::Addressbook::Convert::Eudora();

my $LdifInFile  ="ldifSample.txt";  # name of the file containing the Ldif data

my $raIntermediate = $Ldif->scan(\$LdifInFile); 

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
			
Ldif addressbook:
			  A ldif addressbook. (LDAP Data Interchange Format) 
			  This module works on ldif 
			  files ouputted by the Netscape Client and Netscape Server.
			  You can find information on various formats by searching
			  for B<ldif> on google.com .
			

=head1 METHODS

=head2 new

no arguments needed.

=head2 scan

Input : a reference to an array containing a ldif file or a reference to a scalar containing
	the file name with the ldif data.
	
Returns:  a reference to a STF ( see above).

=head2 output

Input:  a reference to a STF ( see above).
Returns : a reference to an array containing a ldif file.


=head1 LIMITATIONS

This only converts email address, aliases, and mailing lists.  Phone numbers,
postal addresses and other such data are not converted.

This has only been tested on Ldif files produced by Netscape Communicator and
the Netscape Server.


=head1 REFERENCES

You can find information on the ldif format by searching for "ldif" on google.com .

I derived the format by visually inspecting examples, not by reading a document.

		

=head1  HISTORY

This code is derived from the code used on www.interguru.com/mailconv.htm .  The site 
has been up since 1996 ( but ldif was only included on 1997, when Netscape 3  started
using it.)  The site gets about 8000 unique visitors a month, many of whom make addressbook
conversions. The code has been well tested.

=head1 FUTURE DIRECTIONS


Maybe use Net::LDAP::LDIF for the scan method.

=head1 SEE ALSO

Mozilla::LDAP::LDIF 
Net::LDAP::LDIF 



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


package Mail::Addressbook::Convert::Ldif;

use Mail::Addressbook::Convert::PersistentUtilities;
use Mail::Addressbook::Convert::Utilities;
use  5.001;

sub new {
	bless {},shift;
}

######################################################################


sub scan {

my $Ldif = shift;
my $inputParm = shift; # reference to input ldif data as an array or reference to a 
			# scalar containing the name of a file containing the ldif.
			
my $perUtil = new Mail::Addressbook::Convert::PersistentUtilities();

my $raLdifArray= getInput($inputParm);
#NOTE
# This method has been modified and never cleaned up
# There may be some sections of code which are either never
# executed, or irrelevant to the output.
#As it stands, it can process ldif output from Netscape Communicator
# and the Netscape LDAP server
# jhd 19980925




my ($alias, $fullName, $outLine, %aliasOf, @outputFile);

push (@$raLdifArray,"dn:\n\n");  #put final dn: line  in for processing purposes
	# as "dn:" acts as an end of record marker in this code

my (%group,$address);
foreach my $i (@$raLdifArray)
	{
	my ($temp,$isGroup, $xalias) ;
	$i =~ s/[\x88\xa9\xd8]//g; 
	$i =~ s/[\x7e-\xff]//g; 
	if ($i =~ /^objectclass: groupOfNames|^objectclass: groupOfUniqueNames/)
		{
		$isGroup = 1;
		}
	if ($i =~ /^objectclass: person/)
		{
		$isGroup = 0;
		}
	if ($i =~ /^xnavnickname:|^xmozillanickname:/)
		{
		($temp,$xalias) = split(/\:/,$i);
		chomp $xalias;
		$xalias =~ s/\s+//g;
		}
	if ($i =~ /^mail\:/)
		{
		$i =~ s/:\s+/:/;
		($temp,$address) = split(/\:/,$i);
		chomp $address;
		$address =~ s/\s+//g;
		}
	if ($i =~ /^member\:|^uniquemember\:/)
		{
		my ($rm, $rawMember);
		$i =~ s/:\s+/:/;
		($temp, $rawMember) = split(/\:/,$i);
		chomp $rawMember;
		if ($rawMember =~ /,mail=/)
			{
			($a,$rm) = split(/\,mail=/,$rawMember)
			#($a,$rawMember) = split(/\,mail=/,$rawMember)
			}
		else
			{
			($a,$rm) = split(/cn=/,$rawMember)
			}
		$rawMember = (split(",",$rm))[0];
		$rawMember =~ tr/A-Z/a-z/;
		$rawMember =~  s/ /_/g;
		if ($aliasOf{$rawMember})
			{
			$rawMember = $aliasOf{$rawMember};
			}
		$group{$alias} .=$rawMember.',';
		$group{$alias} =~  s/\n|\r//g;

		}
	if ($i =~ /^dn/)
		{
		$i =~ s/:\s+/:/;
		($temp,$fullName) = split(/\:/,$i);
		$fullName = (split(",",$fullName))[0];
		{local $^W;
			$fullName =~ s/cn=//;
			$fullName =~ s/"//g;
			chomp $fullName;
			$alias = $fullName;
			$alias =~ s/ /_/g ;
		}
		

		}
	if ($i !~ /\S/)
		{ local $^W;
		my ($outline);

		if(!$isGroup and $alias)
			{
			$alias = $xalias if $xalias;
			$alias = $perUtil->makeAliasUnique($alias,"_");
			$aliasOf{$address} = $alias;
			
			if ($fullName !~ /@/)
				{
				$outLine = qq(alias $alias "$fullName"<$address>);
				}
			else
				{
				$outLine = qq(alias $alias $address);
				}
			$outLine =~ s/\n|\r|\015//g;
			push (@outputFile, $outLine."\n");
			undef $address;
			undef $outline;
			undef $alias;
			undef $xalias;
			undef $fullName;
			}
		}
	} #end of input array
foreach my $key (sort keys %group)
	{
	my $mems = $group{$key};
	chop $mems;
	my $hold =  "alias $key  $mems";
	$hold =~  s/\n|\r//g;
	push (@outputFile,
	"$hold\n");

	}
return \@outputFile;
}


###########################   sub output #######################
sub output

{

my (@outputFile, $alias1,);

my $Ldif = shift;
my $raInputArray = shift; # reference to input Input data as an array



my $id = 0;    my $k=0; my $numberOfGroups=0;

my ($aliasold, %aliasid, %note, $firstName, $lastName, $name, $address, @groupaddr);
my (@indivname, @indivaddr, @indivalias, @groupalias, %indivnameForLists);
my (%indivaddrForLists,  %isGroup, $aliasid1 , @groupmembers);

foreach (@$raInputArray )
	{
	my @line = split(" ",$_,3);
	my $alias= $line[1];
	$aliasold = $alias;
      	$alias = &cleanalias($aliasold);
	my $rest = $line[2];
	my $rest1 = $rest;
	if ($aliasid{$alias} && ($line[0] ne "note") )  
			# this alias alrady exists
		{
		
		}
		
	 else # unique alias, process the data	
		{
		
		my %aliasid;
		if ($line[0] eq "alias") # This is an alias line
			{
			$id++;	
			$aliasid{$alias} = $id;
			my $commas_outside_quotes1 = &commas_outside_quotes($rest);
			if ($commas_outside_quotes1)
				{
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
				$indivalias[$k] = $alias;
				if ( $rest =~ /</) 
				# compound address of form Name<Address>
					{
					($name,$address) = split(/</,$rest);
					chop ($address);
					$address  =~s/>*//g; 
					$name =~ s/\"//g;
					$name =~ s/\'//g;
					$indivname[$k] = $name;
					#$holdname{$alias} = $name;
					$rest = $address;
					}
				elsif ( $rest =~ /\(/) 
				# compound address of form Address(Name)
					{
					($address,$name) = split(/\(/,$rest);
					$name  =~s/\)*//g; 
					$name =~ s/\"//g;
					$name =~ s/\'//g;
					chomp($name);
					chop($address);
					$indivname[$k] = $name;
					#$holdname{$alias} = $name;
					$rest = $address;
					}
				else # no name give, use the alias as a name
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
				$note{$alias} = $rest1;
				}
		} # end of processing addresses
	}
# Write individual alias section

foreach my $kk (0 .. $k-1)
	{
	  my @hold;
	  $alias1 = $indivalias[$kk];	
	if ($note{$alias1})
		{
		if ($note{$alias1} =~ /name:(.+)>/)
			{
			@hold = split(/>/,$1);
			$indivname[$kk] = $hold[0]
				if length($hold[0]) =~ /\S/;
			}
		}
	@hold = split(" ",$indivname[$kk]);
	$lastName = pop(@hold);
	$firstName = join(" ",@hold);
	push (@outputFile,"\ndn: cn=$indivname[$kk],mail=$indivaddr[$kk]\n");
	push (@outputFile,"cn: $indivname[$kk]\n");
	push (@outputFile,"sn: $lastName\n");
	push (@outputFile,"objectclass: top\n");
	push (@outputFile,"objectclass: person\n");
	push (@outputFile,"mail: $indivaddr[$kk]\n");
	push (@outputFile,"givenname: $firstName\n");
	push (@outputFile,"uid: $alias1\n");
	push (@outputFile,"xnavnickname: $alias1\n");
	push (@outputFile,"xmozillanickname: $alias1\n");
	if ($note{$alias1})
		{
		push (@outputFile,"description: $note{$alias1}\n");
		if ($note{$alias1} =~ /phone:(.+)>/)
			{
			@hold = split(/>/,$1);
			push (@outputFile,
				"telephonenumber: $hold[0]\n");
			}
		}
		if ($note{$alias1} and $note{$alias1} =~ /fax:(.+)>/)
			{
			@hold = split(/>/,$1);
			push (@outputFile,
				"facsimiletelephonenumber: $hold[0]\n");
			}
		if ($note{$alias1} and $note{$alias1} =~ /Home phone.+:(.+)/)
			{
			@hold = split(/</,$1);
			$hold[0] =~ s/^\s+//;
			push (@outputFile,
				"homephone: $hold[0]\n");
			}
	

	
	}


# Write group lists section
foreach my $jj (0 .. $numberOfGroups -1)
	{
	  $alias1 = $groupalias[$jj];


	push (@outputFile,"\ndn: cn=$alias1\n");
	push (@outputFile,"cn: $alias1\n");
	push (@outputFile,"objectclass: top\n");
	push (@outputFile,"objectclass: groupOfNames\n");
	push (@outputFile,"uid: $alias1\n");
	push (@outputFile,"xnavnickname: $alias1\n");
		
      @groupmembers = split(",",$groupaddr[$jj]);
      my $localalias;
	for (@groupmembers)
		{
		if (!/\@/) #  We do not have an internet address as a group member
			{
			$localalias = &cleanalias($_);
			}
		else   #  We have a internet address -- do not modify
				# This makes the error message clearer
			{
			$localalias = $_;
			}

		if ($aliasid{$localalias}) # alias exists
			{
	  		$aliasid1 = $aliasid{$localalias};
			if ($isGroup{$localalias}) #The alias belongs
							   # to a group
				{	
				 push (@outputFile, "member: cn=$localalias\n");
				}
			else     #An individual alias
				{
			
				push (@outputFile, 
				"member: cn=$indivnameForLists{$localalias},mail=$indivaddrForLists{$localalias}\n");				
				
				}
			
			}
		
		}



	}

return \@outputFile;
}



###########################  end sub output #######################
1;