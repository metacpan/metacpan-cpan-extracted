# IUP::ColorBar example

use strict;
use warnings;

use IUP ':all';

my $cnvs = IUP::Canvas->new();

sub redraw_cb {
  my $self = shift;
 
  $self->cdActivate();
  $self->cdClear();
  
  # Draws a rectangle on the canvas
  $self->cdBegin(CD_FILL);
  $self->cdVertex(50, 50);
  $self->cdVertex(150, 50);
  $self->cdVertex(100, 150);
  $self->cdEnd();
  
  # Function executed successfully
  return IUP_DEFAULT;
}

sub cell_cb {
  my ($self, $cell) = @_;
  my ($r, $g, $b) = split / /, $self->GetAttributeId("CELL",$cell);
  ($r, $g, $b) = IUP->GetColor(IUP_MOUSEPOS, IUP_MOUSEPOS, $r, $g, $b);  
  if (defined $r && defined $g && defined $b) {
    $cnvs->cdActivate();
    $cnvs->cdForeground($cnvs->cdEncodeColor($r, $g, $b));
    redraw_cb($cnvs);
    return "$r $g $b";
  }
  return undef;
}

sub select_cb {
  my ($self, $cell, $type) = @_;
  my ($r, $g, $b) = split / /, $self->GetAttribute("CELL$cell");
  my $cd_color = $cnvs->cdEncodeColor($r, $g, $b);
   
  $cnvs->cdActivate();
  if ($type == IUP_PRIMARY) {
    $cnvs->cdForeground($cd_color);
  }
  else {
    $cnvs->cdBackground($cd_color);
  }
  redraw_cb($cnvs);

  return IUP_DEFAULT;
}

sub switch_cb {
  my ($self, $primcell, $seccell) = @_;
  $cnvs->cdActivate();
  my $fgcolor = $cnvs->cdForeground(CD_QUERY);
  $cnvs->cdForeground($cnvs->cdBackground(CD_QUERY));
  $cnvs->cdBackground($fgcolor);
  redraw_cb($cnvs);
  return IUP_DEFAULT;
}

$cnvs->ACTION( \&redraw_cb );
# Sets size, minimum and maximum values, position and size of the thumb
# of the horizontal scrollbar of the canvas
$cnvs->SetAttribute("RASTERSIZE", "200x300");

my $cb = IUP::ColorBar->new(
           RASTERSIZE=>"70x",
           EXPAND=>"VERTICAL",
           NUM_PARTS=>2,
           SHOW_SECONDARY=>"YES",
           SELECT_CB=>\&select_cb,
           CELL_CB=>\&cell_cb,
           SWITCH_CB=>\&switch_cb,
#           SQUARED=>"NO",
           PREVIEW_SIZE=>60 );

# Creates a dialog with a vbox containing the canvas and the colorbar
my $dlg = IUP::Dialog->new( child=>IUP::Hbox->new( child=>[$cnvs, $cb] ) );
  
# Sets the dialog's title, so that it is mapped properly
$dlg->TITLE("IUP::ColorBar");
 
# Shows dialog on the center of the screen
$dlg->Show();

# Initializes IUP main loop
IUP->MainLoop();
