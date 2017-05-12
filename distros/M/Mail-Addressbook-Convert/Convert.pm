package MAIL::CONVERT;

$VERSION = "1.1";
sub Version { $VERSION; }

require 5.001;

#This file does not action except to set the version

=head1 NAME

Mail::Addressbook::Convert -  convert to and from many e-mail addressbooks

=head1 SYNOPSIS

These modules allow to to convert between the following e-mail addressbook formats

From		To
csv		csv  ( Note: MS Outlook. Outlook Express and many other mailers will 
			export and import into this format)
tsv		tsv   (tab-separated ascii, Outlook and OE also do these)
pine		pine
ccMail
Eudora		Eudora
Pegasus		Pegasus
Juno
Lidf		Ldif	(Netscape 4 exports in this format )
Mailrc
Spry




=head1 REQUIRES

Perl, version 5.001 or higher
File::Basename
Carp

=head1 DESCRIPTION

This distribution will convert email addressbooks between many common formats.  Some examples are Pine, Eudora, Pegasus, csv.

The documentation here is general.  For details on conversion, each module has pod 
documentation specific to its conversion


As an example

To use to convert between Pine and Eudora as an example, you would do the following 

use Mail::Addressbook::Convert::Pine;

use Mail::Addressbook::Convert::Eudora;

my $Pine = new Mail::Addressbook::Convert::Pine();

my $Eudora = new Mail::Addressbook::Convert::Eudora();

my $PineInFile  ="pineSample.txt";  # name of the file containing the Pine data

my $raIntermediate = $Pine->scan(\$PineInFile); 

my $raEudora = $Eudora->output($raIntermediate);  # reference to an array containing a Eudora addressbook

All modules follow this template except Pegasus. Pegasus stores its address books in multiple 
files.  See the documentation in Pegasus.pm


=head1 DEFINITIONS 
 
Standard Intermediate Format(STF) :  

			The addressbook format that is used as an intermediate
			between conversions.  It is rfc822 compliant and can
			be used directly as a Eudora addressbook.  Do not use
			a Eudora addressbook as an STF. Some versions of 
			Eudora use a format, that while RFC822 compliant, will
			not work as an STF. Run the Eudora addressbook
			through $Eudora->scan()
			

			

=head1 METHODS

All modules have new and scan methods.  All modules except Juno, CcMail, Spry, and Mailrc have output.  
All modules except Pegasus follow the templates below

=head2 new

no arguments needed for all modules.

=head2 scan

Input : a reference to an array containing a addressbook file or a reference to a scalar containing
	the file name with the addressbook data.
Returns:  a reference to a STF ( see above).

=head2 output

All modules except Juno, CcMail, Spry, and Mailrc have output methods.

Input:  a reference to a STF ( see above).
Returns : a reference to an array containing a pine file.


=head1 LIMITATIONS

This only converts email address, aliases, and mailing lists.  Phone numbers,
postal addresses and other such data are not converted.



=head1 REFERENCES

See individual modules for references
		

=head1  HISTORY

This code is derived from the code used on www.interguru.com/mailconv.htm .  The site 
has been up since 1996  The site gets about 8000 unique visitors a month, many of whom make addressbook
conversions. The code has been well tested.

=head1 FUTURE DIRECTIONS



=head1 SEE ALSO

There are other ways to convert addressbooks.  Many e-mail clients will import adressbooks of other 
e-mail clients.

Dawn is an open source system that will run on Unix and Windows.

You can find information on Dawn and other methods on www.interguru.com/MailInformation.htm

You can do conversions directly on the Web at www.interguru.com/mailconv.htm .


=head1 BUGS

=head1 CHANGES

Original Version 2002-Feb-09
                  
=head1 COPYRIGHT

Copyright (c) 2001 Joe Davidson. All rights reserved.
This program is free software; you can redistribute it 
and/or modify it under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html). or the
GPL copyleft license ( http://www.gnu.org/copyleft/gpl.html) 


=head1 AUTHOR

Mail::Addressbook::Convert was written by Joe Davidson  <jdavidson@interguru.com> in 2002.

=cut
