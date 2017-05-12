use strict;
use Carp;

package InSilicoSpectro::InSilico::IsoelPoint;
require Exporter;

=head1 NAME

InSilicoSpectro::InSilico::IsoelPoint - A class for peptide isoelectric point (pI) prediction

=head1 SYNOPSIS

  use InSilicoSpectro::InSilico::IsoelPoint;

  # create a isoelectric point predictor
  my $pi = InSilicoSpectro::InSilico::IsoelPoint->new;

  # predict isoelectric point for a peptide
  $pi->predict( peptide=>'ACFGDMKWVTFISLLRPLLFSSAYSRGVFRRDTHKSEIAHRFKDLGE' );

  # calibrate the predictor
  $pi->calibrate( data=>{calseqs=>\@calseqs,caltimes=>\@caltimes,calmodifs=>\@calmodifs},calibrator=>$ec );

=head1 DESCRIPTION

InSilicoSpectro::InSilico::IsoelPoint is a class for predicting the isoelectric point of peptides. It gives also a method for calibration of the predictor.

=head1 METHODS

=head3 my $pi=InSilicoSpectro::InSilico::IsoelPoint->new($h)

$h contains a hash with parameters.

=head3 $pi->predict($point)

Predict the isoelectric point.

=head3 $pi->calibrate(%h)

Calibrate the predictor.

=head3 $pi->write_cal( calfile=>$file );

Save current calibrator.

=head3 $pi->read_cal ( calfile=>$file );

Retrieve a previously saved calibrator.

=head3 $pi->set($name, $val)

Set an instance parameter.

=head3 $ip->get($name)

Get an instance parameter.

=head1 FUNCTIONS

=head3 getAuthorList($method)

Returns a pointer to an array of available authors param set for a given method (such as as 'iterative')

=head1 EXAMPLES

see InSilicoSpectro/t/InSilico/testIsoelPoint.pl script

=head1 SEE ALSO

InSilicoSpectro::InSilico::ExpCalibrator

InSilicoSpectro::InSilico::RetentionTimer

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Pablo Carbonell, Alexandre Masselot, www.genebio.com

=cut

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter);
@EXPORT = qw(&getAuthorList);
@EXPORT_OK = ();


our %authorList=(
		 iterative=>['Lehninger', 'Sillero', 'Rodwell', 'EMBOSS', 'Solomon', 'Patrickios'],
		);

sub new {
  my ($pkg,%h)=@_;
  my $pi={};
  bless $pi, $pkg;

#### Check Lehninger's values
  $pi->{pK}{Sillero}=
    {'Carboxyl'=>3.2,D=>4.0,E=>4.5,'Amino'=>8.2,K=>10.4,R=>12.0,H=>6.4,C=>9.0,Y=>10.0}; # Sillero
  $pi->{pK}{Rodwell}=
    {'Carboxyl'=>3.1,D=>3.86,E=>4.25,'Amino'=>8.0,K=>11.5,R=>11.5,H=>6.0,C=>8.33,Y=>10.07}; # Rodwell
  $pi->{pK}{Lehninger}=
    #    {'Carboxyl'=>3.1,D=>4.4,E=>4.4,'Amino'=>8.0,K=>10.0,R=>12,H=>6.5,C=>8.5,Y=>10.0}; # DTASelect (Lehninger)
    {'Carboxyl'=>2.34,D=>3.86,E=>4.25,'Amino'=>9.69,K=>10.5,R=>12.4,H=>6.0,C=>8.33,Y=>10.0}; # Lehninger
  $pi->{pK}{EMBOSS}=
    {'Carboxyl'=>3.6,D=>3.9,E=>4.1,'Amino'=>8.6,K=>10.8,R=>12.5,H=>6.5,C=>8.5,Y=>10.1}; # EMBOSS
  $pi->{pK}{Solomon}=
    {'Carboxyl'=>2.4,D=>3.9,E=>4.3,'Amino'=>9.6,K=>10.5,R=>12.5,H=>6.0,C=>8.3,Y=>10.1}; # Solomon
  $pi->{pK}{Patrickios}=
    {'Carboxyl'=>'A',D=>'A',E=>'A',K=>'B',R=>'B','Amino'=>'B',pKa=>4.2,pKb=>11.2}; # Patrickios' method
#### Check Lehninger's values

  $pi->set('method','iterative');
  $pi->set('current','Lehninger');
  $pi->set('peptide','');# Peptide
  $pi->set('data',{expseqs=>[],exptimes=>[]});# Experimental data

  $pi->set('calfile','-');# default file

  $pi->set('calibrator',InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'bypass',
							 expseqs=>[],expdata=>[],prdata=>[]));# new calibrator

  foreach (keys %h) { $pi->set($_, $h{$_}) }
  return($pi);
}


sub predict {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  return $this->{calibrator}->fit($this->predictor);
}

sub predictor {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  my $method=$this->{method};

  return $this->$method;
}


sub Patrickios {
# Isoelectric point prediction
# Patrickios' formula

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  my $pKa=$this->{pK}{Patrickios}{pKa};
  my $pKb=$this->{pK}{Patrickios}{pKb};
  my $A=1; # Carboxyl
  my $B=1; # Amino

  foreach (split '',$this->{peptide}) {
    if (exists $this->{pK}{Patrickios}{$_}) {
      $A++ if $this->{pK}{Patrickios}{$_} eq 'A';
      $B++ if $this->{pK}{Patrickios}{$_} eq 'B';
    }
  }
  my $R=$A/$B;
  return($pKa - log10((1/2)*((1-$R)/$R)+sqrt((1-$R)*(1-$R)/$R/$R+(4/$R)*10**($pKa-$pKb))));
}

sub iterative {
# Isoelectric point prediction
# Iterative

  my ($this,%h)=@_;

  my $charge;
  my $pH;
  my $step=0.5;
  my %count;
  my @aa;
  my ($gamma,$last_charge,$error); 

  foreach (split '',$this->{peptide}) { $count{$_}++ if /^[KRHDECY]$/  }
  $count{'Amino'}=1;
  $count{'Carboxyl'}=1;

  $pH=7;
  $step=3.5;
  $last_charge=0;
  $gamma=0.00001;

  do {
    $charge=0;
    foreach (keys %count) {
      $charge+= $count{$_}*pcharge($this->{pK}{$this->{current}}{$_},$pH) if /^[KRH]$|Amino/;
      $charge-= $count{$_}*pcharge($pH,$this->{pK}{$this->{current}}{$_}) if /^[DECY]$|Carboxyl/;
    }
    ($charge > 0)? ($pH+=$step) : ($pH-=$step);
    $step/=2;
    $error=abs($charge-$last_charge);
    $last_charge=$charge;
 #   print "$pH $charge $error\n";
    } until $error < $gamma;

  return $pH;
}

sub pcharge {

  my $val=10**($_[1] - $_[0]);
  return 1/(1+$val);

}

sub log10 {

  my $n = shift;
  return log($n)/log(10);
}

sub getAuthorList{
  my $m=shift or CORE::die "must provide a method name when getAuthorList()";
  return $authorList{$m} || CORE::die "empty author list for method [$m]";
}


# -------------------------------   calibrate

sub calibrate {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  my (@prdata,@expdata,@expseqs,@sortaa,%indh,$k);

  $k=0;

  for ($k=0;$k<scalar(@{$this->{data}{calseqs}});$k++) {
     push(@{$this->{data}{prdata}},$this->predictor(peptide=>${$this->{data}{calseqs}}[$k]));
  }

  $k=0;
  foreach (@{$this->{data}{prdata}}) { # Predicted cal. data with the predictor (before calibration)
     $indh{$k++}=$_;# Assign an index to each prediction
  }

  @sortaa= sort {$indh{$a} <=> $indh{$b}} keys %indh;# sort the indexes by predicted values

  foreach (@sortaa) {
    push(@prdata,$indh{$_});
    push(@expdata,${$this->{data}{caltimes}}[$_]);# populate arrays ordered by predicted values
   }

  $this->{calibrator}->train(expdata=>\@expdata,prdata=>\@prdata);
}

# -------------------------------   write / read xml file with the calibrated values

sub write_cal {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  my $str='';
  my $k;

  $str.=$this->{calibrator}->write_xml(file=>$this->{calfile});


}

sub read_cal {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  $this->{calibrator}->read_xml(file=>$this->{calfile});
  $this->{calibrator}->train;
}


#-------------------------------- getters/setters

sub set{
  my ($this, $name, $val)=@_;
  if ((ref($val) eq 'HASH') and defined($this->{$name})) {# Add more fields to the hash
    $this->{$name}={%{$this->{$name}},%$val};
  } else {
    $this->{$name}=$val;
    }
}

sub get{
  my ($this, $n)=@_;
  return $this->{$n};
}

1;
