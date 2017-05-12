#!perl

=head2 NAME

Lintallchecks -- Uses MARC::Lint, MARC::Lintadditions, and MARC::Errorchecks 
to look for MARC21, AACR2/LCRI coding problems in a file of MARC21 records.

=head2 DESCRIPTION

Lint test program prompts for input file of MARC records.
Compares the records against coding definitions in Lint module.
Also checks against added checks in MARC::Lintadditions.
Also checks for errors in multiple fields (vs. individual fields covered by Lint/Lintadditions.
Writes out one file: 
lintwarnings.txt (reported warnings and associated control numbers and titles, tab separation)
Differs from linttest.pl (lintcheck.txt) by not outputting raw MARC.
Differs from lintcheck2.pl by outputting only one file 
(vs. separate warnings and control no files),
and in checking additional conditions given in Lintadditions.pm.
Differs from lintwithadditions.pl in that it incorporates checks which cross multiple fields (such as validation of 008, which requires access to the leader).
This code is based on Example V3 of the MARC::Doc::Tutorial, and incorporates code from the following (available on my Web site):

003cleanupscript.pl
008checker.pl
010cleanup.pl
checkcipforstockno.pl
findmultiplespacesafter010.pl

It uses the MARC::Errorchecks module for checking code not covered in MARC::Lint or MARC::Lintadditions.

=head2 REQUIREMENTS

MARC::Record
MARC::Lintadditions
MARC::Errorchecks
MARC::BBMARC (for interface--timing code)

=head2 TO DO

Improve interface, particularly file name input.

For users of this script: Modify section on which errors not to report.

=cut

###########################
### Initialize includes ###
### and basic needs     ###
###########################
use strict;
use MARC::Batch;
use MARC::Lintadditions;
use MARC::Errorchecks;
use MARC::BBMARC;

##########################
## Time coding routines ##
## Print start time and ##
## set start variable   ##
##########################

use Time::HiRes qw(  tv_interval );
# measure elapsed time 
my $t0 = [Time::HiRes::time()];
my $startingtime = MARC::BBMARC::startstop_time();
#########################
### Start main program ##
#########################

print ("Welcome to Lint All Checks\n");

##### File handling initialization ######
#prompt for input file
print ("What is the input file? ");
my $inputfile=<>;
chomp $inputfile;
$inputfile =~ s/^\"(.*)\"$/$1/;
print ("What is the export file? ");
my $exportfile = <>;
chomp $exportfile;
$exportfile =~ s/^\"(.*)\"$/$1/;
#protect against overwriting input file
if ($inputfile =~ /^\Q$exportfile\E$/i) {
	print "Input file and export file are identical.\nProgram will exit now. Press Enter to continue\n";
	<>;
	die;
}
#check to see if export file exists
if (-f $exportfile) {
	print "That file, $exportfile exists already.\nOverwrite? ";
	my $continue = <>;
	chomp $continue;
	unless ($continue =~ /^y(es)?$/i) {
	#exit program if user typed anything other than y or yes (in any cap)
		print "Exiting (press Enter)\n"; <>; die;
	}
}
open(OUT, ">$exportfile") or die "Can not open $exportfile, $!";

#if using MacPerl, set creator and type to BBEdit and Text
if ($^O eq 'MacOS') {
MacPerl::SetFileInfo('R*ch', 'TEXT', $exportfile);
}

#initialize $batch as new MARC::Batch object
my $batch = MARC::Batch->new('USMARC', "$inputfile");
########## Start extraction #########

############################################
# Set start time for main calculation loop #
############################################
my $t1 = [Time::HiRes::time()];
my $runningrecordcount=0;
###################################################

my $linter = MARC::Lintadditions->new();

my $counter = 0;
my $errorcount = 0;

while (my $record = $batch->next()) {
	$counter++;
	my @haswarnings = ();
	
	#call MARC::Lintadditions (which also performs MARC::Lint checks)
	$linter->check_record($record);

	#get control number for error reporting
	my $controlno =$record->field('001')->as_string() if $record->field('001');

	my $titlea = $record->field('245')->subfield('a');

	#if controlnumber doesn't exist, report as error and use title
	unless ($controlno) {
		push @haswarnings, "001: Control number field not found.";
		$controlno = $titlea;
	} #unless controlno was found
	
	# Retrieve errors that were found by Lint and Lintadditions
	push @haswarnings, ($linter->warnings());

	#call MARC::Errorchecks
	my @errorstoreturn = ();
	push @errorstoreturn, (@{MARC::Errorchecks::check_all_subs($record)});

	#Remove unwanted warnings
	# e.g.
	my @errstoreturn = grep {$_ !~ /(has non\-digits)|(Record is coded level 1)|(Record is coded level 2)/} @errorstoreturn;

	#add MARC::Errorchecks warnings to those found by Lint and Lintadditions

	push @haswarnings, @errstoreturn;
if (@haswarnings){
print OUT join( "\t", "$controlno", "$titlea", @haswarnings, "\t\n");
$errorcount++
}
###################################################
### add to count for user notification ###
$runningrecordcount++;
MARC::BBMARC::counting_print ($runningrecordcount);
###################################################
} # while

close $inputfile;
close OUT;

print "$counter records scanned\n$errorcount errors found\n";
##########################
### Main program done.  ##
### Report elapsed time.##
##########################

my $elapsed = tv_interval ($t0);
my $calcelapsed = tv_interval ($t1);
print sprintf ("%.4f %s\n", "$elapsed", "seconds from execution\n");
print sprintf ("%.4f %s\n", "$calcelapsed", "seconds to calculate\n");
my $endingtime = MARC::BBMARC::startstop_time();
print "Started at $startingtime\nEnded at $endingtime";


print "\n\nPress Enter to quit";
<>;


#####################
### END OF PROGRAM ##
#####################

=head1 LICENSE

This code may be distributed under the same terms as Perl itself. 

Please note that this code is not a product of or supported by the 
employers of the various contributors to the code.

=head1 AUTHOR

Bryan Baldus
eijabb@cpan.org

Copyright (c) 2003-2004

=cut