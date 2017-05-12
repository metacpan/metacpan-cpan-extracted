#!perl

use Test::More tests => 3;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestString;
use MazeTestUtils;

use Games::Maze::SVG;

use strict;
use warnings;

my $maze = Games::Maze::SVG->new( 'Hex' );

can_ok( $maze, qw/get_script_list build_all_script/ );

my $scripts = [
    "scripts/point.es",
    "scripts/sprite.es",
    "scripts/maze.es",
    "scripts/hexmaze.es",
];

is_deeply( [ $maze->get_script_list() ], $scripts, "Correct list of scripts" );

my $script = <<"EOF";
    <script type="text/ecmascript" xlink:href="scripts/point.es"/>
    <script type="text/ecmascript" xlink:href="scripts/sprite.es"/>
    <script type="text/ecmascript" xlink:href="scripts/maze.es"/>
    <script type="text/ecmascript" xlink:href="scripts/hexmaze.es"/>
    <script type="text/ecmascript">
      function push( evt )
      {
          var btn = evt.currentTarget;
          btn.setAttributeNS( null, "opacity", "0.5" );
      }
      function release( evt )
      {
          var btn = evt.currentTarget;
          var opval = btn.getAttributeNS( null, "opacity" );
          if("" != opval &amp;&amp; 1.0 != opval)
              btn.setAttributeNS( null, "opacity", '1.0' );
      }
    </script>
EOF

is_string( $maze->build_all_script(), $script, "Build script elements." );
