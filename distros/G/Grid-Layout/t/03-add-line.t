use strict;
use warnings;

use Test::Simple tests => 3;
use Test::More;
use Test::Files;

use Grid::Layout;
use Grid::Layout::Render;

my $gl = Grid::Layout->new();

my $v_1 = $gl->add_vertical_line  ();
my $h_1 = $gl->add_horizontal_line();

my $v_2 = $gl->add_vertical_line  ();
my $h_2 = $gl->add_horizontal_line();

my $v_3 = $gl->add_vertical_line  ();
my $v_4 = $gl->add_vertical_line  ();

my $h_3 = $gl->add_horizontal_line();
my $h_4 = $gl->add_horizontal_line();

my $area_1 = $gl->area($v_2, $h_2, $v_3, $h_4);
my $area_2 = $gl->area($gl->line_x(0), $h_1, $v_3, $h_2);
isa_ok($area_1, 'Grid::Layout::Area');
isa_ok($area_2, 'Grid::Layout::Area');

my $text = '';
my $rendered = Grid::Layout::Render::top_to_bottom_left_to_right(
  $gl,
  sub {
    my $track_h = shift;
    $text .= "<tr>";
  },
  sub {
     my $cell = shift;

     if (my $area = $cell->{area}) {

       if ($area->x_from == $cell->x and $area->y_from == $cell->y) {
         my $width  = $area->width;
         my $height = $area->height;

         $text .= "<td colspan='$width' rowspan='$height'>";
         $text .= $cell->x . '/' . $cell->y . ' (' . $width . 'x' . $height . ')';
         $text .= "</td>";

       }


     }
     else {
       $text .= "<td>";
       $text .= $cell->x . '/' . $cell->y;
       $text .= "</td>";
     }

  },
  sub {
     $text .= "\n</tr>";
  }
);

open (my $out, '>', 't/03-grid-gotten.html');
print $out "<html>

<table border=1>

$text

</table>

</html>
";
close $out;

compare_ok('t/03-grid-gotten.html', 't/03-grid-expected.html');
