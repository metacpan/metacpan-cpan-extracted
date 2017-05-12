#!perl

=head2 NAME

Geographic Area Code List Cleanup

=head2 DESCRIPTION

Reads MARC code list for geographic area codes (plain text).
Writes only codes and country (or other place) name, separated by tab.
For obsolete codes, adds these at end of output file (keeping the hyphen).

=head2 TO DO

Rewrite code to account for split lines (language name too long to fit on one line, so it is split onto another, possibly during save from Web browser.
Easier to take care of these exceptions manually, as there are only a few and the code list shouldn't need to be changed very often.

=cut

###########################
### Initialize includes ###
### and basic needs     ###
###########################
use strict;
#use Sort::Fields;
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

print ("Welcome to Geographic Area Code List Cleanup\n");

##### File handling initialization ######
#prompt for input file
print ("What is the input file? ");
my $inputfile=<>;
chomp $inputfile;
$inputfile =~ s/^\"(.*)\"$/$1/;
open (IN, "<$inputfile") or die "Can not open $inputfile";
print ("What is the export file? ");
my $exportfile = <>;
chomp $exportfile;
$exportfile =~ s/^\"(.*)\"$/$1/;
open(OUT, ">$exportfile") or die "Can not open $exportfile";

#if using MacPerl, set creator and type to BBEdit and Text
if ($^O eq 'MacOS') {
MacPerl::SetFileInfo('R*ch', 'TEXT', $exportfile);

}


########## Start extraction #########

############################################
# Set start time for main calculation loop #
############################################
my $t1 = [Time::HiRes::time()];
my $runningrecordcount=0;
###################################################

#### Start while loop through records in file #####

my @obsoletelines = ();
my $linecount = 0;
my %validcodes;
my %invalidcodes;
while (my $line = <IN>) {
chomp $line;
#only lines with at least 16 spaces are of interest
if ($line =~ /[a-z]+( {16} *)/) {
#put code and language name in separate spots
my @code_geogarea = split $1, $line;
my $geogareacode = $code_geogarea[0];
my $geogarea = $code_geogarea[1];

#check for obsolete code
# invalid codes go into %invalidcodes hash
if ($geogareacode =~ /^-/) {
$geogareacode =~ s/^-//;
#add extra spaces to end of short codes
if (length ($geogareacode < 7)) {$geogareacode .= "-"x(7-length ($geogareacode))}

$invalidcodes{$geogarea} = $geogareacode;

push @obsoletelines, join "\t", "-$geogareacode", $geogarea;
} 

# valid codes go into %validcodes hash

else {
#add extra spaces to end of short codes
if (length ($geogareacode < 7)) {$geogareacode .= "-"x(7-length ($geogareacode))}

$validcodes{$geogarea} = $geogareacode;
print OUT "$geogareacode\t$geogarea\n";}
} # if line has 2 characters 4 or more spaces

$linecount++;
} # while reading lines


print OUT join "\n", @obsoletelines, "\n";
print OUT "-"x20, "\nObsolete\tNew\tCountry\n", "-"x20, "\n";
foreach my $geogarea (sort keys %invalidcodes) {
print OUT "$invalidcodes{$geogarea}\t$validcodes{$geogarea}\t$geogarea\n";
}
print OUT "\n__GeogAreaCodes__\n"; 

#print tab-separated line of all valid codes
foreach my $key (sort keys %validcodes) {
print OUT $validcodes{$key}, "\t";
}
print OUT "\n__ObsoleteGeogAreaCodes__\n"; 
#print tab-separated line of all invalid codes
foreach my $key (sort keys %invalidcodes) {
print OUT $invalidcodes{$key}, "\t";
}

print "$linecount lines cleaned\n";

close IN;
close OUT;
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