=head1 NAME

Mail::Addressbook::Convert::Mailrc  - from Unix Mailrc Addressbook 

=head1 SYNOPSIS

use strict;

use Mail::Addressbook::Convert::Mailrc;

my $Mailrc = new Mail::Addressbook::Convert::Mailrc();

my $MailrcInFile  ="mailrc";  # name of the file containing the Spry data
				# it is found in the Spry folder

# Convert Mailrc to Standard Intermediate format

# see documentation for details on format.

my $raIntermediate = $Mailrc->scan(\$MailrcInFile);  

# This will also work

#my @MailrcInArray  = @arrayContainingTheMailrcData;

#my $raIntermediate = $Mailrc->scan(\@MailrcInArray);  	




print join "", @$raIntermediate;  



=head1 REQUIRES

Perl, version 5.001 or higher

Carp

=head1 DESCRIPTION

This module is meant to be used as part of the Mail::Addressbook::Convert distribution.

It can convert a Tsv addressbook to a Standard Intermediate format(STF) and a STF to TSV
As part of the larger distribution, it will allow conversion between Spry and many other 
formats.

To use to convert between Mailrc and Eudora as an example, you would do the following 

use Mail::Addressbook::Convert::Mailrc;

use Mail::Addressbook::Convert::Eudora;

my $Mailrc = new Mail::Addressbook::Convert::Mailrc();

my $Eudora = new Mail::Addressbook::Convert::Eudora();

my $mailrcInFile  ="MailrcSampleFile.txt";  # name of the file containing the mailrc data

my $raIntermediate = $Mailrc->scan(\$mailrcInFile); 

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
			
Mailrc addressbook:

			if you are using UNIX mail, you don't need a lot of instructions.
			for details see http://www.unet.univie.ac.at/aix/files/aixfiles/mailrc.htm
			
			
------------------------------------------------------
=head1 METHODS

=head2 new

no arguments needed.

=head2 scan

Input : a reference to an array containing a mailrc file or a reference to a scalar containing
	the file name with the mailrc data.
	
Returns:  a reference to a STF ( see above).

=head2 output

There is no output method.  That is you cannot convert to a Mailrc format.


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



package  Mail::Addressbook::Convert::Mailrc;

use Mail::Addressbook::Convert::Eudora;
use Mail::Addressbook::Convert::Utilities;
use Carp;


use  5.001;

use vars qw(@ISA );
@ISA = qw { Mail::Addressbook::Convert::Eudora };

#############  Constructor ##########################################

# new is inherited

	
######################################################################

sub scan
{
	
	my $Mailrc = shift;
	my $inputParm=shift;
	
	my $raMailrcArray= getInput($inputParm);
	
	
	my @outputFile;
	foreach (@$raMailrcArray)
	{
		s/^\s+//;
		next unless /^alias/;
		#chomp;
		s/\s+/ /g;
		s/\s*,\s*/,/g;
		push (@outputFile,$_);
	}
	
	return $Mailrc->SUPER::scan(\@outputFile);


}


sub output
{
	confess "\nMailRc.pm does not have an output method. \n You cannot convert to Mailrc";


}

1;