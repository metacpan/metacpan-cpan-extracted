#! /usr/local/bin/perl

########################################################################
# Author:  Patrik Lambert (lambert@talp.ucp.es)
# Description: apply a function to each alignment of the Alignment Set
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
use vars qw($dumper);
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
# parse command line
GetOptions(\%opts,'man','help|?','alignmentSub|sub=s@','i_sourceToTarget|i_st|ist=s','i_source|i_s|is=s','i_target|i_t|it=s','i_targetToSource|i_ts|its=s','i_format|if=s','o_sourceToTarget|o_st|ost=s','o_targetToSource|o_ts|ots=s','o_source|o_s|os=s','o_target|o_t|ot=s','o_format|of=s','range=s','alignMode=s','stlex=s','tslex=s') or pod2usage(0);
# check no required arg missing
if ($opts{man}){
    pod2usage(-verbose=>2);
}elsif ($opts{"help"}){
    pod2usage(0);
}elsif( !(exists($opts{"i_sourceToTarget"}) && exists($opts{"o_sourceToTarget"}) && exists($opts{"alignmentSub"})) ){   #required arguments
    pod2usage(-msg=>"Required arguments missing",-verbose=>0);
}

#END PARSING COMMAND-LINE ARGUMENTS

#load input Alignment Set
my $input = Lingua::AlignmentSet->new([[$opts{i_sourceToTarget},$opts{i_format},$opts{range}]]);
if (exists($opts{"i_source"})){
	$input->setSourceFile($opts{"i_source"});	
}
if (exists($opts{"i_target"})){
	$input->setTargetFile($opts{"i_target"});	
}
if (exists($opts{"i_targetToSource"})){
	$input->setTargetToSourceFile($opts{"i_targetToSource"});	
}
#load output Alignment Set location
my $location = {"sourceToTarget"=>$opts{o_sourceToTarget}}; 
if (exists($opts{"o_targetToSource"})){
	$location->{"targetToSource"}=$opts{"o_targetToSource"};	
}
if (exists($opts{"o_source"})){
	$location->{"source"}=$opts{"o_source"};	
}
if (exists($opts{"o_target"})){
	$location->{"target"}=$opts{"o_target"};	
}

#call library function
if (ref($opts{alignmentSub}) eq 'ARRAY'){
    if ($opts{alignmentSub}[0] eq "Lingua::Alignment::forceGroupConsistency" && $opts{alignmentSub}[1] eq "contiguous" && @{$opts{alignmentSub}}>2){
	# in this case we pass the ibm1 bilingual diccionary hash to help separate no-contiguous groups
	my $ibm1File=$opts{alignmentSub}[2];
	open(IBM,"<$ibm1File") or die "file ($ibm1File) opening error:$!";;
	my %ibm1t_s;
	while (<IBM>){
	    chomp;
	    my ($src, $trg, $prob)= split/ /;
	    my $srctrg="$src ||| $trg";
	    $ibm1t_s{$srctrg}=$prob;
	}
	$opts{alignmentSub}[2] = \%ibm1t_s;
	
	#trg->src lexicon
	if (@{$opts{alignmentSub}}>3){
	    $ibm1File=$opts{alignmentSub}[3];
	    open(IBM,"<$ibm1File") or die "file ($ibm1File) opening error:$!";;
	    my %ibm1s_t;
	    while (<IBM>){
		chomp;
		my ($src, $trg, $prob)= split/ /;
		my $srctrg="$src ||| $trg";
		$ibm1s_t{$srctrg}=$prob;
	    }
	    $opts{alignmentSub}[3] = \%ibm1s_t;
	}
    }
}
$input->processAlignment($opts{alignmentSub},$location,$opts{o_format},$opts{alignMode});

1;

__END__

=head1 NAME

processAlignment_alSet-version.pl - apply a function to each alignment of the Alignment Set

=head1 SYNOPSIS

perl processAlignment_alSet-version.pl [options] required_arguments

Required arguments:

    -ist FILENAME    Input source-to-target links file
    -if BLINKER|GIZA|NAACL    Input file(s) format (required if not TALP)
    -ost FILENAME    Output source-to-target links file
    -of BLINKER|GIZA|NAACL    Output file(s) format (required if not TALP)
    -sub SUBROUTINE    Subroutine name (package::subroutine)
    (such as Lingua::Alignment::forceGroupConsistency, swapSourceTarget, intersect, getUnion)
    If the subroutine needs arguments: -sub SUBROUTINE -sub ARG_1 -sub ARG_2 etc.
    Look manual for more subroutines (-man option)
  
Options:

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

=head1 ARGUMENTS

=over 8

=item B<--ist,--i_st,--i_sourceToTarget FILENAME>

Input source-to-target (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--if,--i_format BLINKER|GIZA|NAACL>

Input Alignment Set format (required if different from default, TALP).

=item B<--ost,--o_st,--o_sourceToTarget FILENAME>

Output (new format) source-to-target (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--of,--o_format BLINKER|GIZA|NAACL>

Output (new) Alignment Set format (required if different from default, TALP)

=item B<--sub,--alignmentSub SUBROUTINE --sub,--alignmentSub ARG_1 etc.>

Name of the subroutine to be applied to each alignment of the Alignment Set. If the subroutine takes arguments,
call this item for each argument (except the ref to the Alignment object), respecting the order. 
For instance, a call to MySub with two arguments arg1 and arg2 would look like:

--sub MySub --sub arg1 --sub arg2

The Lingua::Alignment.pm module contains functions:

=over 8

=item <Lingua::Alignment::forceGroupConsistency> 

Prohibits situations of the type {if linked(e,f) and linked(e',f) and linked(e',f') but not linked(e,f')} by linking e and f'

=item <Lingua::Alignment::swapSourceTarget> 

Swaps source and target in the alignments: a link (6 3) becomes (3 6)

=item <Lingua::Alignment::regexpReplace> 

Substitutes, in a side of the corpus, a string (defined by a regular expression) by another and updates the links
accordingly. There are 3 arguments: the regular expressions (pattern and replacement) and the side (source or target) (see the man examples). Notes:

=over 

=item 

In case of deleting various words, all added words are linked to all positions to which deleted words were linked. $al->{sourceLinks} information can be lost for replaced words.

=item 

The regexp is applied to the side of the corpus, and the smallest set of additions and deletions necessary to turn the original word sequence into the modified one is computed using algorithm::diff. In practice, this set is not always minimal, and in these cases various words are replaced by various so links may be changed. To avoid this problem use C<replaceWords> subroutine.

=item 

Is more eficient in "source" side than in "target" side.

=back

=item <Lingua::Alignment::replaceWords> 

Substitutes, in a side of the corpus, a string (of words separated by a white space) by another and updates the links
accordingly. There are 3 arguments: the string of words to be replaced, the string of replacement words and the side (source or target) (see the man examples). Notes:

=over 

=item 

In case of deleting various words, all added words are linked to all positions to which deleted words were linked. $al->{sourceLinks} information can be lost for replaced words.

=item 

Is more eficient in "source" side than in "target" side.

    
=back

=item <Lingua::Alignment::intersect> 

Takes the intersection between source-to-target and target-to-source alignments

=item <Lingua::Alignment::getUnion> 

Takes the union between source-to-target and target-to-source alignments

=item etc. See the AlignmentSet.pm module documentation for more functions

=back

=head1 OPTIONS

=item B<--is,--i_s,--i_source FILENAME>

Input source (words) file name.  Not applicable in GIZA Format.

=item B<--it,--i_t,--i_target FILENAME>

Input target (words) file name. Not applicable in GIZA Format.

=item B<--its,--i_ts,--i_targetToSource FILENAME>

Input target-to-source (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--range BEGIN-END>

Range of the input source-to-target file (BEGIN and END are the sentence pair numbers)

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

=back

=head1 DESCRIPTION

Allows to process the AlignmentSet applying a function to the alignment of each sentence pair of the set. The Alignment.pm module contains such functions.
The command-line utility has been made for convenience. For full details, see the documentation of the AlignmentSet.pm module.

=head1 EXAMPLES

Swapping source and target in source-to-target links file:

perl processAlignment_alSet-version.pl -ist test-giza.eng2spa.naacl -ost test-giza.swapped -sub Lingua::Alignment::swapSourceTarget

Remove '?' and '.' from the source side of the corpus:

perl processAlignment_alSet-version.pl -ist data/spanish-english.naacl -is data/spanish.naacl -ost data/spanish-english-without.naacl -os data/spanish-without.naacl -sub Lingua::Alignment::regexpReplace -sub '\?|\.' -sub '' -sub source

=head1 AUTHOR

Patrik Lambert <lambert@talp.upc.es>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Patrick Lambert

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (version 2 or any later version).

=cut
