=head1 NAME

Mail::Addressbook::Convert::Eudora -  convert to and from Eudora  addressbooks

=head1 SYNOPSIS

use strict;

use Eudora;

my $Eudora = new Eudora();

my $EudoraInFile  ="eudoraSample.txt";  # name of the file containing the Eudora data

# Convert Eudora to Standard Intermediate format

# see documentation for details on format.

my $raIntermediate = $Eudora->scan(\$EudoraInFile);  

# This will also work

#my @EudoraInArray  = @arrayContainingTheEudoraData;

#my $raIntermediate = $Eudora->scan(\@EudoraInArray);  	


# Convert back to Eudora

my $raEudorafOut = $Eudora->output($raIntermediate);

print join "", @$raIntermediate;  

print "\n\n\n\n";

print join "", @$raEudorafOut
;

=head1 REQUIRES

Perl, version 5.001 or higher

Carp
Text::ParseWords

=head1 DESCRIPTION

This module is meant to be used as part of the Mail::Addressbook::Convert distribution.

It can convert a Eudoraaddressbook to a Standard Intermediate format(STF) and a STF to Eudora
As part of the larger distribution, it will allow conversion between Eudora and many other 
formats.

To use to convert between Eudora and Ldif   as an example, you would do the following 

use Mail::Addressbook::Convert::Ldif;

use Mail::Addressbook::Convert::Eudora;

my $Ldif = new Mail::Addressbook::Convert::Ldif();

my $Eudora = new Mail::Addressbook::Convert::Eudora();

my $EudoraInFile  ="eudoraSample.txt";  # name of the file containing the Eudora data

my $raIntermediate = $Ldif->scan(\$EudoraInFile); 

my $raLdif = $Ldif->output($raIntermediate);  # reference to an array containing a Ldif addressbook


=head1 DEFINITIONS 
 
Standard Intermediate Format(STF) :  

			The addressbook format that is used as an intermediate
			between conversions.  It is rfc822 compliant and can
			be used directly as a Eudora addressbook.  Do not use
			a Eudora addressbook as an STF. Some versions of 
			Eudora use a format, that while RFC822 compliant, will
			not work as an STF. Run the Eudora addressbook
			through $Eudora->scan()
			
Eudora addressbook:
			  A Eudora addressbook. The input Eudora address file is 
			"nndbase.txt" in the Eudora directory. for Windows users 
			"Eudora Nicknames" in the System Folder:Eudora Folder for Mac users 

			

=head1 METHODS

=head2 new

no arguments needed.

=head2 scan

Input : a reference to an array containing a Eudora addressbook
	 or a reference to a scalar containing
	the file name with the Eudora Addressbook.
	
Returns:  a reference to a STF ( see above).

=head2 output

Input:  a reference to a STF ( see above).

Returns : a reference to an array containing a Eudora addressbook.


=head1 LIMITATIONS

This only converts email address, aliases, and mailing lists.  Phone numbers,
postal addresses and other such data are not converted.


=head1 REFERENCES



I derived the format by visually inspecting examples, not by reading a document.

		

=head1  HISTORY

This code is derived from the code used on www.interguru.com/mailconv.htm .  The site 
has been up since 1996   The site gets about 8000 unique visitors a month, 
many of whom make addressbook conversions. The code has been well tested.

=head1 FUTURE DIRECTIONS




=head1 SEE ALSO





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


package Mail::Addressbook::Convert::Eudora;

use Mail::Addressbook::Convert::Utilities;
use Mail::Addressbook::Convert::PersistentUtilities;

use  5.001;

sub new {
	bless {},shift;
}

######################################################################


sub scan {

my $Eudora = shift;
my $inputParm = shift; # reference to input Eudora data as an array or reference to a scalar
			#  containing the name of a file containing the Eudora Addressbook.

my $perUtil = new Mail::Addressbook::Convert::PersistentUtilities();
my $raEudoraArray= getInput($inputParm);

my (@outputFile,  %noteLine, $outLine, %listEntry, %name, $alias);
my ( $type, @rest, $rest,  %address, %aliasOf, %newAlias, $nm, @tmp);

use Text::ParseWords;
my $individualIndex = 0;
my $listIndex = 0;
foreach (@$raEudoraArray)
	{
		

	s/\'//g;
	if (tr/"/"/%2 !=0) # to prevent unterminated quotes
		# (which should not exist, but ocasionaly do)
		
		# The garbled line will remain 
		# garbled.
		{
		s/ / "/;
		}
	s/\s+</</;
	@tmp =  split(" ");
	if (@tmp > 3 and /</ and !/"/ and !/^note/)
		{
		/alias\s+(.+)<(.+)>/;
		my $firstPart = $1;
		my $lastPart = $2;
		$firstPart =~ s/^\s+|\s+$//g;  # trim leading and trailing spaces.
		my @hold22= split(" ", $firstPart);
		if (@hold22 > 2)
			{
			my $aliasName= shift @hold22;
			my $givenName = join (" ", @hold22);	
			$_ = qq(alias $aliasName "$givenName"<$lastPart>);
			}
		else
			{
			$_ = qq(alias "$firstPart"<$lastPart>);
		}
		}
	if (/alias "/ and !/<|,/)
		{
			
		($type,$alias,@rest) = quotewords(" ",0,$_);
		my $userName = $alias;
		$alias =~ s/ /_/g;
		$_ = qq(alias $alias $userName<$rest[0]>);
		}

	($type,$alias,@rest) = quotewords(" ",0,$_);
	if ($rest[1])
		{
		$rest = join("_",@rest);
		}
	else
		{
		$rest = $rest[0];
		}
	$alias =~ s/^\s+|\s+$//g;
	$alias =~ s/ //g;
	$rest =~ s/^\s+|\s+$//g;
	if ($type =~ /note/)
		{
		$noteLine{$alias} = $_;
		}
	else
		{
		if ($rest =~ /\,/)
			{
			$listEntry{$alias} = $rest;
			}
		else
			{
			if ($rest =~ /\)$/)
				{
				#alias joan joan.olive@utoronto.ca (Joan Olive)
				($address{$alias}, $name{$alias}) = 
					split(/\(/,$rest);
				}
			elsif ($rest =~ /</)
				{
					
				#alias jhd joe<jhd@intergur.com>
				#alias jhd <jhd@intergur.com>
				#alias jhd Joe Davidson<jdavidson@Interguru.com>
				($name{$alias},$address{$alias}) = split(/\</,$rest);
				$address{$alias} =~ s/>//;
				$name{$alias} = (split(/@/,$address{$alias}))[0]
					unless $name{$alias};
				}
			else
				{
				$address{$alias} = $rest;
				$name{$alias} = (split(/@/,$address{$alias}))[0];
				}
			}
		}
	}

#Examples
foreach my $key (sort { lc($a) cmp lc($b)} ( (keys %name)))
	{

	my $tempAlias = $perUtil->makeAliasUnique($key);
	$address{$key} =~ s/\s+|>\(|\)|<|\n|\r//g;
	$name{$key} =~ s/\)|\(|\n|\r|\"|^\s+|>|<|\s+$//g;
	$aliasOf{$address{$key}} = $tempAlias;
	$newAlias{key} = $tempAlias;
	$nm = $name{$key};
	$nm =~ s/_/ /g;
	#CONTINUE HERE
	$outLine = qq(alias $key \"$nm\"<$address{$key}>\n);
	$outLine =~ s/>>/>/;
	$outLine =~ s/SPRYCOMMA/,/;
	push ( @outputFile, $outLine) if ($address{$key}) ;

	push ( @outputFile, $noteLine{$key}) if $noteLine{$key};
}
my @listMembers;
foreach my $key (sort { lc($a) cmp lc($b)} (keys %listEntry))
	{
	$listEntry{$key} =~ s/\)|\(|\n|\r|\"|^\s+|>|<|\s+$//g;
	@listMembers = split(/\,/,$listEntry{$key});
	foreach my $k (0..$#listMembers)
		{
		$listMembers[$k] =  $aliasOf{$listMembers[$k]}
		 if $aliasOf{$listMembers[$k]};
		}
	$listEntry{$key} = join(',' , @listMembers );
	$outLine = qq(alias $key $listEntry{$key}\n);
	#$outLine =~ s/>>/>/;
	push ( @outputFile, $outLine) ;
	push ( @outputFile, $noteLine{$key}."\n") if $noteLine{$key};
	}

push ( @outputFile, "\n");
return \@outputFile;
}

###########################   sub output #######################
sub output

{

my (@outputFile, $alias1,);

my $Eudora = shift;
my $raInputArray = shift; # reference to input  data as an array


# Return intermediate file, as it is already in Eudora format.

return $raInputArray;
}



###########################  end sub output #######################
1;