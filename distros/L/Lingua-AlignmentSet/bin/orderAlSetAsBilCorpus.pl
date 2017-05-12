#! /usr/local/bin/perl

########################################################################
# Author:  Patrik Lambert (lambert@gps.tsc.upc.edu)
# Description: cd manual (-man option)
#
#-----------------------------------------------------------------------
#
#  Copyright 2005 by Patrik Lambert
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
# parse command line
GetOptions(\%opts,'man','help|?','verbose|v=i','i_sourceToTarget|i_st|ist=s','i_targetToSource|i_ts|its=s','i_source|i_s|is=s','i_target|i_t|it=s','i_format|if=s','o_sourceToTarget|o_st|ost=s','o_targetToSource|o_ts|ots=s','o_source|o_s|os=s','o_target|o_t|ot=s','o_format|of=s','range=s','alignMode=s','corpsrc|cs=s','corptrg|ct=s') or pod2usage(0);
# check no required arg missing
if ($opts{man}){
    pod2usage(-verbose=>2);
}elsif ($opts{"help"}){
    pod2usage(0);
}elsif( !(exists($opts{"i_sourceToTarget"}) && exists($opts{"o_sourceToTarget"}) && exists($opts{"corpsrc"}) && exists($opts{"corptrg"})) ){   #required arguments
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
$input->orderAsBilCorpus($location,$opts{o_format},$opts{alignMode},$opts{corpsrc},$opts{corptrg},$opts{verbose});

__END__

=head1 NAME

orderAlSetAsBilCorpus.pl - Place sentence pairs of a secondary corpus at the head of the Alignment Set, in the same order.

=head1 SYNOPSIS

perl orderAlSetAsBilCorpus.pl [options] required_arguments

See description in the manual (-man option).

Required arguments:

	-ist FILENAME    Input source-to-target links file
	-if BLINKER|GIZA|NAACL    Input file(s) format (required if not TALP)
	-cs FILENAME    New corpus source text file
        -ct FILENAME    New corpus target text file
	-ost FILENAME    Output source-to-target links file
	-of BLINKER|GIZA|NAACL    Output file(s) format (required if not TALP)


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
        -v INT    verbose mode

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

Place sentence pairs of a secondary corpus at the head of the Alignment Set, in the same order.

=head1 EXAMPLES

perl orderAlSetAsBilCorpus.pl -ist eng2spa.A3.final -if giza -cs align_ref/test.eng.iso -ct align_ref/test.spa.iso -ost eng2spa.reordered -of giza

=head1 AUTHOR

Patrik Lambert <lambert@gps.tsc.upc.es>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Patrick Lambert

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (version 2 or any later version).

=cut
