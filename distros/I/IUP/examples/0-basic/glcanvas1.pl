# IUP::CanvasGL example
#
# Creates a OpenGL canvas and draws a line in it.
# This example uses gllua binding of OpenGL to Perl

use warnings;
use strict;

use IUP ':all';
use OpenGL ':all';

my $cnv = IUP::CanvasGL->new( BUFFER=>"DOUBLE", RASTERSIZE=>"300x300" );

sub cb_cnv_action {
  my ($self, $x, $y) = @_;
  my ($w, $h) = split /x/,$self->RASTERSIZE;

  $self->GLMakeCurrent();

  glViewport(0, 0, $w, $h);
  glClearColor(1.0, 1.0, 1.0, 1.0);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glColor3f(1.0,0.0,0.0);
  glBegin(GL_QUADS); 
    glVertex2f( 0.9,  0.9); 
    glVertex2f( 0.9, -0.9); 
    glVertex2f(-0.9, -0.9); 
    glVertex2f(-0.9,  0.9); 
  glEnd();

  $self->GLSwapBuffers();

  return IUP_DEFAULT;
}

sub cb_cnv_k_any {
  my ($self, $c) = @_;
  if ( $c == K_q or $c == K_ESC ) {
    return IUP_CLOSE;
  }
  else {
    return IUP_DEFAULT;
  }
}

$cnv->ACTION(\&cb_cnv_action);
$cnv->K_ANY(\&cb_cnv_k_any);

my $dlg = IUP::Dialog->new( child=>$cnv, TITLE=>"IUP::CanvasGL Example", MINSIZE=>"300x300" );

$dlg->Show();

IUP->MainLoop();
