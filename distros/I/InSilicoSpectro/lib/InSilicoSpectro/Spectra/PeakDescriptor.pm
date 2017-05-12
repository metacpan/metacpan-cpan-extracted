package InSilicoSpectro::Spectra::PeakDescriptor;

#Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com & Jacques Colinge

#This library is free software; you can redistribute it and/or
#modify it under the terms of the GNU Lesser General Public
#License as published by the Free Software Foundation; either
#version 2.1 of the License, or (at your option) any later version.

#This library is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#Lesser General Public License for more details.

#You should have received a copy of the GNU Lesser General Public
#License along with this library; if not, write to the Free Software
#Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


use strict;
use Carp;
require Exporter;

our (@ISA,@EXPORT,@EXPORT_OK);
@ISA=qw (Exporter);
@EXPORT=qw();
@EXPORT_OK=qw();



=head1 NAME

InSilicoSpectro::Spectra::PeakDescriptor - Description of peak properties

=head1 SYNOPSIS

use InSilicoSpectro::Spectra::PeakDescriptor;

=head1 DESCRIPTION

List peak properties in order. By peak properties we mean physical properties
read from fields in the peak list such as mass, intensity, FWHM, etc.

=head1 METHODS

=head2 my new([$itemOrder])

Constructor. It is possible to give a list of properties in a vector, a reference to which
is passed as parameter $itemOrder. The positions in the vector define the order.

=head2 setFields(\@v | $line_starting_#)

Initializes with an array of names, or a text line (heading '#\s*' and trailing
'#.*' are removed).

=head2 getFields([$i])

Return the i^th field. If $i is not present, return the array of fields

=head2 getFieldIndex(name)

Return the index of the field corresponding the $name

=head2 pushField($n)

Adds field $n at the end of the list of fields already in the PeakDescriptor.

=head2 $equalsTo($pd2)

Compares two PeakDescriptor objects and returns true if all the fields are the same and in
the same order.

=head2 toString

Returns a string with order:field_name pairs separated by comas.

=head2 Overloaded "" operator

Returns the result of toString.

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut

sub new{
  my ($pkg, $v)=@_;
  my $self = {};
  my $class = ref($pkg) || $pkg;
  bless $self, $class;
  $self->setFields($v);
  return $self;
}

sub setFields{
  my ($this, $v)=@_;

  if(! defined $v){
    $this->{fieldNames}=[];
    return;
  }

  if((ref $v) eq "ARRAY"){
    $this->{fieldNames}=[@$v];
  }else{
    $v=~s/^\#\s*//;
    $v=~s/\\#.*$//;
    $this->{fieldNames}=[];
    foreach (split /\s+/, $v){
      push @{$this->{fieldNames}}, $_;
    }
  }
}


sub pushField{
  my ($this, $n)=@_;
  push @{$this->{fieldNames}}, $n;
}


sub getFieldIndex{
  my ($this, $n)=@_;
  $n = uc($n);
  foreach (0..((scalar @{$this->{fieldNames}})-1)){
    return $_ if(uc($this->{fieldNames}[$_]) eq $n);
  }

  return undef;
}

sub getFields{
  my ($this, $i)=@_;
  if(defined $i){
    return $this->{fieldNames}->[$i];
  }else{
    return $this->{fieldNames};
  }
}


sub equalsTo{
  my($this, $pd)=@_;

  my @f1=@{$this->getFields()};
  my @f2=@{$pd->getFields()};
  return 0 if $#f1 != $#f2;

  foreach (0..$#f1){
    return 0 unless  $f1[$_] eq $f2[$_];
  }
  return 1;
}


use overload '""' => \&toString;
sub toString{
  my $this = shift;
  my $string;
  for(my $i=0;$i<@{$this->getFields()};$i++){
    $string .= $this->getFields($i)." ";
  }
  return $string;
}

return 1;
