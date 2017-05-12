#! /usr/bin/perl

########################################################################
# Author:  Patrik Lambert (lambert@gps.tsc.upc.edu)
# Description: Displays the aligned sentence pairs as a links enumeration or matrix
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
use Lingua::AlignmentSet;
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
$opts{range}="1-";
$opts{alignMode}="as-is";
$opts{mark}='$\blacksquare$';
$opts{maxRows}=53;
$opts{maxCols}=35;
$opts{representation}="matrix";
$opts{format}="latex";
# parse command line
GetOptions(\%opts,'man','help|?','i_sourceToTarget|i_st|ist=s','i_targetToSource|i_ts|its=s','i_source|i_s|is=s','i_target|i_t|it=s','i_format|if=s','format=s','representation|rep=s','range=s','alignMode=s','mark=s','maxRows=i','maxCols=i') or pod2usage(0);
# check no required arg missing
if ($opts{man}){
    pod2usage(-verbose=>2);
}elsif ($opts{"help"}){
    pod2usage(0);
}elsif( !(exists($opts{"i_sourceToTarget"})) ){   #required arguments
    pod2usage(-msg=>"Required arguments missing",-verbose=>0);
}
#END PARSING COMMAND-LINE ARGUMENTS

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
#call library function
$input->visualise($opts{"representation"},$opts{"format"},*STDOUT,$opts{"mark"},$opts{"alignMode"},$opts{"maxRows"},$opts{"maxCols"});


# DEBUG: print object structure:

__END__

=head1 NAME

visualise_alSet-version.pl - Displays the aligned sentence pairs as a links enumeration or matrix

=head1 SYNOPSIS

perl visualise_alSet-version.pl [options] required_arguments

Required arguments:

	-ist FILENAME    Input source-to-target links file
	-is FILENAME    Input source words file (not applicable in GIZA format)
	-it FILENAME    Input target words file (not applicable in GIZA format)
	-if BLINKER|GIZA|NAACL    Input file(s) format (required if not TALP)

Options:

	-rep enumLinks|matrix|drawLines    Type of visual representation (default: matrix)
	-format text|latex    Format of the output (default: latex)
	-its FILENAME Input target-to-source links file
	-range BEGIN-END    Input Alignment Set range
	-alignMode as-is|null-align|no-null-align    Alignment mode
	-mark STRING    How a link is marked in the matrix representation
	-maxRows INTEGER Maximum number of rows allowed in the matrix
	-maxCols INTEGER Maximum number of columns allowed in the matrix
	-help|?    Prints the help and exits
	-man    Prints the manual and exits

=head1 ARGUMENTS

=over 8

=item B<--ist,--i_st,--i_sourceToTarget FILENAME>

Input source-to-target (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--is,--i_s,--i_source FILENAME>

Input source (words) file name. Not applicable in GIZA Format.

=item B<--it,--i_t,--i_target FILENAME>

Input target (words) file name. Not applicable in GIZA Format.

=item B<--if,--i_format BLINKER|GIZA|NAACL>

Input Alignment Set format (required if different from default, TALP).

=head1 OPTIONS

=item B<--rep, --representation enumLinks|matrix|drawLines>

Type of visual represention (cf documentation for the AlignmentSet.pm module). Note that 'drawLines' representation is not available yet.

=item B<--format text|latex>

Format of the output. If representation=matrix, format must be 'latex'. In this case, the latex output is best seen with a ps viewer
(instead of a dvi viewer).

=item B<--its,--i_ts,--i_targetToSource FILENAME>

Input target-to-source (i.e. links) file name (or directory, in case of BLINKER format)

=item B<--range BEGIN-END>

Range of the input source-to-target file (BEGIN and END are the sentence pair numbers)

=item B<--alignMode as-is|no-null-align|null-align>

Take alignment "as-is" or force NULL alignment or NO-NULL alignment (see AlignmentSet.pm documentation).

=item B<--mark STRING>

Defines how a link is marked in the matrix.Common values are 'cross', 'ambiguity', 'confidence' (cf AlignmentSet.pm documentation).
You can also write a latex-compatible mark, such as '$\blacksquare$'.

=item B<--maxRows INTEGER>

The maximum number of rows (source words) allowed in a matrix. If the sentence pair contains more, 
the alignment is displayed as 'enumLinks' representation.

=item B<--maxCols INTEGER>

The maximum number of columns (target words) allowed in a matrix. If the sentence pair contains more, 
the matrix is continued below.

=item B<--help, --?>

Prints a help message and exits.

=item B<--man>

Prints a help message and exits.

=head1 DESCRIPTION

Displays the aligned sentence pairs as a links enumeration or matrix. The command-line utility has been made for convenience. For full details, see the documentation of the AlignmentSet.pm module.

=head1 EXAMPLES

Visualising as an enumeration of links, in text format, the first 10 sentence pairs of a GIZA file:

perl visualise_alSet-version.pl -ist test-giza.spa2eng.giza -if=GIZA -range=-10 -rep enumLinks -format text

Visualising as a matrix the first 10 sentence pairs in a NAACL file, with a personalized mark (black squares), and redirecting the ouput to a .tex file:

perl visualise_alSet-version.pl -ist test-giza.spa2eng.naacl -is test.spa.naacl -it test.eng.naacl -rep matrix -format latex -range -10 -mark '$\blacksquare$' > matrix.tex

=head1 AUTHOR

Patrik Lambert <lambert@gps.tsc.upc.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Patrick Lambert

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (version 2 or any later version).

=cut
