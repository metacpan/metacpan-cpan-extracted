#!/usr/bin/perl 

use 5.014;
use Bio::Trace::ABIF;
use Getopt::Long;
use File::Basename;
use Term::ANSIColor qw(:constants);
use Data::Dumper;
my @ext = ('.abi','.ab1','.ABI','.abI','.AB1','.ab');
our %iupac = (
 'R' => 'AG',
 'Y' => 'CT',
 'M' => 'CA',
 'K' => 'TG',
 'W' => 'TA',
 'S' => 'CG'
);
my $minq = 20;
my $wnd = 10;
my $bad = 4;
my $opt_debug;
my $file;
my $duplicate;
my $trim;

GetOptions(
    'i=s'       => \$file,
    'm=i'       => \$minq,
    'w=i'       => \$wnd,
    'bad=i'     => \$bad,
    'duplicate' => \$duplicate,
    'trim'      => \$trim,
    'verbose'   => \$opt_debug,
); 
 
print STDERR BOLD, 
 " -----------------------------------------------------------------
 AB1 TO FASTQ   v.01
 -----------------------------------------------------------------", RESET, "
 This program extract a FASTQ sequence from a chromatogram, using
 quality from 0 to 40 (NGS compatible).
 -----------------------------------------------------------------\n"; 

unless ($file) {
print STDERR "
   -i  Input file (ab1)
   -t  Trim sequence on low quality ends
   -w  Windows size for trimming [default: $wnd]
   -b  Max bad bases out of 'w' [default: $bad]
   -d  Duplicate sequence on abiguous bases
   -m  Minimum quality [default: $minq]
   -v  Verbose
";
 print STDERR " -----------------------------------------------------------------\n";
 exit;
}


debug("Opening input file", "Attept to load $file");

# Check input file
if ( not -e "$file" ) {
  die "\n FATAL ERROR:\n File <$file> not found.\n";
} elsif ( -d "$file" ) {
  die "\n FATAL ERROR:\n Please provide a .abi file (directory found at <$file>).\n";
}

my $abif;
my $try_open_abif = eval 
{
  $abif = Bio::Trace::ABIF->new();
  $abif->open_abif($file) or die "Error in file: $file";
  1;
};

die "\n FATAL ERROR:\n unexpected chromatogram error parsing $file.\n" unless ($try_open_abif);

my $v = $abif->abif_version();
my $aps = sprintf("%.4f", $abif->avg_peak_spacing());
my $inst_name = $abif->official_instrument_name();

debug("Input file opened", "\"$file\", ABI v. $v [$inst_name], average peak spacing: $aps");
my $sequence = $abif->sequence();
my @qv = $abif->quality_values();
 
 
if ($sequence!~/[ACGT][RYMKWS]+[ACGT]/i) {
    print STDERR "\n [WARNING]
 This program expects chromatograms analyzed in \"hetero\" mode (ambiguities not found).\n";
}
my @encodedquality = map {chr(int(($_<=93? $_ : 93)*4/6) + 33)} @qv;
my $q = join('', @encodedquality);
 
my ($seqname) = basename($file, @ext);
$seqname=~tr/ /_/;
if ($trim) {
    my ($b, $e) = $abif->clear_range(
                                $wnd,
                                $bad,
                                $minq
                               );   
         if ($b>0 and $e>0) {
            my $l = $e-$b+1;
            $sequence = substr($sequence, $b, $l);
            $q = substr($q, $b, $l);
            print STDERR " [TRIM OK] Sequence trim: $b - $e ($l)\n";
         } else {
            die " Low quality sequence: discarded.\n";
         }
}
 
my @qual = scan_quality($q);
debug("Sequence quality", "Values from $qual[0] to $qual[1], average $qual[2]");

if ($duplicate) {
  my $seq1 = '';
  my $seq2 = '';
  for (my $i = 0; $i<length($sequence); $i++) {
    my $q0 = substr($q, $i, 1);
    my $s0 = substr($sequence, $i,1);

    # Ambiguity detected:
    if ($iupac{$s0}) {
      my ($base1, $base2) = split //, $iupac{$s0};
      $seq1.=$base1;
      $seq2.=$base2;
      ;
      my @qual = scan_quality($q0);
      my $warn = undef;
      $warn = 1 if ($qual[0] == 0);
      debug("Sequence quality at $s0 is $q0 = $qual[2]", undef, $warn);

    } else {
      $seq1.=$s0;
      $seq2.=$s0;
     
    }
  }
  if ($seq1 eq $seq2) {
    print STDERR  RED, " [HETERO OFF]", RESET, " Both sequences are equal. One printed.\n";
    print "\@$seqname\n$sequence\n+\n$q\n";
  } else {
    print STDERR GREEN, " [HETERO OK] ", RESET, "Sequences are different.\n";
    print "\@$seqname\_1\n$seq1\n+\n$q\n";
    print "\@$seqname\_2\n$seq2\n+\n$q\n";
  }
   
} else {
  debug('Single sequence printed', "Turn --duplicate on to split ambiguities", 1);
  print "\@$seqname\n$sequence\n+\n$q\n";
}

sub scan_quality {
  my $quality = shift @_;
  my $min = undef;
  my $max = undef;
  my $sum = 0;
  my $i = 0;
  for ($i = 0; $i < length($quality); $i++) {

    my $quality_char = substr($quality, $i, 1);
    my $value = ord($quality_char)-33;
    $sum += $value;
    $min = $value if (not defined $min or $min > $value);
    $max = $value if (not defined $max or $max < $value);

  }
  my $avg = 0;
  $avg = sprintf("%.4f", $sum / $i) if ($i); 


  return ($min, $max, $avg);
}
sub debug {
  return 0 unless $opt_debug;
  my ($title, $message, $is_warning) = @_;
  my $color = RESET;
  $color = RED if ($is_warning);
  say STDERR  $color,BOLD, ' * ', $title, RESET;
  say STDERR  $color,      '   ', $message, RESET if defined $message;
}