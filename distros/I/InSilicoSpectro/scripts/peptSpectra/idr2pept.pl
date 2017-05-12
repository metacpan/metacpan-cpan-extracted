#!/usr/bin/perl

# Mass spectrometry Perl program for extracting correct peptide matches from a Phenyx idr.xml file

# Copyright (C) 2005, 2006 Jacques Colinge

# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.

# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# Contact:
#  Prof. Jacques Colinge
#  Upper Austria University of Applied Sciences at Hagenberg
#  Hauptstrasse 117
#  A-4232 Hagenberg, Austria
#  www.fh-hagenberg.at

=head1 NAME

idr2pept.pl - Extraction of reliable peptide/spectrum matches from Phenyx .idr.xml files

=head1 SYNOPSIS

xml2pept.pl [options] idr.xml files

=head1 OPTIONS

Use idr2pept.pl -h

=head1 DESCRIPTION

The script parses one or several Phenyx .idr.xml files to extract reliable peptide/spectrum matches and
outputs them in the .peptSpectra.xml format. The .idr.xml file(s) can be compressed (gzipped) files.

The selection of the peptide assignments is performed based on several thresholds applied to identifications
found in the idr.xml file(s):

=over 4

=item maximum peptide p-value

=item minimum peptide score

=item minimum peptide z-score

=item minimum protein score

=item minimum number of distinct peptides per protein

=item minimum peptide save z-score

=back

To be selected a peptide must have a p-value smaller than the maximum peptide p-value, score and z-score larger than
the minimum peptide score and z-score respectively, and a minimum number of distinct peptides satisfying the latter
criteria must match a given protein entry in the database. In case less than the minimum number of distinct peptides
is found for a protein, then all the ones having a z-score higher than the minimum save z-score are nonetheless
selected.

During the parsing of the file, each spectrum is associated with the peptide that gives the best match.
That is, all multiple interpretations of a spectrum are lost in favor of the best one.

It is possible to restrict the exported peptides to an imposed charge state. All the peptides participate in the
selection (criterion on the number of distinct peptides per protein), but only the ones having the imposed
charge are printed in the .peptSpectra.xml output.

It is also possible to give a fasta file containing a list of protein sequences that are known to be in the
analyzed sample. In this case, an additional condition for a peptide to be selected is that it appears in one
of the given sequences. This option is useful when analyzing mixtures of purified proteins for quality control
or any other purpose. It allows to work with released thresholds to increase sensitivity by maintaining high
confidence in the selected peptide/spectrum matches.

Finally, a list of database names can be provided to the script if the original search .idr.xml files contained
results found in several databases.

=head1 EXAMPLE

./idr2pept.pl example.idr.xml > test.peptSpectra.xml

=head1 AUTHOR

Jacques Colinge

=cut


use strict;
use Getopt::Long;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;

my ($help, $verbose, $protList);
my $pValueMax = 1.0e-5;
my $scoreMin = 6.0;
my $zScoreMin = 6.0;
my $zSaveScore = 1.0e+100;
my $minProtScore = 8.0;
my $minNumPept = 2;
my $instrument = 'n/a';
my ($imposedCharge, $fasta, $dbList);

if (!GetOptions('help' => \$help,
                'h' => \$help,
		'protlist' => \$protList,
		'imposedcharge=i' => \$imposedCharge,
                'fasta=s' => \$fasta,
		'maxpvalue=f' => \$pValueMax,
		'minscore=f' => \$scoreMin,
		'minzscore=f' => \$zScoreMin,
		'zsavescore=f' => \$zSaveScore,
		'dblist=s' => \$dbList,
		'minnumpept=i' => \$minNumPept,
		'minprotscore=f' => \$minProtScore,
		'instrument=s' => \$instrument,
                'verbose' => \$verbose) || defined($help))
{
  print STDERR "Usage: xml2pept.pl [options] idJobs
\t-help
\t-h
\t-verbose
\t-protlist            [prints the ID of the proteins only]
\t--fasta=fname
\t--imposedcharge=int
\t--dblist=list        [coma-separated list of database name, by default every database is considered]
\t--maxpvalue=float    [default=$pValueMax]
\t--minscore=float     [default=$scoreMin]
\t--minzscore=float    [default=$zScoreMin]
\t--zsavescore=float   [default=$zSaveScore]
\t--minprotscore=float [minimum protein score, default=$minProtScore]
\t--minnumpept=int     [minimum number of distinct peptides for one protein, default=$minNumPept]
\t--instrument=string  [instrument used, default='$instrument'\n";
  exit(0);
}


InSilicoSpectro::init();

my $correctPeptide;
if ($fasta){
  # Loads a series of correct protein sequences as a fasta file
  my $protein;
  open(F, $fasta) || CORE::die("Cannot open [$fasta]: $!");
  while (<F>){
    if (index($_, '>') == 0){
      $correctPeptide .= $protein.'|';
      undef($protein);
    }
    else{
      s/[\n\r]//g;
      $protein .= $_;
    }
  }
  close(F);
}

my %dbList;
if ($dbList){
  # Prepares a hash with the list of accepted databases
  foreach (split(/,/, $dbList)){
    $dbList{$_} = 1;
  }
}

my $cmdLine = "idr2pept.pl".(defined($verbose)?' -verbose':'').(defined($imposedCharge)?" --imposedcharge=$imposedCharge":'').(defined($fasta)?" --fasta=$fasta":'')." --maxpvalue=$pValueMax --minscore=$scoreMin --minzscore=$zScoreMin --zsavescore=$zSaveScore --minnumpept=$minNumPept --minprotscore=$minProtScore --instrument=$instrument".(defined($dbList)?" --dblist=$dbList":'');
my @time = localtime();
my $date = sprintf("%d-%02d-%02d", 1900+$time[5], 1+$time[4], $time[3]);
my $time = sprintf("%02d:%02d:%02d", $time[2], $time[1], $time[0]);
if (!defined($protList)){
  print <<end_of_xml;
<?xml version="1.0" encoding="ISO-8859-1"?>
  <idi:PeptSpectraIdentifications  xmlns:idi="namespace/PeptSpectra.html">
    <idi:OneSample>
      <idi:header>
        <idi:instrument>$instrument</idi:instrument>
        <idi:spectrumType>msms</idi:spectrumType>
        <idi:date>$date</idi:date>
        <idi:time>$time</idi:time>
        <idi:autoExtraction><![CDATA[$cmdLine]]></idi:autoExtraction>
end_of_xml
}

# Parses files
my (%cmpd, %protList);
use XML::Parser;
our $file;
foreach $file (@ARGV){
  print STDERR "Parsing $file\n" if ($verbose);

  undef(%cmpd);
  if ($file =~ /\.gz$/){
    open(F, "gunzip -c $file |") || print STDERR "Warning, cannot open [$file]: $!";
  }
  else{
    open(F, $file) || print STDERR "Warning, cannot open [$file]: $!";
  }
  my $parser = new XML::Parser(Style => 'Stream');
  $parser->parse(\*F);
  close(F);
}

if (defined($protList)){
  print join("\n", sort {-$protList{$a} <=> -$protList{$b}} keys(%protList))."\n";
}
else{
  print "    </idi:Identifications>
  </idi:OneSample>
</idi:PeptSpectraIdentifications>\n";
}

exit(0);


# ------------------------------ XML --------------------------

my ($curChar, $score, $pValue, $charge, $cmpd, $peakList, $moz, $instrCharge, $parentMass, $peptideDescr);
my ($pept, $modif, $dbOk, $zScore, $sample, @cmpd, @item, @itemRefList, $massIndex, $indexNum, $itemListNum);
my (%protScore, %numPept, $database, $protID);

sub Text
{
  $curChar .= $_;

} # Text


sub StartTag
{
  my($p, $el)= @_;

  if ($el eq 'idl:database'){
    $database = $_{name};
    $dbOk = !$dbList || $dbList{$_{name}};
  }
  elsif ($el eq 'idl:SpectrumRef'){
    $instrCharge = $_{charge};
    $cmpd = "$_{sampleNumber}-$_{compoundNumber}";
  }
  elsif ($el eq 'ple:sample'){
    $sample = $_{sampleNumber};
    $cmpd[$sample] = -1;
  }
  elsif ($el eq 'ple:peptide'){
    $cmpd[$sample]++;
    $cmpd = "$sample-$cmpd[$sample]";
  }
  elsif ($el eq 'ple:item'){
    push(@item, $_{type});
    if (($_{type} eq 'mass') || ($_{type} eq 'moz')){
      $massIndex = $indexNum+0;
    }
    $indexNum++;
  }

  undef($curChar);

} # StartTag


sub EndTag
{
  my($p, $el)= @_;

  if ($el eq 'ple:ItemOrder'){
    if ($itemListNum > 0){
      for (my $i = 0; $i < @item; $i++){
	CORE::die("Inconsistent item order [$file]") if ($item[$i] ne $itemRefList[$i]);
      }
      CORE::die("Inconsistent item order [$file]") if (scalar(@item) != scalar(@itemRefList));
    }
    else{
      @itemRefList = @item;
      $itemListNum++;
      if (!defined($protList)){
	print "        <ple:ItemOrder xmlns:ple=\"namespace/PeakListExport.html\">\n";
	foreach my $item (@item){
	  print "          <ple:item type=\"$item\"/>\n";
	}
	print "        </ple:ItemOrder>\n      </idi:header>\n    <idi:Identifications>\n";
      }
    }
    undef(@item);
  }
  elsif ($el eq 'idl:AC'){
    $protID = "$database|$curChar";
  }
  elsif ($el eq 'idl:score'){
    $protScore{$protID} = $curChar;
  }
  elsif ($el eq 'idl:PeptScore'){
    $score = $curChar;
  }
  elsif ($el eq 'idl:PeptZScore'){
    $zScore = $curChar;
  }
  elsif ($el eq 'idl:pValue'){
    $pValue = $curChar;
  }
  elsif ($el eq 'idl:modif'){
    $modif = $curChar;
    $modif =~ s/\s+//g;
  }
  elsif ($el eq 'idl:sequence'){
    $pept = $curChar;
  }
  elsif ($el eq 'idl:charge'){
    $charge = $curChar;
  }
  elsif ($dbOk && ($el eq 'idl:PeptideMatch')){
    if ((!$cmpd{$cmpd} && ($pValue <= $pValueMax) && ($score >= $scoreMin) && ($zScore >= $zScoreMin)) || ($cmpd{$cmpd} && ($cmpd{$cmpd}->[1] < $score) && ($cmpd{$cmpd}->[2] >= $pValue))){
      #print STDERR "Store $pept $score, $pValue, $zScore, $modif, $charge, $protID [$cmpd, old: $cmpd{$cmpd}]\n";
      @{$cmpd{$cmpd}} = ($pept, $score, $pValue, $zScore, $modif, $charge, $protID);
    }
    else{
      #print STDERR "Ignore $pept $score, $pValue, $zScore, $modif, $charge, $protID\n";
    }
  }
  elsif ($el eq 'idl:IdentificationList'){
    # End of the identifications, we compute the number of peptides per protein
    my %pept;
    foreach my $cmpd (keys(%cmpd)){
      $pept{$cmpd{$cmpd}[6]}{$cmpd{$cmpd}[0]} = 1;
    }
    foreach my $protID (keys(%pept)){
      $numPept{$protID} = scalar(keys(%{$pept{$protID}}));
    }
  }

  # Spectrum parsing
  elsif ($el eq 'ple:PeptideDescr'){
    $peptideDescr = $curChar;
  }
  elsif ($el eq 'ple:ParentMass'){
    $parentMass = $curChar;
    $moz = (split(/\s+/, $curChar))[$massIndex];
  }
  elsif ($el eq 'ple:peaks'){
    $peakList = $curChar;
  }
  elsif ($el eq 'ple:peptide'){
    if ($cmpd{$cmpd} && (!$fasta || (index($correctPeptide, $cmpd{$cmpd}[0]) != -1)) && (index($cmpd{$cmpd}[0], 'B') == -1) && (index($cmpd{$cmpd}[0], 'Z') == -1) && (index($cmpd{$cmpd}[0], 'X') == -1) && (!$imposedCharge || ($imposedCharge == $cmpd{$cmpd}[5])) && (($protScore{$cmpd{$cmpd}[6]} >= $minProtScore) && ($numPept{$cmpd{$cmpd}[6]} >= $minNumPept)) || ($cmpd{$cmpd}[3] >= $zSaveScore)){
      #print STDERR "Output $cmpd{$cmpd}[0] $cmpd{$cmpd}[5] $protScore{$cmpd{$cmpd}[6]} $numPept{$cmpd{$cmpd}[6]}\n";
      if (defined($protList)){
	$protList{"$cmpd{$cmpd}[6]\t$protScore{$cmpd{$cmpd}[6]}\t$numPept{$cmpd{$cmpd}[6]}"} = $protScore{$cmpd{$cmpd}[6]};
      }
      else{
	print <<end_of_xml;
      <idi:OneIdentification>
        <idi:answer>
          <idi:sequence>$cmpd{$cmpd}[0]</idi:sequence>
          <idi:modif>$cmpd{$cmpd}[4]</idi:modif>
          <idi:charge>$cmpd{$cmpd}[5]</idi:charge>
        </idi:answer>
        <idi:source>
          <idi:file>$file</idi:file>
          <idi:proteinId>$cmpd{$cmpd}[6]</idi:proteinId>
          <idi:peptScore>$cmpd{$cmpd}[3]</idi:peptScore>
        </idi:source>
        <ple:peptide xmlns:ple="namespace/PeakListExport.html">
        <ple:PeptideDescr>$peptideDescr</ple:PeptideDescr>
        <ple:ParentMass><![CDATA[$parentMass]]></ple:ParentMass>
        <ple:peaks><![CDATA[$peakList]]></ple:peaks>
        </ple:peptide>
      </idi:OneIdentification>
end_of_xml
      }
    }
    else{
      #print STDERR "Reject $cmpd{$cmpd}[0] $cmpd{$cmpd}[5] $protScore{$cmpd{$cmpd}[6]} $numPept{$cmpd{$cmpd}[6]}\n" if ($cmpd{$cmpd}[0]);
    }
  }

} # EndTag
