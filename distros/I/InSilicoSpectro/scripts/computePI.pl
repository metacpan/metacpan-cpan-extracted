#!/usr/bin/env perl
#
# Command line usage

use strict;
use Carp;
use Getopt::Long;
use Pod::Usage;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../../lib'; # InSilicoSpectro lib
  push @INC, (dirname $0).'/../../../../lib'; # local CPAN packages: should be overriden when properly installed
}

END{
}

use InSilicoSpectro::InSilico::IsoelPoint;
use InSilicoSpectro::InSilico::ExpCalibrator;

eval{

  my @param=@ARGV;
  my $method='iterative';
  my $current='Lehninger';
  my $calibratefrom=''; # file with experimental data for calibration
  my $saveparam=''; # file to save with current settings
  my $readparam=''; # file to read for settings
  my $readsetfile;
  my $out='-'; # output file
  my %settings;
  my $man = 0;
  my $help = 0;

  my (@calseqs,@caltimes);
  my @seqs;
  my ($pi,$pt,$ec);
  my ($peptide,$remaining);
  my $pid;

  # Get options
  my $result = GetOptions ( "saveparam=s"=>\$saveparam,"readparam=s"=>\$readparam,
			    "method=s"=>\$method,"current=s"=>\$current,
			    "calibratefrom=s"=>\$calibratefrom,"out=s"=>\$out,
			    "settings=s"=>\$readsetfile,
			    "help|?"=>\$help,"man"=>\$man) or pod2usage(2);
  pod2usage(-exitstatus => 0, -verbose => 1) if $help;
  pod2usage(-exitstatus => 0, -verbose => 2) if $man;


  # Read additional settings
  %settings=ReadSetFile($readsetfile) if $readsetfile;

  # Read parameters and init the predictor
  ReadParamFile($readparam,\$method,\$current) if $readparam;
  $pi=InSilicoSpectro::InSilico::IsoelPoint->new(method=>$method,current=>$current,%settings);
  if ($readparam) {
    $pi->read_cal(calfile=>$readparam);
  }


  # Calibrate data
  if ($calibratefrom) {
    croak "Bad file $calibratefrom" unless ReadFromFile($calibratefrom,\@calseqs,\@caltimes);
    $ec=InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'linear');
    $pi->calibrate(data=>{calseqs=>\@calseqs,caltimes=>\@caltimes},calibrator=>$ec);
  }

  # Save coefficients
  SaveParamFile($saveparam,$pi)if $saveparam;	

  # Print results
  open (OUT,'>'.$out);
  print OUT "#Isolectric point predicted by computePI.pl\n";
  print OUT "#$0";
  map {print OUT " $_"} @param;
  print OUT "\n";
  print OUT "#\n";
  foreach (@ARGV) {
    open(FILEIN,$_) or croak "Error opening $_";
    print OUT "#$_\n";
    foreach (<FILEIN>) {
      /^#/ and print and next; # Skip comments
      ($peptide,$remaining)=split(' ',$_,2);
      chomp $remaining;
      $pt=$pi->predict(peptide => uc $peptide);
      print OUT "$peptide $remaining $pt \n";
    }
  }
  close(OUT);
};

if ($@) {
  print STDERR "error trapped in main\n";
  carp $@;
}


sub ReadFromFile {
# Put data from a file on variables
# ReadFromFile($filename,\@col1,\@col2...)
  my @items;

  if (open(FILE,shift)) {
    foreach(<FILE>) {
      @items=split;
      foreach(@_) { push @$_, shift @items }
    }
    close(FILE);
    return 1;
  } else {
    return 0;
  }
}

sub ReadParamFile {

  my ($readparam,$pmethod,$pcurrent)=@_;

  my $twig=XML::Twig->new(twig_handlers =>{method => sub {$$pmethod=$_->text},
					   current => sub {$$pcurrent=$_->text},});
  $twig->parsefile($readparam); # build it
  $twig->purge; # purge it
}

sub SaveParamFile {

  my $str;
  my $pid;
  my ($saveparam,$rt,$method,$current)=@_;

  $str="<computeIP>"."\n";
  defined($pid=open(FROM_CHILD,"-|")) or croak "can't fork: $!";
  if ($pid) {
    foreach(<FROM_CHILD>) {$str.="\t".$_};	
  } else {
    $rt->write_cal();
    exit;
  }
  $str.="\n"."</computeIP>"."\n";

  if (open(XMLFILE,'>'.$saveparam)) {
    print XMLFILE $str;
    close XMLFILE;
  } else {
    croak "Bad file $saveparam";
  }
}

sub ReadSetFile {
# Read XML file with additional coefficients

  my ($setfile)=@_;
  my %param;

  my $twig=XML::Twig->new(twig_handlers =>{pK => sub {
			  foreach my $child ($_->children) {
			    foreach my $item (values %{$child->atts}){
				$param{pK}{${$_->atts}{author}}{$item}=$child->text;		
			      }
			    }},});

  $twig->parsefile($setfile); # build it
  $twig->purge; # purge it
  return %param;
}

__END__

=head1 NAME

  computePI.pl - Compute isoelectric point (pI)

=head1 SYNOPSIS

./computePI.pl  [--method=METHOD] [--current=CURRENT] [--saveparam=PARAM] | [--readparam=PARAM] [--calibratefrom=CAL] [--settings=SETTINGS] [--out=OUT] (filein1 [ filein2[...]] | - )

=head1 OPTIONS

=over 8

=item B<--method>

Algorithm : iterative (default) or Patrickios (approximated).

=item B<--current>

Coefficients used for the iterative algorithm. Currently available are: Lehninger (default), EMBOSS, Rodwell, Sillero, Solomon.

=item B<--out>

Output text file (or STDOUT if no such argument is given)

=item B<--calibratefrom>

Calibrate the algorithm by fitting some experimental data. File format of blank-separated columns: "amino acid sequences" "isoelectric point" "additional cols" ...

=item B<--saveparam>

Save current params in PARAM, including calibration.

=item B<--readparam>

Retrieve current params in PARAM, including calibration.

=item B<--settings>

XML file with user-supplied additional coefficients. See 'piset.dtd'.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Print the manual page and exits.

All remaining arguments are names of input files; or '-' for the standard input.

=back

=head1 DESCRIPTION

B<This program> will estimate the isoelectric point (pI) for a given list of peptides. The point is computed by an iterative algorithm or by a theoretical approximation using the regressed dissociation constants (Patrickios et al, Anal. BioChem. 231, 82-91, 1995).

=cut
