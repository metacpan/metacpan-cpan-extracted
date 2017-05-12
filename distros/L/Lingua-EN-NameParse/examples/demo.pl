#!/usr/local/bin/perl -w

# Demo script for Lingua::EN::NameParse.pm

use Lingua::EN::NameParse qw(clean case_surname);
use strict;


# Quick casing, no parsing or context check
my $input = "FRENCH'S";

print("$input :",case_surname($input,1),"\n\n");

my %args =
(
   auto_clean      => 1,
   lc_prefix       => 0,
   initials        => 3,
   allow_reversed  => 1,
   joint_names     => 1,
   extended_titles => 1,

);

my $name = Lingua::EN::NameParse->new(%args);
# Open files to contain errors, a report on data quality and
# an extract of all single names
open(ERROR_FH,">errors.txt");
open(REPORT_FH,">report.txt");
open(EXTRACT_FH,">extract.txt");

my ($num_names,$num_errors);
# loop over all lines in dDATA block below
while (<DATA>)
{
   chomp($_);
   my $input = $_;
   $num_names++;
   my $error = $name->parse($input);

   my %comps = $name->components;
   my %props = $name->properties;
   my $bad_part = $props{non_matching};

   if ($error)
   {
      $num_errors++;
      printf(ERROR_FH "%-40.40s %-40.40s\n",$input,$bad_part);
   }

   if ( $props{type} eq 'Mr_A_Smith' )
   {
      # extract all single names with title and initials
      printf(EXTRACT_FH "%-40.40s %-20.20s %-3.3s %-20.20s\n",
         $input,$comps{title_1},$comps{initials_1},$comps{surname_1});
   }

   my $whole_name = $name->case_all;
   my $salutation = $name->salutation;
   printf(REPORT_FH "%-40.40s %-40.40s %-40.40s\n",$input,$whole_name,$salutation);
}
printf("BATCH DATA QUALITY: %5.2f percent\n",( 1- ($num_errors / $num_names)) *100 );

close(EXTRACT_FH);
close(ERROR_FH);
close(REPORT_FH);

#------------------------------------------------------------------------------
__DATA__
MR AB MACMURDO
LIEUTENANT COLONEL DE DE SILVA
<MR AND MRS AB & CD O'BRIEN>
MR AB AND M/S CD VAN DER HEIDEN-MACNAY
 MR AS & D.E. DE LA MARE
ESTATE OF THE LATE AB LE FONTAIN
MR. EUGENE ANDERSON I
MR. EUGENE ANDERSON II
MR. EUGENE ANDERSON III
MR. EUGENE ANDERSON IV
MR. EUGENE ANDERSON V
MR. EUGENE ANDERSON VI
MR. EUGENE ANDERSON VII
MR. EUGENE ANDERSON VIII
MR. EUGENE ANDERSON IX
MR. EUGENE ANDERSON X
MR. EUGENE ANDERSON XI
MR. EUGENE ANDERSON XII
MR. EUGENE ANDERSON XIII
MR KA MACQUARIE JNR.
REVERAND S.A. VON DER MERVIN SNR
BIG BROTHER & THE HOLDING COMPANY
RIGHT HONOURABLE MR PJ KEATING
MR TOM JONES
Robert James Hawke
EDWARD G WHITLAM
JAMES BROWN
MR AS SMI9TH
prof a.s.d. genius
Coltrane, Mr. John
Davis, Miles A.
Smith, Mr AB
De Silva, Professor A.B.
Air Marshall William Dunn
Major General William Dunn
J.R.R. Tolkien
James Graham, Marquess of Montrose
Flight Officer John Gillespie Magee
Sir Author Conan Doyle
Major JA Dunn