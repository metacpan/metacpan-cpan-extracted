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

use InSilicoSpectro::InSilico::RetentionTimer;
use InSilicoSpectro::InSilico::RetentionTimer::Hodges;
use InSilicoSpectro::InSilico::RetentionTimer::Petritis;
eval{
  require  InSilicoSpectro::InSilico::RetentionTimer::Krokhin;
};
use InSilicoSpectro::InSilico::ExpCalibrator;

eval{

  my @param=@ARGV;

  my $method='Hodges'; # default method
  my $current='Guo86'; # select current coefficients for Hodges method
  my $learnfrom=''; # file with experimental data for learning
  my $calibratefrom=''; # file with experimental data for calibration
  my $saveparam=''; # file to save with current settings
  my $readparam=''; # file to read for settings
  my $readsetfile=''; # file with additional settings
  my %settings=();
  my $out='-'; # output file
  my $man = 0;
  my $help = 0;

  my (@expseqs,@exptimes);
  my (@calseqs,@caltimes);
  my @seqs;
  my ($rt,$pt,$ec);
  my ($peptide,$remaining);
  my $pid;

  # Get options
  my $result = GetOptions ( "method=s"=>\$method, "current=s"=>\$current,
			    "learnfrom=s"=>\$learnfrom, "saveparam=s"=>\$saveparam,
			    "readparam=s"=>\$readparam, "calibratefrom=s"=>\$calibratefrom,
			    "settings=s"=>\$readsetfile,"out=s"=>\$out,
			    "help|?"=>\$help,"man"=>\$man) or pod2usage(2);
  pod2usage(-exitstatus => 0, -verbose => 1) if $help;
  pod2usage(-exitstatus => 0, -verbose => 2) if $man;

  # Read parameters and init the predictor
  ReadParamFile($readparam,\$method,\$current) if $readparam;
  $rt="InSilicoSpectro::InSilico::RetentionTimer::$method"->new(current=>$current);
  if ($readparam) {
    open(SAVEIN,"+<&STDIN"); # Save a copy of STDIN
    defined($pid=open(STDIN,"-|")) or croak "can't fork: $!"; # Fork the process
    if ($pid) { # Parent: read in STDIN the parameters
      $rt->read_xml() if $method eq 'Hodges';
      $rt->read_xml() if $method eq 'Petritis';
    } else {
      ReadConfFile($readparam); # Child: print parameters in STDOUT
      exit;
    }
    $rt->read_cal(calfile=>$readparam);
  }
  open(STDIN,"+<&SAVEIN"); # Restore STDIN

  # Read additional settings
  %settings=ReadSetFile($readsetfile) if $readsetfile;

  # Learn from experimental data
  if ($learnfrom and !$readparam) {
    croak "Bad file $learnfrom"  unless ReadFromFile($learnfrom,\@expseqs,\@exptimes);
    if ($method eq 'Hodges') {
      $rt->learn(data=>{expseqs=>\@expseqs,exptimes=>\@exptimes},
		 current=>'Test',overwrite=>0,comments=>'Test Hodges',
		%settings);
    } elsif ($method eq 'Petritis') {
      $rt->learn(data=>{expseqs=>\@expseqs,exptimes=>\@exptimes},
		 maxepoch=>30,sqrerror=>1e-3,mode=>'quiet',
		 nnet=>{learningrate=>0.05},layers=>[{nodes=>20},{nodes=>6},{nodes=>1}],
		%settings);
    }
  }

  $rt->filter(filter=>10,error=>'relative',%settings) if exists $settings{filter};

  # Calibrate data
  if ($calibratefrom) {
    croak "Bad file $calibratefrom" unless ReadFromFile($calibratefrom,\@calseqs,\@caltimes);
    $ec=InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'linear',%settings);
    $rt->calibrate(data=>{calseqs=>\@calseqs,caltimes=>\@caltimes},calibrator=>$ec);
  }

  # Save coefficients
  SaveParamFile($saveparam,$rt,$method,$current)if $saveparam;	

  # Print results
  open (OUT,'>'.$out);
  print OUT "#Retention time predicted by computeRT.pl\n";
  print OUT "#$0";
  map {print OUT " $_"} @param;
  print OUT "\n";
  print OUT "#\n";
  foreach (@ARGV) {
    open(FILEIN,$_) or croak "Error opening $_";
    print OUT "#$_\n";
    foreach (<FILEIN>) {
      /^#/ and print and next; # Keep comments unchanged
      ($peptide,$remaining)=split(' ',$_,2);
      chomp $remaining;
      $pt=$rt->predict(peptide => uc $peptide);
      print OUT "$peptide $remaining $pt \n"; 
    }
  }
  close(OUT);
  close(SAVEIN);
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

sub SaveParamFile {

  my $str;
  my $pid;
  my ($saveparam,$rt,$method,$current)=@_;

  $str="<computeRT>"."\n";
  $str.="\t"."<method>".$method."</method>"."\n";
  $str.="\t"."<current>".$rt->{current}."</current>"."\n"  if $method eq 'Hodges';
  defined($pid=open(FROM_CHILD,"-|")) or croak "can't fork: $!";
  if ($pid) {
    foreach(<FROM_CHILD>) {$str.="\t".$_};	
  } else {
    $rt->write_xml() if  (($method eq 'Hodges') or ($method eq 'Petritis'));
    $rt->write_cal();
    exit;
  }
  $str.="\n"."</computeRT>"."\n";

  if (open(XMLFILE,'>'.$saveparam)) {
    print XMLFILE $str;
    close XMLFILE;
  } else {
    croak "Bad file $saveparam";
  }
}

sub ReadParamFile {

  my ($readparam,$pmethod,$pcurrent)=@_;

  my $twig=XML::Twig->new(twig_handlers =>{method => sub {$$pmethod=$_->text},
					   current => sub {$$pcurrent=$_->text},});
  $twig->parsefile($readparam); # build it
  $twig->purge; # purge it
}

sub ReadConfFile {

  my ($readparam)=@_;

  my $twig=XML::Twig->new(twig_handlers =>{coefficients=>sub{$_->print},
					   perldata=>sub{$_->print}});
  $twig->parsefile($readparam); # build it
  $twig->purge; # purge it

}

sub ReadSetFile {
# Read XML file with additional settings for learning

  my ($setfile)=@_;
  my %param=();
  my %handler=();

  foreach ('maxepoch','sqrerror','mode','expmodif','modif','current',
	   'overwrite','comments','filter','error','preprocess','fitting','gamma') {
    $handler{$_} = sub { $param{$_->gi}=$_->text }
  }

  $handler{nnet}= sub { foreach ($_->children) { $param{nnet}{$_->gi}=$_->text } };

  $handler{layer} = sub { my %layer;
			  foreach ($_->children) { $layer{$_->gi}=$_->text };
			  push(@{$param{layers}},\%layer); };

  my $twig=XML::Twig->new(twig_handlers =>{%handler});
  $twig->parsefile($setfile); # build it
  $twig->purge; # purge it
  return %param;
}



__END__

=head1 NAME

  computeRT.pl - Compute retention time

=head1 SYNOPSIS

./computeRT.pl  [--method=METHOD [--saveparam=PARAM] [--current=CURRENT]|[--learnfrom=LEARN] [--settings=SET]] | [--readparam=PARAM] [--calibratefrom=CAL] [--out=OUT] (filein1 [ filein2[...]] | - )

=head1 OPTIONS

=over 8

=item B<--method>

The algorithm to be taken (irrelevant if parameters are to be read from a file). Currently available algorithms are: Hodges(averaged sum of amino acid coefficients), Krokhin (modified Hodges) and Petritis (neural network).

=item B<--current>

For Hodges algorithm, precomputed coefficients can be chosen among several references in the literature: Guo86 (default), Guo86_2, Meek80, Su81, Krokhin04, Sagasawa82, Meek81, Browne82, Casal96, Meek80_2, Browne82_2, Petritis03.

=item B<--out>

Output text file (or STDOUT if no such argument is given)

=item B<--learnfrom>

Learn from experimental data in LEARN the coefficients in Hodges algorithm or neural network weights in Petritis. File format of blank-separated columns: "amino acid sequences" "retention time" "additional cols" ...

=item B<--settings>

XML file with additional settings for learning, filtering, etc. See 'rtset.dtd'.

=item B<--calibratefrom>

Calibrate the algorithm by fitting some experimental data. Same format than for learning.

=item B<--saveparam>

Save current params in PARAM, including current coefficients and calibration.

=item B<--readparam>

Retrieve current params in PARAM, including current coefficients and calibration.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Print the manual page and exits.

All remaining arguments are names of input files; or '-' for the standard input.

=back

=head1 DESCRIPTION

B<This program> will estimate the HPLC retention time for a given list of peptides. Several prediction algorithms can be chosen. It is also possible to train the coefficients used in the algorithm or to calibrate the estimates to a set of experimental values.

=cut
