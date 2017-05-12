#!perl

=head2 NAME

003 cleanup script

=head2 Description

Runs through each record in file.
Compares 001 and 003 fields.
Cleans mismatched 003s and outputs to MARC-format file.
Reports unmatched 003s.

=head2 LIMITATIONS

Currently designed to match only DLC, IOrQBI control numbers.
Change those strings to match other needs or add new.

=head2 TO DO

Currently only looks for basic match, ignoring trailing spaces.
Possible future change, remove extra trailing spaces, making 3-4 spaces after all DLC (workaround for cataloging software problem).

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
print ("Welcome to 003 cleanup script\n");

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

#if using MacPerl, set creator and type to BBEdit and Text
if ($^O eq 'MacOS') {
MacPerl::SetFileInfo('R*ch', 'TEXT', $cleanfile);
}


############################################
# Set start time for main calculation loop #
############################################
my $t1 = [Time::HiRes::time()];
my $runningrecordcount=0;
############################################

my $fieldscleaned = 0;
my $cleanedreccount = 0;

#loop through batch file of records
while (my $record = $batch->next()) {
#$reccleaned will be true if 003 is replaced
my $reccleaned = 0;

#get controlno
my $controlno = $record->field('001')->as_string();
my $origfield;
my $field003;
my $before;

if ($record->field('003')) {
$origfield = $record->field('003');
#get 003 field
$field003 = $origfield->as_string();}
#003 did not exist so create placeholder
else {
foreach ($record->fields()) {
$before = $_;
last if ($_->tag() > 003); }
$origfield = MARC::Field->new( '003', ' ' );
$field003 = $origfield->as_string();
}


my $cleaned003data;

#controlno starts with 'a' or spaces then it is LCCN
if ($controlno =~ /^[a\s]\s+\d{8}/) {$cleaned003data = 'DLC    ';}
#controlno starts with 'qbi' then it is QBI
elsif ($controlno =~ /^qbi\d{8}/) {$cleaned003data = 'IOrQBI';}
### Add more here ###
#skip record if the controlno is not one of the above.
else {print "$controlno needs another case\n"; 
#####################################
## Place the following within loop ##
#####################################
$runningrecordcount++;
MARC::BBMARC::counting_print ($runningrecordcount);
#####################################

next;}

#normalize $field003 by removing trailing spaces
$field003 =~ s/\s*$//;
#create temp var to compare with $field003, removing trailing spaces from $cleaned003data
my $cleaned003 = $cleaned003data;
$cleaned003 =~ s/\s*$//;

#ignore good 003 field
if ($field003 eq $cleaned003) {

#####################################
## Place the following within loop ##
#####################################
$runningrecordcount++;
MARC::BBMARC::counting_print ($runningrecordcount);
#####################################

next;}

#add new 003 (did not exist before) with $cleaned003data
elsif ($before) {
my $newfield = MARC::Field->new('003', $cleaned003data);
$record->insert_fields_before($before, $newfield);
$reccleaned = 1;
$fieldscleaned++;
} #elsif

#replace bad 003 field (that existed) with $cleaned003data
else {
my $newfield = MARC::Field->new('003', $cleaned003data);
$origfield->replace_with($newfield);
$reccleaned = 1;
$fieldscleaned++;
} #else


#print cleaned record if it has changed
if ($reccleaned) {print CLEANOUT ($record->as_usmarc());
$cleanedreccount++;}

#####################################
## Place the following within loop ##
#####################################
$runningrecordcount++;
MARC::BBMARC::counting_print ($runningrecordcount);
#####################################
} #while records are in infile

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