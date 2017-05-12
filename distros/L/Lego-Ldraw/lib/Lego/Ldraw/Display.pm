package Lego::Ldraw::Display;

use strict;
use warnings; no warnings qw/void uninitialized/;

use Carp;

use Math::Trig;
use Math::Trig ':radial';
use Math::VectorReal;

use OpenGL qw/ :all /;

use Lego::Ldraw::Line;
use Lego::Ldraw;

my $self = {};

##########################################################
# stuff for playing around
##########################################################

##########################################################
# end of stuff for playing around
##########################################################

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;

  $self->{width}      = shift || 300;
  $self->{height}     = shift || 300;
  $self->{name}       = 'LDraw OpenGL Display';

  my $ldraw = shift;
  $self->{ldraw} = \$ldraw
    if $ldraw;

  $self->{changed}    = undef;    # whether model has been changed

  $self->{camera} = [400, 0, -270];
  $self->{lookat} = [0, 0, 0];

  $self->{cameramode} = undef;    # how camera is moved around
  $self->{gl_init}  = {};         # gl variables;
  $self->{bindings} = {};         # bindings

  $self->{light_ambient}  = [ 0.5, 0.5, 0.5, 1.0 ];
  $self->{light_diffuse}  = [ 1, 1, 1, 1.0 ];
  $self->{light_position} = [ 2000.0, 2000.0, 1000.0, 1.0 ];
  $self->{clearcolor}     = [0.9, 0.9, 1, 0.0];

  $self->{specialkeypressed} = {};
  $self->{keypressed}        = {};

  $self->{nostuds} = 1;

  bless ($self, $class);
  return $self;
}

######################################################
# start of field access functions
######################################################

sub camera {
  my $self = shift;
  if (@_) { $self->{camera} = [@_] }
  return @{ $self->{camera} };
}

sub lookat {
  my $self = shift;
  if (@_) { $self->{lookat} = [@_] }
  return @{ $self->{lookat} };
}

sub move_camera {
  shift->move('camera', @_);
}

sub move {
  my $self = shift;
  my ($point, $how, $what, $qty) = @_;
  for ($how) {
    /^x/ && do {
      $qty = $qty || 8;
      for ($what) {
	(/x/ || /1/) && do { $self->{$point}->[0] += $qty; };
	(/y/ || /2/) && do { $self->{$point}->[1] += $qty; };
	(/z/ || /3/) && do { $self->{$point}->[2] += $qty; };
      };
      last;
    };
    /^s/ && do {
      my ($x, $y, $z) = @{ $self->{$point} };
      $qty = $qty || 12;
      my ($rho, $theta, $phi) = cartesian_to_spherical ($x, $z, $y); # rotate around y axis
      for ($what) {
	(/r/ || /1/) && do { $rho += $qty ; };
	(/t/ || /2/) && do { $qty = deg2rad($qty);  $theta += $qty; };
	(/p/ || /3/) && do { $qty = deg2rad($qty);  $phi += $qty; };
      };
      ($x, $z, $y) = spherical_to_cartesian($rho, $theta, $phi);
      $self->{$point} = [ $x, $y, $z ];
      last;
    };
  }
}

######################################################
# end of field access functions
######################################################

sub load {
}

sub display {
  my $ldraw;
  $self->prepare_display;
  unless (eval { $ldraw = ${ $self->{ldraw} }->copy }) {
    glutSwapBuffers();
    return;
  };
  glutSwapBuffers() unless $self->{count};

  my @parts = @{$ldraw};
  local $, = " "; local $\ = "\n";
  if (!$self->{count} || $self->{changed}) {
    $ldraw->build_gl_tree;
  }

  for my $part (@parts) {
    next unless $part->type;
    if ($part->type == 1) {
      $self->display_part($part);
    } else {
      $self->display_primitive($part);
    }
  }
  glutSwapBuffers();
  $self->{count}++;
}

sub build_list {
  shift;
  my $part = shift;
  unless (ref $part) {
    $part = Lego::Ldraw::Line->new_from_part_name($part);
    #$part->model(${$self->{ldraw}});
  }
  my $lcolor = shift; $lcolor = $part->color unless defined $lcolor;
  return if defined $self->{GL_LISTS}->{$part->name}->{$lcolor};

  my $data = $part->explode->display_struct;

  #-------------------------------------------
  # first, build lists for all colored parts
  #-------------------------------------------
  if ($data->{1}) {
    for my $line (@{$data->{1}->{16}}) {
      $self->build_list($line, $lcolor)
    }
  }

  #-------------------------------------------
  # then start generating the list
  #-------------------------------------------
  my $ln = glGenLists(1);

  return unless $ln;
  glNewList($ln, GL_COMPILE);

  #-------------------------------------------
  # with subparts...
  #-------------------------------------------
  if ($data->{1}) {
    for my $color (keys %{$data->{1}}) {
      for my $line (@{$data->{1}->{$color}}) {
	my $col = $color == 16 ? $lcolor : $color;
	glColor4f(gl_color($col));
	$self->display_part($line, $col);
      }
    }
  }

  #-------------------------------------------
  # ...and primitives
  #-------------------------------------------
  for my $type (2, 3, 4) {
    for my $color (keys %{$data->{$type}}) {
      for my $line (@{$data->{$type}->{$color}}) {
	$self->display_primitive($line);
      }
    }
  }
  glEndList();

  $self->{GL_LISTS}->{$part->name}->{16} = $ln;
  return $ln;
}

sub display_part {
  shift;

  my $part = shift;
  my $col = shift; $col = $part->color unless defined $col;

  #-------------------------------------------
  # first, check if a display list is
  # defined, and define one if not so...
  #-------------------------------------------
  my $ln;
  unless (defined $self->{GL_LISTS}->{$part->name}->{$part->color}) {
    $self->{GL_LISTS}->{$part->name}->{$part->color} = $self->build_list($part);
  }
  $ln = $self->{GL_LISTS}->{$part->name}->{$part->color};

  #-------------------------------------------
  # ...then call list
  #-------------------------------------------
  glPushMatrix();
  my @matrix = ($part->values(qw/a d g '' b e h '' c f i '' x y z/), 1);
  glMultMatrixd_p(@matrix);
  glCallList($ln);
  glPopMatrix();
}

sub display_primitive {
  shift;
  my $part = shift;
  my $gl_type;
  my @d = $part->values;

  for ($part->type) {
    /^5$/ && do { return; $gl_type = GL_LINES;     @d = splice @d, 2, 6; last; };
    /^2$/ && do { return; $gl_type = GL_LINES;     splice @d, 0, 2; last; };
    /^3$/ && do { $gl_type = GL_TRIANGLES; splice @d, 0, 2; last; };
    /^4$/ && do { $gl_type = GL_QUADS;     splice @d, 0, 2; last; };
  }

  glBegin($gl_type);

  #-----------------------------------------------
  # normals are supposed to be important for
  # lighting, but I can't manage to make lighting
  # work, and besides I get divisions by zero
  #-----------------------------------------------
  #my @normal = $part->normal;
  #print @normal;
  #glNormal3f(@normal)
  #  if (($part->type == 3) or ($part->type == 4));
  #-----------------------------------------------
  # end of normal handling, here for the future
  #-----------------------------------------------

  while (@d) {
    my @c = splice @d, 0, 3;
    carp "Wrong part $part" unless (scalar @c == 3);
    glVertex3f(@c);
  }
  glEnd();
}

##########################################################
# initialization etc.
##########################################################
sub resize {
  my ($width, $height) = @_;

  # Let's not core dump, no matter what.
  $height = 1 if ($height == 0);

  glViewport(0, 0, $width, $height);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  gluPerspective(45.0,$width/$height,0.1,4000.0);

  glMatrixMode(GL_MODELVIEW);

  $self->{width} = $width;
  $self->{height} = $height;
}

sub _specialkey {
  my $key = shift;
  my $mod = glutGetModifiers();

  return unless defined $self->{specialkeypressed}->{$mod};
  return unless $self->{specialkeypressed}->{$mod}->{$key};

  my $sub = $self->{specialkeypressed}->{$mod}->{$key};
  &$sub($self);
}

sub bindspec {
  shift;
  my $key = shift;
  my $sub = pop;
  my $mod = shift || 0;
  $self->{specialkeypressed}->{$mod}->{$key} = $sub;
}

sub init {
  shift;
  my $idlefunc = shift;
  glutInit();
  glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE | GLUT_DEPTH);
  glutInitWindowSize($self->{width}, $self->{height});

  $self->{id} = glutCreateWindow($self->{name});

  glutDisplayFunc(\&display);
  glutIdleFunc( sub { &{$idlefunc}; &display } );
  glutReshapeFunc(\&resize);
  glutSpecialFunc(\&_specialkey);

  ourInit($self->{width}, $self->{height});
  glutMainLoop();
}

sub ourInit {
  my ($Width, $Height) = @_;

  # Color to clear color buffer to.
  glClearColor(@{$self->{clearcolor}});

  # Depth to clear depth buffer to; type of test.
  glClearDepth(1.0);
  glDepthFunc(GL_LESS);

  # Enables Smooth Color Shading; try GL_FLAT for (lack of) fun.
  glShadeModel(GL_SMOOTH);
  glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);

  # Load up the correct perspective matrix; using a callback directly.
  resize($self->{width}, $self->{height});

  # Set up a light, turn it on.
  glLightfv_p(GL_LIGHT1, GL_POSITION, @{$self->{light_position}});
  glLightfv_p(GL_LIGHT1, GL_AMBIENT,  @{$self->{light_ambient}});
  glLightfv_p(GL_LIGHT1, GL_DIFFUSE,  @{$self->{light_diffuse}});
  glEnable (GL_LIGHT1);

  # A handy trick -- have surface material mirror the color.

  glColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);
  #glColorMaterial(GL_FRONT_AND_BACK, GL_SPECULAR);
  glEnable(GL_COLOR_MATERIAL);
}

sub prepare_display {
  shift;
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_LIGHTING);

  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_BLEND);
  glEnable(GL_DEPTH_TEST);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  # Need to manipulate the ModelView matrix to move our model around.
  glMatrixMode(GL_MODELVIEW);

  # Reset to 0,0,0; no rotation, no scaling.
  glLoadIdentity();

  # Move the object back from the screen.
  glTranslatef(0.0, 0.0, 0);
  # move the camera away
  gluLookAt($self->camera, $self->lookat, 0, -1, 0);

  # Clear the color and depth buffers.
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

##########################################################
# color handling
##########################################################

my $color_matrix =
  {
   117440511 => [qw/153 192 240 148/],
   0 => [qw/34 34 34/],
   3 => [qw//],
   431 => [qw//],
   379 => [qw/159 178 191/],
   10 => [qw/51 255 102/],
   33 => [qw/0 0 153/],
   46 => [qw/240 196 0/],
   32 => [qw//],
   335 => [qw/212 163 157/],
   378 => [qw/159 204 180/],
   462 => [qw//],
   5 => [qw/255 51 153/],
   42 => [qw/204 255 0/],
   382 => [qw/204 170 102/],
   383 => [qw/204 204 204/],
   418 => [qw/0 191 89/],
   495 => [qw/255 255 128/],
   6 => [qw/102 51 0/],
   14 => [qw/255 229 0/],
   503 => [qw/230 227 218/],
   4 => [qw/204 0 0/],
   373 => [qw/175 150 180/],
   1 => [qw/0 51 178/],
   9 => [qw/0 128 255/],
   3 => [qw/48 128 48/],
   5 => [qw/255 51 153/],
   334 => [qw/240 176 51/],
   12 => [qw/255 201 196/],
   11 => [qw/48 255 48/],
   494 => [qw/204 204 204/],
   2 => [qw/0 127 51/],
   383 => [qw/204 204 204/],
   36 => [qw/204 0 0/],
   15 => [qw/255 255 255/],
   41 => [qw/153 192 240/],
   34 => [qw/0 80 24/],
   13 => [qw/255 176 204/],
   47 => [qw/255 255 255/],
   7 => [qw/153 153 153/],
   8 => [qw/102 102 88/],
  };


sub gl_color {
  my $col      = shift;
  my $linetype = shift;

  $col = 0 unless defined $color_matrix->{$col};
  my @color = @{$color_matrix->{$col}}; $_ /= 256 for @color;
  @color = (@color, 1) unless scalar @color == 4;
  return (@color);
}


sub Lego::Ldraw::Line::gl_color {
  my $self = shift;
  my $ld = shift;   # line or colour
  my $tp = shift; # false if triang or quad (types 3 and 4) , true if line (types 2 and 5)

  $ld = ref $ld ? $ld->color : $ld;
  $tp = ref $ld ? (($ld->type != 3) && ($ld->type != 4)) : $tp;

}

sub Lego::Ldraw::build_gl_tree {
  my $self = shift;
  my $callback = sub { Lego::Ldraw::Display->build_list( shift ) };
  $self->build_tree($callback);
}

sub Lego::Ldraw::display_struct {
  my $self = shift;
  my $data;

  for my $line (@$self) {
    if ($line->type == 5) {
      $line = $line->five2two
    }
    push @{$data->{$line->type}->{$line->color}}, $line
	if $line->type;
  }
  return $data;
}

sub Lego::Ldraw::Line::normal {
  my $self = shift;
  return unless $self->type == 3 or $self->type == 4;
  my @d = $self->values;
  splice @d, 0, 2;
  my ($a, $b, $c, $d, $n);
  for ($a, $b, $c) {
    $_ = vector(splice @d, 0, 3);
  }

  ($n, $d) = plane($a, $b, $c);
  return $n->array;
}

sub Lego::Ldraw::Line::five2two {
  my $self = shift;
  return $self unless $self->type == 5;

  $self = $self->copy;
  $self->{type} = 2;
  for (qw/x3 y3 z3 x4 y4 z4/) {
    delete $self->{$_}
  }
  return $self;
}

1;
