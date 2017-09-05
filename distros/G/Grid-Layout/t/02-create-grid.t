use strict;
use warnings;

use Test::Simple tests => 297;
use Test::More;
use Test::Exception;
use Test::Files;

use Grid::Layout;
use Grid::Layout::Render;

is(Grid::Layout::VH_opposite('V'), 'H', 'Opposite of V is H');
is(Grid::Layout::VH_opposite('H'), 'V', 'Opposite of H is V');

my $gl = Grid::Layout->new();                    isa_ok($gl        , 'Grid::Layout', '$gl is a Grid::Layout');

is(ref($gl->{V}{tracks}), 'ARRAY', '$gl->{V}{tracks} is an array reference');
is(ref($gl->{H}{tracks}), 'ARRAY', '$gl->{V}{tracks} is an array reference');
is(ref($gl->{V}{lines }), 'ARRAY', '$gl->{V}{tracks} is an array reference');
is(ref($gl->{H}{lines }), 'ARRAY', '$gl->{V}{tracks} is an array reference');

my $v_line_0 = $gl->get_vertical_line  (0);
my $h_line_0 = $gl->get_horizontal_line(0);

isa_ok($v_line_0, 'Grid::Layout::Line');
isa_ok($h_line_0, 'Grid::Layout::Line');
is($v_line_0->{position}, 0);
is($h_line_0->{position}, 0);
isnt($v_line_0, $h_line_0);

throws_ok { $v_line_0->_previous_track } qr{Cannot return previous track. I am line zero};
throws_ok { $h_line_0->_previous_track } qr{Cannot return previous track. I am line zero};

throws_ok { $v_line_0->_next_track     } qr{Cannot return next track. I am last line};
throws_ok { $h_line_0->_next_track     } qr{Cannot return next track. I am last line};

is($v_line_0, $gl->line_x(0));
is($h_line_0, $gl->line_y(0));

my @size = $gl->size();

is_deeply(\@size, [0, 0], 'Size is 0x0');

my $cell;

$cell = $gl->cell(0, 0);
is($cell, undef, 'cell 0.0 is undefined');

is(scalar @{$gl->{V}->{lines }}, 1, '1 vertical   tracks after creation');
is(scalar @{$gl->{H}->{lines }}, 1, '1 horizontal tracks after creation');

is(scalar @{$gl->{V}->{tracks}}, 0, '0 vertical   tracks after creation');
is(scalar @{$gl->{H}->{tracks}}, 0, '0 horizontal tracks after creation');

# Add 4 horizontal and 3 vertical tracks:
my ($track_h_A,
    $line_h_A)   = $gl->add_horizontal_track();

                 isa_ok($track_h_A   , 'Grid::Layout::Track', '$track_h_A is a Grid::Layout::Track');
                 isa_ok($line_h_A    , 'Grid::Layout::Line');
                 is($gl->size_x, 0, 'gl size_x is 1');
                 is($gl->size_y, 1, 'gl size_y is 0');
                 @size=$gl->size(); is_deeply(\@size, [0, 1], 'Size is 0x1');
                 $cell = $gl->cell(0, 0); is($cell, undef, 'cell 0.0 is undefined');
                 is(scalar @{$gl->{V}->{lines}}, 1, '1 vertical lines');
                 is(scalar @{$gl->{H}->{lines}}, 2, '2 horizontal lines');
                 is($track_h_A->{position}, 0, '$track_h_A->{position} == 0');
                 is($line_h_A, $gl->line_y(1));
my $track_h_B    = $gl->add_horizontal_track();
                 isa_ok($track_h_B, 'Grid::Layout::Track', '$track_h_B is a Grid::Layout::Track');
                 is($gl->size_x, 0, 'gl size_x is 2');
                 is($gl->size_y, 2, 'gl size_y is 0');
                 @size=$gl->size(); is_deeply(\@size, [0, 2], 'Size is 0x2');
                 $cell = $gl->cell(0, 0); is($cell, undef, 'cell 0.0 is undefined');
                 is(scalar @{$gl->{V}->{lines}}, 1, '1 vertical lines');
                 is(scalar @{$gl->{H}->{lines}}, 3, '3 horizontal lines');
                 is($track_h_B->{position}, 1, '$track_h_B->{position} == 1');
my ($track_h_C,
    $line_h_C)   = $gl->add_horizontal_track();
                 isa_ok($track_h_C, 'Grid::Layout::Track', '$track_h_C is a Grid::Layout::Track');
                 isa_ok($line_h_C , 'Grid::Layout::Line' , '$line_h_C  is a Grid::Layout::Line' );
                 is($gl->size_x, 0, 'gl size_x is 3');
                 is($gl->size_y, 3, 'gl size_y is 0');
                 $cell = $gl->cell(0, 0); is($cell, undef, 'cell 0.0 is undefined');
                 is(scalar @{$gl->{V}->{lines}}, 1, '1 vertical lines');
                 is(scalar @{$gl->{H}->{lines}}, 4, '4 horizontal lines');
                 is($line_h_C, $gl->line_y(3));
                 throws_ok { $line_h_C->_next_track} qr{Cannot return next track. I am last line};

                 my $line_h_C_prev_track = $line_h_C->_previous_track;
                 isa_ok($line_h_C_prev_track, 'Grid::Layout::Track');

my ($track_v_abc,
    $line_v_abc) = $gl->add_vertical_track();
                 isa_ok($track_v_abc, 'Grid::Layout::Track', '$track_v_abc is a Grid::Layout::Track');
                 isa_ok($line_v_abc , 'Grid::Layout::Line' , '$line_v_abc is a Grid::Layout::Line');
                 @size=$gl->size(); is_deeply(\@size, [1, 3], 'Size is 1x3');
                 $cell = $gl->cell(0, 0); isa_ok($cell, 'Grid::Layout::Cell', 'cell 0.0 is Cell');
                 $cell = $gl->cell(0, 1); isa_ok($cell, 'Grid::Layout::Cell', 'cell 0.1 is Cell');
                 $cell = $gl->cell(0, 2); isa_ok($cell, 'Grid::Layout::Cell', 'cell 0.2 is Cell');
                 $cell = $gl->cell(1, 0); is    ($cell,  undef              , 'cell 0.1 is undef');
                 $cell = $gl->cell(1, 1); is    ($cell,  undef              , 'cell 1.1 is undef');
                 is(scalar @{$gl->{V}->{lines}}, 2, '2 vertical lines');
                 is(scalar @{$gl->{H}->{lines}}, 4, '4 horizontal lines');
                 is($track_v_abc->{V_or_H}, 'V', '$track_v_abc->{V_or_H} eq V');
                 is($track_v_abc->{position}, 0, '$track_v_abc->{position} == 0');
my $track_v_def = $gl->add_vertical_track();
                 isa_ok($track_v_def, 'Grid::Layout::Track', '$track_v_def is a Grid::Layout::Track');

my $track_h_D   = $gl->add_horizontal_track();
                 isa_ok($track_h_D, 'Grid::Layout::Track', '$track_h_D is a Grid::Layout::Track');
                 is($track_h_D->{V_or_H}, 'H', '$track_h_D->{V_or_H} eq H');
my $track_v_ghi = $gl->add_vertical_track();
                 isa_ok($track_v_ghi, 'Grid::Layout::Track', '$track_h_C is a Grid::Layout::Track');
                 @size = $gl->size(); is_deeply(\@size, [3, 4], 'Size is 3 (vertical) x 4 (horizontal) tracks');
                 is($track_v_ghi->{position}, 2, '$track_v_ghi->{position} == 2');

isnt($gl->cell(0, 0), $gl->cell(0, 1));
isnt($gl->cell(0, 0), $gl->cell(1, 0));
isnt($gl->cell(0, 0), $gl->cell(1, 1));

is($gl->cell(0, 0), $gl->cell($track_v_abc, $track_h_A));
is($gl->cell(0, 1), $gl->cell($track_v_abc, $track_h_B));
is($gl->cell(1, 0), $gl->cell($track_v_def, $track_h_A));
is($gl->cell(1, 1), $gl->cell($track_v_def, $track_h_B));

is($gl->size_x, 3, 'Horizontal size is 4');
is($gl->size_y, 4, 'Vertical size is 3');


# Add another 6 horizontal and 5 vertical tracks;

my $track_h_E  = $gl->add_horizontal_track();
my $track_h_F  = $gl->add_horizontal_track();
my $track_h_G  = $gl->add_horizontal_track();
my $track_h_H  = $gl->add_horizontal_track();
my $track_h_09 = $gl->add_horizontal_track();
my $track_h_10 = $gl->add_horizontal_track();

my $track_v_jkl= $gl->add_vertical_track();
my $track_v_mno= $gl->add_vertical_track();
my $track_v_pqr= $gl->add_vertical_track();
my $track_v_stu= $gl->add_vertical_track();
my $track_v_vwx= $gl->add_vertical_track();

# ---------------------------------------------

is($gl->size_x,  8, 'size_x =  8');
is($gl->size_y, 10, 'size_y = 10');


is(scalar @{$gl->{V}->{lines}}, 9, '9 vertical lines');
is(scalar @{$gl->{H}->{lines}},11, '11 horizontal lines');

my @cells;
my $cnt;
@cells = $track_h_C->cells();
is(scalar @cells, 8);
$cnt = 0;
for my $c (@cells) {
  isa_ok($c, 'Grid::Layout::Cell');
  is($c->x, $cnt++);
  is($c->y, 2);
}

@cells = $track_v_vwx->cells();
is(scalar @cells, 10);
$cnt = 0;
for my $c (@cells) {
  isa_ok($c, 'Grid::Layout::Cell');
  is($c->x, 7);
  is($c->y, $cnt++);
}

my $line_h_03_beneath = $track_h_C->line_beneath();
my $line_h_04_above   = $track_h_D->line_above();
my $line_h_05_above   = $track_h_E ->line_above();

my $line_v_03_right   = $track_v_ghi->line_right();
my $line_v_04_left    = $track_v_jkl->line_left();
my $line_v_05_left    = $track_v_mno->line_left();

isa_ok($line_h_03_beneath, 'Grid::Layout::Line', '$line_h_03_beneath should be a Grid::Layout::Line');
isa_ok($line_h_04_above  , 'Grid::Layout::Line', '$line_h_04_above   should be a Grid::Layout::Line');
isa_ok($line_h_05_above  , 'Grid::Layout::Line', '$line_h_04_above   should be a Grid::Layout::Line');
isa_ok($line_v_03_right  , 'Grid::Layout::Line', '$line_v_03_right   should be a Grid::Layout::Line');
isa_ok($line_v_04_left   , 'Grid::Layout::Line', '$line_v_04_left    should be a Grid::Layout::Line');
isa_ok($line_v_05_left   , 'Grid::Layout::Line', '$line_v_05_left    should be a Grid::Layout::Line');

is  ($line_h_04_above, $line_h_03_beneath, '$line_h_04_above eq $line_h_03_beneath');
isnt($line_h_04_above, $line_h_05_above  , '$line_h_05_above ne $line_h_05_above');

is  ($line_v_03_right, $line_v_04_left   , '$line_v_03_right eq $line_v_04_left');
isnt($line_v_04_left , $line_v_05_left   , '$line_v_04_left eq $line_v_05_left');


my $area_1 = $gl->area(
  $track_v_abc, $track_h_H,
  $track_v_ghi, $track_h_H);

my $area_2 = $gl->area(
  $track_v_def, $track_h_C,
  $track_v_def, $track_h_F);

my $area_3 = $track_h_B->area($track_v_def, $track_v_jkl);
my $area_4 = $track_v_jkl->area($track_h_D, $track_h_G);

my $area_5 = $gl->area(
  $track_v_mno, $track_h_E,
  $track_v_vwx, $track_h_G);

isa_ok($area_1, 'Grid::Layout::Area');
isa_ok($area_2, 'Grid::Layout::Area');
isa_ok($area_3, 'Grid::Layout::Area');
isa_ok($area_4, 'Grid::Layout::Area');
isa_ok($area_5, 'Grid::Layout::Area');

isnt  ($area_1, $area_2);
isnt  ($area_1, $area_3);
isnt  ($area_1, $area_4);
isnt  ($area_1, $area_5);

is($gl->cell(0, 0)->{area}, undef  , 'Cell 0/0 is in no Area');
is($gl->cell(1, 0)->{area}, undef  , 'Cell 1/0 is in no Area');
is($gl->cell(2, 0)->{area}, undef  , 'Cell 2/0 is in no Area');
is($gl->cell(3, 0)->{area}, undef  , 'Cell 3/0 is in no Area');
is($gl->cell(4, 0)->{area}, undef  , 'Cell 4/0 is in no Area');
is($gl->cell(0, 1)->{area}, undef  , 'Cell 0/1 is in no Area');
is($gl->cell(1, 1)->{area}, $area_3, 'Cell 1/1 is in Area 3');
is($gl->cell(2, 1)->{area}, $area_3, 'Cell 2/1 is in Area 3');
is($gl->cell(3, 1)->{area}, $area_3, 'Cell 3/1 is in Area 3');
is($gl->cell(4, 1)->{area}, undef  , 'Cell 4/1 is in no Area');
is($gl->cell(0, 2)->{area}, undef  , 'Cell 0/2 is in no Area');
is($gl->cell(1, 2)->{area}, $area_2, 'Cell 1/2 is in no Area');
is($gl->cell(2, 2)->{area}, undef  , 'Cell 2/2 is in no Area');
is($gl->cell(3, 2)->{area}, undef  , 'Cell 3/2 is in no Area');
is($gl->cell(4, 2)->{area}, undef  , 'Cell 4/2 is in no Area');

is($gl->cell($track_v_abc, $track_h_C)->{area}, undef);
is($gl->cell($track_v_def, $track_h_C)->{area}, $area_2);
is($gl->cell($track_v_ghi, $track_h_C)->{area}, undef);
is($gl->cell($track_v_def, $track_h_D)->{area}, $area_2);
is($gl->cell($track_v_def, $track_h_E)->{area}, $area_2);
is($gl->cell($track_v_def, $track_h_F)->{area}, $area_2);
is($gl->cell($track_v_def, $track_h_G)->{area}, undef);

is($gl->cell($track_v_jkl, $track_h_C)->{area}, undef);
is($gl->cell($track_v_jkl, $track_h_D)->{area}, $area_4);
is($gl->cell($track_v_mno, $track_h_D)->{area}, undef);
is($gl->cell($track_v_mno, $track_h_E)->{area}, $area_5);
is($gl->cell($track_v_vwx, $track_h_E)->{area}, $area_5);

#        abc    def    ghi    jkl    mno    pqr    stu    vwx
#
#      +------+------+------+------+------+------+------+------+
#  A   |      |      |      |      |      |      |      |      |
#      +------+--------------------+------+------+------+------+
#  1   |      |  Area 3            |      |      |      |      |
#      +------+--------------------+------+------+------+------+
#  C   |      |      |      |      |      |      |      |      |
#      +------|   A  |------+------+------+------+------+------+
#  D   |      |   r  |      |      |      |      |      |      |
#      +------|   e  |------|  A   |---------------------------+
#  E   |      |   a  |      |  r   |                           |
#      +------|      |------|  e   |                           |
#  F   |      |   2  |      |  a   |    Area 5                 |
#      +------+------+------|      |                           |
#  G   |      |      |      |  4   |                           |
#      +--------------------+------+---------------------------+
#  H   |    Area 1          |      |      |      |      |      |
#      +--------------------+------+------+------+------+------+
#  8   |      |      |      |      |      |      |      |      |
#      +------+------+------+------+------+------+------+------+
#  9   |      |      |      |      |      |      |      |      |
#      +------+------+------+------+------+------+------+------+
#

is($area_2->x_from, 1);
is($area_2->x_to  , 1);
is($area_2->y_from, 2);
is($area_2->y_to  , 5);

is($area_5->x_from, 4);
is($area_5->x_to  , 7);
is($area_5->y_from, 4);
is($area_5->y_to  , 6);

is($area_3->width , 3);
is($area_3->height, 1);

throws_ok { $gl->area($track_v_def, $track_h_G, $track_v_jkl, $track_h_G) } qr{cell 3/6 already belongs to an area};

my $text = '';
my $rendered = Grid::Layout::Render::top_to_bottom_left_to_right(
  $gl,
  sub {
    my $track_h = shift;
    isa_ok($track_h, 'Grid::Layout::Track');
    is($track_h->{V_or_H}, 'H');
    $text .= "<tr>";
  },
  sub {
     my $cell = shift;

     isa_ok($cell, 'Grid::Layout::Cell');

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

open (my $out, '>', 't/02-grid-gotten.html');
print $out "<html>

<table border=1>

$text

</table>

</html>
";
close $out;

compare_ok('t/02-grid-gotten.html', 't/02-grid-expected.html');
