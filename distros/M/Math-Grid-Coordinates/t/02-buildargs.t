use strict;
use warnings;

use Test::More tests => 7;
use Data::Dump qw/dump/;

use Math::Grid::Coordinates;

use lib './t/lib';

$\ = "\n"; $, = "\t"; binmode(STDOUT, ":utf8");

my $g;

$g = Math::Grid::Coordinates->new({ page_width => 60, page_height => 40, grid_width => 6, grid_height => 4 });

is_deeply($g->to_hash, {
  arrange     => "h",
  border_b    => 0,
  border_l    => 0,
  border_r    => 0,
  border_t    => 0,
  grid_height => 4,
  grid_width  => 6,
  gutter_h    => 0,
  gutter_v    => 0,
  item_height => 10,
  item_width  => 10,
  page_height => 40,
  page_width  => 60,
});

$g = Math::Grid::Coordinates->new({ page_width => 600, page_height => 400, grid_width => 6, grid_height => 4, gutter => "2pw" });

is_deeply($g->to_hash, {
  arrange     => "h",
  border_b    => 0,
  border_l    => 0,
  border_r    => 0,
  border_t    => 0,
  grid_height => 4,
  grid_width  => 6,
  gutter_h    => 12,
  gutter_v    => 12,
  item_height => 91,
  item_width  => 90,
  page_height => 400,
  page_width  => 600,
});

$g = Math::Grid::Coordinates->new(page => 600, 400, 91, 90, "2pw");

is_deeply($g->to_hash, {
  arrange     => "h",
  border_b    => 0,
  border_l    => 0,
  border_r    => 0,
  border_t    => 0,
  grid_height => 0,
  grid_width  => 0,
  gutter_h    => 12,
  gutter_v    => 12,
  item_height => 90,
  item_width  => 91,
  page_height => 400,
  page_width  => 600,
});

$g = Math::Grid::Coordinates->new(grid => 6, 4, 91, 90, 12);

is_deeply($g->to_hash, {
  arrange     => "h",
  border_b    => 0,
  border_l    => 0,
  border_r    => 0,
  border_t    => 0,
  grid_height => 4,
  grid_width  => 6,
  gutter_h    => 12,
  gutter_v    => 12,
  item_height => 90,
  item_width  => 91,
  page_height => 0,
  page_width  => 0,
});

$g = Math::Grid::Coordinates->new({ page_width => 210, page_height => 297, grid_width => 2, grid_height => 3, gutter => 6, border => 12 });

is_deeply($g->to_hash, {
  arrange     => "h",
  border_b    => 12,
  border_l    => 12,
  border_r    => 12,
  border_t    => 12,
  grid_height => 3,
  grid_width  => 2,
  gutter_h    => 6,
  gutter_v    => 6,
  item_height => 87,
  item_width  => 90,
  page_height => 297,
  page_width  => 210,
});

$g = Math::Grid::Coordinates->new({ item_width => 90, item_height => 87, grid_width => 2, grid_height => 3, gutter => 6, border => 12 });

is_deeply($g->to_hash, {
  arrange     => "h",
  border_b    => 12,
  border_l    => 12,
  border_r    => 12,
  border_t    => 12,
  grid_height => 3,
  grid_width  => 2,
  gutter_h    => 6,
  gutter_v    => 6,
  item_height => 87,
  item_width  => 90,
  page_height => 297,
  page_width  => 210,
});

$g = Math::Grid::Coordinates->new({ page_width => 210, page_height => 297, grid_width => 2, grid_height => 3, gutter => "3pw", border => "6pw" });

is_deeply($g->to_hash, {
  arrange     => "h",
  border_b    => 12.6,
  border_l    => 12.6,
  border_r    => 12.6,
  border_t    => 12.6,
  grid_height => 3,
  grid_width  => 2,
  gutter_h    => 6.3,
  gutter_v    => 6.3,
  item_height => 86.4,
  item_width  => 89.25,
  page_height => 297,
  page_width  => 210,
});

# print dump($g->to_hash);

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
