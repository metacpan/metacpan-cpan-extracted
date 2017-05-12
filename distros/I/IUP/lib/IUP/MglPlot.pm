package IUP::MglPlot;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;
use Carp;

sub BEGIN {
  #warn "[DEBUG] IUP::MglPlot::BEGIN() started\n";
  IUP::Internal::LibraryIup::_IupMglPlotOpen();
}

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupMglPlot();
  return $ih;
}

sub PlotBegin {
  my ($self, $dim) = @_;
  IUP::Internal::LibraryIup::_IupMglPlotBegin($self->ihandle, $dim);
  return $self;
}

sub PlotEnd {
  #int IupPlotEnd(Ihandle* ih); [in C]
  #iup.PlotEnd(ih: ihandle) -> (index: number) [in Lua]
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupMglPlotEnd($self->ihandle);
}

sub PlotNewDataSet {
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupMglPlotNewDataSet($self->ihandle, @_);
}

### 1D

sub PlotAdd1D {
  # params: ($x, $y) or (\@x, \@y)
  my ($self, $x, $y) = @_;
  IUP::Internal::LibraryIup::_IupMglPlotAdd1D($self->ihandle, $x, $y);
  return $self;
}

sub PlotSet1D {
  # params: ($ds_index, \@x, \@y) or ($ds_index, \@y)
  # returns: $self
  my ($self, $ds_index) = (shift, shift);
  unshift(@_, undef) if @_ <= 1;
  IUP::Internal::LibraryIup::_IupMglPlotSet1D($self->ihandle, $ds_index, @_);
  return $self;
}

sub PlotInsert1D {
  # params: ($ds_index, $sample_index, \@x, \@y) or ($ds_index, $sample_index, \@y)
  # returns: $self
  my ($self, $ds_index, $sample_index) = (shift, shift, shift);
  unshift(@_, undef) if @_ <= 1;
  IUP::Internal::LibraryIup::_IupMglPlotInsert1D($self->ihandle, $ds_index, $sample_index, @_);
  return $self;
}

#sub PlotAppend1D {
#  # params: ($ds_index, \@x, \@y) or ($ds_index, \@y)
#  my ($self, $ds_index) = @_;
#  return $self->PlotInsert1D($ds_index, $self->DS_COUNT, @_);
#}

### 2D

sub PlotAdd2D {
  # params: ($x, $y) or (\@x, \@y)
  my ($self, $x, $y) = @_;
  IUP::Internal::LibraryIup::_IupMglPlotAdd2D($self->ihandle, $x, $y);
  return $self;
}

sub PlotSet2D {
  # params: ($ds_index, \@x, \@y)
  # returns: $self
  my ($self, $ds_index) = (shift, shift);
  IUP::Internal::LibraryIup::_IupMglPlotSet2D($self->ihandle, $ds_index, @_);
  return $self;
}

sub PlotInsert2D {
  # params: ($ds_index, $sample_index, \@x, \@y)
  # returns: $self
  my ($self, $ds_index, $sample_index) = (shift, shift, shift);
  IUP::Internal::LibraryIup::_IupMglPlotInsert2D($self->ihandle, $ds_index, $sample_index, @_);
  return $self;
}

#sub PlotAppend2D {
#  # params: ($ds_index, \@x, \@y)
#  my ($self, $ds_index) = (shift, shift);
#  return $self->PlotInsert2D($ds_index, $self->DS_COUNT, @_);
#}

### 3D

sub PlotAdd3D {
  # params: ($x, $y, $z) or (\@x, \@y, \@z)
  my ($self, $x, $y, $z) = @_;
  IUP::Internal::LibraryIup::_IupMglPlotAdd3D($self->ihandle, $x, $y, $z);
  return $self->PlotEnd();
}

sub PlotSet3D {
  # params: ($ds_index, \@x, \@y, \@z)
  # returns: $self
  my ($self, $ds_index) = (shift, shift);
  IUP::Internal::LibraryIup::_IupMglPlotSet3D($self->ihandle, $ds_index, @_);
  return $self;
}

sub PlotInsert3D {
  # params: ($ds_index, $sample_index, \@x, \@y, \@z)
  # returns: $self
  my ($self, $ds_index, $sample_index) = (shift, shift, shift);
  IUP::Internal::LibraryIup::_IupMglPlotInsert3D($self->ihandle, $ds_index, $sample_index, @_);
  return $self;
}

#sub PlotAppend3D {
#  # params: ($ds_index, \@x, \@y, \@z)
#  my ($self, $ds_index) = @_;
#  return $self->PlotInsert3D($ds_index, $self->DS_COUNT, @_);
#}

###

sub PlotTransform {
  my ($self, $x, $y, $z) = @_;
  my ($ix, $iy) = IUP::Internal::LibraryIup::_IupMglPlotTransform($self->ihandle, $x, $y, $z);
  return ($ix, $iy);
}

sub PlotTransformTo {
  my ($self, $ix, $iy) = @_;
  my ($x, $y, $z) = IUP::Internal::LibraryIup::_IupMglPlotTransformTo($self->ihandle, $ix, $iy);
  return ($x, $y, $z);
}

sub PlotPaintTo {
  my $self = shift;
  my ($filename, $w, $h, $dpi) = @_;
  my $format;
  $format = "SVG" if $filename =~ /\.svg$/i;
  $format = "EPS" if $filename =~ /\.eps$/i;
  die "format should be 'EPS' or 'SVG'\n" unless $format;
  IUP::Internal::LibraryIup::_IupMglPlotPaintTo($self->ihandle, $format, ($w||0), ($h||0), ($dpi||0), $filename);
  return  $self;
}

sub PlotDrawMark {
  my $self = shift;
  IUP::Internal::LibraryIup::_IupMglPlotDrawMark($self->ihandle, @_);
  return  $self;
}

sub PlotDrawLine {
  my $self = shift;
  IUP::Internal::LibraryIup::_IupMglPlotDrawLine($self->ihandle, @_);
  return  $self;
}

sub PlotDrawText {
  my $self = shift;
  IUP::Internal::LibraryIup::_IupMglPlotDrawText($self->ihandle, @_);
  return  $self;
}

sub PlotSetFormula {
  my $self = shift;
  IUP::Internal::LibraryIup::_IupMglPlotSetFormula($self->ihandle, @_);
  return  $self;
}

sub PlotLoadData {
  my $self = shift;
  IUP::Internal::LibraryIup::_IupMglPlotLoadData($self->ihandle, @_);
  return  $self;
}

sub PlotSetFromFormula {
  my $self = shift;
  IUP::Internal::LibraryIup::_IupMglPlotSetFromFormula($self->ihandle, @_);
  return  $self;
}

sub PlotSetData {
  my $self = shift;
  IUP::Internal::LibraryIup::_IupMglPlotSetData($self->ihandle, @_);
  return  $self;
}

1;
