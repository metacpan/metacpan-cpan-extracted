#!/usr/bin/env perl
use strict;

use Carp;

BEGIN{
  use File::Basename;
  push @INC, (dirname $0).'/../../lib';
  push @INC, (dirname $0).'/../../../lib';
}

END{
}

use InSilicoSpectro::InSilico::IsoelPoint;
use InSilicoSpectro::InSilico::ExpCalibrator;

our (@expseqs,@exptimes,@expmodif,@expscore);
my (@seqs,@times,@modifs,@calseqs,@caltimes,@calmodifs,@testseqs,@testtimes);
my %table_coef;
my ($rt,$pt,$ec);
my $k=0;

if (@ARGV) {
  do $ARGV[0];
} else {

  # Read external data
  do 'data/406.dat';		#do 'data/krok.dat'; #do 'data/genebio.dat';
  @seqs=@expseqs[0..$#expseqs/2];
    @times=@exptimes[0..$#exptimes/2];
  @modifs=@expmodif[0..$#expmodif/2];
    @calseqs=@expseqs[0..$#expseqs/2];
  @caltimes=@exptimes[0..$#exptimes/2];
    @calmodifs=@expmodif[0..$#expmodif/2];

  #    @seqs=('DYE');

  # Create a new retention time predictor
  $rt=InSilicoSpectro::InSilico::IsoelPoint->new(data=>{expseqs=>\@seqs,
							exptimes=>\@times,expmodifs=>\@modifs});

  # Calibrate data
  $ec=InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'linear');
  $rt->calibrate(data=>{calseqs=>\@calseqs,caltimes=>\@caltimes},calibrator=>$ec);
  $rt->write_cal(calfile=>'data/fitip.xml');
  $rt->read_cal();

  # Testing loop
  for ($k=0;$k<(scalar @{$rt->{data}{expseqs}});$k++) {
    $pt=$rt->predict(peptide => ${$rt->{data}{expseqs}}[$k]);
    print $rt->{peptide}," pI: ",sprintf("%.2f",$pt),"\n";
  }

}
