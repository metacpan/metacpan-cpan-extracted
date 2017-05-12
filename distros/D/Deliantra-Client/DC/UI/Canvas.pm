package DC::UI::Canvas;

use common::sense;

use List::Util qw(max min);

use DC::OpenGL;

our @ISA = DC::UI::Fixed::;

sub new {
   my ($class, %arg) = @_;

   my $items = delete $arg{items};

   my $self = $class->SUPER::new (
      items   => [],
      @_,
   );

   $self->add (@$items)
      if $items && @$items;

   $self
}

sub add_items {
   my ($self, @items) = @_;

   push @{$self->{items}}, @items;

   my @coords =
      map @{ $_->{coord} },
         grep $_->{coord_mode} ne "rel",
            @{ $self->{items} };

   $self->{item_max_w} = max map $_->[0], @coords;
   $self->{item_max_h} = max map $_->[1], @coords;

   $self->realloc;

   map $_+0, @items
}

sub size_request {
   my ($self) = @_;

   my ($w, $h) = $self->SUPER::size_request;

   (
      (max $w, $self->{item_max_w}),
      (max $h, $self->{item_max_h}),
   )
}

my %GLTYPE = (
   lines          => GL_LINES,
   line_strip     => GL_LINE_STRIP,
   line_loop      => GL_LINE_LOOP,
   quads          => GL_QUADS,
   quad_strip     => GL_QUAD_STRIP,
   triangles      => GL_TRIANGLES,
   triangle_strip => GL_TRIANGLE_STRIP,
   triangle_fan   => GL_TRIANGLE_FAN,
   polygon        => GL_POLYGON,
);

sub _draw {
   my ($self) = @_;

   $self->SUPER::_draw;

   for my $item (@{ $self->{items} }) {
      glPushMatrix;
      glScale $self->{w}, $self->{h} if $item->{coord_mode} eq "rel";

      glColor @{ $item->{color} };
      glLineWidth $item->{width} || 1.;
      glPointSize $item->{size}  || 1.;

      if (my $gltype = $GLTYPE{$item->{type}}) {
         glBegin $gltype;
         glVertex @$_ for @{$item->{coord}};
         glEnd;
      }

      glPopMatrix;
   }

   glLineWidth 1;
   glPointSize 1;
}

1

