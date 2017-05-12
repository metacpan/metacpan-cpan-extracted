#! /usr/local/bin/perl

########################################################################
# Author:  Patrik Lambert (lambert@gps.tsc.upc.edu)
# Description: converts an alignment set to another format
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
# parse command line
GetOptions(\%opts,'man','help|?','i_sourceToTarget|i_st|ist=s','i_targetToSource|i_ts|its=s','i_source|i_s|is=s','i_target|i_t|it=s','i_format|if=s','o_sourceToTarget|o_st|ost=s','o_targetToSource|o_ts|ots=s','o_source|o_s|os=s','o_target|o_t|ot=s','o_format|of=s','range=s','alignMode=s') or pod2usage(0);
# check no required arg missing
if ($opts{man}){
    pod2usage(-verbose=>2);
}elsif ($opts{"help"}){
    pod2usage(0);
}elsif( !(exists($opts{"i_sourceToTarget"}) && exists($opts{"o_sourceToTarget"})) ){   #required arguments
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
$input->chFormat($location,$opts{o_format},$opts{alignMode});



__END__

=head1 NAME

chFormat_alSet-version.pl - converts an Alignment Set to another format

=head1 SYNOPSIS

perl chFormat_alSet-version.pl [options] required_arguments

Required arguments:

	-ist FILENAME    Input source-to-target links file
	-if BLINKER|GIZA|NAACL    Input file(s) format (required if not TALP)
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

=head1 DESCRIPTION

Converts an Alignment Set to the specified format. It creates, at the specified location, the new format file(s), but cannot delete
the old format files. The command-line utility has been made for convenience. For full details, see the documentation of the Lingua::AlignmentSet.pm module.

=head1 EXAMPLES

Converting NAACL files to BLINKER format:

perl chFormat_alSet-version.pl -ist test-giza.eng2spa.naacl -is test.eng.naacl -it test.spa.naacl -ost test-giza.eng2spa.blinker -of BLINKER -os test.eng -ot test.spa

Converting a GIZA file to NAACL format:

perl chFormat_alSet-version.pl -ist test-giza.eng2spa.giza -if GIZA -ost test-giza.eng2spa.naacl -os test.eng.naacl -ot test.spa.naacl


=head1 AUTHOR

Patrik Lambert <lambert@gps.tsc.upc.edu>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Patrick Lambert

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License (version 2 or any later version).

=cut
