=head1 NAME

Mail::Addressbook::Convert::Spry  - from ccmail  Addressbook 

=head1 SYNOPSIS

use strict;

use Mail::Addressbook::Convert::Ccmail;

my $Ccmail = new Mail::Addressbook::Convert::Ccmail();

my $ccMailInFile  ="ccmailSample.txt";  # name of the file containing the ccmail data


# Convert ccmail to Standard Intermediate format

# see documentation for details on format.

my $raIntermediate = $Ccmail->scan(\$ccMailInFile);  

# This will also work

#my @ccmailInArray  = @arrayContainingTheccmailData;

#my $raIntermediate = $Ccmail->scan(\@ccmailInArray);  	




print join "", @$raIntermediate;  



=head1 REQUIRES

Perl, version 5.001 or higher

Carp

=head1 DESCRIPTION

This module is meant to be used as part of the Mail::Addressbook::Convert distribution.

It can convert a ccMail addressbook to a Standard Intermediate format(STF) 
As part of the larger distribution, it will allow conversion between ccMail and many other 
formats.

To use to convert between ccMial and Eudora as an example, you would do the following 

use Mail::Addressbook::Convert::Ccmail;

use Mail::Addressbook::Convert::Eudora;

my $Ccmail = new Mail::Addressbook::Convert::Ccmail();

my $Eudora = new Mail::Addressbook::Convert::Eudora();

my $ccMailInFile  ="ccmailSample.txt";  # name of the file containing the ccmail data

my $raIntermediate = $Ccmail->scan(\$ccMailInFile); 

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
			
ccMail addressbook:

	* There are two possible input files, you can use either one.
	
	   1. Export your address list to a file, "ccmail.txt".If you have several files you can export them all,
	   	 and combine them with a word processor.
	   2. Use your private address book directly, you just pick up the file "privdir.ini".
	   	 It is in the ccmail sub-directory of your windows directory.
	
	* If you want to export from both files, you can combine both types of files and use them together.



=head1 METHODS

=head2 new

no arguments needed.

=head2 scan

Input : a reference to an array containing a tsv file or a reference to a scalar containing
	the file name with the tsv data.
Returns:  a reference to a STF ( see above).

=head2 output

There is no output method.  That is you cannot convert to a ccmail format.


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

package  Mail::Addressbook::Convert::Ccmail;

use Mail::Addressbook::Convert::Genr;
use Mail::Addressbook::Convert::Utilities;
use Carp;

use  5.001;

use vars qw(@ISA );
@ISA = qw { Mail::Addressbook::Convert::Genr };

#############  Constructor ##########################################

# new is inherited

	
######################################################################

sub scan
{
	my $Ccmail = shift;
	
	my $inputParm = shift; # reference to input ccMail data as an array or reference to a 
			# scalar containing the name of a file containing the ccMail data.
			
	$Ccmail->setfileFormat("tsv");

	my $raCcMailArray= getInput($inputParm);
	
	my $haveName = 0;
	my $haveAddress = 0;
	my $endOfAddress = 0;
	my ($name, $address, $part, @hold, @outputFile , $comment, $h1, $h2);

	while (my $line = shift @$raCcMailArray)
		{
		chomp $line;
		$line =~ s/\r//g;
		if ($line =~ /^Name/)
			{
			$line =~ s/Name: //;
			if ($line =~ /.+\@.+\..+/)
				{
				$haveName = 1;
				$haveAddress = 1;
				$name = "";
				$address = $line;
				}
			else
				{
				$haveName = 1;
				$name = $line;
				}
			}
		elsif ($line =~ /^Addr/)
			{
			$line =~ s/^Addr: //g;
			@hold = split(" ",$line);
			while ($part = shift @hold)
				{
				if (isValidInternetAddress($part))
					{
					$haveAddress = 1;
					$address = $part;
					}
	
				}
			}
		elsif ($line =~ /^Cmts/)
			{
			$line = substr($line,5);
			$comment = $line;
			$endOfAddress = 1;
			}
		elsif ($line =~ /^Entry\d=/)
			{
			($h1,$h2) = split("=", $line);
			if (&::isValidInternetAddress($h2))
				{
				$haveName = 1;
				$haveAddress = 1;
				$endOfAddress = 1;
				$name = "";
				$address = $h2;
				undef $comment;
				}
			}
		if ($haveAddress and $haveName and $endOfAddress)
			{
			$haveName = 0;
			$endOfAddress = 0;
			$haveAddress = 0;
			$address =~ s/<//g;
			$address =~ s/>//g;
			push (@outputFile, $address."\t".$name.
				"\t\t\t".$comment."\n");
	
			undef $comment;
			}	
		}
	# Now we have a tab separated ascii file,
	
	$Ccmail->SUPER::scan(\@outputFile);


}


sub output
{
	confess "\nCcmail.pm does not have an output method. \n You cannot convert to ccMail";


}

1;