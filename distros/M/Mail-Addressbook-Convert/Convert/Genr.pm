=head1 NAME

Mail::Addressbook::Convert::Genr -  base class for many email conversion classes

=head1 SYNOPSIS

This class is not meant to be called by the user.  It is the base class for

Juno.pm

Spry.pm

Csv.pm

Tsv.pm

Compuserve.pm

These classes will convert csv (comma separated variables), tsv (tab separated variables),
sprymail exports, juno address exports.

=head1  REQUIRES

Perl, version 5.001 or higher

Carp

=head1 DESCRIPTION

This is a base class designed for other modules in this distribution.

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

=head2 new

no arguments needed.

=head2 scan

Input : a reference to an array containing  input data.
 
Returns:  a reference to a STF ( see above).

=head2 output

Input:  a reference to a STF ( see above).
Returns : a reference to an array containing the output file.

=head2  setfileFormat

Sets the file format  must be called before calling scan or output.
Input, 
	must be one of following "csv","tsv","spry","compuserve" before calling scan
	must be one of following "csv","tsv" before calling scan
	 


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


package Mail::Addressbook::Convert::Genr;

use Carp qw(croak confess) ;


use Mail::Addressbook::Convert::Eudora;
use Mail::Addressbook::Convert::Utilities;
use Mail::Addressbook::Convert::PersistentUtilities;
use Mail::Addressbook::Convert::Pine;
use  5.001;

######################################################################

sub new {
	bless {
		separator => "",
		fileFormat => "",
		}
		,shift;
		
		
}

######################################################################

sub setfileFormat
{
	my $Genr = shift;
	$Genr->{fileFormat} = shift;
}








######################################################################
sub scan {

my $Genr = shift;
my $fileFormat= $Genr->{fileFormat};

my $perUtil = new Mail::Addressbook::Convert::PersistentUtilities();


my $inputParm = shift; # reference to input  data as an array reference 


my $raGenrArray= getInput($inputParm);



my @file= @$raGenrArray;


unless ($fileFormat) {confess "file format not specified\n"};

if ($fileFormat !~ /^csv$|^tsv$|^spry$|^compuserve$/)
	{confess qq(\nFile format "$fileFormat" is not supported );}


my (%listMember,@outputFile, @comment, @address, $totalAddress);
my ($totalName , @firstName, @lastName);
my ( $ai, @temp, $individualAliasNumber);
my ($AAA, @a, $tempAlias, @b, $i, $j, %aliasList, @alias);
my ($tempAlias1, %existingListAlias);

my $separator = "\t";
$separator = "," if ($fileFormat eq "csv");


foreach my $i (0..$#file)
   	{  #Block 1
  
	chomp $file[$i];
	next unless $file[$i];
	$file[$i] =~ s/\r|\015//g;
	#####  for Spry Mail ########
	if ($fileFormat eq "spry")
		{	
		my ($a1,$b1) = split(":",$file[$i]);
		$file[$i] = $b1."\t".$a1;
		$file[$i] =~s/,/SPRYCOMMA/g;
		#print "JHD SPRY file = $file[$i]\n";
		undef $ai; 
		undef $b1;
		}
	######  end SpryMail ##########################
	#####  all formats below ##################

	@temp = split($separator,$file[$i]);
	foreach (@temp) {s/^\s*"|"\s*$//;}   # get rid of leading and trailing quotes.
		{ local $^W; # turn off warnings
		($address[$individualAliasNumber],$firstName[$individualAliasNumber],
			$lastName[$individualAliasNumber],$tempAlias,
			$comment[$individualAliasNumber])
			= @temp[0..4];
		}
		
		
#####  start section for CompuServe   ##########################
	if ($fileFormat eq "compuserve")
		{
		$address[$individualAliasNumber] =~ s/INTERNET://g;
		if ($address[$individualAliasNumber]  =~ /\,/ and
				$address[$individualAliasNumber] !~/@/)
			{
			$address[$individualAliasNumber] =~ s/\"//g;
			$address[$individualAliasNumber] =~ s/\,/\./;
			$AAA = $address[$individualAliasNumber];
			$address[$individualAliasNumber] =
				$AAA.'@compuserve.com';
			$tempAlias = $firstName[$individualAliasNumber].
				$lastName[$individualAliasNumber];
			unless ($tempAlias) {$tempAlias = $AAA;}
			}
		}
######### end Compuserve Section	
	unless ($tempAlias)
		{
			{
				local $^W;
				@a = split('@',$address[$individualAliasNumber]);
			}
		$tempAlias = $a[0];
		if ($tempAlias =~ /\"/ )
			{
			@a = split ("\"", $tempAlias);
			$tempAlias = $a[$#a];
			@a = split ("\"",$address[$individualAliasNumber]);
			$address[$individualAliasNumber] = $a[$#a];
			}
		if ($tempAlias =~ /\>/ )
			{
			@a = split ("<", $tempAlias);
			$tempAlias = $a[1];
			@b = split ("\<",$address[$individualAliasNumber]);
			$address[$individualAliasNumber] = $b[1];
			$address[$individualAliasNumber] =~ s/\>+//;
			$address[$individualAliasNumber] =~ s/\<+//;
			unless ($firstName[$individualAliasNumber]
				 or $lastName[$individualAliasNumber])
				{
				$firstName[$individualAliasNumber] = $b[0];
				$firstName[$individualAliasNumber] =~ s/\"//g;
				}
			}
		}
		$tempAlias = $perUtil->makeAliasUnique($tempAlias);
		$aliasList{$tempAlias} = 1;
		{local $^W;
			$alias[$individualAliasNumber] = $tempAlias ;
		}
		
		if ($temp[5])
		{ 
		$j = 5;
		while ($temp[$j] )
			{
			if($existingListAlias{$temp[$j]})
				{
				$tempAlias1 = $existingListAlias{$temp[$j]};
				}
			else
				{
				$tempAlias1 = $perUtil->makeAliasUnique($temp[$j]);
				$existingListAlias{$temp[$j]} = $tempAlias1;
				}
			{local $^W;
				$listMember{$tempAlias1} = 
				$listMember{$tempAlias1}.$alias[$individualAliasNumber].",";
			}
			
			$j++
			} 
		}
		else
			{
			local $^W;
			$listMember{'notonanotherlist'} = 
				$listMember{'notonanotherlist'}.$alias[$individualAliasNumber].",";
			}
		undef (@temp);
		{ local $^W;
			$listMember{'everybody'} = 
				$listMember{'everybody'}.$alias[$individualAliasNumber].",";
		}
			
	$individualAliasNumber++;
   	}  #End Block 1

foreach $i (0 .. $#address)
	{
	if ($firstName[$i] or $lastName[$i])
		{local $^W;
		$totalName = $firstName[$i]." ".$lastName[$i];
		$totalAddress = qq{"$totalName"<$address[$i]>};
		}
	else
		{
		$totalAddress = $address[$i];
		}

	push (@outputFile, "alias ".$alias[$i]." ".
				$totalAddress."\n");
	if ($comment[$i])
		{
		push (@outputFile, "note ".$alias[$i]." ".
				$comment[$i]."\n");
		}
	}


foreach my $listAlias (keys %listMember)
      {
      chop $listMember{$listAlias};  # get rid of trailing comma
	push (@outputFile, "alias ".$listAlias." ".
				$listMember{$listAlias}."\n");
      }


# run $Eudora->scan to resolve list addresses into aliases

my $Eudo = new Mail::Addressbook::Convert::Eudora();
my $raOuputFile = $Eudo->scan(\@outputFile);

return $raOuputFile;	
}


###########################   sub output #######################
sub output

{

my (@outputFile);

my $Genr = shift;
my $raInputArray = shift; # reference to input Input data as an array
my $fileFormat= $Genr->{fileFormat};

unless ($fileFormat eq 'csv' or $fileFormat eq 'tsv')
	{confess "\n Ascii output file format must be specified as 'csv' or 'tsv'\n\n";}

my $Pine = new Mail::Addressbook::Convert::Pine();

my $raPineArray = $Pine->output($raInputArray);

#print "\njhd4455 PINE \n@$raPineArray\n\n";

my $sep = "\t";
$sep = ',' if $fileFormat eq 'csv';

foreach $_ (@$raPineArray)
	{
	#print "JHD53 $_\n";
	next unless /\t/;
	chomp;
	my ($alias,$wholeName,$address,$junk,$comment) =
		split('\t');
	my ($name1,$name2) = split(',',$wholeName);
	$address =~ s/\(|\)//g;
	$address = &addquotes($address)if $address  ;
	$name1 = &addquotes($name1) if $name1 ;
	$name2 = &addquotes($name2) if $name2;
	$comment = &addquotes($comment) if $comment ;
	$alias = &addquotes($alias) ;
	my $holdLine;
	{ local $^W; #turn off warnings
		 $holdLine = join($sep, $address,$name1,$name2,$alias,$comment);
	}
		
	push (@outputFile, $holdLine."\n") if $holdLine =~ /[^"$sep]/;
	}
return \@outputFile;
}

sub addquotes
{
	my $input = shift;
	$input =~ s/"//g;
	return '"'.$input.'"';
}

		

###########################  end sub output #######################
1;