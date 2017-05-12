# IUP::Canvas (with scrollbar) example
#
# Virtual space size: 600x400
# The canvas will be a window into that space.
# If canvas is smaller than the virtual space, scrollbars are active.
#  
# The drawing is a red cross from the corners of the virtual space.
# But CD must draw in the canvas space. So the position of the scrollbar
# will define the convertion between canvas space and virtual space.
#

use strict;
use warnings;

use IUP ':all';

sub action_cb {
  my ($self, $posx, $posy) = @_;

  # update CD canvas size
  $self->cdActivate();

  # invert scroll reference (YMAX-DY - POSY)
  $posy = 399 - $self->DY - $posy;
  
  $self->cdClear();
  $self->cdForeground(CD_RED);
  $self->cdLine(0-$posx, 0-$posy, 599-$posx, 399-$posy);
  $self->cdLine(0-$posx, 399-$posy, 599-$posx, 0-$posy);

  return IUP_DEFAULT;
}

sub scroll_cb {
  my ($self, $op, $posx, $posy) = @_;
  action_cb($self, $posx, $posy);
  return IUP_DEFAULT;
}

sub resize_cb {
  my ($self, $w, $h) = @_;

  # update page size, it is always the client size of the canvas
  $self->SetAttribute( DX=>$w, DY=>$h );

  # update CD canvas size
  $self->cdActivate();

  return IUP_DEFAULT;
}

my $canvas = IUP::Canvas->new(
               RASTERSIZE=>"300x200",
               SCROLLBAR=>"YES",
               XMAX=>"599",
               YMAX=>"399",
               SCROLL_CB=>\&scroll_cb,
               RESIZE_CB=>\&resize_cb,
               ACTION=>\&action_cb );
                   
my $dialog = IUP::Dialog->new( child=>$canvas, TITLE=>"Scrollbar Test" );

$dialog->ShowXY(IUP_CENTER, IUP_CENTER);

# release the minimum limitation - must go after ShowXY or Map
$canvas->RASTERSIZE(undef);

IUP->MainLoop();
