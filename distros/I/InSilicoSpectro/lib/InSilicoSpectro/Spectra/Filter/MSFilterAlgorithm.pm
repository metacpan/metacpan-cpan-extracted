use strict;

use InSilicoSpectro;
use InSilicoSpectro::InSilico::MassCalculator;


package InSilicoSpectro::Spectra::Filter::MSFilterAlgorithm;


use InSilicoSpectro::Spectra::MSSpectra;
#use InSilicoSpectro::Spectra::MSMSSpectra;
#use InSilicoSpectro::Spectra::MSRun;

require Exporter;
our (@ISA,@EXPORT,@EXPORT_OK, $VERSION);
@ISA=qw (Exporter InSilicoSpectro::Spectra::Filter::MSFilter);
@EXPORT=qw($VERSION);
@EXPORT_OK=qw();


=head1 NAME

InSilicoSpectro::Spectra::Filter::MSFilterAlgorithm

=head1 SYNOPSIS

my $file= "a.mgf";
my $format="mgf";
my $sp=InSilicoSpectro::Spectra::MSSpectra->new(source=>$file, format=>$format);
$sp->open();

my $sf = new InSilicoSpectro::Spectra::Filter::MSFilter();
$sf->readXml('a.xml');
$sf->filterSpectra($sp);

$sp->write('mgf', "another.mgf");

=head1 DESCRIPTION

This class allows for quality assasement and filtering of spectra or peaks using algorithms mainly presented in the following paper:

M. Bern et al.
Vol. 20 Suppl. 1 2004, pages i49-i54
Bioinformatics

=head1 FUNCTIONS

=item compare_float($float_A, $comparator, $float_B, $precision)

This function is used to corretctly compare two floating-point values using a certain precision and the comparator (<, >, <=, ..). Makes it slower but it's still faster than using Math::FixedPrecision.

=head1 METHODS

=over 4

=item my $sf=InSilicoSpectro::Spectra::Filter::MSFilterAlogrithm->new()

create a new object.

=item $sf->readXml($filename)

opens the provided XML-file containing the information which filter to use and its parameters. 

=item $sf->readTwigEl($el)

reads the TwigEl passed by $el and executes twig_addSpectrumFilter() with this values.

=item $sf->filterSpectra($Spectra)

apply the XML-file previously loaded on the Spectra (can be MSRun, MS, MSMS, or MSCmpd-Spectra).

=item $sf->applyAction();

applies the action on the currentSpectra under the threshold conditions.

=item $sf->computeFilterValue($sp);

only prepared for further classes inheriting from this one.

=item $sf->checkValidity();

checks if the different values provided by the xml are valid.

=item $sf->smartPeaks();

puts a score for each peak into filterValue. The score is higher for peaks with high intensities but gets lower if they're in a region with high-intensity peaks and or a lot of peaks. A high weightIntensity-value puts more weight into regions of high peaks. A high weightDensity-value puts  more weight into regions of high peak density.

=item $sf->selectPeakWindow();

divides the whole a moz-adefined number of bands and makes a normalization of the intensities in each of those bands. 


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

=item $sf->banishNeighbors();

takes off the neighbouring peaks close to the selected ones (change number to select by selectStrongest). The region where the peaks should be taken off can be adjusted by banishRange

=item $sf->currentSpectra([$sp]);

set or get a current spectra.

=item $sf->thresholdValue([$val]);

set or get the threshold value.

=item $sf->filterValue([$val]);

set or get the filter value.

=head1 EXAMPLES

see the MSFilterAlgorithm.t for an example.

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



use File::Basename;
use Carp;
use List::Util qw(max min sum first);


$VERSION = "0.9";

###############################



sub new{
  
 my $pkg = shift;

 my $self = {};
 my $class = ref($pkg) || $pkg;
 bless $self, $class;
 return $self;
}


##############################
### read xml 

#get the parameters used by this algorithm

sub readXmlFilterType{
  my ($this)= @_;


   my $el= $this->currentTwigEl();


  my %param;
  
  foreach($el->get_xpath('*')){
    $param{$_->atts->{name}}= $_->text;
  }
  
  my $filter_name=  $param{''};
  delete $param{''};
  
  my @names= split(/\./, $filter_name);

  #if we need to come back to the original
  $this->originalFilterName(\@names);

  $this->param(\%param);


}


#################################################
### computeFilterValue and the methods it uses

#to set the precision of float-values after comma used by method compare_float
my $precision = 5;

############################################################  

#uses parameter weightIntensity to put more weight into regions near very high peaks
#parameter weightDensity to put more weight into regions with a lot of peaks

sub smartPeaks{
  my $this= shift;
  require Statistics::Basic::Mean;
  require Statistics::Basic::StdDev;

  my @moz;
  my @int;

  #use this variable in case, there's no peak at all in the spectra
  my $peaks=0;

  foreach(@{$this->currentSpectra()->spectrum()}){
    #push @{$this->filterValue()}, $_->[$pdInd];
    push @int, $_->[$this->{fragPD}->{intensity}];
    push @moz, $_->[$this->{fragPD}->{moz}];
  }

  my $win_size= $this->param()->{winSize};
  my $step_size= $this->param()->{stepSize};
  my ($min_moz,$max_moz) = (min(@moz), max(@moz));
  my ($max_int) = (max(@int));
  my @mean_win_int;

  my $last=0;

  #go through the whole spectrum
  #for(my $i=$min_moz; &compare_float($i+$win_size, '<=', $max_moz+$step_size, $precision); $i+= $step_size){
  for(my $i=$min_moz; $i+$win_size <= $max_moz+$step_size; $i+= $step_size){
    my $found=0;
    my ($start_pos, $end_pos)= (undef, undef);

    #to prevent the window of going further than the last peak of the spectra
    if($i+$win_size > $max_moz){
      $i= $max_moz-$win_size;
      $last= 1;
    }

    #get the start and end-index of the peaks in the current-window
    #my @current_win= map {&compare_float($_, '>=', $i, $precision) and &compare_float($_, '<=', $i+$win_size, $precision)} @moz;
    my @current_win= map {($_ >=$i) and ($_<=$i+$win_size)} @moz;

    foreach(0..$#current_win){
      if(!defined $start_pos){
	$start_pos= $_ if($current_win[$_]);
	next;
      }elsif(!$current_win[$_]){
	$end_pos= $_-1;
	last;
      }
    }

    #to get the last position if this is a true value
    $end_pos= $#current_win unless defined $end_pos;

    #if there are no peaks in the current window
    next unless defined $start_pos;

    #calculate the mean of the current window
    my @actual_window=@int[$start_pos..$end_pos];
    my $sum= sum @actual_window;

    #weightDensity to put more weight into windows with a lot of peaks
    my $mean= $sum/ ((scalar @actual_window)**(1/$this->param()->{weightDensity}));

    #the mean intensity of this window is stored for all the peaks ($j) in the current window
    for(my $j=$start_pos; $j<=$end_pos; $j++){
	push @{$mean_win_int[$j]}, $mean;
    }

    #ok, there was a peak
    $peaks=1;

    last if $last;
  }

  #use $this->{copy} in MSFilter::applyAction for debugging..
  #my @cp = @int;
  #$this->{copy}= \@cp;

  #no peaks, so just leave this function without touching anything!
  return $this unless $peaks;

  #the mean of all the windows in which the peak $i was found
  my @peak;
  for(my $i=0; $i<=$#int; $i++){
    my @peak= @{$mean_win_int[$i]};

    my $mean = Statistics::Basic::Mean->new(\@peak)->query;
    #weightIntensity to put more weight onto peaks in a region of high peaks
    $int[$i]/= $mean**($this->param()->{weightIntensity});
  }

  #change the filterValue, so other methods can use this values
  $this->filterValue(\@int);


  #to have a value between 0..1 as a result
  # my $max= max (@{$this->filterValue()});
  #  for(my $i=0; $i<=$#{$this->filterValue()}; $i++){
  #    $this->filterValue()->[$i]/= $max;
  #  }

  if($this->{actionType} eq 'algorithm'){
    foreach(0..$#int){
      $this->currentSpectra()->spectra()->[$_]->[$this->{fragPD}->{intensity}]= $int[$_];
    }
  }


}


#########################

#calculates the balance of the peaks using relative std-dev

sub balance{
 my $this= shift;
  require Statistics::Basic::Mean;
  require Statistics::Basic::StdDev;


 if(ref($this->currentSpectra()) ne 'InSilicoSpectro::Spectra::MSMSCmpd'){

   #have to backup the currentSpectra
   my $backup_sp= $this->currentSpectra();
  
   my @tmp;
   foreach my $a_cmpnd (@{$this->currentSpectra()->spectrum()}) {
     $this->currentSpectra($a_cmpnd);

     #go recursively through all the cmpds and get the results of all of them
     push @tmp, $this->balance();
   }

   $this->currentSpectra($backup_sp);
   #the way to pass the obtained values
   $this->filterValue(\@tmp);


   # go through the cmpd
 } else {
   my @moz;
   my @int;
   
   foreach(@{$this->currentSpectra()->spectrum()}){
     push @int, $_->[$this->{fragPD}->{intensity}];
     push @moz, $_->[$this->{fragPD}->{moz}];
     
   }

   my $division= $this->param()->{bands};

   #get min/max moz values. if there's no value as low/high as chosen by the param, the lowest/highest are selected
   my ($min_moz,$max_moz);
   ($this->param()->{minMoz}) > (min(@moz))?($min_moz=$this->param()->{minMoz}):($min_moz=min(@moz));
   ($this->param()->{maxMoz}) < (max(@moz))?($max_moz=$this->param()->{maxMoz}):($max_moz=max(@moz));
   $min_moz=min(@moz) unless defined ($this->param()->{minMoz});
   $max_moz=max(@moz) unless defined ($this->param()->{maxMoz});



   #the size of one part
   my $part_size= ($max_moz-$min_moz)/$division;
   my @sums;

   #go through all the parts of the spectrum
   for(my $i=$min_moz; &compare_float($i+$part_size, '<=', $max_moz, $precision); $i+= $part_size){
     #for(my $i=$min_moz; $i+$part_size <= $max_moz; $i+= $part_size){

     #make an array with true values for all the moz values inside the current part
     #gives the same result in the test without compare_float and is a lot faster
     #my @keep= map {&compare_float($i, '<=', $_, $precision) and &compare_float($_, '<=', $i+$part_size, $precision)} @moz;
     my @keep= map {($i<= $_) and ($_<= $i+$part_size)} @moz;

     #part contains all the intensities of current part
     #use the found, so it's not going meaningless trough the whole end of the array
     my @part;
     my $found=0;
     foreach (0..$#keep) {
       if ($keep[$_]) {
	 push @part, $int[$_];
	 $found++ unless $found;
       } elsif ($found) {
	 last;
       }
     }

     #put a 0 into undef part
     push @part, 0 unless $part[0];

     #the sum of all the intensities of a part
     my $sum = sum (@part);
     push @sums, $sum; 
   }
 
   my $std_dev= Statistics::Basic::StdDev->new(\@sums)->query;
   my $mean= Statistics::Basic::Mean->new(\@sums)->query;


   #divide one by rel-stdev, because the smaller the stddev, the better the result
   return 0 unless $mean;
   return 1 unless $std_dev;
   return 1/($std_dev/$mean);

 }
 
}



#need this function in order to compare float-point values correctly
#makes it slow but still faster than using Math::FixedPrecision

sub compare_float{
  my ($A, $comparator,  $B, $dp)= @_;

  my $result= eval "sprintf(\"%.${dp}g\", $A) $comparator sprintf(\"%.${dp}g\", $B)";
  carp($@) if $@;

  return $result;
}



#the balance algorithm described in the paper from Bern et al.
#should be possible to make a lot faster one. But first I want to see if it's worth something..

sub balanceBern{
 my $this= shift;

 if(ref($this->currentSpectra()) ne 'InSilicoSpectro::Spectra::MSMSCmpd'){

   my $backup_sp= $this->currentSpectra();
   my @tmp;
   my $i=0;
   foreach my $a_cmpnd (@{$this->currentSpectra()->spectrum()}) {
     $this->currentSpectra($a_cmpnd);
     $tmp[$i++]=$this->balanceBern();

    
   }
    
   $this->currentSpectra($backup_sp);
   $this->filterValue(\@tmp);

 
 } else {

   my @moz;
   my @tmp;
   
   foreach(@{$this->currentSpectra()->spectrum()}){
     push @tmp, $_->[$this->{fragPD}->{intensity}];
     push @moz, $_->[$this->{fragPD}->{moz}];
     
   }

     
   $this->filterValue(\@tmp);

   my $division= 10;
   
 #get min/max moz values. if there's no value as low/high as chosen by the param, the lowest/highest are selected
   my ($min_moz,$max_moz);
   ($this->param()->{minMoz}) > (min(@moz))?($min_moz=$this->param()->{minMoz}):($min_moz=min(@moz));
   ($this->param()->{maxMoz}) < (max(@moz))?($max_moz=$this->param()->{maxMoz}):($max_moz=max(@moz));
   $min_moz=min(@moz) unless defined ($this->param()->{minMoz});
   $max_moz=max(@moz) unless defined ($this->param()->{maxMoz});

   
   my $part_size= ($max_moz-$min_moz)/$division;
   my @sums;


   #for(my $i=$min_moz; &compare_float($i+$part_size, '<=', $max_moz, $precision); $i+= $part_size){
   for (my $i=$min_moz; $i+$part_size <= $max_moz; $i+= $part_size){
     
     #my @keep= map {&compare_float($i, '<=', $_, $precision) and &compare_float($_, '<=', $i+$part_size, $precision)} @moz;
     my @keep= map {($i <= $_) and ($_<=$i+$part_size)} @moz;
     
     #use the found, so it's not going meaningless trough the whole end of the array
     my @part;
     my $found=0;
     foreach (0..$#keep) {
       if ($keep[$_]) {
	 push @part, $this->filterValue()->[$_];
	 $found++ unless $found;
       } elsif ($found) {
	 last;
       }
     }

     #put a 0 into undef part
     push @part, 0 unless $part[0];

     my $sum = sum (@part);
     #print "sum: $sum\t\n";
     push @sums, $sum; 
   }


   my @sorted= sort{$b <=> $a} @sums;
   #print ($sorted[0]+$sorted[1]-$sorted[-7]-$sorted[-6]-$sorted[-5]-$sorted[-4]-$sorted[-3]-$sorted[-2]-$sorted[-1], "\n");
 
   return $sorted[0]+$sorted[1]-$sorted[-7]-$sorted[-6]-$sorted[-5]-$sorted[-4]-$sorted[-3]-$sorted[-2]-$sorted[-1];

 }
 
}



########################################


sub goodDiff{
  my $this= shift;
  #if current spectra is MSMSSpectra we call goodDiff recursively for each compound
  if(ref($this->currentSpectra()) ne 'InSilicoSpectro::Spectra::MSMSCmpd'){

    my $backup_sp= $this->currentSpectra();
    my @tmp;
    my $i=0;
    foreach my $a_cmpnd(@{$this->currentSpectra()->spectrum()}){
      $this->currentSpectra($a_cmpnd);

      #because this method already used the first name we leave this one away
      my @double= @{$this->originalFilterName()}[1..$#{$this->originalFilterName()}];
      $this->filterName(\@double);

      #call this function recursively
      $tmp[$i++]=$this->goodDiff();

    }

    $this->currentSpectra($backup_sp);
    $this->filterValue(\@tmp);

    return $this;

  #calculate goodDiff for actual compound 
  }else{

    #load the amino acid-masses from insilicodef.xml
    if(!defined $this->{aaMasses}){

#    print "".__FILE__.":".__LINE__.": problem between here\n";

    InSilicoSpectro::init();
    
 #   print "".__FILE__.":".__LINE__.": and here??\n";



      my @aa_list= qw/A C D E F G H I K L M N P Q R S T V W Y/;

      my @mono;
      my @average;

      foreach (@aa_list){
	push @mono, InSilicoSpectro::InSilico::MassCalculator::getMass("aa_$_", 0);
	push @average, InSilicoSpectro::InSilico::MassCalculator::getMass("aa_$_", 1);

      }

      $this->{aaMasses}->{mono}= \@mono;
      $this->{aaMasses}->{average}= \@average;



    }

    my @moz;
    my @int;
    my @singly_charged;

    #use singly_charged to keep only singly charged values
    my $i=0;
    if(defined $this->{fragPD}->{charge}){
      foreach(@{$this->currentSpectra()->spectra()}){
	if ($_->[$this->{fragPD}->{charge}] <= 1) {
	  push @singly_charged, $i;
	  push @moz, $_->[$this->{fragPD}->{moz}];	
	}
	$i++;
      }
    }else{
      foreach(@{$this->currentSpectra()->spectra()}){
	if ($_->[$this->{fragPD}->{chargemask}] <= 3) {
	  push @singly_charged, $i;
	  push @moz, $_->[$this->{fragPD}->{moz}];	
	}
	$i++;
      }
    }

    #because I make a copy of the current-spectrum, I can delete peaks out of it
    my @tmp = @{$this->currentSpectra->spectrum()}[@singly_charged];
    $this->currentSpectra->spectrum(\@tmp);

    

    #get the int-values from the following filter-name (so we can use normalisation eg: goodDiff.normRank) 
    my $current_name= shift @{$this->filterName()};

    eval "\$this->".$current_name."()";
    carp($@) if $@;
    @int=@{$this->filterValue()};

    my $tolerance= $this->param()->{tolerance};

    #select if avarage or monoisotopic mass
    my $mass_id= $this->param()->{mass};

    #if we want to apply this function just on a defined number of peaks using a filter
    if(defined $this->param()->{filter}){
      
      my $filter= $this->param()->{filter};
    
      eval "\$this->".$filter."()";
      carp($@) if $@;

      my $backup= $this->thresholdValue();
      $this->thresholdValue(1+$this->param()->{peakNr});
      my $threshold= $this->nFix();
      $this->thresholdValue($backup);

      my @keep= map {$_ >= $threshold} @{$this->filterValue()};

      my @keep_id;
     
      foreach(0..$#keep){
	push @keep_id, $_ if $keep[$_]==1;
	
      }

      #keep only the int and moz values of the selected peaks
      @int = @int[@keep_id];
      @moz= @moz[@keep_id];

     

    }

    #for debugging..
   # my @count;
#    foreach(0..$#moz){
#      $count[$_]='';
#    }


    

    my $count=0;
      
    #it gives a different result, by using the &compare_float function in this algorithm.
    #but because the errors are few and it's a lot faster, I leave it like this..
   
    for(my $current_peak=0; $current_peak<$#moz; $current_peak++){
    #to consider each peak_pair only once, even if several aa-masses (eg. leu/ile) match
      my %used_i;
      #check all the 20 amino-acids
      for(my $j=0; $j<=$#{$this->{aaMasses}->{$mass_id}}; $j++){
	#if there's one that matches the distance between the peaks within the tolerance..
	for(my $i=$current_peak+1; ($moz[$i]-$moz[$current_peak] <= $this->{aaMasses}->{$mass_id}->[$j]+$tolerance) and $i<=$#moz; $i++){
	  if(($moz[$i]-$moz[$current_peak] >= $this->{aaMasses}->{$mass_id}->[$j]-$tolerance)and !defined($used_i{$i})){
	    #for debugging only..
	    #$count[$current_peak].="<".$this->filterValue()->[$i].">".$this->{aaMasses}->{$mass_id}->[$j];

	    #add the values of these peaks to the total
	    $count+= $int[$i] + $int[$current_peak];
	    $used_i{$i}=1;
	  }
	
	}
      }
    }

    #for debugging only..
    #foreach(0..$#count){
#      printf ("%f\t%f\t%s\n", $this->filterValue()->[$_], $moz[$_], $count[$_]);
#    }


    return $count;

  }

}



########################################
#basically the same as goodDiff.. but looks only for the distance of the mass of water..
#have a look at goodDiff for better documentation..


sub waterLosses{
  my $this= shift; 

  #if current spectra is MSSpectra we call waterLosses recursively for each compound
  if(ref($this->currentSpectra()) ne 'InSilicoSpectro::Spectra::MSMSCmpd'){

   
    my $backup_sp= $this->currentSpectra();
    my @tmp;
    my $i=0;
    foreach my $a_cmpnd(@{$this->currentSpectra()->spectrum()}){
      $this->currentSpectra($a_cmpnd);
      my @double= @{$this->originalFilterName()}[1..$#{$this->originalFilterName()}];
      $this->filterName(\@double);
      $tmp[$i++]=$this->waterLosses();
      
    }

    $this->currentSpectra($backup_sp);
    $this->filterValue(\@tmp);

       
  #calculate waterLosses for actual compound
  }else{


    my %waterMasses= (
		      'mono' => 18.01056, 
		      'average' => 18.01524, 
		     );

    my @moz;
    my @int;
    my @singly_charged;

   
    my $i=0;
    if(defined $this->{fragPD}->{charge}){
      foreach(@{$this->currentSpectra()->spectra()}){

	#print ("chargemask: ",$this->{fragPD}->{chargemask}, "\n");
	#print ($_->[$this->{fragPD}->{charge}], "\n");

	if ($_->[$this->{fragPD}->{charge}] <= 1) {
	  push @singly_charged, $i;
	  push @moz, $_->[$this->{fragPD}->{moz}];	
	}
	$i++;
      }
    }else{
      foreach(@{$this->currentSpectra()->spectra()}){

	#print ("chargemask: ",$this->{fragPD}->{chargemask}, "\n");
	#print ($_->[$this->{fragPD}->{chargemask}], "\n");

	if ($_->[$this->{fragPD}->{chargemask}] <= 3) {
	  push @singly_charged, $i;
	  push @moz, $_->[$this->{fragPD}->{moz}];	
	}
	$i++;
      }
    }

    my @tmp = @{$this->currentSpectra->spectrum()}[@singly_charged];
    $this->currentSpectra->spectrum(\@tmp);

    my $current_name= shift @{$this->filterName()};
    eval "\$this->".$current_name."()";
    carp($@) if $@;
    @int=@{$this->filterValue()};

    my $tolerance= $this->param()->{tolerance};
    my $mass_id= $this->param()->{mass};

    #if we want to apply this function just on a defined number of peaks using a filter
    if(defined $this->param()->{filter}){

      my $filter= $this->param()->{filter};

      eval "\$this->".$filter."()";
      carp($@) if $@;

      my $backup= $this->thresholdValue();
      $this->thresholdValue(1+$this->param()->{peakNr});
      my $threshold= $this->nFix();
      $this->thresholdValue($backup);


      my @keep= map {$_ >= $threshold} @{$this->filterValue()};
      
      my @keep_id;

      foreach(0..$#keep){
	
	push @keep_id, $_ if $keep[$_]==1;
	
      }

      @int = @int[@keep_id];

      @moz= @moz[@keep_id];
    }


     #for debugging..
    # my @count;
#        foreach(0..$#moz){
#          $count[$_]='';
#        }



    my $count=0;

    for(my $current_peak=0; $current_peak<$#moz; $current_peak++){
      #because a tolerance is used we have to watch out to consider each peak_pair only once
      
      for(my $i=$current_peak+1; ($moz[$i]-$moz[$current_peak]<=$waterMasses{$mass_id}+$tolerance) and $i<=$#moz; $i++){
	if($moz[$i]-$moz[$current_peak]>=$waterMasses{$mass_id}-$tolerance){
	  #$count[$current_peak].="<$moz[$i]>".$waterMasses{$mass_id};

	  #there's a good distance, so add the value of both the peaks to the total count.
	  $count+= $int[$i]+ $int[$current_peak];
	  
	}
	
      }
    }
    
    #for debugging only..
    #foreach(0..$#count){
#      print "$count[$_]\n";
#    }

    return $count;
    
  }
  
}



########################################3

# will be implemented later.. probably..


sub isotopes{
  my $this= shift;

  croak "filter \'isotopes\' not implemented yet!\n";

}


###########################################

# takes off the neighbouring peaks close to the selected ones (change number to select by selectStrongest)
# the region where the peaks should be taken off can be adjusted by banishRange


sub selectPeakWindow{
  my $this= shift;

#  print ($this->currentSpectra()->{title}, "\n");

  croak "banishNeighbors can only be applied on level: peaks\n" unless($this->{level} eq 'peaks');


  my $action_type= $this->{actionType};
  my $window_nr= $this->param()->{nrWindows};


  #get moz and int
    my @moz;
    my @int;

    foreach (@{$this->currentSpectra()->spectrum()}) {
      #push @{$this->filterValue()}, $_->[$pdInd];
      push @int, $_->[$this->{fragPD}->{intensity}];
      push @moz, $_->[$this->{fragPD}->{moz}];
    }

    my $moz_min= min(@moz);
    my $moz_max= max(@moz);
    my $moz_range= $moz[$#moz]-$moz[0];

    my $win_size= $moz_range/$window_nr;

    my $pos= 0;
    my $current_max_moz= $moz_min+ $win_size;


  if($action_type eq 'algorithm'){
    my $peak_nr = $this->param()->{nrPeaksTotal};
    my $peak_nr_window= int($this->param()->{nrPeaksTotal}/$window_nr);

    #print "peaks to selcet: $peak_nr_window\n";

    my @to_keep;

    #loop through all the windows
    for (my $j=0; $j<$window_nr; $j++) {
      my $old_pos= $pos;

      #print ("part from ", $moz[$old_pos], " to ", $current_max_moz, ": \n");
      my $win_int_max= 0;

      my @win_int;

      #loop trouhg all the peaks in one window
      while (($moz[$pos]<=$current_max_moz) and ($pos<$#moz)) {
	push @win_int, $int[$pos];
	$pos++;
      }

      my $threshold= ((sort{$b <=> $a} @win_int)[$peak_nr_window-1]);
      #if there are less nr than u want
      $threshold= min(@win_int) if(! defined $threshold);
      #if theres nothing at all
      next if(! defined $threshold);

      #print ("pekas in wind: ", scalar(@win_int), "\n");
      #print ("higest", max(@win_int), "\n");

      #print ("lowest", min(@win_int), "\n");

      #print "threshold: $threshold\n";

      for (my $i=$old_pos; $i<$pos; $i++) {
	push @to_keep, $i if $int[$i]>=$threshold;
	#print "$int[$i]\t$threshold\n";
      }
      $current_max_moz+= $win_size;
    }

    #print "*******************************************\n";
    #foreach(@to_keep){
        #print "$_\n";
    #}
    

    @{$this->currentSpectra()->spectra}=  @{$this->currentSpectra()->spectra}[@to_keep];

  }else{

    my @filter_value;

    #loop through all the windows
    for (my $j=0; $j<$window_nr; $j++) {
      my $old_pos= $pos;

      #print ("part from ", $moz[$old_pos], " to ", $current_max_moz, ": \n");
      my $win_int_max= 0;

      #loop trouhg all the peaks in one window
      while (($moz[$pos]<=$current_max_moz) and ($pos<$#moz)) {
	#     print ($moz[$pos], "\t", $int[$pos], "\n");
	$win_int_max= $int[$pos] if $int[$pos]>$win_int_max;
	$pos++;
      }

      #loop again trough peaks to divide by max-int
      for (my $i=$old_pos; $i<$pos; $i++) {
	push @filter_value, ($int[$i]/$win_int_max);
	#print ($moz[$i], "\t", $int[$i], "\n");
      }

      $current_max_moz+= $win_size;
    }

    $this->filterValue(\@filter_value);

  }

}



sub banishNeighbors{
  my $this= shift;

  croak "banishNeighbors can only be applied on level: peaks\n" unless($this->{level} eq 'peaks');


  #backup the parameters
  my $action_type= $this->{actionType};
  
  #get the parameters
  my $select_quantile= 1-$this->param()->{selectStrongest};
  my $win_size= $this->param()->{banishRange};
  my $skip_spectra_below= $this->param()->{skipSpectraBelow} if ($action_type eq 'algorithm');
  my $banish_limit= $this->param()->{banishLimit};


  #first we have to use a seperate filter on the currentSpectra to get
  #get the intensities
  $this->fragment("intensity");
  my @int= @{$this->filterValue()};


  my @ranks;
  if($action_type eq 'algorithm'){
    return $this->filterValue() if (scalar(@int) < $skip_spectra_below);
  }
  else{
    #get the ranks.. need them to make the peaks without interest smaller
    
    my %rank;
    my $i=1;
    my $j=0;
    my $last=0;

    foreach (sort {$b <=> $a} @{$this->filterValue()}) {
      if ($_==$last) {
	$j++;
      } else {
	$rank{$_}= $j+$i++;
	$j=0 if $j;
	$last=$_;
      }
    }
    foreach (@{$this->filterValue()}) {
      push @ranks, $rank{$_};
    }
  }
 
  my $qtIndx=int ($select_quantile*@int);
  my $threshold= (sort {$a <=> $b} @int)[$qtIndx];
  my @keep= map {$_ >= $threshold} @int;

  my @selected_peaks_moz;

  foreach(0..$#keep){
    push @selected_peaks_moz, $this->currentSpectra()->spectra()->[$_]->[$this->{fragPD}->{'moz'}] if $keep[$_];
  }


  $this->fragment("moz");
  my @moz= @{$this->filterValue()};


  my $min_int= min(@int);
  my $min_moz= min(@moz);
  my $max_moz= max(@moz);


  my %to_delete;

  #go through peaks considered as 'strong'..
  foreach my $j(0..$#selected_peaks_moz){
    my $left_border= $selected_peaks_moz[$j]-$win_size>=$min_moz ? $selected_peaks_moz[$j]-$win_size : $min_moz;
    my $right_border= $selected_peaks_moz[$j]+$win_size<=$max_moz ? $selected_peaks_moz[$j]+$win_size : $max_moz;

    #ze window
    my @current_win= map {($_ >=$left_border) and ($_<=$right_border)}@moz;
    my %current_win_values;
    my $after_window=0;

    foreach my $i(0..$#current_win){
       last if ($current_win[$i]==0 and $after_window);
       next unless $current_win[$i]==1;

       $current_win_values{$i}=$int[$i];
       $after_window=1 unless $after_window;
     }

    my $peak_limit= max(values %current_win_values)*$banish_limit;


    foreach(keys %current_win_values){
      if($action_type eq 'algorithm'){
	$to_delete{$_}=1 if($current_win_values{$_}<$peak_limit);

      }else{
	#make division by the rank to make them smaller than even the smallest peak
	$int[$_]= $min_int/$ranks[$_] if($current_win_values{$_}<$peak_limit);
      }

    }

  }

  if($action_type eq 'algorithm'){

    my @to_keep;
    foreach (0..$#int) {
      push @to_keep, $_ unless defined $to_delete{$_};
    }
    @{$this->currentSpectra()->spectra}=  @{$this->currentSpectra()->spectra}[@to_keep];
  }

  $this->filterValue(\@int);
}



#############################################################
#looks if the moz of two peaks add up to the precursor-ion

#the first part is essentially the same as goodDiff, so have a look there for better documentation


sub complements{
  my $this= shift;

 #if current spectra is MSSpectra we call recursively for each compound
  if(ref($this->currentSpectra()) ne 'InSilicoSpectro::Spectra::MSMSCmpd'){

    my $backup_sp= $this->currentSpectra();
    my @tmp;
    my $i=0;
    foreach my $a_cmpnd(@{$this->currentSpectra()->spectrum()}){
      $this->currentSpectra($a_cmpnd);
      my @double= @{$this->originalFilterName()}[1..$#{$this->originalFilterName()}];
      $this->filterName(\@double);
      $tmp[$i++]=$this->complements();
    }

    $this->currentSpectra($backup_sp);
    $this->filterValue(\@tmp);

  #calculate complements for actual compound
  }else{

    my @moz;
    my @int;
    my @singly_charged;
    my @parent_charge;

    #to get the different charge states of the precursor into an array
    my $parent_moz= $this->currentSpectra()->getParentData($this->{parentPD}->{moz});

    if(defined $this->{parentPD}->{chargemask}){
      my $mask= $this->currentSpectra()->getParentData($this->{parentPD}->{chargemask});

      #get the different probable charges of the precursor-ion into array
      my $charges= chargemask2string($mask);

      @parent_charge = split(',',$charges);

    }else{
      @parent_charge = split(',',$this->currentSpectra()->getParentData($this->{parentPD}->{charge}));
    }
      

    #get a list with all the singly charged values and the moz-values
    my $i=0;

    if(defined $this->{fragPD}->{charge}){
      foreach(@{$this->currentSpectra()->spectra()}){
	#print ("chargemask: ",$this->{fragPD}->{chargemask}, "\n");
	#print ($_->[$this->{fragPD}->{charge}], "\n");

	if ($_->[$this->{fragPD}->{charge}] <= 1) {
	  push @singly_charged, $i;
	  push @moz, $_->[$this->{fragPD}->{moz}];	
	}
	$i++;
      }
    }else{
      foreach(@{$this->currentSpectra()->spectra()}){

	#print ("chargemask: ",$this->{fragPD}->{chargemask}, "\n");
	#print ($_->[$this->{fragPD}->{chargemask}], "\n");

	if ($_->[$this->{fragPD}->{chargemask}] <= 3) {
	  push @singly_charged, $i;
	  push @moz, $_->[$this->{fragPD}->{moz}];	
	}
	$i++;
      }
    }

    my @tmp = @{$this->currentSpectra->spectrum()}[@singly_charged];
    $this->currentSpectra->spectrum(\@tmp);

    #get the int-values
    my $current_name= shift @{$this->filterName()};
    #print "current_name: $current_name\n";
    eval "\$this->".$current_name."()";
    carp($@) if $@;
    @int=@{$this->filterValue()};


    my $tolerance= $this->param()->{tolerance};
    my $mass_id= $this->param()->{mass};

    #if we want to apply this function just on a defined number of peaks using a filter
    if(defined $this->param()->{filter}){

      my $filter= $this->param()->{filter};

      eval "\$this->".$filter."()";
      carp($@) if $@;

      my $backup= $this->thresholdValue();
      $this->thresholdValue(1+$this->param()->{peakNr});
      my $threshold= $this->nFix();
      $this->thresholdValue($backup);


      my @keep= map {$_ >= $threshold} @{$this->filterValue()};
      my @keep_id;

      foreach(0..$#keep){
	push @keep_id, $_ if $keep[$_]==1;
      }

      @int = @int[@keep_id];
      @moz= @moz[@keep_id];
    }

    #only for debugging
    #my @print_count;
    #foreach(0..$#moz){
    #      $print_count[$_]='';
    #    }
    #    my $j=0;
    
    my @count;


    #set all to 0
    foreach(@parent_charge){
      $count[$_]=0;
    }


    #go through all the peaks..
    for(my $current_peak=0; $current_peak<$#moz; $current_peak++){
      #..and compare them with all following peaks
      for(my $i=$current_peak+1; $i<=$#moz; $i++){
	#consider the different parent-charge states
	foreach(@parent_charge){
	  my $sum_moz= $moz[$i]+$moz[$current_peak];
	
	  #if the sum is equal (with tolerance) the parent-moz
	  if (($sum_moz>=($parent_moz*$_)-$tolerance)and ($sum_moz<=($parent_moz*$_)+$tolerance)){

	    #only for debugging..
	    #    $print_count[$j++]=sprintf ("sum: %f\t-t: %f\t+t: %f p1/p2/chr: %i/%i/%i m1/m2: %i/%i\n", $sum_moz, ($parent_moz*$_)-$tolerance, ($parent_moz*$_)+$tolerance, $current_peak, $i, $_, $moz[$current_peak], $moz[$i]);
	
	    $count[$_]= $int[$i] + $int[$current_peak];
	
	  }
	}
	
      }
    }

    #only for debbuging..
   # foreach(0..$#print_count){
    #  print "$print_count[$_]\n";
    #}


    #and only return the bigger result for the possible parent-charge states
    return (max(@count));

  }

}





##########################################
###   setters and getters


sub param{
  my ($this, $sp)=@_;

  if(defined $sp){
    $this->{param}= $sp;
    return $this;
  }
  else{
    return $this->{param};
  }
} 










return 1;
