use strict;

package InSilicoSpectro::InSilico::RetentionTimer;
require Exporter;
use Carp;
use File::Basename;

use InSilicoSpectro::InSilico::ExpCalibrator;

=head1 NAME

InSilicoSpectro::InSilico::RetentionTimer - A base class for implementing a peptide retention time predictor

=head1 SYNOPSIS

  use InSilicoSpectro::InSilico::RetentionTimer;

  # create a retention time predictor
  my $rt = InSilicoSpectro::InSilico::RetentionTimer->new;

  # predict retention time for a peptide
  $rt->predict( peptide=>'ACFGDMKWVTFISLLRPLLFSSAYSRGVFRRDTHKSEIAHRFKDLGE' );

  # calibrate the predictor
  $rt->calibrate( data=>{calseqs=>\@calseqs,caltimes=>\@caltimes,calmodifs=>\@calmodifs},calibrator=>$ec );

=head1 DESCRIPTION

InSilicoSpectro::InSilico::RetentionTimer is a base class for predictors of peptides retention time in HPLC. It gives also a method for calibration of the predictor.

=head1 FUNCTIONS

=head2 count_aa()

This function counts the number of ocurrences of each amino acid in a given sequence and returns a reference to an array with the count sorted by the one-letter symbol: ACDEFGHIKLMNPQRSTVWY.

  my $count = count_aa( 'AAK' );
  print "Found $count[0] Alanines and $count[1] Cysteines\n";

=head1 METHODS

=head3 my $rt=InSilicoSpectro::InSilico::RetentionTimer->new($h)

$h contains a hash with parameters.

=head3 $rt->predict($point)

Predict the retention time.

=head3 $rt->calibrate(%h)

Calibrate the predictor.

=head3 $rt->write_cal( calfile=>$file );

Save current calibrator.

=head3 $rt->read_cal ( calfile=>$file );

Retrieve a previously saved calibrator.

=head3 $rt->set($name, $val)

Set an instance parameter.

=head3 $rt->get($name)

Get an instance parameter.

=head1 EXAMPLES

=head1 SEE ALSO

InSilicoSpectro::InSilico::RetentionTime::Hodges

InSilicoSpectro::InSilico::RetentionTime::Petritis

InSilicoSpectro::InSilico::ExpCalibrator

InSilicoSpectro::InSilico::IsoelPoint

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
@EXPORT = qw(&count_aa);
@EXPORT_OK = ();

sub new{
  my ($pkg,%h)=@_;# pkg: name of the module; h: hash with the rest of parameters
  my $rt={};# Create an empty reference
  bless $rt, $pkg;# Assign it to the object

# Setting of properties
  $rt->set('peptide','');# Peptide
  $rt->set('data',{expseqs=>[],exptimes=>[]});# Experimental data

  $rt->set('calfile','-');# default file

  $rt->set('filter',10); # Threshold (in %) for method filter()
  $rt->set('error','relative');

  $rt->set('calibrator',InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'bypass',
							 expseqs=>[],expdata=>[],prdata=>[]));# new calibrator

  foreach (keys %h){ $rt->set($_, $h{$_}) }

  return $rt;
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

# -------------------------------   predict

sub predict {

  my ($this,$point)=@_;

  return $this->{calibrator}->fit($point);
}


sub count_aa {

  my ($seq)=@_;
  my %counter;
  my @aas=split '','ACDEFGHIKLMNPQRSTVWY';
  my @point;

  foreach (@aas) {
    $counter{$_}=0;
  }
  foreach (split '',$seq) {
    if (exists($counter{$_})) {
      $counter{$_}++;
    } else {
      carp "Coefficient for symbol $_ not defined. Discarding\n";
      }
  }

  foreach (@aas) {
    push(@point,$counter{$_});
  }
  return @point;
}

# -------------------------------   Filter data

sub filter {

 my ($this,$error)=@_;

 my @norder=(0..$#{$this->{data}{exptimes}});

 for(my $m=0;$m<=$#{$this->{data}{exptimes}};$m++) {
   if ($$error[$m]>(($this->{filter})*(($this->{error} eq 'relative') ? ($this->{data}{exptimes}[$m]/100) : 1))) {
     foreach (keys %{$this->{data}})
       {
	 splice(@{$this->{data}{$_}},$m,1);
       }
     splice(@$error,$m,1);
     splice(@norder,$m--,1);
   }
 }

 return \@norder;
}

# -------------------------------   calibrate

sub calibrate {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  my (@prdata,@expdata,@expseqs,@sortaa,%indh,$k);

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


# -------------------------------   misc
return 1;

