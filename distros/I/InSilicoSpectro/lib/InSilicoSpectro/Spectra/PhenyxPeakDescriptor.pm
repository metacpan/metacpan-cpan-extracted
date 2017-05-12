use strict;

package InSilicoSpectro::Spectra::PhenyxPeakDescriptor;
use Carp;

use  InSilicoSpectro::Spectra::PeakDescriptor;

our (@ISA,@EXPORT,@EXPORT_OK);
@ISA=qw (InSilicoSpectro::Spectra::PeakDescriptor);
@EXPORT=qw();
@EXPORT_OK=qw();


=head1 NAME

InSilicoSpectro::Spectra::PhenyxPeakDescriptor

=head1 SYNOPSIS

  my $t=XML::Twig->new->parsefile($file);
  my @el=$t->get_xpath("ple:ItemOrder");
  my @pd;
  foreach(@el){
    my $pd=InSilicoSpectro::Spectra::PhenyxPeakDescriptor->new();
    $pd->readTwigEl($_);
    $pd->writeXml();
    push @pd, $pd;
  }
  print "comparing to first node\n";
  foreach(1..$#pd){
    print "$_ -> ".(($pd[$_]->equalsTo($pd[0]))?"OK":"!=")."\n";
  }

=head1 DESCRIPTION

List of fields name related to peak
Merely contains a list of names (ex ['mass', 'intensity', 'prob'])

=head1 FUNCTIONS


=head1 METHODS

=over 4

=item my $pd=InSilicoSpectro::Spectra::PhenyxPeakDescriptor->new([\%h])

=item $pd->writeXml()

=item $pd->readTwigEl($tw)

Read info from an Xml::Twig node tagged <ple:ItemOrder>

=head1 EXAMPLES


=head1 SEE ALSO

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

Alexandre Masselot, www.genebio.com

=cut

sub new{
  my $class=shift;
  my $self = InSilicoSpectro::Spectra::PeakDescriptor->new(@_);
  bless $self, $class;
  return $self;
}



use XML::Twig;
sub readTwigEl{
  my ($this, $t)=@_;
  confess unless $t;
  confess "InSilicoSpectro::Spectra::PhenyxPeakDescriptor::readTwigEl tag name should be (ple:)?ItemOrder" unless $t->gi =~/(ple:)?ItemOrder/;
  $this->{fieldNames}=[];
  foreach($t->children("ple:item"), $t->children("item")){
    my $f=$_->att('type') or croak "InSilicoSpectro::Spectra::PhenyxPeakDescriptor::readTwigEl no 'type' attribute for element ple:item";
    $this->pushField($f);
  }
}


sub writeXml{
  my ($this, $shift, $transformCharge)=@_;

  print "$shift<ple:ItemOrder xmlns:ple=\"namespace/PeakListExport.html\">\n";
  foreach (@{$this->{fieldNames}}){
    if ($transformCharge and ($_ eq 'chargemask')){
      print "$shift  <ple:item type=\"charge\"/>\n" ;
    }else{
      print "$shift  <ple:item type=\"$_\"/>\n";
    }
  }
  print "$shift</ple:ItemOrder>\n";
}


sub sprintData{
  my ($this, $data, $transformCharge)=@_;

  my $ret;
  my @tmp=reverse @$data;
  foreach (@{$this->{fieldNames}}){
    my $v=pop @tmp;
    if(not defined $v){
      $ret.="? ";
      next;
    }
    if($transformCharge and ($_ eq 'chargemask')){
      if($v eq '?' or not $v){
	$ret.='? ';
      }else{
	$ret.=InSilicoSpectro::Spectra::MSSpectra::chargemask2string($v)." ";
      }
    }else{
      $ret.="$v ";
    }
  }
  $ret=~s/\s+$//;
  return $ret;
}

return 1;
