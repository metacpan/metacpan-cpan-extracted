#!perl

=head2 NAME

007 cleanup script

=head2 Description

Runs through each record in file.
Calls subroutine to check validity of each 007 value.
Reports any records needing manual correcting (outputs these to file). Cleans fields with valid values, but that are too long, and outputs these to separate file.

Both output files are USMARC/MARC21 format.

=cut

########################
### Program template ###
########################
###########################
### Initialize includes ###
### and basic needs     ###
###########################
use MARC::Batch;
use MARC::BBMARC;
use MARC::Lintadditions;
##Time coding to wrap around program to determine how long execution takes:

##########################
## Time coding routines ##
## Print start time and ##
## set start variable   ##
##########################

use Time::HiRes qw(  tv_interval );
# measure elapsed time 
my $t0 = [Time::HiRes::time()];
my $startingtime = MARC::BBMARC::startstop_time();
# do bunch of stuff here
#########################
### Start main program ##
#########################
print ("Welcome to 007 cleanup script\n");

##### File handling initialization ######
#prompt for updated file
print ("What is the input file?: ");
my $inputfile=<>;
chomp $inputfile;
$inputfile =~ s/^\"(.*)\"$/$1/;
#initialize $infile as new MARC::Batch object
my $batch = MARC::Batch->new('USMARC', "$inputfile");

print ("Export file for cleaned records\n");
print ("Export record file: ");
#read command line for name of export file
my $cleanfile= <>;
chomp $cleanfile;
$cleanfile =~ s/^\"(.*)\"$/$1/;
open(CLEANOUT, ">$cleanfile") or die "cannot open Cleanout\n";
if ($^O eq 'MacOS') {
#set creator and type to BBEdit and Text
MacPerl::SetFileInfo('R*ch', 'TEXT', $cleanfile);
}

print ("Export file for manual check records\n");
print ("Manual check record file: ");
my $badfieldfile = <>;
chomp $badfieldfile;
$badfieldfile =~ s/^\"(.*)\"$/$1/;
open(VISUALIZEOUT, ">$badfieldfile") or die "cannot open Badfieldfile\n";
if ($^O eq 'MacOS') {
#set creator and type to BBEdit and Text
MacPerl::SetFileInfo('R*ch', 'TEXT', $badfieldfile);
}

############################################
# Set start time for main calculation loop #
############################################
my $t1 = [Time::HiRes::time()];
my $runningrecordcount=0;
############################################

my $fieldscleaned = 0;
my $badbytecount = 0;
my $visualizecount = 0;
my $cleanedreccount = 0;

#loop through batch file of records
while (my $record = $batch->next()) {
#$reccleaned will be true if 007 is replaced
my $reccleaned = 0;
#$badrecord will be true if bytes have 'bad' or if data exists after limit
my $badrecord;

#look at each 007 field in record
foreach my $field ( $record->field('007') ) {
my $field007 = $field->as_string();
my @bytes = (split ('', $field007));

#clean byte[2] before passing (change 'u' or '|' to blank space)
$bytes[2] =~ s/[u|]/ /;
#call validate007 sub, which is part of Lintadditions
#The sub returns an arrayref and a scalarref
my ($arrayref007, $hasextradataref)  = MARC::Lintadditions::validate007(\@bytes);

#dereference the returned values
my @cleaned007 = @$arrayref007;
#loop through the array looking for bad bytes
for (my $i = 0 ; $i <= $#cleaned007; $i++) {
if ($cleaned007[$i] eq 'bad'){
#set marker for printing bad record
$badrecord = 1;
$badbytecount++;
} #if bad byte
} #for each byte

#check for data after valid limit
if ($$hasextradataref) {
#set marker for printing bad record
$badrecord = 1;
$visualizecount++;
}

#unless badrecord was found, replace old 007 with new
#also ignore 007s that didn't have extra spaces
unless ($badrecord) {
my $cleaned007data = join ('', @cleaned007);
#ignore good 007 fields
if ($field007 eq $cleaned007data) {next;}
else {
my $newfield = MARC::Field->new('007', $cleaned007data);
$field->replace_with($newfield);
$reccleaned = 1;
$fieldscleaned++;
} #else
} #unless

} #for each 007 field

#if bad 007 was found print it out for manual checking
if ($badrecord) {
print VISUALIZEOUT ($record->as_usmarc()); 
}
#otherwise, print cleaned record
elsif ($reccleaned) {print CLEANOUT ($record->as_usmarc());
$cleanedreccount++;}

#####################################
## Place the following within loop ##
#####################################
$runningrecordcount++;
MARC::BBMARC::counting_print ($runningrecordcount);
#####################################
} #while records are in infile

print "$badbytecount total bytes are bad\n";
print "$visualizecount fields have data after limit\n";
print "$fieldscleaned fields were cleaned in $cleanedreccount records\n";

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
print "Press Enter to quit";
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
eija [at] inwave [dot] com

Copyright (c) 2003-2004

=cut