use strict;
use warnings;
use FFI::C::ArrayDef;
use FFI::C::StructDef;

my $point_def = FFI::C::StructDef->new(
  name  => 'point_t',
  class => 'Point',
  members => [
    x => 'double',
    y => 'double',
  ],
);

my $rect_def = FFI::C::ArrayDef->new(
  name    => 'rectangle_t',
  class   => 'Rectangle',
  members => [
    $point_def, 2,
  ]
);

# create a rectangle using the def's create method
my $square = $rect_def->create([
  { x => 1.0, y => 1.0 },
  { x => 2.0, y => 2.0 },
]);

printf "[[%d %d][%d %d]]\n",
  $square->[0]->x, $square->[0]->y,
  $square->[1]->x, $square->[1]->y;   # [[1 1][2 2]]

# move square by 1 on the x axis
$square->[$_]->x( $square->[$_]->x + 1 ) for 0..1;

printf "[[%d %d][%d %d]]\n",
  $square->[0]->x, $square->[0]->y,
  $square->[1]->x, $square->[1]->y;   # [[2 1][3 2]]

# Create a rectange usingn the generated class
my $rect = Rectangle->new;
$rect->[0]->x(1.0);
$rect->[0]->y(1.0);
$rect->[1]->x(2.0);
$rect->[1]->y(3.0);

