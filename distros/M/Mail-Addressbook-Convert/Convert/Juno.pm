=head1 NAME

Mail::Addressbook::Convert::Juno  -- convert from Juno addressbooks.

=head1 SYNOPSIS

use strict;

use Mail::Addressbook::Convert::Juno;

my $Juno = new Mail::Addressbook::Convert::Juno();

my $JunoInFile  ="junoSample.nv";  # name of the file containing the Juno data
				# it is found in the Spry folder

# Convert Juno to Standard Intermediate format

# see documentation for details on format.

my $raIntermediate = $Juno->scan(\$JunoInFile.nv);  

# This will also work

#my @JunoInArray  = @arrayContainingTheJunoData;

#my $raIntermediate = $Juno->scan(\@JunoInArray);  	

print join "", @$raIntermediate;  



=head1 REQUIRES

Perl, version 5.001 or higher

Carp

=head1 DESCRIPTION

This module is meant to be used as part of the Mail::Addressbook::Convert distribution.

It can convert a Tsv addressbook to a Standard Intermediate format(STF) and a STF to TSV
As part of the larger distribution, it will allow conversion between Spry and many other 
formats.

To use to convert between Juno and Eudora as an example, you would do the following 

use Mail::Addressbook::Convert::Juno;

use Mail::Addressbook::Convert::Eudora;

my $Juno = new Mail::Addressbook::Convert::Juno();

my $Eudora = new Mail::Addressbook::Convert::Eudora();

my $junoInFile  ="junoSampleFile.nv";  # name of the file containing the juno data

my $raIntermediate = $Juno->scan(\$junoInFile); 

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
			
Juno addressbook:

			use the file with a .nv extension as the input
			
			
------------------------------------------------------
=head1 METHODS

=head2 new

no arguments needed.

=head2 scan

Input : a reference to an array containing a Juno file or a reference to a scalar containing
	the file name with the Juno data.  The file exists in the Juno folder with an ".nv"
	extension.
	
Returns:  a reference to a STF ( see above).

=head2 output

There is no output method.  That is you cannot convert to a Juno format.


=head1 LIMITATIONS

This only converts email address, aliases, and mailing lists.  Phone numbers,
postal addresses and other such data are not converted.



=head1 REFERENCES



		

=head1  HISTORY

This code is derived from the code used on www.interguru.com/mailconv.htm .  The site 
has been up since 1996 ( but ldif was only included on 1997, when Netscape 3  started
using it.)  The site gets about 8000 unique visitors a month, many of whom make addressbook
conversions. The code has been well tested.

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



package  Mail::Addressbook::Convert::Juno;

use Mail::Addressbook::Convert::Eudora;
use Mail::Addressbook::Convert::Utilities;
use Mail::Addressbook::Convert::PersistentUtilities;
use Carp;


use  5.001;

use vars qw(@ISA );
@ISA = qw { Mail::Addressbook::Convert::Eudora };

#############  Constructor ##########################################

# new is inherited

	
######################################################################

sub scan
{
	
	my $Juno = shift;
	my $inputParm=shift;
	
	my $raJunoArray= getInput($inputParm);
	
	my $perUtil = new Mail::Addressbook::Convert::PersistentUtilities();
	my @outputFile;

	my $insideRecord = 0;
	
	my (@hold,$type,$name, @hold1, @hold2,$email,$alias1,@list, %aliasOf, %isAlias);
	my (@members, $n1, $hold2, $holdLine, %nameOf);
	
	
	# First Loop
	foreach  (@$raJunoArray)
		{
		$insideRecord = 1 if /^Type/;
		$insideRecord = 0 unless /\S/;
		if ($insideRecord)
			{
			chomp;
			@hold = split(':');
			$type = $hold[1] if ($hold[0] =~ /Type/);
			$name = $hold[1] if ($hold[0] =~ /Name/);
			if ($name =~ /\,/)
				{
				@hold2 = split(/\,/,$name, 2);
				$name = $hold2[1]." ".$hold2[0];
				}
	
			$name =~ s/^\s+|\s+$//g;
			$email = $hold[1] if ($hold[0] =~ /Email/);
			$alias1 = $hold[1] if ($hold[0] =~ /Alias/);
			if ($hold[0] =~ /Member/)
				{
				push (@list , $hold[1])
				}
			}
		else
			{
			if ($type =~ /Entry/ )
				{
				@hold1 = split('@',$email);
				$alias1 = $hold1[0];
				unless  ($aliasOf{$email} 
					or $email !~ /\@/)
					{
					$aliasOf{$email} = 
						$perUtil->makeAliasUnique($alias1);
					$isAlias{$aliasOf{$email}} = 1;
					}
				}
			elsif ($type =~ /MList/ )
				{
				foreach (@list)
					{
					if (/@/ and not $aliasOf{$_})
						{
						my @holdB = split('@');
						$aliasOf{$_} =
							$perUtil->makeAliasUnique($holdB[0])
							unless $aliasOf{$_};
						}
					}
				}
	
			$nameOf{$email} = $name;
			undef $alias1;
			undef $type;
			undef $email;
			undef $name;
			}
		}
	# Second Loop
	$insideRecord = 0;
	foreach (@$raJunoArray)
		{
		
		$insideRecord = 1 if /^Type/;
		$insideRecord = 0 unless /\S/;
		if ($insideRecord)
			{
			chomp;
			@hold = split(':');
			$type = $hold[1] if ($hold[0] =~ /Type/);
			$email = $hold[1] if ($hold[0] =~ /Email/);
			$name = $hold[1] if ($hold[0] =~ /Name/);
			push (@list , $hold[1])
				if $hold[0] =~ /Member/;
			push (@members , $hold[1])
					if ( $hold[0] =~ /Member/);
			}
		else
			{
			if ($type =~ /Entry/ )
				{
				$n1 = qq("$nameOf{$email}")
					if $nameOf{$email};
				$hold2 =
					qq(alias $aliasOf{$email} $n1<$email>\n);
				$hold2 =~ s/\n|\r//g;
				push (@outputFile, $hold2."\n")
					  if ($email =~ /\@/);
				}
			elsif ($type =~ /MList/  and $list[0])
				{
				$holdLine = qq(alias $name );
				foreach (@members)
					{
					if ($isAlias{$_})
						{
						$holdLine .= $_.",";
						}
					else
						{
						$holdLine .= $aliasOf{$_}.",";
						}
					}
				$holdLine =~ s/,$//;
				$holdLine =~ s/ ,/ /;
				$holdLine =~ s/,,/,/g;
				$holdLine .="\n";
				$holdLine =~ s/\n|\r//g;
				push (@outputFile,$holdLine);
				foreach (@members)
					{
					#print "JHD20 $_\n";
					}
				}
	
			undef $type;
			undef $email;
			undef $name;
			undef @members;
			undef $n1;
			}
		}

	
	return $Juno->SUPER::scan(\@outputFile);


}


sub output
{
	confess "\nJuno.pm does not have an output method. \n You cannot convert to Juno";


}

1;