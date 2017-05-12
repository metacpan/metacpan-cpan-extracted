#!perl

=head2 NAME

Language Code List Cleanup

=head2 DESCRIPTION

Reads MARC code list for languages (plain text--ASCII version L<http://www.loc.gov/marc/>).
Writes only codes and language name, separated by tab.
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

print ("Welcome to Language Code List Cleanup\n");

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
#only lines with at least 19 spaces are of interest
if ($line =~ /[a-z]{3}( {19} *)/) {
#put code and language name in separate spots
my @code_lang = split $1, $line;
my $langcode = $code_lang[0];
my $language = $code_lang[1];

#check for obsolete code
# invalid codes go into %invalidcodes hash
if ($langcode =~ /^-/) {
$langcode =~ s/-//;
$invalidcodes{$language} = $langcode;

push @obsoletelines, join "\t", @code_lang;
} 

# valid codes go into %validcodes hash

else {
$validcodes{$language} = $langcode;
print OUT "$langcode\t$language\n";}
} # if line has 3 characters 19 or more spaces

$linecount++;
} # while reading lines


print OUT join "\n", @obsoletelines, "\n";
print OUT "-"x20, "\nObsolete\tNew\tLanguage\n", "-"x20, "\n";
foreach my $lang (sort keys %invalidcodes) {
print OUT "$invalidcodes{$lang}\t$validcodes{$lang}\t$lang\n";
}

print OUT "\n__LanguageCodes__\n"; 

#print tab-separated line of all valid codes
foreach my $key (sort keys %validcodes) {
print OUT $validcodes{$key}, "\t";
}
print OUT "\n__ObsoleteLanguageCodes__\n"; 
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