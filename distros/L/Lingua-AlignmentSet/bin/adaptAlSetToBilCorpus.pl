#! /usr/local/bin/perl

########################################################################
# Author:  Patrik Lambert (lambert@talp.ucp.es)
# Description: converts an alignment set to NAACL or BLINKER format
#
#-----------------------------------------------------------------------
#
#  Copyright 2004 by Patrik Lambert
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
########################################################################
use strict;
use Getopt::Long;
use Pod::Usage;
use Lingua::AlignmentSet 1.1;
#Debug:
use Dumpvalue;
my $dumper = new Dumpvalue; 

my $TRUE = 1;
my $FALSE = 0;
my $INFINITY = 9999999999;
my $TINY = 1 - $INFINITY / ($INFINITY + 1);

#PARSING COMMAND-LINE ARGUMENTS
my %opts=();
# optional arguments defaults
$opts{i_format}="TALP";
$opts{o_format}="TALP";
$opts{range}="1-";
$opts{alignMode}="as-is";
$opts{verbose}=0;
$opts{pdiff}=20;
$opts{mindiff}=3;
$opts{maxdiff}=6;
$opts{nfirst}=5;
# parse command line
GetOptions(\%opts,'man','help|?','verbose|v=i','i_sourceToTarget|i_st|ist=s','i_targetToSource|i_ts|its=s','i_source|i_s|is=s','i_target|i_t|it=s','i_format|if=s','o_sourceToTarget|o_st|ost=s','o_targetToSource|o_ts|ots=s','o_source|o_s|os=s','o_target|o_t|ot=s','o_format|of=s','range=s','alignMode=s','corpsrc|cs=s','corptrg|ct=s','pdiff=f','mindiff=i','maxdiff=i','wfirst=i') or pod2usage(0);
# check no required arg missing
if ($opts{man}){
    pod2usage(-verbose=>2);
}elsif ($opts{"help"}){
    pod2usage(0);
}elsif( !(exists($opts{"i_sourceToTarget"}) && exists($opts{"o_sourceToTarget"}) && exists($opts{"corpsrc"}) && exists($opts{"corptrg"})) ){   #required arguments
    pod2usage(-msg=>"Required arguments missing",-verbose=>0);
}
#END PARSING COMMAND-LINE ARGUMENTS

my %restrictions=("allowedPercentWordDiff",$opts{pdiff},"minAllowedNumWordDiff",$opts{mindiff},"maxAllowedNumWordDiff",$opts{maxdiff},"numWordsConsideredFirst",$opts{nfirst});
#load input Alignment Set
my $input = Lingua::AlignmentSet->new([[$opts{i_sourceToTarget},$opts{i_format},$opts{range}]]);
if ( (exists($opts{i_source}) && !exists($opts{i_target})) || (exists($opts{i_target}) && !exists($opts{i_source})) ){
    pod2usage(-msg=>"You must specify both source and target words file.",-verbose=>0);
}elsif(exists($opts{i_source})){
    $input->setWordFiles($opts{i_source},$opts{i_target});
}
if (exists($opts{"i_targetToSource"})){
	$input->setTargetToSourceFile($opts{"i_targetToSource"});	
}
#load output Alignment Set location
my $location;
if ( (exists($opts{o_source}) && !exists($opts{o_target})) || (exists($opts{o_target}) && !exists($opts{o_source})) ){
    pod2usage(-msg=>"You must specify both source and target words file.",-verbose=>0);
}elsif(exists($opts{o_source})){
	$location = {"sourceToTarget"=>$opts{o_sourceToTarget},"source"=>$opts{o_source},"target"=>$opts{o_target}}; 
}else{
	$location = {"sourceToTarget"=>$opts{o_sourceToTarget}}; 
}
if (exists($opts{"o_targetToSource"})){
	$location->{"targetToSource"}=$opts{"o_targetToSource"};	
}
#call library function
$input->adaptToBilCorpus($location,$opts{o_format},$opts{alignMode},$opts{corpsrc},$opts{corptrg},\%restrictions,$opts{verbose});

__END__

=head1 NAME

adaptAlSetToBilCorpus.pl - Looks if the Alignment Set sentence pairs are in another bilingual corpus, and for each sentence pair which is not in the corpus, it searches the corpus sentence pair with best longuest common subsequence (LCS) ratio. Finally, it detects the edits (word insertions, deletions, and substitutions) necessary to pass from the Alignment Set sentences to the corpus sentences with best LCS ratio, prints the edit list and transmits these edits in the output links file.

=head1 SYNOPSIS

perl adaptAlSetToBilCorpus.pl [options] required_arguments

See description in the manual (-man option).

Required arguments:

	-ist FILENAME    Input source-to-target links file
	-if BLINKER|GIZA|NAACL    Input file(s) format (required if not TALP)
	-cs FILENAME    New corpus source text file
        -ct FILENAME    New corpus target text file
	-ost FILENAME    Output source-to-target links file
	-of BLINKER|GIZA|NAACL    Output file(s) format (required if not TALP)


Options:

        -pdiff FLOAT    Percent number of words difference allowed to calculate LCS [default 20]
        -mindiff INT    LCS calculated although word number difference is below mindiff [default 3]
        -maxdiff INT    Maximum number of words difference allowed to calculated LCS [default 6]
        -wfirst INT    Number of words to consider in the first LCS calculation [default 5]
	-is FILENAME    Input source words file
	-it FILENAME    Input target words file
	-its FILENAME Input target-to-source links file
	-os FILENAME    Output source words file
	-ot FILENAME    Output target words file
	-ots FILENAME Output target-to-source links file
	-range BEGIN-END    Input Alignment Set range
	-alignMode as-is|null-align|no-null-align    Alignment mode
	-help|?    Prints the help and exits
	-man    Prints the manual and exits
        -v 0-3    0:silent 1:verbose mode 2,3:debug

=head1 ARGUMENTS

=over 8

=item B<--ist,--i_st,--i_sourceToTarget FILENAME>

Input source-to-target (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--if,--i_format BLINKER|GIZA|NAACL>

Input Alignment Set format (required if different from default, TALP).

=item B<--cs,--corpsrc FILENAME>

New corpus source text file

=item B<--ct,--corptrg FILENAME>

New corpus target text file

=item B<--os,--o_st,--o_sourceToTarget FILENAME>

Output (new format) source-to-target (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--of,--o_format BLINKER|GIZA|NAACL>

Output (new) Alignment Set format (required if different from default, TALP)

=head1 OPTIONS

=item B<--pdiff FLOAT>

Percent number of words difference allowed to calculate LCS [default 20]

=item B<--mindiff INTEGER>

LCS calculated although word number difference is below mindiff [default 3]

=item B<--maxdiff INTEGER>

Maximum number of words difference allowed to calculated LCS [default 6]

=item B<--wfirst INTEGER>

Number of words to consider in the first LCS calculation [default 5]

=item B<--os,--o_s,--o_source FILENAME>

Output (new format) source (words) file name. Not applicable in GIZA Format.

=item B<--ot,--o_t,--o_target FILENAME>

Output (new format) target (words) file name. Not applicable in GIZA Format.

=item B<--ots,--o_ts,--o_targetToSource FILENAME>

Output (new format) target-to-source (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--alignMode as-is|null-align|no-null-align>

Take alignment "as-is" or force NULL alignment or NO-NULL alignment (see AlignmentSet.pm documentation).

=item B<--help, --?>

Prints a help message and exits.

=item B<--man>

Prints a help message and exits.

=head1 DESCRIPTION

This script looks if the Alignment Set sentence pairs are in the provided bilingual corpus, and for each sentence pair which is not in the corpus, it searches the corpus sentence pair with best LONGEST COMMON SUBSEQUENCE (LCS) ratio at character level. Because this can be extremely slow for a large corpus, various options are provided to avoid the calculation of LCS for most sentence pairs. First, sentences of very different length can't have a large LCS ratio and in those cases the calculation can be avoided. Then if the beginning of the sentences are totally different (LCS ratio at word level is zero), they can't either have a large LCS ratio. If LCS ratio of beginning is not zero, the LCS ratio of the whole sentences is calculated. To go faster, it is first calculated at word level, and then at the character level for the best matching pairs.

B<pdiff> option determines the percentage number of words difference allowed to go for LCS calculation. For example if pdiff=20%, and the alignment set sentences have respectively 10 and 15 words lengths, only LCS of corpus sentences of respectively 8-12 words lengths and 12-18 words length will be calculated.

B<mindiff> option garanties that even if the difference is less than this threshold, LCS will be calculated

B<maxdiff> option permits to avoid LCS calculation if the length difference is more than this threshold number.

B<nfirst> option determines the length considered for the first LCS calculation (if nfirst=5, LCS will be calculated for the whole sentences only if LCS of the first 5 words is not zero).

The final allowed length difference is max( min(al_set_length*pdiff/100,maxdiff) , mindiff )

Finally, the script detects the edits (word insertions, deletions, and substitutions) necessary to pass from the Alignment Set sentences to the corpus sentences with best LCS ratio, prints the edit list and transmits these edits in the output links file.

=head1 EXAMPLES

perl adaptAlSetToBilCorpus.pl -ist alignref-1.0/sum/tagged.engspa.naacl -is alignref-1.0/tagged.eng.iso.naacl -it alignref-1.0/tagged.spa.iso.naacl -cs euparl05may.tagged/train.eng.iso -ct euparl05may.tagged/train.spa.iso -os euparl05may.tagged/alignref-1.0/eng.iso -ot euparl05may.tagged/alignref-1.0/spa.iso

=head1 AUTHOR

Patrik Lambert <lambert@gps.tsc.upc.es>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Patrick Lambert

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (version 2 or any later version).

=cut
