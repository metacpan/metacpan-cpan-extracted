use strict;

package InSilicoSpectro::Spectra::Filter::MSFilter;

use InSilicoSpectro::Spectra::MSSpectra;
use InSilicoSpectro::Spectra::Filter::MSFilterDirectValue;
use InSilicoSpectro::Spectra::Filter::MSFilterAlgorithm;


require Exporter;
our (@ISA,@EXPORT,@EXPORT_OK, $VERSION);
@ISA=qw (Exporter);
@EXPORT=qw($VERSION);
@EXPORT_OK=qw();



=head1 NAME

InSilicoSpectro::Spectra::Filter::MSFilter

=head1 DESCRIPTION

This is a virtual class to provide the basic functionallity for further classes used for quality assasement and filtering of spectra or peaks.

=head1 SYNOPSIS

use InSilicoSpectro::Spectra::Filter::MSFilter;
use InSilicoSpectro::Spectra::MSSpectra;


my $file= "a.mgf";
my $format="mgf";
my $sp=InSilicoSpectro::Spectra::MSSpectra->new(source=>$file, format=>$format);
$sp->open();

my $sf = new InSilicoSpectro::Spectra::Filter::MSFilter();

# see InSilicoSpectro/t/Spectra/Filter/example.xml for examples of usage
$sf->readXml('a.xml');
$sf->filterSpectra($sp);

$sp->write('mgf', "another.mgf");

# look in InSilicoSpectro/t/Spectra/Filter/ for more examples of usage

=head1 METHODS

=over 4

=item my $sf=InSilicoSpectro::Spectra::Filter::MSFilter->new()

create a new object.

=item $sf->readXml($filename)

opens the provided XML-file containing the information which filter to use and its parameters. 

=item $sf->readTwigEl($el)

reads the TwigEl passed by $el and executes twig_addSpectrumFilter() with this values.

=item $sf->filterSpectra($Spectra)

apply the XML-file previously loaded on the Spectra (can be MS, MSMS, or MSCmpd-Spectra).

=item $sf->applyAction();

applies the action on the currentSpectra under the threshold conditions.

=item $sf->computeFilterValue($sp);

only prepared for further classes inheriting from this one.

=item $sf->checkValidity();

checks if the different values provided by the xml are valid.

=item $sf->fragment([$val]);

gets the values (moz, intensity) from the fragments of the currentSpectra (has to be an MSCmpd). The results are stored into filterValue. Which values should be extracted can be selected by $val, otherwise the next name in the filterName is used.

=item $sf->precursor([$val]);

gets the values (moz, intensity) from the precursors of the currentSpectra (has to be an MSMSSpectra). The The results are stored into filterValue. Which values should be extracted can be selected by $val, otherwise the next name in the filterName is used.

=item $sf->intensity();

calls fragment("intensity"). Allows you just to write intensity as a filter-name instead.

=item $sf->moz();

calls fragment("moz"). Allows you just to write moz as a filter-name instead.

=item $sf->normRank();

calculates the rank from the intensity of the fragments from the smallest first and biggest last (1, 3, 3, 4, 5, ..) and divides it by the total number of peaks.

=item $sf->normRankBern();

makes the normalisation of the int-peaks as described in the paper from M. Bern et al. Because we can make a selection of peaks to be tested before, it doesnt make a lot of sense in this context.

=item $sf->currentSpectra([$sp]);

set or get a current spectra.

=item $sf->thresholdValue([$val]);

set or get the threshold value.

=item $sf->filterValue([$val]);

set or get the filter value.

=head1 EXAMPLES

=head1 SEE ALSO

search.cpan.org

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

Roman Mylonas, www.genebio.com

=cut


use Carp;
use List::Util qw(max min);


$VERSION = "0.9";


#contains the information to transform an object in another one used in the method readXml
my %hFmt=(
       directValue=>"InSilicoSpectro::Spectra::Filter::MSFilterDirectValue", 
       algorithm=>"InSilicoSpectro::Spectra::Filter::MSFilterAlgorithm",
      );

#to transform the comparators, used in the method applyAction
my %hComparator=(
		 'ge' => '>=', 
		 'gt' => '>', 
		 'le' => '<=',
		 'lt' => '<',
		 'eq' => '==',
		);


#################################
### new and some other functions


sub new{

 my $pkg = shift;

 my $self = {};
 my $class = ref($pkg) || $pkg;
 bless $self, $class;
 return $self;

}



sub filterSpectra{
  my ($this, $sp) = @_;

  $this->currentSpectra($sp);

  if (ref($this->currentSpectra()) eq 'InSilicoSpectro::Spectra::MSRun') {
    my $sp_backup_run= $this->currentSpectra();

    foreach (@{$this->currentSpectra()->get('spectra')}){
    
      $this->filterSpectra($_);
    }
    $this->currentSpectra($sp_backup_run);
  } else {

    #get all the PeakDescriptors if this isn't allready done
    unless (defined $this->{fragPD}) {
      if (ref($sp) eq 'InSilicoSpectro::Spectra::MSMSSpectra'){

	$this->{fragPD}->{intensity}= $this->currentSpectra()->get('fragPD')->getFieldIndex('intensity');
	$this->{fragPD}->{moz}= $this->currentSpectra()->get('fragPD')->getFieldIndex('moz');
	($this->{fragPD}->{charge}= $this->currentSpectra()->get('fragPD')->getFieldIndex('charge')) or ($this->{fragPD}->{chargemask}= $this->currentSpectra()->get('fragPD')->getFieldIndex('chargemask'));
	
	$this->{parentPD}->{intensity}= $this->currentSpectra()->get('parentPD')->getFieldIndex('intensity');
	$this->{parentPD}->{moz}= $this->currentSpectra()->get('parentPD')->getFieldIndex('moz');
	($this->{parentPD}->{charge}= $this->currentSpectra()->get('parentPD')->getFieldIndex('charge')) or ($this->{parentPD}->{chargemask}= $this->currentSpectra()->get('parentPD')->getFieldIndex('chargemask'));

#	$this->{parentPD}->{charge}= defined $this->currentSpectra()->get('parentPD')->getFieldIndex('charge')?$this->currentSpectra()->get('parentPD')->getFieldIndex('charge'):InSilicoSpectro::Spectra::MSSpectra::chargemask2string($this->currentSpectra()->get('parentPD')->getFieldIndex('chargemask'));
      } elsif(ref($sp) eq 'InSilicoSpectro::Spectra::MSSpectra'){
	#if it's a MSSpectra
	$this->{fragPD}->{intensity}= $this->currentSpectra()->get('peakDescriptor')->getFieldIndex('intensity');
	$this->{fragPD}->{moz}= $this->currentSpectra()->get('peakDescriptor')->getFieldIndex('moz');
	$this->{fragPD}->{chargemask}= $this->currentSpectra()->get('peakDescriptor')->getFieldIndex('chargemask');

#FIXME: Should get PD's properly!
      }elsif(ref($sp) eq 'InSilicoSpectro::Spectra::MSMSCmpd'){
	$this->{fragPD}->{intensity}= 1;
	$this->{fragPD}->{moz}= 0;
	$this->{fragPD}->{charge}= 2;
	
	$this->{parentPD}->{intensity}= 1;
	$this->{parentPD}->{moz}= 0;
	$this->{parentPD}->{charge}= 2;

      }else{
	croak("you cannot use ", ref($sp), " as spectra.\n");
	
      }
    }

    if (($this->{level} eq 'peaks') and ($this->{spectrumType} eq 'msms') and (ref($sp) ne 'InSilicoSpectro::Spectra::MSMSCmpd')) {
      
      my $sp_backup =  $this->currentSpectra();
      if(ref($this->currentSpectra()) eq 'InSilicoSpectro::Spectra::MSSpectra'){
	foreach (@{$this->currentSpectra()->spectra()}) {
	  $this->filterSpectra($_);
	}
	$this->currentSpectra($sp_backup);
      }
    } else {
      $this->computeFilterValue();
      $this->applyAction();

    }
  }

  return $this->currentSpectra();
 
}



#########################################################################
### computeFilterValue and functions to get moz and intensities values


#the result of the methods are saved in filterValue

sub computeFilterValue{
  my $this = shift;

  croak "no defined 'currentSpectra'\n" unless defined $this->currentSpectra();

  croak "no defined 'filterName'\n" unless defined $this->originalFilterName();

  my @double= @{$this->originalFilterName()};
  $this->filterName(\@double);
  
  my $current_name= shift @{$this->filterName()};
  
  eval "\$this->".$current_name."()";
  carp($@) if ($@);

  return $this;
}


sub fragment{
  my ($this, $pdVal)= @_;

  croak "the currentSpectra shouldnt be an MSMSSpectra\n" if (ref($this->currentSpectra()) eq 'InSilicoSpectro::Spectra::MSMSSpectra');

  $pdVal=shift @{$this->filterName()} unless defined $pdVal;

  my @tmp;

  foreach(@{$this->currentSpectra()->spectra()}){
    push @tmp, $_->[$this->{fragPD}->{$pdVal}];
    
  }

  #foreach(@tmp){
#            print "".__FILE__."\n";
#	    print "$_\n";
#	  }

  $this->filterValue(\@tmp);
  return $this->filterValue();

}



sub precursor{
  my ($this, $pdVal)= @_;

  croak "the currentSpectra has to be a MSMSSpectra\n" unless (ref($this->currentSpectra()) eq 'InSilicoSpectro::Spectra::MSMSSpectra');
  
  $pdVal=shift @{$this->filterName()} unless defined $pdVal;
 
  my @tmp;
       
  foreach(@{$this->currentSpectra()->spectra()}){
    push @tmp, $_->getParentData($this->{parentPD}->{$pdVal});
  }
  $this->filterValue(\@tmp);

  return $this->filterValue();
  
}

#allows you to write 'intensity' instead of 'fragment.intensity'
sub intensity{
  my $this= shift;

  $this->fragment("intensity");

  return $this;
}

#the same for 'moz'
sub moz{
  my $this= shift;

  $this->fragment("moz");

  return $this;
}


#makes the normalisation of the int-peaks as described in the paper from M. Bern et al
#doesnt make a lot of sense in this context, because we can allready make a selection of 
#spectra before

sub normRankBern{
  my $this= shift;

  my $c1= $this->param()->{c1};
  my $c2= $this->param()->{c2};
  #this value essentially lets you choose the number of peaks your gonna use (relative to total nr of peaks)
  my $max_mz= $this->param()->{max_mz};

  #get the intensities into filterValue()
  $this->fragment("intensity");
  
  my %rank;
  my $i=1;
  my $j=0;
  my $last=0;

  foreach(sort {$b <=> $a} @{$this->filterValue()}){ 
    if($_==$last){
      $j++;
    }else{
      $rank{$_}= $j+$i++;
      $j=0 if $j;
      $last=$_;   
    }
  }
 
  foreach(0..$#{$this->filterValue()}){
        $this->filterValue()->[$_]= $c1-($c2/$max_mz)*$rank{$this->filterValue()->[$_]};
        $this->filterValue()->[$_]= 0 if $this->filterValue()->[$_]<0;
  }


}


#without the parameters.. just the reversed Rank divided by total rank number. 
#Makes more sense because I allready make a choice of peaks before using smartPeaks.

sub normRank{
  my $this= shift;

  

  #get the intensities into filterValue()
  $this->fragment("intensity");
  
  my %rank;
  my $i=1;
  my $j=0;
  my $last=-1;
  my $first=1;

  
  #have to get the first value extra, because want to have ranks like 1, 3, 3, 4, ... and than divided by the total number of ranks
  
  #sort from small to big
  foreach(sort {$a <=> $b} @{$this->filterValue()}){
    #first value extra
    if($first){
      $last=$_;
      $first=0;
      next;
    }
    #if the value is the same as last time
    if($_==$last){
      $j++;
    }else{
      $rank{$last}= $j+$i++;
      if($j){
	$i+=$j;
	$j=0;
      }
      $last=$_; 
    }
  }
  #and don't forget the last one!
  $rank{$last}= $i;

  #total nr of ranks
  my $rank_nr= scalar @{$this->filterValue()};

  foreach(0..$#{$this->filterValue()}){
        $this->filterValue()->[$_]= $rank{$this->filterValue()->[$_]}/$rank_nr;
  }
}








############################################
### applyAction and relyied methods

sub applyAction{
  my $this = shift;

  croak "no defined 'filterValue'\n" unless defined $this->filterValue();

  if(($this->{actionType} eq 'none') or ($this->{actionType} eq 'algorithm')){
    return $this;
  }

  #to get the actual threshold value
  my $threshold = eval "\$this->".$this->{relativeTo}."()";
  carp($@) if $@;

  my $comparator = $hComparator{$this->{comparator}};

  #a list containing true values in each element which fullfills the conditions
  my @keep= map {eval "$_ $comparator $threshold"} @{$this->filterValue()};
  carp($@) if $@;

  if($this->{actionType} eq 'label'){

    croak "you cannot label fragments\n" unless ref($this->currentSpectra()) eq "InSilicoSpectro::Spectra::MSMSSpectra";

    my $i=0;
    foreach(@{$this->currentSpectra()->spectrum()}){
      my $value_tmp= sprintf("$this->{labelValue}", $this->filterValue()->[$i]);
      $_->label($this->{labelName}, $value_tmp) if $keep[$i++];
    }

    return $this;
  }

 

  my @tmp;

  if($this->{actionType} eq 'remove'){
    foreach(0..$#keep){
      push @tmp, $this->currentSpectra->spectrum()->[$_] unless $keep[$_];
    }
  }elsif($this->{actionType} eq 'removeOther'){
    foreach(0..$#keep){
      push @tmp, $this->currentSpectra->spectrum()->[$_] if $keep[$_];
      
    }
  }

  #for debugging, have to decomment @cp in MSFilterAlgorithm::smartPeaks(). Only used for this method..
#  foreach(0..$#keep){
#   printf ("%d\t%d\t%.3f\t%d\n", $_, $this->{copy}->[$_], $this->filterValue->[$_], $keep[$_]);
#    print ($this->filterValue->[$_], "\n");
#  }


  #keep only the spectra we want to

  $this->currentSpectra->spectrum(\@tmp);

  return $this;
}

sub nFix{
  my $this = shift;
  if(defined (my $d= (sort{$b <=> $a} @{$this->filterValue()})[$this->thresholdValue()-1])){
    return $d;
  }else{
    return min(@{$this->filterValue()});
  }
}


sub absValue{
  my $this = shift;
  return $this->thresholdValue();
}


sub relMax{
  my $this = shift;
  return ($this->thresholdValue())*(max @{$this->filterValue()});
}


sub quantile{
  my $this = shift;

  my $qtIndx=int ($this->thresholdValue()*@{$this->filterValue()});
  return (sort {$a <=> $b} @{$this->filterValue()})[$qtIndx];

}



##############################
### read xml part


  
use XML::Twig;

sub readXml{
  my ($this, $xml_file) = @_;

  $this->{xml_file}= $xml_file;

  my $twig=XML::Twig->new(twig_handlers=>{
					  '/ExpMsMsSpectrumFilter/oneExpMsMsSpectrumFilter'=> sub {twig_addSpectrumFilter($this, $_[0], $_[1])},
					 },
			  pretty_print=>'indented'
			 );
  
  #actually parse the file
  $twig->parsefile($xml_file) or croak "cannot parse [$xml_file]: $!";

}


sub twig_addSpectrumFilter{
  my ($this, $twig, $el)=@_;
  

  $this->{spectrumType}= $el->atts->{spectrumType};
  $this->{level}= $el->first_child('level')->text;
  
  $this->{actionType}= $el->first_child('action')->atts->{type};
  
  if ($this->{actionType} eq 'label') {
    $this->{labelValue}= $el->first_child('action')->first_child('labelValue')->text;
    $this->{labelName}= $el->first_child('action')->first_child('labelName')->text;
  }

  
  unless (($this->{actionType} eq 'algorithm') or ($this->{actionType} eq 'none')) {
  
    my $el_thr = $el->first_child('action')->first_child('threshold');
  
    $this->{relativeTo}= $el_thr->first_child('relativeTo')->text;
    $this->thresholdValue($el_thr->first_child('thresholdValue')->text);
    $this->{comparator}= $el_thr->first_child('comparator')->text;
  } 

  $this->{filterType}= $el-> first_child('filterValue')->atts->{type};
   
  bless $this, $hFmt{$this->{filterType}};

  $this->currentTwigEl($el->first_child('filterValue'));
  $this->readXmlFilterType();
    
  #free memory;
  $twig->purge if defined $twig;
}


sub readTwigEl{
  my ($this, $el) = @_;
    
  #my $el= $this->currentTwigEl();
  
  $this->twig_addSpectrumFilter(undef, $el);

}




##########################################
###   setters and getters

sub currentSpectra{
  my ($this, $sp) = @_;
  
  if(defined $sp){
    $this->{currentSpectra}= $sp;
    $this->{filterValue}=[];

    return $this;
  }
  else{
    return $this->{currentSpectra};
  }
}


sub thresholdValue{
  my ($this, $sp)=@_;

  if(defined $sp){
    $this->{thresholdValue}= $sp;
    return $this;
  }
  else{
    return $this->{thresholdValue};
  }
}


sub filterValue{
  my ($this, $sp)=@_;

  if(defined $sp){
    $this->{filterValue}= $sp;
    return $this;
  }
  else{
    return $this->{filterValue};
  }
}

sub filterName{
  my ($this, $sp)=@_;

  if(defined $sp){
    $this->{filterName}= $sp;
    return $this;
  }
  else{
    return $this->{filterName};
  }
} 



sub currentTwigEl{
   my ($this, $sp)=@_;

  if(defined $sp){
    $this->{currentTwigEl}= $sp;
    return $this;
  }
  else{
    return $this->{currentTwigEl};
  }
} 



sub originalFilterName{
  my ($this, $sp)=@_;

  if(defined $sp){
    $this->{originalFilterName}= $sp;
    return $this;
  }
  else{
    return $this->{originalFilterName};
  }
} 





return 1;
