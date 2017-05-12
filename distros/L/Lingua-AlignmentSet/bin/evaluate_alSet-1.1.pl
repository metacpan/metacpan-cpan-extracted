#! /usr/local/bin/perl

########################################################################
# Author:  Patrik Lambert (lambert@talp.ucp.es)
# Description: Evaluates a submitted Alignment Set against an answer Alignment Set
#
# -----------------------------------------------------------------------
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
$opts{sub_format}="TALP";
$opts{ans_format}="TALP";
$opts{sub_range}="1-";
$opts{ans_range}="1-";
$opts{alignMode}="no-null-align";
$opts{wheighted}=0;
# parse command line
GetOptions(\%opts,'man','help|?','weighted|w!','submission|sub=s@','answer|ans=s','sub_format|subf=s','sub_range=s','ans_format|ansf=s','ans_range=s','alignMode=s','title=s') or pod2usage(0);
# check no required arg missing
if ($opts{man}){
    pod2usage(-verbose=>2);
}elsif ($opts{"help"}){
    pod2usage(0);
}elsif( !(exists($opts{"answer"}) && exists($opts{"submission"})) ){   #required arguments
    pod2usage(-msg=>"Required arguments missing",-verbose=>0);
}
#END PARSING COMMAND-LINE ARGUMENTS

my @evaluation = ();
#load answer Alignment Set
my $answer = Lingua::AlignmentSet->new([[$opts{answer},$opts{ans_format},$opts{ans_range}]]);

#load submission Alignment Set(s)
foreach my $string (@{$opts{submission}}){
    my ($subFile,$description)=split /,/,$string;
    my $submission = Lingua::AlignmentSet->new([[$subFile,$opts{sub_format},$opts{sub_range}]]);
    #call library function
    push @evaluation, [$submission->evaluate($answer,$opts{alignMode},$opts{weighted}),$description];
}
Lingua::AlignmentEval::compare(\@evaluation,$opts{title},\*STDOUT,"text");


__END__

=head1 NAME

evaluate_alSet-version.pl - Evaluates submitted Alignment Set(s) against an answer Alignment Set

=head1 SYNOPSIS

perl evaluate_alSet-version.pl [options] required_arguments

Required arguments:

	-sub FILENAME,'DESCRIPTION'    As many as submission source-to-target links files.
	-subf BLINKER|GIZA|NAACL    Submission file(s) format (required if not TALP).
	-ans FILENAME    Answer source-to-target links file
	-ansf BLINKER|GIZA|NAACL    Answer file format (required if not TALP)

Options:

	-sub_range BEGIN-END    Submission Alignment Set range
	-ans_range BEGIN-END    Answer Alignment Set range
	-alignMode as-is|null-align|no-null-align Alignment mode. Default: no-null-align
	-w    Activates the weighting of the links
	-title Title of the experiment series
	-help|?    Prints the help and exits
	-man    Prints the manual and exits

=head1 ARGUMENTS

=over 8

=item B<--sub,--submission FILENAME,'DESCRIPTION'>

One entry for each submission source-to-target (i.e. links) file name (or directory, in case of BLINKER format). Optionally a description can be added, between '' if it contains white spaces.

=item B<--subf,--sub_format BLINKER|GIZA|NAACL>

Submission Alignment Set format (required if different from default, TALP). The same format is required for all input files.

=item B<--ans,--answer FILENAME>

Answer source-to-target (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--ansf,--ans_format BLINKER|GIZA|NAACL>

Answer Alignment Set format (required if different from default, TALP)

=head1 OPTIONS

=item B<--sub_range BEGIN-END>

Range of the submission source-to-target file (BEGIN and END are the sentence pair numbers). The same range is required for all input files.

=item B<--ans_range BEGIN-END>

Range of the answer source-to-target file (BEGIN and END are the sentence pair numbers)

=item B<--alignMode as-is|null-align|no-null-align>

Take alignment "as-is" or force NULL alignment or NO-NULL alignment (see AlignmentSet.pm documentation).
The default here is 'no-null-align' (as opposed to the other scripts, where the default is 'as-is').
Use "as-is" only if you are sure answer and submission files are in the same alignment mode.

=item B<-w, --weighted>

Weights the links according to the number of links of each word in the sentence pair.

=item B<--title>

Give a title to the table where results are compared

=item B<--help, --?>

Prints a help message and exits.

=item B<--man>

Prints a help message and exits.

=head1 DESCRIPTION

Evaluates one or various submitted Alignment Set(s) against an answer Alignment Set, and compare the results in a table.

=head1 EXAMPLES

perl evaluate_alSet-version.pl -sub test-giza.spa2eng.giza,'Spanish to English' -sub test-giza.eng2spa.giza,'English to Spanish' -title'Alignment Evaluation' -subf=GIZA -ans test-answer.spa2eng.naacl

Gives the following output:

    Alignment Evaluation   
----------------------------------
 Experiment                Ps	  Rs	  Fs	  Pp	  Rp	  Fp	 AER  

Spanish to English       93.95  67.51   78.57   93.95   67.51   78.57   21.43

English to Spanish       81.57  74.14   77.68   86.31   65.60   74.54   20.07

=head1 AUTHOR

Patrik Lambert <lambert@gps.tsc.upc.edu>
Some code from Rada Mihalcea's wa_eval_align.pl (http:://www.cs.unt.edu/rada/wpt/code/) has been integrated in the library function.

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Patrick Lambert

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (version 2 or any later version).

=cut
