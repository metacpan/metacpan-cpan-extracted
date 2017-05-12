#!perl
=head2

Looks for extra spaces at the end of fields greater than 010.
Removes unnecessary spaces.
Also ignores all 016 fields.
Outputs records that have been cleaned.

=cut

###########################
### Initialize includes ###
### and basic needs     ###
###########################
use strict;
use MARC::Batch;
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

print ("Welcome to trailing spaces cleanup\n");

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
#if using MacPerl, set creator and type to BBEdit and Text
if ($^O eq 'MacOS') {
MacPerl::SetFileInfo('R*ch', 'TEXT', $exportfile);
}



#initialize $infile as new usmarc file object
my $batch = MARC::Batch->new('USMARC', "$inputfile");
########## Start extraction #########

############################################
# Set start time for main calculation loop #
############################################
my $t1 = [Time::HiRes::time()];
my $runningrecordcount=0;
###################################################
#initialize counting and notification variables
my $fieldcleanedcount = 0;
my $cleanedreccount=0;
#### Start while loop through records in file #####
while (my $record = $batch->next()) {
#new record so reset $recordchanged
my $recordchanged = 0;

#look at each field in record
foreach my $field ($record->fields()) {
#skip control fields and LCCN (010)
next if ($field->tag()<=10);
next if ($field->tag() == 16);
#create array holding arrayrefs for subfield code and data
my @subfields= $field->subfields();

#look at data in last subfield
my $lastsubfield = pop (@subfields);

#each $subfield is an array ref containing a subfield code character and subfield data
my ($code, $data) = @$lastsubfield;

#look for one or more instances of spaces at end of subfield data
if ($data =~ /\s+$/) {
#field had extra spaces
#declare array to store subfields after cleaning the last one
my @newSubfields = ();

#remove all extra white space at end of data
$data =~ s/\s*$//;
#put last subfield onto newSubfields array
unshift (@newSubfields, $code, $data);

#put the rest of the subfields onto @newSubfields
while (my $subfield = pop (@subfields)) {
my ($code, $data) = @$subfield;
unshift (@newSubfields, $code, $data);
}

$fieldcleanedcount++;
#replace field in $record
my $newfield = MARC::Field->new (
$field->tag(),
$field->indicator(1),
$field->indicator(2),
@newSubfields
);

$field->replace_with($newfield);
$recordchanged = 1;

} #if had spaces
} # foreach field

if ($recordchanged) {print OUT $record->as_usmarc;
$cleanedreccount++;
}
###################################################
### add to count for user notification ###
$runningrecordcount++;
MARC::BBMARC::counting_print ($runningrecordcount);
###################################################
} # while

close $inputfile;
close OUT;
print "$fieldcleanedcount fields cleaned\n";
print "$cleanedreccount records cleaned in $runningrecordcount records scanned\n";

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
eija [at] inwave [dot] com

Copyright (c) 2003-2004

=cut