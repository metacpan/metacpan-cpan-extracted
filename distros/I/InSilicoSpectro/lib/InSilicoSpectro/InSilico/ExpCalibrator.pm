use strict;

package InSilicoSpectro::InSilico::ExpCalibrator;
require Exporter;
use Carp;

use Statistics::Regression;
require Math::Spline;

use XML::Twig;
use File::Basename;

=head1 NAME

InSilicoSpectro::InSilico::ExpCalibrator - Calibrates a RetentionTimer predictor based on experimental data

=head1 SYNOPSIS

  use InSilicoSpectro::InSilico::ExpCalibrator;

  # creates a calibrator
  my $ec = InSilicoSpectro::InSilico::ExpCalibrator->new(fitting=>'spline');

  # trains it from experimental data
  $ec->train( expdata=>[1310.00,1520.00],prdata=>[1314.05,1500.75], );

=head1 DESCRIPTION

Calibrates retention time predictors. Based on the comparison between predicted and experimental data and the chosen method of fitting. It performs also some preprocessing on the given data.

=head1 METHODS

=head3 my $ec=InSilicoSpectro::InSilico::ExpCalibrator->new($h)

$h contains a hash with parameters.

=head3 $ec->train($h)

Trains the calibrator

=head3 $fval=$ec->fit($val)

Fits the input value according to the calibrator and returns the adjusted value

=head3 $ec->preprocess($h)

Preprocess the experimental data and filters outliers

=head3 $ec->set($name, $val)

Set an instance parameter.

=head3 $ec->get($name)

Get an instance parameter.

=head1 EXAMPLES

=head1 SEE ALSO

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
@EXPORT = qw();
@EXPORT_OK = ();

sub new{
  my ($pkg,%h)=@_;# pkg: name of the module; h: hash with the rest of parameters
  my $ec={};# Create an empty reference
  bless $ec, $pkg;# Assign it to the object

# Setting of default properties
  $ec->set('preprocess',1);
  $ec->set('fitting','bypass');
  $ec->set('fitmodel',[0.0,1.0]);
  $ec->set('gamma',1e-6);# Filter predicted values which are closer than gamma
  $ec->set('expdata',[]);
  $ec->set('prdata',[]);
  $ec->set('file','-'); # Set stdin/stdout as default file

# Setting of properties
  foreach (keys %h){ $ec->set($_, $h{$_}) }

  return $ec;
}

#-------------------------------- getters/setters

sub set{
  my ($this, $name, $val)=@_;
  $this->{$name}=$val;
}

sub get{
  my ($this, $n)=@_;
  return $this->{$n};
}

# -------------------------------   train

sub train {

  my ($this,%h)=@_;
  foreach (keys %h) { $this->set($_, $h{$_}) }

  my @prdata=@{$this->{prdata}};
  my @expdata=@{$this->{expdata}};

  for ($this->{fitting}) {
    /bypass/ && do { $this->set('fitmodel',[0.0,1.0]); last; };
    $this->preprocess(\@prdata,\@expdata) if  $this->{preprocess};
    /linear/ && do { my $reg = Statistics::Regression->new("linear regression", ["const","prdata"]);
		     foreach (@expdata) {
		       $reg->include($_,[1,shift(@prdata)]);
		     }
		     $this->{fitmodel}=$reg; 
		     last;};
    /spline/ && do { $this->{fitmodel}=Math::Spline->new(\@prdata,\@expdata); last; };
    carp "Fitting method $_ not implemented";
  }
}

sub fit {

  my ($this,$x)=@_;
  my ($a,$b)=(0.0,1.0);

  for ($this->{fitting}) {
    /bypass/ && do { $this->set('fitmodel',[$a,$b]); return($a+$b*$x); };
    /linear/ && do { ($a,$b)=$this->{fitmodel}->theta; return($a+$b*$x); };
    /spline/ && do { return($this->{fitmodel}->evaluate($x)); };
    croak "Fitting method $_ not implemented";
  }
}

sub preprocess {# clean outliers and inconsistencies bw predicted and experimental data

  my ($this,$x,$y)=@_;

  for(my ($k,$no)=(0,1);$k<(scalar @{$x}-1);$k++) {# Filter of repeated predicted values
    if (abs(${$x}[$k]-${$x}[$k+1])<$this->{gamma}) {
      splice(@{$x},$k,1);# Repeated predicted value: leave it out
      ${$y}[$k]*=$no++;
      ${$y}[$k]+=splice(@{$y},$k+1,1);;# Take the mean of experimental values
      ${$y}[$k--]/=$no;
    } else {
      $no=1;
      }
  }

#More processing...
}

# -------------------------------   save / load data


sub write_xml {

  my  ($this,%h)=@_;

  foreach (keys %h){
    $this->set($_, $h{$_});
  }

  my $k;
  my $str;

  $str='<calibrator>';
  $str.="\t".'<train>'."\n";
  $str.="\t\t"."<preprocess>$this->{preprocess}</preprocess>"."\n";
  $str.="\t\t"."<fitting>$this->{fitting}</fitting>"."\n";
  $str.="\t\t"."<gamma>$this->{gamma}</gamma>"."\n";
  $str.="\t".'</train>'."\n";

  $str.="\t".'<data>'."\n";
  for($k=0; $k< scalar @{$this->{expdata}};$k++) {
      $str.="\t\t".'<value time="'.${$this->{expdata}}[$k].'">';
      $str.=${$this->{prdata}}[$k];
      $str.='</value>'."\n";
  }
  $str.="\t".'</data>'."\n";
  $str.='</calibrator>';

  if (open(XMLFILE,'>'.$this->{file})) {
    print XMLFILE $str;
    close XMLFILE;
  } else {
    carp "Bad calibration file";
  }

}

sub read_xml {

 my  ($this,%h)=@_;

 foreach (keys %h){ $this->set($_, $h{$_}) }

 my @exptime;
 my @prtime;

 my $twig=XML::Twig->new(twig_handlers => 
                          { preprocess => sub {$this->{preprocess}=$_->text; },
			    fitting => sub {$this->{fitting}=$_->text;},
			    gamma => sub {$this->{gamma}=$_->text;},
			    value => sub {push(@exptime,${$_->atts}{time});
					   push(@prtime,$_->text); },
} );
 $twig->parsefile($this->{file}); # build it
 $twig->purge; # purge it
 if (@exptime) {
   $this->{expdata}=\@exptime;
   $this->{prdata}=\@prtime;
  }

}

# -------------------------------   misc
return 1;

