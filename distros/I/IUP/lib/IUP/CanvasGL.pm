package IUP::CanvasGL;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;

sub BEGIN {
  #warn "[DEBUG] IUP::CanvasGL::BEGIN() started\n";
  IUP::Internal::LibraryIup::_IupGLCanvasOpen();
}

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  my $ih = IUP::Internal::LibraryIup::_IupGLCanvas(undef);
  return $ih;
}

sub GLMakeCurrent {
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupGLMakeCurrent($self->ihandle);
}

sub GLIsCurrent {
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupGLIsCurrent($self->ihandle);
}

sub GLSwapBuffers {
  my $self = shift;
  return IUP::Internal::LibraryIup::_IupGLSwapBuffers($self->ihandle);
}

sub GLPalette {
  my ($self, $index, $r, $g, $b) = @_;
  return IUP::Internal::LibraryIup::_IupGLPalette($self->ihandle, $index, $r, $g, $b);
}

sub GLUseFont {
  my ($self, $first, $count, $list_base) = @_;
  return IUP::Internal::LibraryIup::_IupGLUseFont($self->ihandle, $first, $count, $list_base);
}

sub GLWait {
  my ($self, $gl) = @_;
  return IUP::Internal::LibraryIup::_IupGLWait($gl);
}

1;
