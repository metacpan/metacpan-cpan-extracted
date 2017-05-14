package Lego::Ldraw::Line;

use 5.008004;
use strict;
use warnings;

no warnings qw(uninitialized redefine);
use overload
  '""'  => \&stringify,
  '*'   => \&transform;

use Carp;
use YAML;
use Lego::Ldraw;
use Data::Dumper;
use Math::MatrixReal;
use Math::Trig;
use File::Basename;

my $line_formats = [
		    [qw(type command)],
		    [qw(type colour x y z a b c d e f g h i part)],
		    [qw(type colour x1 y1 z1 x2 y2 z2)],
		    [qw(type colour x1 y1 z1 x2 y2 z2 x3 y3 z3)],
		    [qw(type colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4)],
		    [qw(type colour x1 y1 z1 x2 y2 z2 x3 y3 z3 x4 y4 z4)]
		   ];

our $config;
our %descriptions;

#######################################################################
# Constructors
#######################################################################

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};

  bless ($self, $class);
  return $self;
}

sub new_from_string {
  my $self  = shift->new;

  my $line = shift;
  for ($line) {
    s/\s+$//; s/^\s+//;
  }

  my @line = split ' ', $line;
  @line = ($line[0], join (' ', @line[1..$#line])) unless ($line[0]); # handle comment lines

  my @fields = @{$line_formats->[$line[0]]};
  @{$self}{@fields} = @line;

  return $self;
}

sub new_from_part_name {
  my $self = shift;
  my $part = shift;

  return $self->new_from_string('1 16 0 0 0 1 0 0 0 1 0 0 0 1 ' . $part);
}

#######################################################################
# Field access functions
#######################################################################

sub BEGIN {
  #--------------------------------------------------
  # Use generated functions for clarity and speed,
  # with exceptions...
  #--------------------------------------------------
  my @field_list = ('colour', 'a'..'i', 'x', 'y', 'z',
		    'x1', 'y1', 'z1', 'x2', 'y2', 'z2',
		    'x3', 'y3', 'z3', 'x4', 'y4', 'z4');
  no strict 'refs';
  for my $field (@field_list) {
    *$field = sub {
      my $self = shift;
      return unless exists $self->{$field};
      if (@_) {
	$self->{$field} = shift;
	return $self->{$field};
      } else {
	return $self->{$field};
      }
    }
  }
  use strict 'refs';
}

#--------------------------------------------------
# ...because of uppercasing
#--------------------------------------------------
sub part {
  my $self = shift;
  return unless exists $self->{'part'};
  my $part = $self->{part};
  $part =~ s/\\/\//g;
  return lc $part;
}

sub name {
  return basename(shift->part);
}

#--------------------------------------------------
# ...because it's read-only
#--------------------------------------------------
sub type {
  return shift->{type};
}

#--------------------------------------------------
# ...because of spelling
#--------------------------------------------------
sub color {
  shift->colour(@_);
}

#######################################################################
# other field access functions
#######################################################################

sub copy {
  my $self = shift;
  return bless { %{$self} }, ref $self;
}

sub fields {
  return @{$line_formats->[ shift->type ]}
}

sub model {
  my $self = shift;
  if (@_) {
    $self->{model} = shift;
  }
  return $self->{model};
}

sub description {
  my $self = shift;
  return unless $self->type == 1;

  return $descriptions{$self->part};
}


sub values {
  my $self = shift;
  my @fields = @_;
  @fields = $self->fields unless @fields;
  return @{$self}{ @fields }
}

sub coords {
    my $self = shift;
    my @fields = grep { /^[xyz]/ } $self->fields;
    return $self->values(@fields);
}

sub points {
  my $points = shift->type;
  return $points > 4 ? 4 : $points;
}

sub transform_matrix {
    my $self = shift;
    return unless ($self->type == 1);

    my @fields = grep { /^[a-ixyz]$/ } $self->fields;
    return $self->values(@fields);
}

sub point {
  my $self = shift;
  my $point = shift;
  return unless my $type = $self->type;

  if ($type == 1) {
    return $self->values(qw(x y z));
  } else {
    return $self->values(map { $_ . $point } qw(x y z))
  }
}

sub format {
  my $self = shift;

  my @text = $self->values;

  for ($self->type) {
    /^0/ && do  {
      return "$self";
    };
    /^1/ && do {
      my $string = "%d %7d";
      for (2..$#text-1) {
	$string .= "% 8.2f";
      }
      $string .= " %12s";
      return sprintf $string, @text;
    };
    my $string = "%d";
    for (1..$#text) {
      $string .= "% 8.2f";
    }
    return sprintf $string, @text;
  }
}

sub eval {
    my $self = shift;
    my $expr = shift;

    $expr = lc $expr;
    $expr =~ s/color/colour/g;

    # substitute % strings with field accesses,
    # and while doing so check if field exists:
    # if it doesn't return undef
    while ($expr =~ s/\%([a-z0-9]+)/\$self->{$1}/) {
	return unless defined $self->$1;
    }

    # substitute & strings with function calls,
    # and while doing so check if function exists:
    # if it doesn't return undef
    while ($expr =~ s/\&(\w+)/\$self->$1/) {
	return unless defined $self->can($1);
    }

    # now we've got a full eval'uable string, and
    # we eval it
    if (eval $expr) {
      return $self
    } else {
      return
    }
}

#######################################################################
# inlining
#######################################################################

sub normalize {
  my $self = shift;
  return unless $self->type == 1;

  @{$self}{qw/x y z a b c d e f g h i/} = qw/0 0 0 1 0 0 0 1 0 0 0 1/;
  return $self;
}

sub dir {
  my $self = shift;
  $self->{dir} = shift if @_;
  return $self->{dir};
}

sub partfile {
  my $self = shift;
  return unless $self->type == 1;

  my $part = $self->part;
  return $self->config->{partfiles}->{$part}
    if $self->config->{partfiles}->{$part};

  my $base = $self->config->{base};

  my @parts = @{$self->config->{parts}};
  @parts = map { $_ = $base . $_ . $part } @parts;

  @parts = ('./' . $part, $self->dir . '/' . $part, @parts);

  for (@parts) {
    s/\\/\//g;
    if (-e $_) {
      $self->config->{partfiles}->{$part} = $_;
      return $_;
    }
  }
}

sub explode {
  my $self = shift;

  return unless $self->type == 1;

  my $file = $self->partfile;

  return unless $file;
  return Lego::Ldraw->new_from_file($file);
}

sub traslate {
  my $self = shift;
  my %trans;

  if (ref $_[0] eq 'HASH') { %trans = %{ $_[0] } }
  else { @trans{qw(x y z)} = @_ };

  for my $axis (keys %trans) {
    for my $field ( grep { /^$axis/ } $self->fields ) {
      $self->{$field} += $trans{$axis}
    }
  }
  return $self;
}

sub transform {
  my $self = shift;
  my $line = shift;

  return unless $self->type;
  return unless $line->type == 1;

  $self->color($line->color) if $self->color == 16;
  my $m = $line->_transform_matrix;

  if ($self->type == 1) {
    my $x = $self->_transform_matrix();
    $self->_transform_matrix($x * $m);
  } else {
    for (1..$self->points) {
      my $p = $self->_xyz_matrix(undef, $_);
      $self->_xyz_matrix($p * $m, $_)
    }
  }
}

sub rotate {
  my $self = shift;
  my ($axis, $degrees) = @_;
  return unless $self->type;

  my $x = $self->_transform_matrix();
  my $r = $self->_rotate_matrix($axis, $degrees);
  $self->_transform_matrix($x * $r);
  return $self;
}

#######################################################################
# other stuff
#######################################################################

sub stringify {
  my $self = shift;
  my $type = $self->type;

  my @fields = @{$line_formats->[$self->type]};
  return join ' ', @{$self}{@fields};
}

#######################################################################
# matrix calculation
#######################################################################

sub _xyz_matrix {
  my $self = shift;
  my $matrix = shift;

  if ($matrix) {
    my $point = $self->type == 1 ? undef : shift;
    my @fields = map { $_ . $point } ('x', 'y', 'z');

    $matrix->each( sub { 
		     my $field = shift @fields;
		     return unless $field;
		     $self->$field(shift)
		   } );

    return $self;
  } else {
    my @point  = $self->point(shift);
    my $matrix = Math::MatrixReal->new(1, 4);
    $matrix->[0] = [ [ @point, 1 ] ];
    return @point ? $matrix : undef;
  }
}

sub _transform_matrix {
  my $self = shift;
  my $matrix = shift;

  if ($matrix) {
    my @fields = (qw(a d g), undef,
		  qw(b e h), undef,
		  qw(c f i), undef,
		  qw(x y z), undef);

    # update each field in order with
    # the matrix' value
    $matrix->each( sub { 
		     my $field = shift @fields;
		     return unless $field;
		     $self->$field(shift)
		   } );
    return $self;
  } else {
    my $matrix = Math::MatrixReal->new(4, 4);
    $matrix->[0] = [
		    [ $self->values( qw(a d g) ), 0 ],
		    [ $self->values( qw(b e h) ), 0 ],
		    [ $self->values( qw(c f i) ), 0 ],
		    [ $self->values( qw(x y z) ), 1 ]
		   ];
    return $matrix;
  }
}

sub _rotate_matrix {
  my $self = shift;
  my ($axis, $degrees) = @_;
  my $rad = deg2rad($degrees);
  my $matrix = Math::MatrixReal->new(4, 4);

  for ($axis) {
    /^x$/ && do {
      $matrix->[0] = [
		      [ 1, 0, 0, 0 ],
		      [ 0, cos($rad), sin($rad), 0 ],
		      [ 0, -sin($rad), cos($rad), 0 ],
		      [ 0, 0, 0, 1 ]
		     ];
    };
    /^y$/ && do {
      $matrix->[0] = [
		      [cos($rad), 0, -sin($rad), 0],
		      [0, 1, 0, 0],
		      [sin($rad), 0, cos($rad), 0],
		      [0, 0, 0, 1],
		     ];
    };
    /^z$/ && do {
      $matrix->[0] = [
		      [ cos($rad), sin($rad), 0, 0 ],
		      [ -sin($rad), cos($rad), 0, 0 ],
		      [0, 0, 1, 0],
		      [0, 0, 0, 1]
		     ];
    };
  }

  return $matrix;


}

###############################################################
# configuration stuff
###############################################################

sub INIT {
  return if $config;
  $config = do { local $/; <DATA> };
  $config = Load($config);

  $config->{base} = $ENV{'LDRAWDIR'};
  open DESCRIPTIONS, $config->{base} . 'parts.lst' || return;
  while (<DESCRIPTIONS>) {
    chop;
    my ($part, $description) = unpack 'A14A*', $_;
    $descriptions{$part} = $description;
  }
}

sub config {
  return $config;
}

sub basedir {
  local $_ = $config->{base};
  s/\/$//;
  s/\\$//;
  return $_;
}

sub partsdirs {
  my $self = shift;
  my @d = @{$config->{parts}};
  my $base = $self->basedir;

  for (@d) {
    $_ = join ('/', $base, $_)
      unless /^\./;
    s/\/$//;
    s/\\$//;
  }
  return @d;
}

sub primitives {
  return %{$config->{primitives}}
}

###############################################################
# faster constructor for Matrix::Real
###############################################################

sub Math::MatrixReal::new {
    my ($proto, $rows, $cols) =  @_;

    my $class = ref($proto) || $proto || 'Math::MatrixReal';
    my($i, $j, $this);

    $this = [ [ ], $rows, $cols ];

    bless($this, $class);
    return($this);
}

###############################################################
# end of faster constructor for Matrix::Real
###############################################################

1;

__DATA__
base: 'd:/lego/ldraw/'
parts:
 - 'parts/'
 - 'parts/s/'
 - 'p/'
 - 'p/48/'
lgeo: 'd:/lego/lgeo/'
l3p: d:/lego/util/l3p.exe;
