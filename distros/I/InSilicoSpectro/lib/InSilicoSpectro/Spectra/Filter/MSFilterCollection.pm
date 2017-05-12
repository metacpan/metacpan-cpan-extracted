use strict;

package InSilicoSpectro::Spectra::Filter::MSFilterCollection;

use InSilicoSpectro::Spectra::MSSpectra;
use InSilicoSpectro::Spectra::Filter::MSFilter;
#use InSilicoSpectro::Spectra::MSMSSpectra;
#use InSilicoSpectro::Spectra::MSRun;

require Exporter;
our (@ISA,@EXPORT,@EXPORT_OK, $VERSION);
@ISA=qw (Exporter);
@EXPORT=qw($VERSION);
@EXPORT_OK=qw();

=head1 NAME

InSilicoSpectro::Spectra::Filter::MSFilterCollection

=head1 SYNOPSIS

my $file= "a.idj.xml";
my $sr=InSilicoSpectro::Spectra::MSRun->new();
$sr->readIDJ($file);

my $fc = new InSilicoSpectro::Spectra::Filter::MSFilterCollection();
$fc->readXml('a_filter_list.xml');
$fc->filterSpectra($sr);

my $file_out;
open ($file_out, ">another.idj.xml");
$sr->write('idj', $file_out);
close $file_out;

=head1 DESCRIPTION

This class allows you to filter your spectra with a list of filters in a xml-entry. The spectra is succesively filtered one after each other.

=head1 METHODS

=over 4

=item my $sf=InSilicoSpectro::Spectra::Filter::MSFilterCollection->new()

create a new object.

=item $sf->readXml($filename)

opens the provided XML-file containing the information the filters and its parameters.

=item $sf->filterSpectra($Spectra, [$filter_nr])

apply all or only a selected XML-filter previously loaded on the Spectra (can be MS, MSMS, MSCmpd-Spectra or MSRun).

=item $sf->checkValidity();

checks if the different values provided by the xml are valid.

=item $sf->xmlFilter([$filter_nr]);

returns the filter chosen or a list containing all the filters.

=item $sf->addXmlFilter($filter_twig_el);

adds a xml-filter-twig-el to the actual filter-list.

=head1 EXAMPLES

see the the MSFilterCollection.t for an example.

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

#use File::Basename;
use Carp;
#use List::Util qw(max min sum first);


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


use XML::Twig;

sub readXml{
  my ($this, $xml_file) = @_;

  $this->{xml_file}= $xml_file;
  $this->{xmlFilterList}= ();

  my $twig=XML::Twig->new(twig_handlers=>{
					  '/ExpMsMsSpectrumFilter'=> sub {twig_addSpectrumFilter($this, $_[0], $_[1])},
					 },
			  pretty_print=>'indented'
			 );
  
  #actually parse the file
  $twig->parsefile($xml_file) or croak "cannot parse [$xml_file]: $!";

}


sub twig_addSpectrumFilter{
  my ($this, $twig, $el)=@_;

  foreach my $twig_el ($el->get_xpath('*')) {
    $this->addXmlFilter($twig_el);
  }

  #free memory;
  $twig->purge if defined $twig;
}


sub readXmlString{
  my ($this, $xml_string)= @_;

  $this->{xmlFilterList}= ();

  my $twig= XML::Twig->new(twig_handlers=>{
					  '/ExpMsMsSpectrumFilter'=> sub {twig_addSpectrumFilter($this, $_[0], $_[1])},
					 },
			  pretty_print=>'indented'
			 );

  $twig->parse($xml_string) or croak "cannot parse the xml-string: $!";

}




######################################

sub addXmlFilter{
  my ($this, $filter_el)= @_;

  push @{$this->{xmlFilterList}}, $filter_el;

  return $this->{xmlFilterList};
}


#####################################


sub filterSpectra{
  my ($this, $spectra, $filter_nr) = @_;

  if(defined $filter_nr){
    my $sf = new InSilicoSpectro::Spectra::Filter::MSFilter();
    $sf->readTwigEl($this->{xmlFilterList}->[$filter_nr]);
    $sf->filterSpectra($spectra);
  }else{
    foreach(0..$#{$this->{xmlFilterList}}){
      $this->filterSpectra($spectra, $_);
    }
  }

  return $spectra;
}



#######################################


sub xmlFilter{
  my ($this, $filter_nr);

  if(defined $filter_nr){
    return $this->{xmlFilterList}->[$filter_nr];
  }

  return $this->{xmlFilterList};

}




return 1;

