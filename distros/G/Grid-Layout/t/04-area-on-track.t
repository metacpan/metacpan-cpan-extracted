#!/usr/bin/perl
use strict;
use warnings;

use Test::Simple tests => 1;
use Test::More;
use Test::Files;

use Grid::Layout;
use Grid::Layout::Render;

my $gl = Grid::Layout->new();

my $v_l_1 = $gl->add_vertical_line   ();
my $v_l_2 = $gl->add_vertical_line   ();
my $v_l_3 = $gl->add_vertical_line   ();
my $v_t_4 = $gl->add_vertical_track  ();
my $v_t_5 = $gl->add_vertical_track  ();

my $h_l_1 = $gl->add_horizontal_line ();
my $h_t_2 = $gl->add_horizontal_track();
my $h_l_3 = $gl->add_horizontal_line ();
my $h_l_4 = $gl->add_horizontal_line ();

$h_t_2->area($v_l_1, $v_t_4);
$v_t_5->area($h_l_1, $h_l_3);

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

open (my $out, '>', 't/04-grid-gotten.html');
print $out "<html>

<table border=1>

$text

</table>

</html>
";
close $out;

compare_ok('t/04-grid-gotten.html', 't/04-grid-expected.html');
