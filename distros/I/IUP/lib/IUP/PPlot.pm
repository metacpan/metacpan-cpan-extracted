package IUP::PPlot;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;
use Carp;

sub BEGIN {
  #warn "[DEBUG] IUP::PPlot::BEGIN() started\n";
  IUP::Internal::LibraryIup::_IupPPlotOpen();
}

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupPPlot();
  return $ih;
}

sub PlotBegin {
  #void IupPlotBegin(Ihandle* ih, int strXdata); [in C]
  #iup.PlotBegin(ih: ihandle, strXdata: number) [in Lua]
  my ($self, $dim) = @_;
  my $strXdata = ($dim && $dim == 1) ? 1 : 0;
  IUP::Internal::LibraryIup::_IupPPlotBegin($self->ihandle, $strXdata);
  return $self;
}

sub PlotEnd {
  #int IupPlotEnd(Ihandle* ih); [in C]
  #iup.PlotEnd(ih: ihandle) -> (index: number) [in Lua]
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupPPlotEnd($self->ihandle);
}

sub PlotNewDataSet {
  my ($self, $dim) = @_;
  return $self->PlotBegin($dim)->PlotEnd();
}

sub PlotAdd1D {
  # params: ($x, $y) or (\@x, \@y)
  my ($self, $x, $y) = @_;
  if (ref $x eq 'ARRAY' && !defined $y) {
    IUP::Internal::LibraryIup::_IupPPlotAddStr($self->ihandle, [(0..scalar(@$x)-1)], $x);
    return $self;
  }
  elsif (defined $x && !ref $x && !defined $y) {
    IUP::Internal::LibraryIup::_IupPPlotAddStr($self->ihandle, '', $x);
    return $self;
  }
  else {
    IUP::Internal::LibraryIup::_IupPPlotAddStr($self->ihandle, $x, $y);
    return $self;
  }
}

sub PlotAdd2D {
  # params: ($x, $y) or (\@x, \@y)
  my ($self, $x, $y) = @_;
  IUP::Internal::LibraryIup::_IupPPlotAdd($self->ihandle, $x, $y);
  return $self;
}

#sub PlotAppend1D {
#  # params: ($ds_index, \@x, \@y)
#  my $self = shift;
#  IUP::Internal::LibraryIup::_IupPPlotAddStrPoints($self->ihandle, @_);
#  return $self;
#}

#sub PlotAppend2D {
#  # params: ($ds_index, \@x, \@y)
#  my $self = shift;
#  IUP::Internal::LibraryIup::_IupPPlotAddPoints($self->ihandle, @_);
#  return $self;
#}

sub PlotSet1D {
  # params: ($ds_index, $x, $y) or ($ds_index, \@x, \@y)
  my ($self, $ds_index) = (shift, shift);
  $self->CURRENT($ds_index);
  my $i = $self->DS_COUNT;
  for my $j (0..$i-1) { $self->DS_REMOVE($j) }
  $self->PlotInsert1D($ds_index, 0, @_);
  return $self;
}

sub PlotSet2D {
  # params: ($ds_index, $x, $y) or ($ds_index, \@x, \@y)
  my ($self, $ds_index) = (shift, shift);
  $self->CURRENT($ds_index);
  my $i = $self->DS_COUNT;
  for my $j (0..$i-1) { $self->DS_REMOVE($j) }
  $self->PlotInsert2D($ds_index, 0, @_);
  return $self;
}

sub PlotInsert1D {
  # params: ($ds_index, $sample_index, $x, $y) or ($ds_index, $sample_index, \@x, \@y)
  my $self = shift;
  if (ref($_[0]) eq 'ARRAY') {
    IUP::Internal::LibraryIup::_IupPPlotInsertStr($self->ihandle, @_);
  }
  else {
    IUP::Internal::LibraryIup::_IupPPlotInsertStrPoints($self->ihandle, @_);
  }
  return $self;
}

sub PlotInsert2D {
  # params: ($ds_index, $sample_index, $x, $y) or ($ds_index, $sample_index, \@x, \@y)
  my $self = shift;
  if (ref($_[0]) eq 'ARRAY') {
    IUP::Internal::LibraryIup::_IupPPlotInsert($self->ihandle, @_);
  }
  else {
    IUP::Internal::LibraryIup::_IupPPlotInsertPoints($self->ihandle, @_);
  }
  return $self;
}

sub PlotTransform {
  #void IupPlotTransform(Ihandle* ih, float x, float y, int *ix, int *iy); [in C]
  #iup.PlotTransform(ih: ihandle, x, y: number) -> (ix, iy: number) [in Lua]
  my ($self, $x, $y) = @_;
  my ($ix, $iy) = IUP::Internal::LibraryIup::_IupPPlotTransform($self->ihandle, $x, $y);
  return ($ix, $iy);
}

sub PlotPaintToCanvas {
  #void IupPlotPaintTo(Ihandle* ih, cdCanvas* cnv); [in C]
  #iup.PlotPaintTo(ih: ihandle, cnv: cdCanvas) [in Lua]
  my ($self, $cnv) = @_;
  return IUP::Internal::LibraryIup::_IupPPlotPaintTo($self->ihandle, $cnv->cnvhandle);
}

1;
