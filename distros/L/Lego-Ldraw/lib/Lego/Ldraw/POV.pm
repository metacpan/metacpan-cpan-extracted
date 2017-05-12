##########################################################
# to do's:
# 1) matrix correction for singular matrixes
# 2) tidy up yml files search - done
# 3) header generation - done (kindof)
# 4) bounding box calculation - not needed as povray does it
# 5) metallic colors
# 6) special color handling
# 7) perl macro comments
#
##########################################################

package Lego::Ldraw::POV;

use strict;
use warnings; no warnings qw/void uninitialized/;

use Carp;

use Lego::Ldraw::Line;
use Lego::Ldraw;

use YAML;
use Template;

my $self = {};

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;

  my $ldraw = shift;
  $self->{ldraw} = \$ldraw
    if $ldraw;

  $self->{primitives_file} = "primitives.yml";
  $self->{colors_file} = "colors.yml";

  bless ($self, $class);
  return $self;
}

sub model {
  return $self->{model}
}

sub pov_color {
  shift;
  my $color = shift;
  $color = 0 if (($color == 16) || ($color == 24));

  my $primitives;
  unless ($self->{colordefs}) {
    open DATA, $self->ymlfile('colors');
    $primitives = do { local $/; <DATA> };
    $self->{colordefs} = Load($primitives);
  }
  my $def = $self->{colordefs}->{rgb}->{$color} || 'pigment { rgb <0.5,0.5,0.5> }';
  return unless $def;

  $self->{template} = Template->new
    unless $self->{template};

  my $type = $def =~ /filter/ ? 'normal' : 'transparent';
  my $template = $self->{colordefs}->{colordecl}->{$type};
  my $vars = {
	      color_name  => "Color$color",
	      color_def   => $def
	     };

  my $output;
  $self->{template}->process(\$template, $vars, \$output);
  return $output;
}

sub _pov_name {
  my $name = shift;
  for ($name) {
    s/^(\d)/_$1/;  # initial digit
    s/\./_dot_/;   # dot in name
    s/\-/_dash_/;  # dash in name
  }
  return $name
}

sub toPOV {
  shift;
  my $part = shift;
  my $ldraw;
  my $ref = ref $part;

  for ($ref) {
    # just a part name
    /^$/ && do {
      $part = Lego::Ldraw::Line->new_from_part_name($part);
      $part->model(${$self->{ldraw}});
      $ldraw = $part->explode;
      last;
    };
    # a part line
    /Line$/ && do {
      $part->model(${$self->{ldraw}});
      $ldraw = $part->explode;
      last;
    };
    # a model
    $ldraw = $part;
  };

  my $pov_name = $part->pov_name;
  unless ($self->{primitives}) {
    my $primitives;
    open DATA, $self->ymlfile('primitives');
    $primitives = do { local $/; <DATA> };
    $self->{primitives} = Load($primitives);
  }

  if (my $primitive = $self->{primitives}->{$pov_name}) {
    $self->{model} .= "$primitive\n\n";
  } else {
    $self->{model} .= '#declare ' . $pov_name . " = union {\n";
    $self->{model} .= join '', '// ' , ($part->description || 'no description available'), "\n";
    my @mesh = grep { $_->type == 3 or $_->type == 4 } $ldraw->lines;
    if (@mesh) {
      $self->{model} .= "\tmesh {\n";
      for (@mesh) {
	$self->{model} .= "\t\t" . $_->toPOV . "\n";
	$self->{colors}->{$_->color}++;
      }
      $self->{model} .= "\t}\n";
    }
    for (grep { $_->type == 1 } $ldraw->lines) {
      $self->{model} .= (join '', "\t", $_->toPOV, "\n");
      $self->{colors}->{$_->color}++;
    }
    $self->{model} .= "}\n\n";
  }
}

sub colors {
  shift;
  return keys %{$self->{colors}}
}

sub colordef {
  for ($self->colors) {
    $self->{colordef} .= ($self->pov_color($_) . "\n\n");
  }
  return $self->{colordef};
}

sub ymlfile {
  shift;
  my $type = shift;
  carp "File type unknow" unless ($type =~ /^primitives$/ || $type =~ /^colou*rs$/);

  local $_ = __PACKAGE__;

  # get the directory the package resides in
  s/::[^:]+$//;
  s/::/\//g;
  my $pkgdir = $_;

  my $file;
  for ('.', $ENV{'HOME'}, Lego::Ldraw->basedir, map { join '/', $_, $pkgdir } @INC) {
    if (-e join '/', $_, "$type.yml") {
      $file = join '/', $_, "$type.yml";
      last;
    }
  }
  return $file;
}

sub header {
  shift;
  my $header = <<EOF;
#declare QUAL = 2;  // Quality level, 0=BBox, 1=no refr, 2=normal, 3=studlogo

#declare SW = 0.5;  // Width of seam between two bricks

#declare STUDS = 1;  // 1=on 0=off

#declare BUMPS = 0;  // 1=on 0=off


#declare BUMPNORMAL = normal { bumps 0.01 scale 20 }
#declare AMB = 0.4;
#declare DIF = 0.4;


#declare O7071 = sqrt(0.5);

#declare L3Logo = union {
	sphere {<-59,0,-96>,6}
	cylinder {<-59,0,-96>,<59,0,-122>,6 open}
	sphere {<59,0,-122>,6}
	cylinder {<59,0,-122>,<59,0,-84>,6 open}
	sphere {<59,0,-84>,6}

	sphere {<-59,0,-36>,6}
	cylinder {<-59,0,-36>,<-59,0,1>,6 open}
	sphere {<-59,0,1>,6}
	cylinder {<0,0,-49>,<0,0,-25>,6 open}
	sphere {<0,0,-25>,6}
	sphere {<59,0,-62>,6}
	cylinder {<59,0,-62>,<59,0,-24>,6 open}
	sphere {<59,0,-24>,6}
	cylinder {<-59,0,-36>,<59,0,-62>,6 open}

	sphere {<-35.95,0,57>,6}
	torus {18.45,6 clipped_by{plane{<40,0,-9>,0}} translate<-40,0,39>}
	cylinder {<-44.05,0,21>,<35.95,0,3>,6 open}
	torus {18.45,6 clipped_by{plane{<-40,0,9>,0}} translate<40,0,21>}
	cylinder {<44.05,0,39>,<0,0,49>,6 open}
	sphere {<0,0,49>,6}
	cylinder {<0,0,49>,<0,0,34>,6 open}
	sphere {<0,0,34>,6}

	torus {18.45,6 clipped_by{plane{<40,0,-9>,0}} translate<-40,0,99>}
	cylinder {<-44.05,0,81>,<35.95,0,63>,6 open}
	torus {18.45,6 clipped_by{plane{<-40,0,9>,0}} translate<40,0,81>}
	cylinder {<44.05,0,99>,<-35.95,0,117>,6 open}

	scale 4.5/128
}
EOF
  return $header;
}

##########################################################
# Lego::Ldraw subs
##########################################################

sub Lego::Ldraw::POVdesc {
  my $self = shift;
  my $ldraw = $self->copy;
  Lego::Ldraw::POV->new($ldraw);
  my $callback = sub { Lego::Ldraw::POV->toPOV( shift ) };
  $self->build_tree($callback);
  Lego::Ldraw::POV->toPOV($self);
  return (join "\n\n",
	  (
	   Lego::Ldraw::POV->header,
	   Lego::Ldraw::POV->colordef,
	   Lego::Ldraw::POV->model
	  )
	 );
}

sub Lego::Ldraw::pov_name {
  return _pov_name(shift->name);
}

##########################################################
# Lego::Ldraw::Line subs
##########################################################

sub Lego::Ldraw::Line::pov_name {
  return _pov_name(shift->name);
}

sub Lego::Ldraw::Line::pov_coords {
  my @i = shift->coords;
  my @p;
  while (@i) {
    my @d = splice @i, 0, 3;
    push @p, (join ', ', @d);
  }
  return '<' . (join '>, <', @p) . '>';
}

sub Lego::Ldraw::Line::pov_matrix {
  my @m = shift->transform_matrix;
  my $m = join ', ', @m[3, 6, 9, 4, 7, 10, 5, 8, 11, 0, 1, 2];
  return "matrix <$m>";
}

sub Lego::Ldraw::Line::pov_material {
  my $self = shift;
  return if (($self->color == 16) || ($self->color == 24));
  my $col = $self->color;
  return "material { Color$col }";
}

sub Lego::Ldraw::Line::quad_to_triangs {
  my $self = shift;
  return unless $self->type == 4;

  my $a = $self->new;
  $a->{type} = 3;
  my @f = qw/colour x1 y1 z1 x2 y2 z2 x3 y3 z3/;
  for (@f) {
    $a->{$_} = $self->{$_};
  }

  my $b = $self->new;
  $b->{type} = 3;
  for (qw/colour x1 y1 z1 x3 y3 z3 x4 y4 z4/) {
    $b->{shift @f} = $self->{$_};
  }
  return ($a, $b);
}

sub Lego::Ldraw::Line::det {
  return shift->_transform_matrix->det()
}

sub Lego::Ldraw::Line::toPOV {
  my $self = shift;
  for ($self->type) {
    /1/ && do {
      if ($self->det) {
	return join ' ', ('object {', $self->pov_name, $self->pov_matrix, $self->pov_material, '}');
      } else {
	return join ' ', ('// object {', $self->pov_name, $self->pov_matrix, '}');
      }
      last;
    };
    /3/ && do {
     return ('triangle {' . $self->pov_coords . '}');
     last;
    };
    /4/ && do {
      my ($a, $b) = $self->quad_to_triangs;
      return ('triangle {' . $a->pov_coords . "}\n\t\t\ttriangle {" . $b->pov_coords . "}");
      last;
    };
  }
}

1
