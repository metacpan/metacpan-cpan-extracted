#!/usr/bin/perl

# Mass spectrometry Perl program for extracting correct peptide matches from Mascot .dat files

# Copyright (C) 2006 Jacques Colinge

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

mascot2pept.pl - Extraction of reliable peptide/spectrum matches from Mascot .dat files

=head1 SYNOPSIS

mascot2pept.pl [options] .dat files

=head1 OPTIONS

Use mascot2pept.pl -h

=head1 DESCRIPTION

The script parses one or several Mascot .dat files to extract reliable peptide/spectrum matches and
outputs them in the .peptSpectra.xml format. The .dat file(s) can be compressed (gzipped) files.

The selection of the peptide assignments is performed based on several thresholds applied to identifications
found in the .dat file(s):

=over 4

=item minimum ion score (Mascot peptide score)

=item minimum protein score

=item minimum number of distinct peptides per protein

=item minimum peptide save ion score

=item minimum peptide sequence length

=item minimum ion score to read a peptide from the .dat file (simple pre-filtering)

=back

To be selected a peptide must have an ion score larger than
the minimum peptide score, a protein score larger than the minimum protein score, and a minimum number
of distinct peptides with sufficient score
must match a given protein entry in the database. In case less than the minimum number of distinct peptides
is found for a protein, then all the ones having an ion score higher than the minimum save ion score
are nonetheless selected.

During the parsing of the file, each spectrum is associated with the peptide that gives the best match.
That is, all multiple interpretations of a spectrum are lost in favor of the best one. Moreover, all
peptides with score less than the basic score (typically 5) are not read.

It is possible to restrict the exported peptides to an imposed charge state. All the peptides participate in the
selection (criterion on the number of distinct peptides per protein), but only the ones having the imposed
charge are printed in the .peptSpectra.xml output.

It is also possible to give a fasta file containing a list of protein sequences that are known to be in the
analyzed sample. In this case, an additional condition for a peptide to be selected is that it appears in one
of the given sequences. This option is useful when analyzing mixtures of purified proteins for quality control
or any other purpose. It allows to work with released thresholds to increase sensitivity by maintaining high
confidence in the selected peptide/spectrum matches.

=head1 EXAMPLE

./mascot2pept.pl example.dat > test.peptSpectra.xml

=head1 AUTHOR

Jacques Colinge

=cut


use strict;
use Getopt::Long;
use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;

my ($help, $verbose);
my $basicScore = 5.0;
my $minScore = 20.0;
my $saveScore = 1.0e+100;
my $minProtScore = 40.0;
my $minNumPept = 2;
my $minLen = 6;
my $instrument = 'n/a';
my ($imposedCharge, $fasta, $outputScore);

if (!GetOptions('help' => \$help,
                'h' => \$help,
		'imposedcharge=i' => \$imposedCharge,
                'fasta=s' => \$fasta,
		'basicscore=f' => \$basicScore,
		'outputscore=f' => \$outputScore,
		'minscore=f' => \$minScore,
		'savescore=f' => \$saveScore,
		'minnumpept=i' => \$minNumPept,
		'minprotscore=f' => \$minProtScore,
		'minlen=i' => \$minLen,
		'instrument=s' => \$instrument,
                'verbose' => \$verbose) || defined($help) || (defined($outputScore) && (($basicScore > $outputScore) || ($outputScore > $minScore))) || (!defined($outputScore) && ($basicScore > $minScore)) || ($minScore > $saveScore))
{
  print STDERR "Usage: xml2pept.pl [options] idJobs
\t-help
\t-h
\t-verbose
\t--fasta=fname
\t--imposedcharge=int
\t--minscore=float     [minimum ion score to count the peptide, default=$minScore]
\t--savescore=float    [save ion score, default=$saveScore]
\t--outputscore=float  [minimum ion score to output the peptide, default=$outputScore]
\t--minprotscore=float [minimum protein score, default=$minProtScore]
\t--minnumpept=int     [minimum number of distinct peptides for one protein, default=$minNumPept]
\t--minlen=int         [minimum peptide length, default=$minLen]
\t--basicscore=float   [minimum ion score to read a peptide from the file, default=$basicScore]
\t--instrument=string  [instrument used, default='$instrument']

Note: It is mandatory that basicscore <= outputscore <= minscore <= savescore\n";
  exit(0);
}

$outputScore = $minScore if (!defined($outputScore));
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

# Charge format conversion
my %charge = (
	      '1+,2+,and3+' => '1,2,3',
	      '1+,2+and3+' => '1,2,3',
	      '1+' => '1',
	      '2+' => '2',
	      '2+and3+' => '2,3',
	      '2+,and3+' => '2,3',
	      '3+' => '3',
	      '4+' => '4'
	     );

# Modifications conversion (Macot mod_file to InSilicoSpectro insilicodef.xml)
my %modifConv = (
		 'Acetyl (K)' => 'ACET_core',
		 'Acetyl (N-term)' => 'ACET_nterm',
		 'Amide (C-term)' => 'AMID',
		 'Title:Biotin (K)' => 'BIOT',
		 'Title:Biotin (N-term)' => 'BIOT_nterm',
		 'Carbamidomethyl (C)' => 'Cys_CAM',
		 'Carbamyl (K)' => 'CAM_core',
		 'Carbamyl (N-term)' => 'CAM_nterm',
		 'Carboxymethyl (C)' => 'Cys_CM',
		 'Deamidation (NQ)' => 'DEAMID',
		 'Guanidination (K)' => 'Guanidination',
		 'ICAT_light' => 'ICAT_light',
		 'ICAT_heavy' => 'ICAT_heavy',
		 'iTRAQ (K)' => 'iTRAQ_KY',
		 'iTRAQ (N-term)' => 'iTRAQ_nterm',
		 'iTRAQ (Y)' => 'iTRAQ_KY',
		 'N-Acetyl (Protein)' => 'ACET_nterm',
		 'N-Formyl (Protein)' => 'FORM',
		 'O18 (C-term)' => 'O18',
		 'Oxidation (M)' => 'Oxidation_M',
		 'Oxidation (HW)' => 'Oxidation_HW',
		 'Phospho (STY)' => 'PHOS',
		 'Phospho (Y)' => 'PHOS',
		 'Propionamide (C)' => 'Cys_PAM',
		 'Pyro-glu (N-term Q)' => 'PYRR',
		 'S-pyridylethyl (C)' => 'Cys_PE',
		 'Sulfation (Y)' => 'SULF_core',
		 'Sulfation (S)' => 'SULF_core',
		 'Sulfation (T)' => 'SULF_core',
		 'Ubiquination I (K)' => 'Ubiquitin_0mc',
		 'Ubiquitination II (K)' => '"Ubiquitin_1mc'
		);

my $cmdLine = "mascot2pept.pl".(defined($verbose)?' -verbose':'').(defined($imposedCharge)?" --imposedcharge=$imposedCharge":'').(defined($fasta)?" --fasta=$fasta":'')." --basicscore=$basicScore --minscore=$minScore --savescore=$saveScore --minnumpept=$minNumPept --minprotscore=$minProtScore --instrument=$instrument --minlen=$minLen";
my @time = localtime();
my $date = sprintf("%d-%02d-%02d", 1900+$time[5], 1+$time[4], $time[3]);
my $time = sprintf("%02d:%02d:%02d", $time[2], $time[1], $time[0]);
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
	<ple:ItemOrder xmlns:ple="namespace/PeakListExport.html">
	  <ple:item type="mass"/>
	  <ple:item type="intensity"/>
	  <ple:item type="charge"/>
	</ple:ItemOrder>
      </idi:header>
    <idi:Identifications>
end_of_xml

# Parses files
use XML::Parser;
our $file;
my (%cmpd, %prot, %query, @fixedModif, @variableModif);
foreach $file (@ARGV){
  print STDERR "Parsing $file\n" if ($verbose);
  undef(%cmpd);
  undef(%prot);
  undef(%query);
  undef(@fixedModif);
  undef(@variableModif);

  if ($file =~ /\.gz$/){
    open(F, "gunzip -c $file |") || print STDERR "Warning, cannot open [$file]: $!";
  }
  else{
    open(F, $file) || print STDERR "Warning, cannot open [$file]: $!";
  }
  mascotParse(\*F);
  close(F);

  # Only keeps in %prot and %query the best score for each peptide
  foreach my $query (keys(%query)){
    my @scores = sort {$a <=> $b} values(%{$query{$query}{ac}});
    my $bestScore = $scores[-1];
    #print STDERR "Best score for $query is $bestScore\n";
    foreach my $ac (keys(%{$query{$query}{ac}})){
      if ($prot{$ac}{queries}{$query}{score} < $bestScore){
	#print STDERR "  eliminate $query from prot $ac ($prot{$ac}{queries}{$query}{score})\n";
	undef($prot{$ac}{queries}{$query});
	undef($query{$query}{ac}{$ac});
      }
    }
  }

  # Detects proteins identified by the same set of peptides exactly
  my %pattern;
  foreach my $ac (keys(%prot)){
    my $pattern = join('|', sort({$a <=> $b} keys(%{$prot{$ac}{queries}})));
    if ($pattern{$pattern}){
      # Another protein has the same set of queries
      #print STDERR "Protein $ac shares its peptides with $pattern{$pattern} [$pattern]\n";
      undef($prot{$ac});
    }
    else{
      $pattern{$pattern} = $ac;
    }
  }

  # Number of distinct peptides per protein that are above $minScore
  my (%numPept, %distinct);
  foreach my $ac (keys(%prot)){
    my %pept;
    foreach my $query (keys(%{$prot{$ac}{queries}})){
      my $score = $prot{$ac}{queries}{$query}{score};
      my $pept = $prot{$ac}{queries}{$query}{pept};
      $pept{$pept} = 1 if ($score > $minScore);
      if ($score > $distinct{$ac}{$pept}){
	$distinct{$ac}{$pept} = $score;
      }
    }
    $numPept{$ac} = scalar(keys(%pept));
  }

  # Protein score
  my %protScore;
  foreach my $ac (keys(%prot)){
    foreach my $score (values(%{$distinct{$ac}})){
      $protScore{$ac} += $score;
    }
    #print STDERR "$ac has $numPept{$ac} distinct peptides and score $protScore{$ac} (".join('+',sort {$a<=>$b} values(%{$distinct{$ac}})).")\n";
  }

  # Selects and print peptide/spectrum matches
  my %alreadyCmpd;
  foreach my $ac (sort {-$protScore{$a} <=> -$protScore{$b}} keys(%prot)){
    foreach my $query (keys(%{$prot{$ac}{queries}})){
      #print STDERR "$ac: Query $query already output by $alreadyCmpd{$query} (".join(',',keys(%{$query{$query}{ac}})).")\n" if ($alreadyCmpd{$query});
      if (!$alreadyCmpd{$query}){
	my $peptide = $prot{$ac}{queries}{$query}{pept};
	if ((!$fasta || (index($correctPeptide, $peptide) != -1)) && (length($peptide) >= $minLen) && (index($peptide, 'B') == -1) && (index($peptide, 'Z') == -1) && (index($peptide, 'X') == -1) && ($prot{$ac}{queries}{$query}{score} >= $outputScore) && ((($protScore{$ac} >= $minProtScore) && ($numPept{$ac} >= $minNumPept)) || ($prot{$ac}{queries}{$query}{score} >= $saveScore))){
	  my $modif = convertMascotModif($peptide, $prot{$ac}{queries}{$query}{modif});
	  if ($modif){
	    my @modif = split(/:/, $modif);
	    my $theoMass = getPeptideMass(pept=>$peptide, modif=>\@modif);
	    my ($charge, $moz2) = getCorrectCharge($theoMass, $cmpd{$query}{expMoz});
	    next unless (!$imposedCharge || ($imposedCharge == $charge));
	    $alreadyCmpd{$query} = $ac;

	    print <<end_of_xml;
      <idi:OneIdentification>
        <idi:answer>
          <idi:sequence>$peptide</idi:sequence>
          <idi:modif>$modif</idi:modif>
          <idi:charge>$charge</idi:charge>
end_of_xml
	    if ($cmpd{$query}{rt}){
	      print "          <idi:retentionTime>$cmpd{$query}{rt}</retentionTime>\n";
	    }
	    print <<end_of_xml;
        </idi:answer>
        <idi:source>
          <idi:file>$file</idi:file>
          <idi:proteinId>$ac</idi:proteinId>
          <idi:peptScore>$prot{$ac}{queries}{$query}{score}</idi:peptScore>
        </idi:source>
        <ple:peptide xmlns:ple="namespace/PeakListExport.html">
        <ple:PeptideDescr>$cmpd{$query}{expMass} $cmpd{$query}{intensity} $cmpd{$query}{charge}</ple:PeptideDescr>
        <ple:ParentMass><![CDATA[$cmpd{$query}{expMoz} $cmpd{$query}{intensity} $cmpd{$query}{charge}]]></ple:ParentMass>
        <ple:peaks><![CDATA[
$cmpd{$query}{massList}]]></ple:peaks>
        </ple:peptide>
      </idi:OneIdentification>
end_of_xml
	  }
	  else{
	    print STDERR "Cannot use peptide [$peptide] because one modification has no InSilicoSpectro equivalent [$prot{$ac}{queries}{$query}{modif}]\n" if ($verbose);
	  }
	}
      }
    }
  }
}

print "    </idi:Identifications>
  </idi:OneSample>
</idi:PeptSpectraIdentifications>\n";
exit(0);


sub convertMascotModif
{
  my ($pept, $mascotModif) = @_;

  # First we set the variable modification as found by Mascot
  my $isModified = 0;
  my @mascotModif = split(//, $mascotModif);
  for (my $i = 0; $i < @mascotModif; $i++){
    $isModified = 1 if ($mascotModif[$i] > 0);
    $mascotModif[$i] = $variableModif[$mascotModif[$i]];
    if ($mascotModif[$i] eq 'noISSEquiv'){
      # This peptide contains a variable modification we cannot convert
      return '';
    }
  }

  # Second, we localize the fixed mofifications
  my @modif;
  locateModif($pept, \@mascotModif, \@fixedModif, [], \@modif);
  return modifToString(\@modif);

} # convertMascotModif


sub mascotParse
{
  my $F = shift;

  while (<$F>){
    s/[\r\n]//g;

    if (/^Content-Type: +application\/x\-Mascot; +name="parameters"/){
      parseParameters($F);
    }
    elsif (/^q(\d+)_p(\d+)=(.*)/){
      my $query = $1;
      my ($nmc, $mass, $delta, $nIons, $pept, $nUsed1, $modif, $score, $ionSeries, $nUsed2, $nUsed3, @part) = split(/[,;:]/, $3);
      if ($score >= $basicScore){
	for (my $i = 0; $i < @part; $i += 5){
	  my $ac = $part[$i];
	  $prot{$ac}{queries}{$query}{score} = $score;
	  $prot{$ac}{queries}{$query}{pept} = $pept;
	  $prot{$ac}{queries}{$query}{modif} = $modif;
	  $query{$query}{ac}{$ac} = $score;
	}
      }
    }
    elsif (/^qmass(\d+)=(.+)/){
      $cmpd{$1}{expMass} = $2;
    }
    elsif (/^qexp(\d+)=(.+),(.+)/){
      $cmpd{$1}{expMoz} = $2;
    }
    elsif (/^qintensity(\d+)=(.+)/){
      $cmpd{$1}{intensity} = $2;
    }
    elsif (/^Content\-Type: +application\/x\-Mascot; +name="query(\d+)"/){
      parseOneExpSpectrum($1, $F);
    }
  }

} # mascotParse


sub parseParameters
{
  my $F = shift;

  while (<$F>){
    last if (index($_, '--gc0p4Jq0M2Yt08jU534c0p') == 0);

    s/[\r\n]//g;
    if (/^MODS=(.+)/){
      my $modif = $modifConv{$1};
      CORE::die("Fixed modification [$1] cannot be converted in an InSilicoSpectro equivalent") if (!$modif);
      push(@fixedModif, $modif);
    }
    elsif (/^IT_MODS=(.+)/){
      $variableModif[0] = '';
      my $modifOrder = 1;
      foreach my $mmodif (split/,/, $1){
	my $modif = $modifConv{$mmodif};
	if (!$modif){
	  $modif = 'noISSEquiv';
	}
	@variableModif[$modifOrder] = $modif;
	$modifOrder++;
      }
    }
  }

} # parseParameters


sub parseOneExpSpectrum
{
  my ($queryNum, $F) = @_;

  my ($massList, $charge, $rt);
  while (<$F>){
    last if (index($_, '--gc0p4Jq0M2Yt08jU534c0p') == 0);

    s/[\r\n]//g;
    if (/charge=(.+)/){
      $charge = $1;
      $charge =~ s/\s//g;
      $charge = $charge{$charge};
      $charge = '2,3' if (!$charge);
    }
    elsif (/rtinseconds=(.+)/){
      $rt = $1;
      if ($rt =~ /([\d\.]+)\-([\d\.]+)/){
	# The retention time is given as a range, take the average
	$rt = ($1+$2)*0.5;
      }
    }
    elsif (/Ions1=(.+)/){
      my @part = split(/,/, $1);
      undef($massList);
      foreach my $peak (@part){
	my ($mass, $intensity) = split(/:/, $peak);
	$massList .= "$mass $intensity ?\n";
      }
    }
  }

  $cmpd{$queryNum}{charge} = $charge;
  $cmpd{$queryNum}{rt} = $rt;
  $cmpd{$queryNum}{massList} = $massList;

} # parseOneExpSpectrum

