# IUP::CanvasGL example
#
# Inspired by FLTK example gl.pl by Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

use warnings;
use strict;

use IUP ':all';
use OpenGL ':all';

my $cnv = IUP::CanvasGL->new( BUFFER=>"DOUBLE", RASTERSIZE=>"300x300" );

my $theta     = 0.0;
my $speed     = 0.0;
my $direction = -1;
my $range     = 12;

sub redraw_cb {
  my $self = shift;
  my ($w, $h) = split /x/,$self->RASTERSIZE;

  $self->GLMakeCurrent();
  glViewport(0, 0, $w, $h);
  
  glClearColor(0, 0, 0, 0);
  glClear(GL_COLOR_BUFFER_BIT);
  glPushMatrix();
  glRotatef($theta, 0.0, 0.0, 1.0);
  glBegin(GL_TRIANGLES);
    glColor3f(1.0, 0.0, 0.0);
    glVertex2f(0.0, 1.0);
    glColor3f(0.0, 1.0, 0.0);
    glVertex2f(0.87, -0.5);
    glColor3f(0.0, 0.0, 1.0);
    glVertex2f(-0.87, -0.5);
  glEnd();
  glPopMatrix();
  $theta += $speed;

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

sub timer_cb {
  my $self = shift;
  if ($speed > $range) {
    $direction = -1;
  }
  elsif ($speed < -$range) {
    $direction = 1;
  }
  $speed += (0.1 * $direction);
  redraw_cb($cnv);
}

$cnv->ACTION(\&redraw_cb);
$cnv->K_ANY(\&cb_cnv_k_any);

my $timer = IUP::Timer->new( TIME=>10, ACTION_CB=>\&timer_cb );
my $dlg = IUP::Dialog->new( child=>$cnv, TITLE=>"IUP::CanvasGL Example", MINSIZE=>"300x300" );

$dlg->Show();
$timer->RUN("YES");

IUP->MainLoop();
