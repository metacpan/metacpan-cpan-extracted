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

use InSilicoSpectro::InSilico::RetentionTimer::Hodges;
use InSilicoSpectro::InSilico::ExpCalibrator;

eval{

  our (@expseqs,@exptimes,@expmodif,@expscore);
  my (@seqs,@times,@modifs,@calseqs,@caltimes,@calmodifs,@testseqs,@testtimes);
  my %table_coef;
  my ($rt,$pt,$ec);
  my ($sse,$k)=(0,0);

  if(@ARGV){
    do $ARGV[0];
  } else {

    # Read external data
    do 'data/406.dat';    #do 'data/krok.dat'; #do 'data/genebio.dat';
    @seqs=@expseqs[0..$#expseqs/2];
    @times=@exptimes[0..$#exptimes/2];
    @modifs=@expmodif[0..$#expmodif/2];
    @calseqs=@expseqs[0..$#expseqs/2];
    @caltimes=@exptimes[0..$#exptimes/2];
    @calmodifs=@expmodif[0..$#expmodif/2];

    # Create a new retention time predictor
    $rt=InSilicoSpectro::InSilico::RetentionTimer::Hodges->new();

    # Learn from experimental data
    $rt->set('current','Guo86') unless $rt->learn(data=>{expseqs=>\@seqs,exptimes=>\@times,expmodif=>\@modifs},
						     modif=>1, current=>'LinRegGB',overwrite=>1,
						     comments=>'Test Hodges');
    # Filter data
    $rt->filter(filter=>10,error=>'relative');
    $rt->set('current','Guo86') unless $rt->learn(current=>'LinRegGB',overwrite=>1);

    # Save coefficients
    $rt->write_xml(confile=>'data/coef.xml',current=>'Exp01');

    $rt->delete_coef('Exp01');
    $rt->read_xml(current=>'Su81');

    # Set dead time
    $rt->set_t0(60);

    # Length correction
    $rt->learn_lc();
    $rt->set('length_correction',0);

    # Calibrate data
    $ec=InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'linear');
    $rt->calibrate(data=>{calseqs=>\@calseqs,caltimes=>\@caltimes,calmodifs=>\@calmodifs},calibrator=>$ec);
    $rt->write_cal();
    $rt->write_cal(calfile=>'data/fitguo.xml');
    $rt->read_cal();

 # Testing loop
    for ($k=0;$k<(scalar @{$rt->{data}{expseqs}});$k++) {
      $pt=$rt->predict(peptide => ${$rt->{data}{expseqs}}[$k],
				      modification => ${$rt->{data}{expmodif}}[$k]);
      print "Exp: ",sprintf("%.2f",${$rt->{data}{exptimes}}[$k]),"; Pred: ",sprintf("%.2f",$pt),"\n";
      $sse+=(${$rt->{data}{exptimes}}[$k]-$pt)**2;
    }
    print "SSE: ",sqrt($sse)/$k," \n" if $k;

    %table_coef=$rt->get_coef;

    foreach (sort keys %table_coef) { print $_,"   ",$table_coef{$_},"\n";  }
  }
};

if ($@) {
  print STDERR "error trapped in main\n";
  carp $@;
}

