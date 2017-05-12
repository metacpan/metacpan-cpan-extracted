package Games::Lacuna::Task::Constants;

use strict;
use warnings;
use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

# do not change order
our @RESOURCES = qw(water ore energy food);

our @RESOURCES_ALL = (@RESOURCES,'waste');

our %CARGO = (
    ship    => 50_000,
    glyph   => 100,
    plan    => 10_000,
    prisoner=> 350,
);

our $SCREEN_WIDTH = 78;

our $MAX_MAP_QUERY = 30; # 30 x 30 units

our $MAX_STAR_CACHE_AGE = 60*60*24*31*3; # Three months


1;