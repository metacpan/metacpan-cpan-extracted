=head1 NAME

InSilicoSpectro::InSilico::RetentionTimer::Petritis Prediction of peptide retention time by neural network training

=head1 SYNOPSIS

  # creates a retention time predictor
  my $rt = InSilicoSpectro::InSilico::RetentionTimer::Petritis->new;

  # trains the predictor
  $rt->learn( data=>{expseqs=>['ELGFQG','HPGDFGADAQAAMSK','LSSPATLNSR','RFIK'],
              exptimes=>[1314,1194,1152,1500]},mode=>'verbose',
	      maxepoch=>100, sqrerror=>1e-3,mode=>'verbose',
	      nnet=>{learningrate=>0.05},layers=>[{nodes=>20},{nodes=>2},{nodes=>1}] );

  # predicts retention time for a peptide
  $rt->predict( peptide=>'ACFGDMKWVTFISLLRPLLFSSAYSRGVFRRDTHKSEIAHRFKDLGE' );

  # saves the network
  $rt->write_xml(confile=>'nnet01.xml');

  # retrieves a previously saved network
  $rt->read_xml(confile=>'nnet00.xml');

  # assigns a calibrator to the predictor
  $ec=InSilicoSpectro::InSilico::ExpCalibrator->new( fitting=>'spline' );

  # fits the calibrator from expermiental values
  $rt->calibrate( data=>{calseqs=>['ELGFQG','HPGDFGADAQAAMSK','LSSPATLNSR','RFIK'],
                 caltimes=>[1314,1194,1152,1500]},calibrator=>$ec );

  # save current calibrator
  $rt->write_cal( calfile=>$file );

  # retrieve previously saved calibrator
  $rt->read_cal ( calfile=>$file );


=head1 DESCRIPTION

Predicts HPLC retention time for peptides

=head1 METHODS

=head3 my $rt=InSilicoSpectro::InSilico::RetentionTimer::Petritis->new(%h )

%h contains a hash

=head3 $rt->learn( data=>{expseqs=>\@seqs,exptimes=>\@times},
                   mode=>'verbose',maxepoch=>100, sqrerror=>1e-3,mode=>'verbose',
	           nnet=>{learningrate=>0.05},layers=>[{nodes=>20},{nodes=>2},{nodes=>1}] ); );

Trains the network from experimental data given in the arrays (@seqs,@times).

=over 4

=item maxepoch, sqrerror : train the network until sse < sqrerror or maxepoch

=item nnet=>{%h} : hash with options for method AI::NNFlex::Backprop->new( %h )

=item layers=>[{%h1},{%h2},{%h3}] : hashes with options for the 3 layers as defined by method AI::NNFlex::Backprop->add_layer( %hi )

=item mode=>'silent'|'verbose'

Method used for fitting

=back

=head3 $rt->predict(peptide=>$str)

Predicts retention time for the peptide

=head3 $rt->predictor(peptide=>$str)

Same as predict() but without experimental fitting

=head3 $rt->calibrate( data=>{calseqs=>\@str,caltimes=>\@val},fitting=>$str );

Trains the predictor with experimental data and the chosen fitting method

=over 4

=item fitting=>'linear'|'spline'

Method used for fitting

=back

=head3 $rc->filter( filter=>$pc,error=>$str )

Filter experimental data in $rc->{data} by a cutting threshold of relative prediction error of $pc (in %).

=over 4

=item error=>'relative'|'absolute'

Type of error for filtering.

=back

=head3 $rt->writexml( confile=>$file )

Saves network into a file

=head3 $rt->readxml( confile=>$file )

Retrieves a previously saved network

=head3 $rt->write_cal( calfile=>$file );

Save current calibrator.

=head3 $rt->read_cal ( calfile=>$file );

Retrieve a previously saved calibrator.

=head3 $rt->set($name, $val)

Set an instance paramter.

=head3 $rt->get($name)

Get an instance parameter.

=head1 EXAMPLES

see InSilicoSpectro/t/InSilico/testPetritis.pl script

=head1 SEE ALSO

InSilicoSpectro::InSilico::RetentionTimer

InSilicoSpectro::InSilico::ExpCalibrator

Petritis K, Kangas LJ, Ferguson PL, Anderson GA, Pasa-Tolic L, Lipton MS, Auberry KJ, Strittmatter EF, Shen Y, Zhao R, Smith RD. "Use of artificial neural networks for the accurate prediction of peptide liquid chromatography elution times in proteome analyses". Anal Chem. 2003; 75(5):1039-48.

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

use strict;

package InSilicoSpectro::InSilico::RetentionTimer::Petritis;
require Exporter;
use Carp;

use InSilicoSpectro::InSilico::RetentionTimer;
use InSilicoSpectro::InSilico::ExpCalibrator;

use File::Basename;

use AI::NNFlex::Dataset;
use AI::NNFlex::Backprop;

use XML::Dumper;

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter InSilicoSpectro::InSilico::RetentionTimer);
@EXPORT = qw();
@EXPORT_OK = ();

sub new{
  my ($pkg,%h)=@_;# pkg: name of the module; h: hash with the rest of parameters
  my $rt=$pkg->SUPER::new;# Create a reference

# Setting of properties
  $rt->set('confile','-');# default file

  $rt->set('maxepoch',1000);
  $rt->set('sqrerror',1e-3);
  $rt->set('mode','silent');
  $rt->set('network',{});
  $rt->set('nnet',{});
  $rt->set('layers',[{},{},{}]);

  $rt->set('nnet0',{randomconnections=>0,randomweights=>1,learningrate=>.1,
		  debug=>[],bias=>1,momentum=>0.6});
  my %layerdef=(persistentactivation=>0,
		decay=>0.0,
		randomactivation=>0,
		threshold=>0.0,);
  $rt->set('layers0',[{%layerdef,nodes=>20,activationfunction=>"linear",},
		    {%layerdef,nodes=>2,activationfunction=>"sigmoid",},
		    {%layerdef,nodes=>1,activationfunction=>"sigmoid",}]);

  foreach (keys %h){ $rt->set($_, $h{$_}) }

  return $rt;
}

# -------------------------------   predictor

sub predict {
  my ($this,%h)=@_;
  foreach (keys %h){ $this->set($_, $h{$_}) }

  return $this->SUPER::predict($this->predictor);

}

sub predictor {


  my ($this,%h)=@_;
  foreach (keys %h){ $this->set($_, $h{$_}) }

  my $dataset = AI::NNFlex::Dataset->new;
  $dataset->add([[count_aa($this->{peptide})],[0]]);
  return(${${$dataset->run($this->{network})}[0]}[0]/$this->{knorm});
}

# -------------------------------   learn

sub learn {

  my ($this,%h)=@_;
  foreach (keys %h){ $this->set($_, $h{$_}) }

  my ($network,$dataset,$knorm);
  my ($watcher,$sqrerror)=(0,10);

  my @expdata=@{$this->{data}{expseqs}};# Sequences
  my @prdata=@{$this->{data}{exptimes}};# Retention times
  my @aas=split '','ACDEFGHIKLMNPQRSTVWY';

  $network = AI::NNFlex::Backprop->new(%{$this->{nnet0}},%{$this->{nnet}});
  for (0..2) {
    $network->add_layer(%{$this->{layers0}[$_]},%{$this->{layers}[$_]});
  }
  $network->init();
  $this->{network}=$network;
  $dataset = AI::NNFlex::Dataset->new;

  $this->{knorm}=normdata(\@prdata);# Normalize scale of times

  # Add data points
  for (my $k=0;$k<(scalar @expdata);$k++) {
    $dataset->add([[count_aa($expdata[$k])],[$this->{knorm}*$prdata[$k]]]);
  }

  while (($sqrerror>$this->{sqrerror}) and ($watcher<$this->{maxepoch}))
      {
        $sqrerror = $dataset->learn($network);# Learning
	$watcher++;
	print "Epoch: ",$watcher," SSE: ",$sqrerror,"\n" if ($this->{mode} eq 'verbose');
      }
}

sub normdata {
  my $tmax=1e-12;
  foreach (@{$_[0]}) { $tmax=$_ if ($_ > $tmax) }
  return(1/$tmax);
}

# -------------------------------   calibrate

sub calibrate {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  my (@prdata);
  my $k;

  for ($k=0;$k<scalar(@{$this->{data}{calseqs}});$k++) {
     push(@prdata,$this->predictor(peptide=>${$this->{data}{calseqs}}[$k]));# Assign an index to each prediction
  }
  $this->set('data',{prdata=>\@prdata});
  $this->SUPER::calibrate;

}

# -------------------------------   Filter data

sub filter {

  my ($this,%h)=@_;
  foreach (keys %h){ $this->set($_, $h{$_}) }

  my @error;

  for(my $m=0;$m<=$#{$this->{data}{expseqs}};$m++) {
     push(@error,(abs($this->predict(peptide=>${$this->{data}{expseqs}}[$m])
		      -${$this->{data}{exptimes}}[$m])));
   }

 return $this->SUPER::filter(\@error);
}


# -------------------------------   write / read xml file with nnet data

sub write_xml {

  my ($this,%h)=@_;
  foreach (keys %h){ $this->set($_, $h{$_}) }

  my $dump = new XML::Dumper;
  $dump->pl2xml( [$this->{network},$this->{knorm}],$this->{confile} );

}

sub read_xml_str {

 my  ($this,$str)=@_;

  my $dump = new XML::Dumper;
  ($this->{network},$this->{knorm}) = @{$dump->xml2pl( $str )};
}


sub read_xml {

 my  ($this,%h)=@_;
 foreach (keys %h){ $this->set($_, $h{$_}) }

  my $dump = new XML::Dumper;
  ($this->{network},$this->{knorm}) = @{$dump->xml2pl( $this->{confile} )};
}

# -------------------------------   misc
return 1;

