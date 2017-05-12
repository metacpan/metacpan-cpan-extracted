use strict;

package InSilicoSpectro::Spectra::Filter::MSFilterDirectValue;

use InSilicoSpectro::Spectra::MSSpectra;

require Exporter;
our (@ISA,@EXPORT,@EXPORT_OK, $VERSION);
@ISA=qw (Exporter InSilicoSpectro::Spectra::Filter::MSFilter);
@EXPORT=qw($VERSION);
@EXPORT_OK=qw();



=head1 NAME

InSilicoSpectro::Spectra::Filter::MSFilterDirectValue

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

This class allows for quality assasement and filtering of spectra or peaks using direct (or very simple) accesible informations.

=head1 METHODS

=over 4

=item my $sf=InSilicoSpectro::Spectra::Filter::MSFilterDirectValue->new()

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

=item $sf->size();

stores the at the moment just considers the size of fragments

=item $sf->summ();

sums up the fragment intensities or moz-values and stores the value for each compound in filterValues. The method summ() corresponds to the filter sum. It is renamed, because List::Utils allready uses this function-name.

=item $sf->log_();

the natural log of the filterValue. This method is renamed to log_() because this name is already used. 

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

see MSFilterDirecValue.t for an example.

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
use List::Util qw(max sum);


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
### read xml part

sub readXmlFilterType{
  my ($this)= @_;

  #my $twig=XML::Twig->new(twig_handlers=>{
#					  '/ExpMsMsSpectrumFilter/oneExpMsMsSpectrumFilter/filterValue'=> sub {twig_addDirectValue($this, $_[0], $_[1])},
#					 },
#			  pretty_print=>'indented'
#			 );
  
#  #actually parse the file
#  $twig->parsefile($this->{xml_file}) or croak "cannot parse [$this->{xml_file}]: $!";


  my $el= $this->currentTwigEl();
  my $filter_name = $el->first_child('name')->text;
  $filter_name=~ s/log/log_/;
  $filter_name=~ s/sum/summ/;

  my @names= split(/\./, $filter_name);
  $this->originalFilterName(\@names);
  


}



#################################################
### computeFilterValue and the methods it uses

#at the moment just considers the size of fragments..
sub size{
  my $this= shift;

  foreach(@{$this->currentSpectra()->spectrum()}){
     push @{$this->filterValue()}, $_->size();

  }
}


#renamed from sum because sum is allready used by List::Utils
sub summ{
  my $this= shift;
  my @dummy;
  my $backup_sp = $this->currentSpectra();

  my $current_name= shift @{$this->filterName()};
  my $next_name= shift @{$this->filterName()};


  foreach(@{$this->currentSpectra()->spectrum()}){
    $this->currentSpectra($_);

    eval "\$this->".$current_name."(\"".$next_name."\")";
    carp($@) if $@;

    push @dummy, sum(@{$this->filterValue()});

  }

  $this->currentSpectra($backup_sp);

  $this->filterValue(\@dummy);
}


#the natural log of the filterValue, renamed from log
sub log_{
  my $this= shift;

  my @dummy;
  my $backup_sp = $this->currentSpectra();

  my $current_name= shift @{$this->filterName()};
  my $next_name= shift @{$this->filterName()};

  eval "\$this->".$current_name."(\"".$next_name."\")";
  carp($@) if $@;

  my @tmp_filterValue;
  foreach(@{$this->filterValue()}){
    push @tmp_filterValue, log($_);
  }

  $this->currentSpectra($backup_sp);
  $this->filterValue(\@tmp_filterValue);

}



###############################################
### just to define..

sub param{
  my $this=shift;
  my %h=('empty' => 'no params..');
  $this->{param}= \%h;
}



##########################################
###   setters and getters








return 1;
