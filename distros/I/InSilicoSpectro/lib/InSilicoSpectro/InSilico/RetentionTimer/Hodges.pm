=head1 NAME

InSilicoSpectro::InSilico::RetentionTimer::Hodges Prediction of peptide retention time method by sum of amino acid coefficients.

=head1 SYNOPSIS

  use InSilicoSpectro::InSilico::RetentionTimer::Hodges;
  use InSilicoSpectro::InSilico::ExpCalibrator;

  # create the retention time predictor and select the current coefficients
  my $rt = InSilicoSpectro::InSilico::RetentionTimer::Hodges->new(current=>'Guo86');

  # make the predictor to learn
  $rt->learn( data=>{expseqs=>['ELGFQG','HPGDFGADAQAAMSK','LSSPATLNSR','RFIK'],
              exptimes=>[1314,1194,1152,1500],
              expmodif=>['::Oxidation_M::::','::::::::::::::::',':::::']});

  # learn also the correction for peptide length
  $rt->learn_lc( expseqs=>['LFTGHPETLEK','HPGDFGADAQAAMSK','LSSPATLNSR',],
                 exptimes=>[1224,1152,1500], );

  # predict retention time for a given peptide
  $rt->predict( peptide=>'ACFGDMKWVTFISLLRPLLFSSAYSRGVFRRDTHKSEIAHRFKDLGE',
                modification=>' ::::::::::::::::::::::::::::::::::Oxidation_M:::::::::::::');

  # filter current data
  $rt->filter( filter=>10 );

  # save current coefficients
  $rt->write_xml( confile=>$file,current=>'Exp00' );

  # retrieve previously saved coefficients
  $rt->read_xml( current=>'Exp01' );

  # assigns a calibrator to the predictor
  $ec=InSilicoSpectro::InSilico::ExpCalibrator->new( fitting=>'spline' );

  # fits the calibrator from experimental values
  $rt->calibrate( data=>{calseqs=>['ELGFQG','HPGDFGADAQAAMSK','LSSPATLNSR','RFIK'],
                  caltimes=>[1314,1194,1152,1500],
                  calmodifs=>['::Oxidation_M::::','::::::::::::::::',':::::']},
                 calibrator=>$ec );

  # save current calibrator
  $rt->write_cal( calfile=>$file );

  # retrieve previously saved calibrator
  $rt->read_cal ( calfile=>$file );

=head1 DESCRIPTION

Prediction of reversed-phase HPLC retention time for peptides using the sum of retention coefficients for every amino acid. The coefficients can be chosen from a list of selected precomputed values from the literature or can be learned by means of a multilinear regression fitted from experimental data.

A correction factor for polypeptide chain length is also available.

=head1 METHODS

=head3 my $rt=InSilicoSpectro::InSilico::RetentionTimer::Hodges->new( %h )

$h contains a hash.

=head3 $rt->getAuthorList()

REturns an array of authors name with available parameters values in the config file

=head3 $rt->learn( data=>{expseqs=>\@seqs,exptimes=>\@times,expmodif=>\@modifs} );

Learn the coefficients from experimental data.

=head3 $rt->learn_lc( data=>{expseqs=>\@seqs,exptimes=>\@times,expmodif=>\@modifs}  );

Learn correction factor for polypeptide chain length.

=head3 $rt->predict( peptide=>$str );

Predict retention time for the peptide.

=head3 $rt->predictor( peptide=>$str );

Same as predict() but without the calibrator's experimental fitting.

=head3 $rt->calibrate( calseqs=>\@str, caltimes=>\@val,fitting=>$str );

Train the predictor with experimental data and the chosen fitting method.

=over 4

=item fitting=>'linear'|'spline'

Method used for fitting.

=back

=head3 $rc->filter( filter=>$pc,error=>$str )

Filter experimental data in $rc->{data} by a cutting threshold of relative prediction error of $pc (in %).

=over 4

=item error=>'relative'|'absolute'

Type of error for filtering.

=back

=head3 $rt->writexml( confile=>$file );

Write coefficients.

=head3 $rt->readxml( current=>$str );

Retrieve saved coefficients and t0 labelled as in "current".

=head3 $rt->delete_coef( current=>$str );

Delete permanently from the current file the list of coefficients identified by $str.

=head3 @list=$rt->list_coef( $str );

Return a list of currently available sets of coefficients

=head3 @list=$rt->list_coef( );

List available coefficients in the current file.

=head3 %coef=$rt->get_coef( );

Return a hash with the current coefficients.

=head3 $value=$rt->set_t0();

Set the value of delay.

=head3 $value=$rt->get_t0();

Get the current value of delay.

=head3 $rt->calibrate( data=>{calseqs=>\@seqs,caltimes=>\@times,calmodifs=>\@modifs},calibrator=>$ec );

Calibrate the predictor with experimental data and saves it in $rt->{calibrator}.

=over 4

=item calibrator=>$ec

Reference to a InSilicoSpectro::InSilico::ExpCalibrator class instance.

=back

=head3 $rt->write_cal( calfile=>$file );

Save current calibrator.

=head3 $rt->read_cal ( calfile=>$file );

Retrieve a previously saved calibrator.

=head3 $rt->set( $name );

Set an instance parameter.

=head3 $rt->get( $name );

Get an instance parameter.

=head1 EXAMPLES

see InSilicoSpectro/t/InSilico/testHodges.pl script

=head1 SEE ALSO

InSilicoSpectro::InSilico::RetentionTimer

InSilicoSpectro::InSilico::ExpCalibrator

Guo D, Mant CT, Taneja AK, Parker JMR, Hodges RS. "Prediction of peptide retention times in reversed-phase high-performance liquid chromatography I. Determination of retention coefficients of amino acid residues of model synthetic peptides," J Chromatogr. 1986; 359:499-518.

Mant CT, Zhou NE, Hodges RS. "Correlation of protein retention times in reversed-phase chromatography with polypeptide chain length and hydrophobicity," J Chromatogr. 1989; 476:363-75.

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

package InSilicoSpectro::InSilico::RetentionTimer::Hodges;
require Exporter;
use Carp;

use InSilicoSpectro::InSilico::RetentionTimer;
use InSilicoSpectro::InSilico::ExpCalibrator;
use File::Basename;

our (@ISA, @EXPORT, @EXPORT_OK);
@ISA = qw(Exporter InSilicoSpectro::InSilico::RetentionTimer);
@EXPORT = qw(&getAuthorList);
@EXPORT_OK = ();

our $defConfigFile=dirname(__FILE__).'/'.'hodges_coef.xml';

sub new{
  my ($pkg,%h)=@_;# pkg: name of the module; h: hash with the rest of parameters
  my $rt=$pkg->SUPER::new;# Create a reference

# Setting of properties
  $rt->set('confile', getDefaultConfigFile());# init file


  $rt->set('current','Guo86');# Select precomputed values
  $rt->set('data',{%{$rt->get('data')},expmodif=>[]});
  $rt->set('overwrite',0);# Overwrite old values when learning?
  $rt->set('modif',0); # Use modifications as dummy variables?
  $rt->set('comments','');

  $rt->set('length_correction',0);# If set, calculate length correction

  foreach (keys %h){ $rt->set($_, $h{$_}) }

  $rt->read_xml();# Read the retention times coefficients into a Hash
  $rt->set('confile','-'); # default file

  if (scalar @{$rt->{data}{expseqs}}) {
    $rt->learn();
  }

  return $rt;
}

#------------------------------- accessors

sub getDefaultConfigFile{
  return $defConfigFile;
}

sub getAuthorList{
  my $this=shift;
  my @tmp;

  my $twig=XML::Twig->new(twig_handlers =>{values => 
					   sub {push @tmp, $_->atts->{author}}
					  }
 );
  $twig->parsefile($this->{confile}||getDefaultConfigFile); # build it
  $twig->purge; # purge it
  return @tmp;
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

  my %counter;
  my %coeff;
  if (exists($this->{coeff}{$this->{current}})) {
    %coeff=%{$this->{coeff}{$this->{current}}};
  } else {
    croak "Set of coefficients $this->{current} not defined";
    }

  foreach (split '',$this->{peptide}) {
    if (exists($coeff{Rc}{$_})) {
      $counter{$_}++;
    } else {
      carp "Coefficient for symbol $_ not defined. Discarding";
      }
  }
  my $R=$coeff{t0};
  foreach (keys %counter) {
    $R+=$counter{$_}*$coeff{Rc}{$_};
  }

 if ($this->{modif}) {
   # Count modifications for peptide
   foreach (split ':',$this->{modification}) {
     if (exists $coeff{Rc}{"~$_"}) { $R+=$coeff{Rc}{"~$_"} if /(.+)/ } }
 }

  if ($this->{length_correction}) {
    if (length($this->{peptide})>10) {
      $R-=$coeff{lc}{slope}*$R*log(length($this->{peptide}))
	+$coeff{lc}{intercept};
    }
  }

  return($R);
}


# -------------------------------   learn

sub learn {

  my ($this,%h)=@_;
  foreach (keys %h){ $this->set($_, $h{$_}) }

  if ((!exists $this->{coeff}{$this->{current}}) or ($this->{overwrite})) {

    my (@theta,$reg);
    my %coeff;
    my @expdata=@{$this->{data}{expseqs}};# Sequences
    my @prdata=@{$this->{data}{exptimes}};# Retention times
    my @expmodif=@{$this->{data}{expmodif}};
    my @aas=split '','ACDEFGHIKLMNPQRSTVWY';
    my %listmodif;

    unshift (@aas,'t0');

    if ($this->{modif}) { 
      foreach (@expmodif) { foreach (split ':') { $listmodif{"~$_"}++ if /(.+)/ } }
      foreach (sort keys %listmodif) { push(@aas,$_) }
	}

    if ((scalar @aas)>(scalar @expdata)) {
      carp "Too few data points for learning";
    } else {
      $reg = Statistics::Regression->new(scalar @aas, "multiple regression",\@aas );

    # Add data points
      for (my $k=0;$k<(scalar @expdata);$k++) {
	my @vector=count_aa($expdata[$k]);
	if ($this->{modif}) {
	  # Count modifications for peptide
	  my %modif;
	  foreach (sort keys %listmodif) {$modif{$_}=0};
	  foreach (split ':',$expmodif[$k]) { $modif{"~$_"}++ if /(.+)/ };
	  foreach (sort keys %listmodif) { push(@vector,$modif{$_}) };
	}
	unshift(@vector,1); #Intercept
	$reg->include($prdata[$k],\@vector);# Add point
      }

      @theta = $reg->theta;
      $coeff{t0}=shift(@theta);

      shift(@aas);
      $coeff{Rc}= {};
      for (my $k=0;$k<(scalar @aas);$k++) {# Vector of data
	$coeff{Rc}{$aas[$k]}=$theta[$k];
      }
      $coeff{comments}=$this->{comments};

      $this->{coeff}{$this->{current}}=\%coeff;
      return 1;
    }
  }
  return 0;
}

sub learn_lc { # learn length correction

  my ($this,%h)=@_;
  foreach (keys %h){ $this->set($_, $h{$_}) }

  my $reg;

  my $pcoeff=$this->{coeff}{$this->{current}};
  my @expdata=@{$this->{data}{expseqs}};# Sequences
  my @prdata=@{$this->{data}{exptimes}};# Retention times
  my @expmodif=@{$this->{data}{expmodif}};

  $reg = Statistics::Regression->new(2, "linear regression",['b','m']);

  # Add data points
  $this->{length_correction}=0;
  for (my $k=0;$k<(scalar @expdata);$k++) {
    if (length($expdata[$k])>10) {
      $reg->include( $this->predictor(peptide=>$expdata[$k],modification=>$expmodif[$k]
				     )-$prdata[$k], 
		[1,$this->predictor(peptide=>$expdata[$k],modification=>$expmodif[$k]
				   )*log(length($expdata[$k]))] ); 
    }
  }
  if ($reg->theta) {
    $this->{length_correction}=1;
    (${$pcoeff}{lc}{intercept},${$pcoeff}{lc}{slope})=$reg->theta;
  }
}

# -------------------------------   calibrate

sub calibrate {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  my (@prdata);
  my $k;

  for ($k=0;$k<scalar(@{$this->{data}{calseqs}});$k++) {
     push(@prdata,$this->predictor(peptide=>${$this->{data}{calseqs}}[$k],
				   modification=>${$this->{data}{calmodifs}}[$k]));# Assign an index to each prediction
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
     push(@error,(abs($this->predict(peptide=>${$this->{data}{expseqs}}[$m],
				     modification=>${$this->{data}{expmodif}}[$m])
		      -${$this->{data}{exptimes}}[$m])));
 }
 return $this->SUPER::filter(\@error);
}

# -----------------------------  restore / delete Rc

# delete coefficients
sub delete_coef {

  my ($this,$name)=@_;

  if ($name ne $this->{current}) { delete $this->{coeff}{$name} }
}

# list available set of coefficients
sub list_coef {

  my ($this)=@_;

  return (keys %{$this->{coeff}});
}

sub get_coef {

  my ($this)=@_;

  return %{$this->{coeff}{$this->{current}}{Rc}};
}

# -----------------------------  set / get t0

sub set_t0 {

  my ($this,$value)=@_;

  $this->{coeff}{$this->{current}}{t0}=$value;
}

sub get_t0 {
  my ($this)=@_;
  return $this->{coeff}{$this->{current}}{t0};
}

# -------------------------------   write / read xml file with Rc data

sub write_xml {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  my $str;

  $str="<coefficients>"."\n";
  foreach my $author (keys %{$this->{coeff}}) {
     $str.="\t".'<values author="'.$author.'">'."\n";
     foreach my $item (sort keys %{$this->{coeff}{$author}}) {
       if (ref $this->{coeff}{$author}{$item}) {
	 foreach (sort keys %{$this->{coeff}{$author}{$item}}) {
	   if ( $this->{coeff}{$author}{$item}{$_}=~/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ ) {
	   $str.="\t\t"."<$item data=".'"'.$_.'">'.sprintf("%.3e",$this->{coeff}{$author}{$item}{$_})."</$item>"."\n";
	 } else {
	   $str.="\t\t"."<$item data=".'"'.$_.'">'.$this->{coeff}{$author}{$item}{$_}."</$item>"."\n";
	   }
	 }
       } else {
	 if ( $this->{coeff}{$author}{$item}=~/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/ )  {
	 $str.="\t\t"."<$item>".sprintf("%.3e",$this->{coeff}{$author}{$item})."</$item>"."\n";
       } else {
	 $str.="\t\t"."<$item>".$this->{coeff}{$author}{$item}."</$item>"."\n";
       }
       }
     }
     $str.="\t"."</values>"."\n";
   }
   $str.="</coefficients>";

  if (open(XMLFILE,'>'.$this->{confile})) {
    print XMLFILE $str;
    close XMLFILE;
  } else {
    carp "Bad configuration file";
  }
}


sub read_xml {

  my  ($this,%h)=@_;

  foreach (keys %h){ $this->set($_, $h{$_}) }

  my $twig=XML::Twig->new(twig_handlers =>{values => sub {
			  foreach my $baby ($_->children) {
			    if (%{$baby->atts}) {
			      foreach my $item (values %{$baby->atts}){
				$this->{coeff}{${$_->atts}{author}}{$baby->gi}{$item}=$baby->text;		
			      }
			    } else {
			      $this->{coeff}{${$_->atts}{author}}{$baby->gi}=$baby->text;
			    } } },} );
  $twig->parsefile($this->{confile}); # build it
  $twig->purge; # purge it

}


# -------------------------------   misc
return 1;

