#!/usr/local/perl -w

=Head1 INFORMATION 

testHarness.pl

Distributed as part of Mail::Addressbook::Convert


Copyright (c) 2001 Joe Davidson. All rights reserved.
This program is free software; you can redistribute it 
and/or modify it under the terms of the Perl Artistic License
(see http://www.perl.com/perl/misc/Artistic.html). or the
GPL copyleft license ( http://www.gnu.org/copyleft/gpl.html) 

=cut

#use strict;

use lib ("..","t");
use Test::Simple tests => 9;


my $rundir = "t/";
my $holdir = "hold/";

{ # isolate all data for this test

##  TEST 1, Convert to and from Ldif, using Ldif.pm

        use Mail::Addressbook::Convert::Ldif;

	my $LDIF = new Mail::Addressbook::Convert::Ldif();

	my $LdifInFile  = $rundir."ldifSample.txt";  # name of the file containing the Ldif data
	
	# Convert Ldif to Standard Intermediate format
	# see documentation for details on format.
	my $raIntermediate = $LDIF->scan(\$LdifInFile);  
	
	# Convert back to Ldif
	my $raLdifOut = $LDIF->output($raIntermediate);
	my $ldifOutput = join('', @$raLdifOut);
	#print $ldifOutput."\n\n";
	
####################  temporary	to develop expected output
if (0){	
	#print $ldifOutput;
	local *FH1;
	open (FH1, ">".$holdir."expectedOutputFromLdifTest.txt") or die $!;
	print FH1 $ldifOutput;
	close FH1;
}
######################  end temporary
	local *FH;
	
	my $expectedOutputFromLdifTest = "";
	{ 
		local $/;
		$expectedOutputFromLdifTest = <FH>
			if (open (FH, $rundir."expectedOutputFromLdifTest.txt"));
		close FH;
	}
	$ldifOutput =~ s/\r|\n//g;  # get rid of CRs and LFs
	#print $ldifOutput."\n\n";
	#print "\n ----- \n";
	$expectedOutputFromLdifTest =~ s/\r|\n//g;  # get rid of CRs and LFs
	#print $expectedOutputFromLdifTest;

	ok ($ldifOutput eq $expectedOutputFromLdifTest, "Ldif Test");
}

{ # isolate all data for this test

##  TEST 2, Convert to and from Eudora, using Eudora.pm

        use Mail::Addressbook::Convert::Eudora;

	my $EUDORA = new Mail::Addressbook::Convert::Eudora();

	my $EudoraInFile  =$rundir."EudoraSampleFile.txt";  # name of the file containing the Eudora data
	
	# Convert Ldif to Standard Intermediate format
	# see documentation for details on format.
	my $raIntermediate = $EUDORA->scan(\$EudoraInFile);  
	
	# Convert back to Ldif
	my $raEudoraOut = $EUDORA->output($raIntermediate);
	my $eudoraOutput = join('', @$raEudoraOut);

####################  temporary	to develop expected output
if (0){	
	#print $eudoraOutput;
	local *FH1;
	open (FH1, ">".$holdir."expectedOutputFromEudoraTest.txt") or die $!;
	print FH1 $eudoraOutput;
	close FH1;
}
######################  end temporary

	local *FH;
	
	my $expectedOutputFromEudoraTest = "";
	{ 
		local $/;
		$expectedOutputFromEudoraTest = <FH>
			if (open (FH, $rundir."expectedOutputFromEudoraTest.txt"));
		close FH;
	}
	$eudoraOutput =~ s/\r//g;  # get rid of CRs and LFs
	$expectedOutputFromEudoraTest =~ s/\r//g;  # get rid of CRs and LFs
	ok ($eudoraOutput eq $expectedOutputFromEudoraTest, "Eudora Test");
}


{ # isolate all data for this test

##  TEST 3, Convert to and from Pine, using Pine.pm

        use Mail::Addressbook::Convert::Pine;

	my $PINE = new Mail::Addressbook::Convert::Pine();

	my $PineInFile  =$rundir."pineSample.txt";  # name of the file containing the Pine data
	
	# Convert Pine to Standard Intermediate format
	# see documentation for details on format.
	my $raIntermediate = $PINE->scan(\$PineInFile);  
	
	# Convert back to Pine
	my $raPineOut = $PINE->output($raIntermediate);
	my $pineOutput = join('', @$raPineOut);
	#print @$raPineOut;
	
####################  temporary	to develop expected output
if (0){	
	#print $pineOutput;
	local *FH1;
	open (FH1, ">".$holdir."expectedOutputFromPineTest.txt") or die $!;
	print FH1 $pineOutput;
	close FH1;
}
######################  end temporary
	local *FH;
	
	my $expectedOutputFromPineTest = "";
	{ 
		local $/;
		$expectedOutputFromPineTest = <FH>
			if (open (FH, $rundir."expectedOutputFromPineTest.txt"));
		close FH;
	}
	$pineOutput =~ s/\r//g;  # get rid of CRs and LFs
	$expectedOutputFromPineTest =~ s/\r//g;  # get rid of CRs and LFs
	ok ($pineOutput eq $expectedOutputFromPineTest, "Pine Test");
}

{ # isolate all data for this test

##  TEST 4, Convert to and from Csv, using Csv.pm

        use Mail::Addressbook::Convert::Csv;

	my $CSV = new Mail::Addressbook::Convert::Csv();

	my $CsvInFile  =$rundir."csvSample.txt";  # name of the file containing the csv data
	
	# Convert Csv to Standard Intermediate format
	# see documentation for details on format.
	my $raIntermediate = $CSV->scan(\$CsvInFile);  
	
	# Convert back to Csv
	my $raCsvOut = $CSV->output($raIntermediate);
	my $csvOutput = join('', @$raCsvOut);
	#print @$csvOutput;
	
####################  temporary	to develop expected output
if (0){	
	#print $csvOutput;
	local *FH1;
	open (FH1, ">".$holdir."expectedOutputFromCsvTest.txt") or die $!;
	print FH1 $csvOutput;
	close FH1;
}
######################  end temporary
	
	local *FH;
	
	my $expectedOutputFromCsvTest = "";
	{ 
		local $/;
		$expectedOutputFromCsvTest = <FH>
			if (open (FH, $rundir."expectedOutputFromCsvTest.txt"));
		close FH;
	}
	$csvOutput =~ s/\r//g;  # get rid of CRs and LFs
	$expectedOutputFromCsvTest =~ s/\r//g;  # get rid of CRs and LFs
	ok ($csvOutput eq $expectedOutputFromCsvTest, "Csv Test");
}

{ # isolate all data for this test

##  TEST 5, Convert to and fromTsv, using Tsv.pm

        use Mail::Addressbook::Convert::Tsv;

	my $TSV = new Mail::Addressbook::Convert::Tsv();

	my $TsvInFile  =$rundir."tsvSample.txt";  # name of the file containing the Tsv data
	
	# Convert Tsv to Standard Intermediate format
	# see documentation for details on format.
	my $raIntermediate = $TSV->scan(\$TsvInFile);  
	
	# Convert back to Tsv
	my $raTsvOut = $TSV->output($raIntermediate);
	my $tsvOutput = join('', @$raTsvOut);
	
####################  temporary	to develop expected output
if (0){	
	#print $tsvOutput;
	local *FH1;
	open (FH1, ">".$holdir."expectedOutputFromTsvTest.txt") or die $!;
	print FH1 $tsvOutput;
	close FH1;
}
######################  end temporary
	
	local *FH;
	
	my $expectedOutputFromTsvTest = "";
	{ 
		local $/;
		$expectedOutputFromTsvTest = <FH>
			if (open (FH, $rundir."expectedOutputFromTsvTest.txt"));
		close FH;
	}
	$tsvOutput =~ s/\r//g;  # get rid of CRs and LFs
	$expectedOutputFromTsvTest =~ s/\r//g;  # get rid of CRs and LFs
	ok ($tsvOutput eq $expectedOutputFromTsvTest, "Tsv Test");
}

{ # isolate all data for this test

##  TEST 6, Convert  from mailrc, using Mailrc.pm

        use Mail::Addressbook::Convert::Mailrc;

	my $MAILRC = new Mail::Addressbook::Convert::Mailrc();

	my $MailrcInFile  =$rundir."mailrcSample.txt";  # name of the file containing the mailrc data
	
	# Convert Mailrc to Standard Intermediate format
	# see documentation for details on format.
	my $raIntermediate = $MAILRC->scan(\$MailrcInFile);  
	

	my $intermediateOutput = join('', @$raIntermediate);
	
	
####################  temporary	to develop expected output
if (0){	
	#print $intermediateOutput;
	local *FH1;
	open (FH1, ">".$holdir."expectedOutputFromMailrcTest.txt") or die $!;
	print FH1 $intermediateOutput;
	close FH1;
}
######################  end temporary

	local *FH;
	
	my $expectedOutputFromMailrcTest = "";
	{ 
		local $/;
		$expectedOutputFromMailrcTest = <FH>
			if (open (FH, $rundir."expectedOutputFromMailrcTest.txt"));
		close FH;
	}
	$intermediateOutput =~ s/\r//g;  # get rid of CRs and LFs
	$expectedOutputFromMailrcTest =~ s/\r//g;  # get rid of CRs and LFs
	ok ($intermediateOutput eq $expectedOutputFromMailrcTest, "Mailrc Test");
}

{ # isolate all data for this test

##  TEST 7, Convert  from ccMail, using Ccmail.pm

        use Mail::Addressbook::Convert::Ccmail;

	my $Ccmail = new Mail::Addressbook::Convert::Ccmail();

	my $CcmailInFile  =$rundir."ccmailSample.txt";  # name of the file containing the ccMail data
	
	# Convert Ccmail to Standard Intermediate format
	# see documentation for details on format.
	my $raIntermediate = $Ccmail->scan(\$CcmailInFile);  
	

	my $intermediateOutput = join('', @$raIntermediate);


####################  temporary	to develop expected output
if (0){	
	#print $intermediateOutput;
	local *FH1;
	open (FH1, ">".$holdir."expectedOutputFromCcMailTest.txt") or die $!;
	print FH1 $intermediateOutput;
	close FH1;
}
######################  end temporary
	
	local *FH;
	
	my $expectedOutputFromCcMailTest = "";
	{ 
		local $/;
		$expectedOutputFromCcMailTest = <FH>
			if (open (FH, $rundir."expectedOutputFromCcMailTest.txt"));
		close FH;
	}
	$intermediateOutput =~ s/\r//g;  # get rid of CRs and LFs
	$expectedOutputFromCcMailTest =~ s/\r//g;  # get rid of CRs and LFs
	ok ($intermediateOutput eq $expectedOutputFromCcMailTest, "ccMail Test");
}

{ # isolate all data for this test

##  TEST 8, Convert  from Spry, using Spry.pm

#  No Spry addressbook available now.  This is a placeholder

ok (1, "Spry Test");

}

{ # isolate all data for this test

##  TEST 9, Convert  to and from from Pegasus, using Pegasus.pm

use Mail::Addressbook::Convert::Pegasus;


my $Pegasus = new Mail::Addressbook::Convert::Pegasus();



my $PegasusAddr1InFile  =$rundir."PegasusAddr1Sample.txt";  # name of a file containing the Pegasus  Addressbook data

my $PegasusAddr2InFile  =$rundir."PegasusAddr2Sample.txt";  # name of a file containing the Pegasus  Addressbook data

my $PegasusDist1InFile  =$rundir."LIST5029.PML";  # name of the file containing the a distribution list data

my $PegasusDist2InFile  =$rundir."LIST4C76.PML";  # name of the file containing the a distribution list data

#convert from Pegasus to intermediate format.
my $raIntermediate = $Pegasus->scan( [\$PegasusAddr1InFile, \$PegasusAddr2InFile],  [\$PegasusDist1InFile, \$PegasusDist2InFile ]);  

#convert from Intermediate format back to Pegausus
my @raPegasus = $Pegasus->output($raIntermediate);  # reference to an array containing a intermediate addressbook
	
my @mainAddressbook = @{$raPegasus[0]};

my @PegasusTestFile = @mainAddressbook;

my @distListArrayRefs = @{$raPegasus[1]};


my $numberOfDistLists = @distListArrayRefs;
;

my @distListArrayNames = @{$raPegasus[2]};

foreach my $i (0..$numberOfDistLists-1)
{
	my $DistListName = $distListArrayNames[$i];
	my @DistList = @{$distListArrayRefs[$i]};
	push @PegasusTestFile, $DistListName ."\n", @DistList;
}

my $PegOut = join "", @PegasusTestFile;
	
####################  temporary	
if (0){	
	
	local *FH1;
	open (FH1, ">expectedOutputFromPegasusTest.txt") or die $!;
	print FH1 $PegOut;
	close FH1;
}
######################  end temporary
	local *FH;
	
	my $expectedOutputFromPegasusTest = "";
	{ 
		local $/;
		$expectedOutputFromPegasusTest = <FH>
			if (open (FH, $rundir."expectedOutputFromPegasusTest.txt"));
		close FH;
	}
	$PegOut =~ s/\r//g;  # get rid of CRs and LFs
	$expectedOutputFromPegasusTest =~ s/\r//g;  # get rid of CRs and LFs
	ok ($PegOut eq $expectedOutputFromPegasusTest, "Pegasus Test");
}

