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

use InSilicoSpectro::InSilico::RetentionTimer::Petritis;
use InSilicoSpectro::InSilico::ExpCalibrator;

eval{

  my ($rt,$pt,$ec);
  my ($sse,$k)=(0,0);

  my @seqs=('HGTVVLTALGGILK','LFTGHPETLEK','VEADLAGHGQEVLIR','VEADIAGHGQEVLIR',
	    'HPGDFGADAQGAMTK','LFTGHPETLEK','YLEFISDAIIHVLHSK','RDLSPR','VEADLAGHGQEVLIR',
	    'VEADIAGHGQEVLIR','HPGDFGADAQAAMSK','VEADLAGHGQEVLIR','VEADIAGHGQEVLIR',
	    'HPGDFGADAQGAMTK','ELHHFRILGEEQYNR','TEDEMKASEDLK','YRVICFLEEVMHDPDLLTQER',
	    'KLDNYK','LGEHNIDVLEGNEQFINAAK','ELGFQG','HPGDFGADAQAAMSK','LSSPATLNSR','RFIK');

  my @times=(1740,1224,1374,1374,1182,1230,2094,1284,1380,1380,1182,1368,1368,1194,1674,
	     1170,1914,1038,1620,1314,1194,1152,1500);

  my @calseqs=@seqs[0..$#seqs];
  my @caltimes=@times[0..$#times];

  # Create a new retention time predictor
  $rt=InSilicoSpectro::InSilico::RetentionTimer::Petritis->new;

  # Learn from experimental data
  $rt->learn(data=>{expseqs=>\@seqs,
		    exptimes=>\@times},
	     maxepoch=>100,
	     sqrerror=>1e-3,
	     mode=>'verbose',
	     nnet=>{learningrate=>0.05},
	     layers=>[{nodes=>20},{nodes=>6},{nodes=>1}],);

  # Save and retrieve predictor
  $rt->write_xml(confile=>'data/nnet.xml');
  $rt->read_xml();

  # Filter data
  $rt->filter(filter=>10,error=>'relative');

  # Calibrate data
  $ec=InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'spline');
  $rt->calibrate(data=>{calseqs=>\@calseqs,caltimes=>\@caltimes},calibrator=>$ec);
  $rt->write_cal(calfile=>'data/fitpet.xml');
  $rt->read_cal();

# Testing loop
  foreach (@seqs) {
    $pt=$rt->predict(peptide => $_,);
    print "Exp: ",$times[$k],"; Pred: ",sprintf("%.2f",$pt),"\n";
    $sse+=($times[$k]-$pt)**2;
    $k++;
  }
  print "SSE: ",sqrt($sse)/$k," \n";

};

if ($@){
  print STDERR "error trapped in main\n";
  carp $@;
}
