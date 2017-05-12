#!perl

=head2 NAME

010 cleanup -- Fixes spacing problems in 010 subfield a.

=head2 DESCRIPTION

This version will clean only subfield 'a' of 010 and skips records which have no 010 and those that have no 010 subfield 'a'

=head2 OUTLINE OF PROCESS

Get subfield 'a', remove non-digits.
If result is exactly 8 digits, substr(result, 0, 2) >=70 or =00 or error.
New field a = '   result '
If result is exactly 10 digits, substr(result, 0, 4) >=2001 and <= 2010 (will change as year changes) or error.
New field a = '  result'
Compare new field a with existing field a and report only those that differ.


=head2 TO DO

Think about whether subfield 'z' needs extra spaces removed.

Deal with non-digit characters in original 010a field.
Currently these are simply reported and the record is skipped.

=cut

###########################
### Initialize includes ###
### and basic needs     ###
###########################
use strict;
use MARC::Batch;
#use MARC::File::USMARC;
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

print ("Welcome to 010 cleanup\n");

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
open(OUT, ">$exportfile");
print ("What is the error file? ");
my $errorfile = <>;
chomp $errorfile;
$errorfile =~ s/^\"(.*)\"$/$1/;
open(ERRORS, ">$errorfile");

#if using MacPerl, set creator and type to BBEdit and Text
if ($^O eq 'MacOS') {
MacPerl::SetFileInfo('R*ch', 'TEXT', $exportfile);
MacPerl::SetFileInfo('R*ch', 'TEXT', $errorfile);

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
my $cleanedreccount=0;
#### Start while loop through records in file #####
while (my $record = $batch->next()) {

###################################################
### add to count for user notification ###
$runningrecordcount++;
MARC::BBMARC::counting_print ($runningrecordcount);
###################################################
##############################################
## Declare variables needed for each record ##
##############################################
my $recordchanged = 0;
# predeclare $controlno for reporting errors
my $controlno;
# $field_010 will have MARC::Field version of the 010 field of the record
my $field_010;
#$cleaned010a will have the finished cleaned 010a data
my $cleaned010a;
# $haserrors will have tab-separated string of errors
my $haserrors = "";

#skip records with no 010 and no 010$a
unless (($record->field('010')) && ($record->field('010')->subfield('a'))) {next;}

# record has an 010 with subfield a, so check for errors and then do cleanup
else {
#get record control number for reporting errors
$controlno = $record->field('001')->as_string();

$field_010 = $record->field('010');
my $orig010a = $field_010->subfield('a');
my $subfielda = $field_010->subfield('a');

#Get number portion of subfield
$subfielda =~ s/\D*(\d{8,10})\D*/$1/;
#report error if 8-10 digit number was not found
unless ($1) {$haserrors .= "$controlno\tCould not find an 8-10 digit number in $subfielda\t"}
#######################################################
# LCCN validity checks and setting of cleaned version # 
#######################################################
#check validity of resulting digits
if ($subfielda =~ /^\d{8}$/) {
my $year = substr($subfielda, 0, 2);
#should be old lccn, so first 2 digits are 00 or > 80 (for QBI records)
if (($year >= 1) && ($year < 80)) {$haserrors .= "$controlno\tFirst digits of lccn are $year\t"}
#otherwise, 8 digit lccn needs 3 spaces before, 1 after, so put that in $cleaned010a
else {
$cleaned010a = "   $subfielda ";
} #else $subfielda has valid lccn
} #if lccn is 8 digits

#otherwise if $subfielda is 10 digits
elsif ($subfielda =~ /^\d{10}$/) {
my $year = substr($subfielda, 0, 4);
# no valid 10 digit will be less than 2001
# change upper limit as years progress
if (($year < 2001) || ($year > 2006)) {$haserrors .= "$controlno\tFirst digits of lccn are $year\t";}
#otherwise, 10 digit lccn needs 2 spaces before, 0 after, so put that in $cleaned010a
else {
$cleaned010a = "  $subfielda";
} #else $subfielda has valid lccn
} #if lccn is 10 digits

# lccn is not 8 or 10 digits so report error
else {$haserrors .= "$controlno\tLCCN $subfielda is not 8 or 10 digits\t";}

#report errors in validity of LCCNs
if ($haserrors) {print ERRORS "Original 010\t$orig010a\tvalidity errors:\t$haserrors\n"; next;}

###########################################
### Compare cleaned field with original ###
###########################################

#if original and cleaned match, go to next record
if ($orig010a eq $cleaned010a) {next;}

#if cleaned version does not match original, replace old with cleaned
else {
#but only if $orig010a has no non-digitchars
#### Work on this code so that non-digit characters are not a problem.
if ($orig010a !~ /^[ \d]*$/) {print ERRORS "$controlno\t010\t$orig010a\thas non-digits\n"; next;}

my @subfields = $field_010->subfields();
my @newsubfields = ();

#break subfields into code-data array (so the entire field is in one array)
while (my $subfield = pop(@subfields)) {
my ($code, $data) = @$subfield;
#replace subfield a with cleaned data
if ($code eq 'a') {$data = $cleaned010a}
unshift (@newsubfields, $code, $data);
} # while subfields

#replace field in $record
my $newfield = MARC::Field->new (
$field_010->tag(),
$field_010->indicator(1),
$field_010->indicator(2),
@newsubfields
);

$field_010->replace_with($newfield);
$recordchanged = 1;
} #else old differs
if ($recordchanged) {print OUT $record->as_usmarc;
$cleanedreccount++;

####for program debugging and testing####
print ERRORS "$controlno cleaned from\t$orig010a\tto\t$cleaned010a\n";
}
} # else record has 010subfielda

} # while records

close $inputfile;
close OUT;
print "$cleanedreccount records cleaned\n";
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

if ($^O eq 'MacOS') {
#set creator and type to BBEdit and Text
MacPerl::SetFileInfo('R*ch', 'TEXT', $exportfile);
}

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
eija [at] inwave [dot] com

Copyright (c) 2003-2004

=cut