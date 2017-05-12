package IUP::Plot;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;
use Carp;

sub BEGIN {
  #warn "[DEBUG] IUP::PPlot::BEGIN() started\n";
  IUP::Internal::LibraryIup::_IupPlotOpen();
}

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupPlot();
  return $ih;
}

sub PlotBegin {
  my ($self, $dim) = @_;
  IUP::Internal::LibraryIup::_IupPlotBegin($self->ihandle, ($dim && $dim == 1) ? 1 : 0);
  return $self;
}

sub PlotEnd {
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupPlotEnd($self->ihandle);
}

sub PlotNewDataSet {
  my ($self, $dim) = @_;
  return $self->PlotBegin($dim)->PlotEnd();
}

### 1D

sub PlotAdd1D {
  # params: ($x, $y) or (\@x, \@y)
  my ($self, $x, $y) = @_;
  if (ref $x eq 'ARRAY' && !defined $y) {
    IUP::Internal::LibraryIup::_IupPlotAddStr($self->ihandle, [(0..scalar(@$x)-1)], $x);
    return $self;
  }
  elsif (defined $x && !ref $x && !defined $y) {
    IUP::Internal::LibraryIup::_IupPlotAddStr($self->ihandle, '', $x);
    return $self;
  }
  else {
    IUP::Internal::LibraryIup::_IupPlotAddStr($self->ihandle, $x, $y);
    return $self;
  }
}

sub PlotSet1D {
  # params: ($ds_index, $x, $y) or ($ds_index, \@x, \@y)
  my ($self, $ds_index) = (shift, shift);
  $self->CURRENT($ds_index);
  my $i = $self->DS_COUNT;
  for my $j (0..$i-1) { $self->DS_REMOVE($j) }
  $self->PlotInsert1D($ds_index, 0, @_);
  return $self;
}

sub PlotInsert1D {
  # params: ($ds_index, $sample_index, $x, $y) or ($ds_index, $sample_index, \@x, \@y)
  my $self = shift;
  if (ref($_[0]) eq 'ARRAY') {
    IUP::Internal::LibraryIup::_IupPlotInsertStr($self->ihandle, @_);
  }
  else {
    IUP::Internal::LibraryIup::_IupPlotInsertStrSamples($self->ihandle, @_);
  }
  return $self;
}

#sub PlotAppend1D {
#  # params: ($ds_index, \@x, \@y)
#  my $self = shift;
#  IUP::Internal::LibraryIup::_IupPlotAddStrSamples($self->ihandle, @_);
#  return $self;
#}

### 2D

sub PlotAdd2D {
  # params: ($x, $y) or (\@x, \@y)
  my ($self, $x, $y) = @_;
  IUP::Internal::LibraryIup::_IupPlotAdd($self->ihandle, $x, $y);
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

sub PlotInsert2D {
  # params: ($ds_index, $sample_index, $x, $y) or ($ds_index, $sample_index, \@x, \@y)
  my $self = shift;
  if (ref($_[0]) eq 'ARRAY') {
    IUP::Internal::LibraryIup::_IupPlotInsert($self->ihandle, @_);
  }
  else {
    IUP::Internal::LibraryIup::_IupPlotInsertSamples($self->ihandle, @_);
  }
  return $self;
}

#sub PlotAppend2D {
#  # params: ($ds_index, \@x, \@y)
#  my $self = shift;
#  IUP::Internal::LibraryIup::_IupPlotAddSamples($self->ihandle, @_);
#  return $self;
#}

###

sub PlotTransform {
  my ($self, $x, $y) = @_;
  my ($ix, $iy) = IUP::Internal::LibraryIup::_IupPlotTransform($self->ihandle, $x, $y);
  return ($ix, $iy);
}

sub PlotTransformTo {
  my ($self, $ix, $iy) = @_;
  my ($x, $y) = IUP::Internal::LibraryIup::_IupPlotTransformTo($self->ihandle, $ix, $iy);
  return ($x, $y);
}

sub PlotPaintToCanvas {
  my ($self, $cnv) = @_;
  return IUP::Internal::LibraryIup::_IupPlotPaintTo($self->ihandle, $cnv->cnvhandle);
}

1;
