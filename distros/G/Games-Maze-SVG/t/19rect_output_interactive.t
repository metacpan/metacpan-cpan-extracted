#!perl

use Test::More;
eval 'use Test::MockModule;';
if($@)
{
    plan( skip_all => q{missing Test::MockModule} );
}
else
{
    plan( tests => 5 );
}
use FindBin;
use lib "$FindBin::Bin/lib";
use TestString;

use Games::Maze::SVG;

use strict;
use warnings;

my $gmaze = Test::MockModule->new( 'Games::Maze' );

my $template = do { local $/ = undef; <DATA>; };

$gmaze->mock(
    make => sub { my $self = shift; $self->{entry} = [2,0]; $self->{exit} = [2,5]; },
    to_ascii => sub { <<EOM },
:--:  :--:--:
|  |        |
:  :  :--:  :
|     |     |
:  :--:--:--:
|  |        |
:  :--:--:  :
|           |
:--:  :--:--:
EOM
);

# Default constructor.

my $output = resolve_template( qq{      <path id="ul" d="M5,10 v-5 h5"/>
      <path id="ur" d="M0,5  h5  v5"/>
      <path id="ll" d="M5,0  v5  h5"/>
      <path id="lr" d="M0,5  h5  v-5"/>
      <path id="h"  d="M0,5  h10"/>
      <path id="v"  d="M5,0  v10"/>
      <path id="l"  d="M0,5  h5"/>
      <path id="r"  d="M5,5  h5"/>
      <path id="t"  d="M5,0  v5"/>
      <path id="d"  d="M5,5  v5"/>
      <path id="tr" d="M5,0  v10 M5,5 h5"/>
      <path id="tl" d="M5,0  v10 M0,5 h5"/>
      <path id="tu" d="M0,5  h10 M5,0 v5"/>
      <path id="td" d="M0,5  h10 M5,5 v5"/>
      <path id="cross" d="M0,5 h10 M5,0 v10"/>} );

my $maze = Games::Maze::SVG->new( 'Rect', cols => 3, rows => 3 );
$maze->set_interactive();

is_string( $maze->toString(), $output, "Full transform, default wall style." );

#open( my $fh, '>rect1.svg' ) or die;
#print $fh $maze->toString();

# ---- Bevel ----
# Because of the outside edge effects, I can't use the template in the
# same way.

$maze = Games::Maze::SVG->new( 'Rect', cols => 3, rows => 3 );
$maze->set_wall_form( 'bevel' );
$maze->set_interactive();
like( $maze->toString(),
      qr{      <path id="ul" d="M5,10.1 v-.1 l5,-5 h.1"/>
      <path id="ur" d="M-.1,5 h.1 l5,5 v.1"/>
      <path id="ll" d="M5,-.1 v.1 l5,5 h.1"/>
      <path id="lr" d="M-.1,5 h.1 l5,-5 v-.1"/>
      <path id="h"  d="M0,5  h10"/>
      <path id="v"  d="M5,0  v10"/>
      <path id="l"  d="M0,5  h5"/>
      <path id="r"  d="M5,5  h5"/>
      <path id="t"  d="M5,0  v5"/>
      <path id="d"  d="M5,5  v5"/>
      <polygon id="tr" points="5,0 5,10 10,5"/>
      <polygon id="tl" points="5,0 5,10 0,5"/>
      <polygon id="tu" points="0,5 10,5 5,0"/>
      <polygon id="td" points="0,5 10,5 5,10"/>
      <polygon id="cross" points="0,5 5,10 10,5 5,0"/>
      <path id="oul" d="M5,10.1 v-.1 l5,-5 h.1"/>
      <path id="our" d="M-.1,5 h.1 l5,5 v.1"/>
      <path id="oll" d="M5,-.1 v.1 l5,5 h.1"/>
      <path id="olr" d="M-.1,5 h.1 l5,-5 v-.1"/>
      <path id="oh"  d="M0,5  h10"/>
      <path id="ov"  d="M5,0  v10"/>
      <path id="ol"  d="M0,5  h5"/>
      <path id="or"  d="M5,5  h5"/>
      <path id="ot"  d="M5,0  v5"/>
      <path id="od"  d="M5,5  v5"/>
      <path id="otr" d="M5,0 l5,5 l-5,5"/>
      <path id="otl" d="M5,0 l-5,5 l5,5"/>
      <path id="otu" d="M0,5 l5,-5 l5,5"/>
      <path id="otd" d="M0,5 l5,5 l5,-5"/>},
    "Full transform, bevel wall style." );


# ---- Round Corners ----
$output = resolve_template( qq{      <path id="ul" d="M5,10 Q5,5 10,5"/>
      <path id="ur" d="M0,5  Q5,5 5,10"/>
      <path id="ll" d="M5,0  Q5,5 10,5"/>
      <path id="lr" d="M0,5  Q5,5 5,0"/>
      <path id="h"  d="M0,5  h10"/>
      <path id="v"  d="M5,0  v10"/>
      <path id="l"  d="M0,5  h5"/>
      <path id="r"  d="M5,5  h5"/>
      <path id="t"  d="M5,0  v5"/>
      <path id="d"  d="M5,5  v5"/>
      <path id="tr" d="M5,0  v10 M5,5 h5"/>
      <path id="tl" d="M5,0  v10 M0,5 h5"/>
      <path id="tu" d="M0,5  h10 M5,0 v5"/>
      <path id="td" d="M0,5  h10 M5,5 v5"/>
      <path id="cross" d="M0,5 h10 M5,0 v10"/>} );

$maze = Games::Maze::SVG->new( 'Rect', cols => 3, rows => 3 );
$maze->set_wall_form( 'roundcorners' );
$maze->set_interactive();

my $got = $maze->toString();
is_string( $got, $output, "Full transform, roundcorners wall style." );

# ---- Round ----

$output = resolve_template( qq{      <path id="ul" d="M5,10 Q5,5 10,5"/>
      <path id="ur" d="M0,5  Q5,5 5,10"/>
      <path id="ll" d="M5,0  Q5,5 10,5"/>
      <path id="lr" d="M0,5  Q5,5 5,0"/>
      <path id="h"  d="M0,5  h10"/>
      <path id="v"  d="M5,0  v10"/>
      <path id="l"  d="M0,5  h5"/>
      <path id="r"  d="M5,5  h5"/>
      <path id="t"  d="M5,0  v5"/>
      <path id="d"  d="M5,5  v5"/>
      <path id="tr" d="M5,0  Q5,5 10,5 Q5,5 5,10"/>
      <path id="tl" d="M5,0  Q5,5 0,5  Q5,5 5,10"/>
      <path id="tu" d="M0,5  Q5,5 5,0  Q5,5 10,5"/>
      <path id="td" d="M0,5  Q5,5 5,10 Q5,5 10,5"/>
      <path id="cross"
                    d="M0,5 Q5,5 5,0  Q5,5 10,5 Q5,5 5,10 Q5,5 0,5"/>} );

$maze = Games::Maze::SVG->new( 'Rect', cols => 3, rows => 3 );
$maze->set_wall_form( 'round' );
$maze->set_interactive();

is_string( $maze->toString(), $output, "Full transform, round wall style." );

# ---- Straight ----

$output = resolve_template( qq{      <path id="ul" d="M5,10 v-5 h5"/>
      <path id="ur" d="M0,5  h5  v5"/>
      <path id="ll" d="M5,0  v5  h5"/>
      <path id="lr" d="M0,5  h5  v-5"/>
      <path id="h"  d="M0,5  h10"/>
      <path id="v"  d="M5,0  v10"/>
      <path id="l"  d="M0,5  h5"/>
      <path id="r"  d="M5,5  h5"/>
      <path id="t"  d="M5,0  v5"/>
      <path id="d"  d="M5,5  v5"/>
      <path id="tr" d="M5,0  v10 M5,5 h5"/>
      <path id="tl" d="M5,0  v10 M0,5 h5"/>
      <path id="tu" d="M0,5  h10 M5,0 v5"/>
      <path id="td" d="M0,5  h10 M5,5 v5"/>
      <path id="cross" d="M0,5 h10 M5,0 v10"/>} );

$maze = Games::Maze::SVG->new( 'Rect', cols => 3, rows => 3 );
$maze->set_wall_form( 'straight' );
$maze->set_interactive();

is_string( $maze->toString(), $output, "Full transform, straight wall style." );

#
# Convert the template into a complete svg page.
#
# walldefs  a string containing the wall piece definitions
#
# Returns the complete output.
sub resolve_template
{
    my $walldefs = shift;
    my $output = $template;
    
    $output =~ s/\{\{walldefs\}\}/$walldefs/sm;
    
    $output;
}

__DATA__
<?xml version="1.0"?>
<svg width="340" height="365"
     xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink"
     xmlns:maze="http://www.anomaly.org/2005/maze"
     onload="initialize()">
  <title>A Playable SVG Maze</title>
  <desc>This maze was generated using the Games::Maze::SVG Perl
    module.</desc>
  <metadata>
    <!--
        Copyright 2004-2013, G. Wade Johnson
        Some rights reserved.
    -->
    <rdf:RDF xmlns="http://web.resource.org/cc/"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
    <Work rdf:about="">
       <dc:title>SVG Maze</dc:title>
       <dc:date>2006</dc:date>
       <dc:description>An SVG-based Game</dc:description>
       <dc:creator><Agent>
          <dc:title>G. Wade Johnson</dc:title>
       </Agent></dc:creator>
       <dc:rights><Agent>
          <dc:title>G. Wade Johnson</dc:title>
       </Agent></dc:rights>
       <dc:type rdf:resource="http://purl.org/dc/dcmitype/Interactive" />
       <license rdf:resource="http://creativecommons.org/licenses/by-sa/2.0/" />
    </Work>

    <License rdf:about="http://creativecommons.org/licenses/by-sa/2.0/">
       <permits rdf:resource="http://web.resource.org/cc/Reproduction" />
       <permits rdf:resource="http://web.resource.org/cc/Distribution" />
       <requires rdf:resource="http://web.resource.org/cc/Notice" />
       <requires rdf:resource="http://web.resource.org/cc/Attribution" />
       <permits rdf:resource="http://web.resource.org/cc/DerivativeWorks" />
       <requires rdf:resource="http://web.resource.org/cc/ShareAlike" />
    </License>

    </rdf:RDF>
  </metadata>

  <defs>
     <style type="text/css">
        text { font-family: sans-serif; font-size: 10px; }
        .panel  { fill:#ccc; stroke:none; }
        .button {
                   cursor: pointer;
                }
        .button rect { fill: #33f; stroke: none; filter: url(#bevel);
                    }
        .button text { text-anchor:middle; fill:#fff; font-weight:bold; }
        .button polygon { fill:white; stroke:none; }
        .ctrllabel { text-anchor:middle; font-weight:bold; }
        #solvedmsg { text-anchor:middle; pointer-events:none; font-size:80px; fill:red;
                   }
     </style>
     <filter id="bevel">
       <feFlood flood-color="#ccf" result="lite-flood"/>
       <feFlood flood-color="#006" result="dark-flood"/>
       <feComposite operator="in" in="lite-flood" in2="SourceAlpha"
                    result="lighter"/>
       <feOffset in="lighter" result="lightedge" dx="-1" dy="-1"/>
       <feComposite operator="in" in="dark-flood" in2="SourceAlpha"
                    result="darker"/>
       <feOffset in="darker" result="darkedge" dx="1" dy="1"/>
       <feMerge>
         <feMergeNode in="lightedge"/>
         <feMergeNode in="darkedge"/>
         <feMergeNode in="SourceGraphic"/>
        </feMerge>
     </filter>
    <script type="text/ecmascript" xlink:href="scripts/point.es"/>
    <script type="text/ecmascript" xlink:href="scripts/sprite.es"/>
    <script type="text/ecmascript" xlink:href="scripts/maze.es"/>
    <script type="text/ecmascript" xlink:href="scripts/rectmaze.es"/>
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

    <maze:board start="3,-2" end="3,10" tile="10,10">
      1111111
      1010101
      1111111
      1010101
      1111111
      1010101
      1111111
    </maze:board>

  </defs>
  <svg x="250" y="0" width="90" height="110"
       viewBox="-10 -20 90 110" id="maze">
    <defs>
      <style type="text/css">
        path    { stroke: black; fill: none; }
        polygon { stroke: black; fill: grey; }
        #sprite { stroke: grey; stroke-width:0.2px; fill: orange; }
        .crumbs { fill:none; stroke-width:1px; stroke-dasharray:5px,3px; }
        .mazebg { fill:#ffc; stroke:none; }
        text { font-family: sans-serif; font-size: 10px; }
        .sign text {  fill:#fff;text-anchor:middle; font-weight:bold; }
        .exit rect {  fill:red; stroke:none; }
        .entry rect {  fill:green; stroke:none; }
      </style>
      <circle id="savemark" r="3" fill="#6f6" stroke="none"/>
      <path id="sprite" d="M0,0 Q5,5 0,10 Q5,5 10,10 Q5,5 10,0 Q5,5 0,0"/>
{{walldefs}}
    </defs>
    <rect id="mazebg" class="mazebg" x="-10" y="-20" width="100%" height="100%"/>

    <use x="0" y="0" xlink:href="#ul"/>
    <use x="10" y="0" xlink:href="#h"/>
    <use x="20" y="0" xlink:href="#td"/>
    <use x="30" y="0" xlink:href="#h"/>
    <use x="40" y="0" xlink:href="#td"/>
    <use x="50" y="0" xlink:href="#h"/>
    <use x="60" y="0" xlink:href="#ur"/>
    <use x="0" y="10" xlink:href="#v"/>
    <use x="20" y="10" xlink:href="#v"/>
    <use x="40" y="10" xlink:href="#v"/>
    <use x="60" y="10" xlink:href="#v"/>
    <use x="0" y="20" xlink:href="#tr"/>
    <use x="10" y="20" xlink:href="#h"/>
    <use x="20" y="20" xlink:href="#cross"/>
    <use x="30" y="20" xlink:href="#h"/>
    <use x="40" y="20" xlink:href="#cross"/>
    <use x="50" y="20" xlink:href="#h"/>
    <use x="60" y="20" xlink:href="#tl"/>
    <use x="0" y="30" xlink:href="#v"/>
    <use x="20" y="30" xlink:href="#v"/>
    <use x="40" y="30" xlink:href="#v"/>
    <use x="60" y="30" xlink:href="#v"/>
    <use x="0" y="40" xlink:href="#tr"/>
    <use x="10" y="40" xlink:href="#h"/>
    <use x="20" y="40" xlink:href="#cross"/>
    <use x="30" y="40" xlink:href="#h"/>
    <use x="40" y="40" xlink:href="#cross"/>
    <use x="50" y="40" xlink:href="#h"/>
    <use x="60" y="40" xlink:href="#tl"/>
    <use x="0" y="50" xlink:href="#v"/>
    <use x="20" y="50" xlink:href="#v"/>
    <use x="40" y="50" xlink:href="#v"/>
    <use x="60" y="50" xlink:href="#v"/>
    <use x="0" y="60" xlink:href="#ll"/>
    <use x="10" y="60" xlink:href="#h"/>
    <use x="20" y="60" xlink:href="#tu"/>
    <use x="30" y="60" xlink:href="#h"/>
    <use x="40" y="60" xlink:href="#tu"/>
    <use x="50" y="60" xlink:href="#h"/>
    <use x="60" y="60" xlink:href="#lr"/>

    <polyline id="crumb" class="crumbs" stroke="#f3f" points="35,-15"/>
    <use id="me" x="30" y="-20" xlink:href="#sprite" visibility="hidden"/>

    <g transform="translate(35,-30)" class="entry sign">
      <rect x="-16" y="-8" width="35" height="16" rx="3" ry="3"/>
      <text x="2" y="4">Entry</text>
    </g>
    <g transform="translate(35,120)" class="exit sign">
      <rect x="-16" y="-8" width="32" height="16" rx="3" ry="3"/>
      <text x="0" y="4">Exit</text>
    </g>
  </svg>
  <g id="control_panel" transform="translate(0,0)">
    <rect x="0" y="0" width="250" height="365"
          class="panel"/>

    <g onclick="restart()" transform="translate(20,20)" class="button"
       onmousedown="push(evt)" onmouseup="release(evt)" onmouseout="release(evt)">
      <rect x="0" y="0" width="50" height="20" rx="5" ry="5"/>
      <text x="25" y="15">Begin</text>
    </g>

    <g onclick="save_position()" transform="translate(80,20)" class="button"
       onmousedown="push(evt)" onmouseup="release(evt)" onmouseout="release(evt)">
      <rect x="0" y="0" width="50" height="20" rx="5" ry="5"/>
      <text x="25" y="15">Save</text>
    </g>

    <g onclick="restore_position()" transform="translate(140,20)" class="button"
       onmousedown="push(evt)" onmouseup="release(evt)" onmouseout="release(evt)">
      <rect x="0" y="0" width="50" height="20" rx="5" ry="5"/>
      <text x="25" y="15">Back</text>
    </g>

    <g transform="translate(20,65)">
      <rect x="-2" y="-2" rx="25" ry="25" width="68" height="68"
          fill="none" stroke-width="0.5" stroke="black"/>
      <text x="34" y="-5" class="ctrllabel">Move View</text>

      <g onclick="maze_up()" transform="translate(22,0)" class="button"
         onmousedown="push(evt)" onmouseup="release(evt)" onmouseout="release(evt)">
        <rect x="0" y="0" width="20" height="20" rx="5" ry="5"/>
        <polygon points="10,5 5,15 15,15"/>
      </g>

      <g onclick="maze_left()" transform="translate(0,22)" class="button"
         onmousedown="push(evt)" onmouseup="release(evt)" onmouseout="release(evt)">
        <rect x="0" y="0" width="20" height="20" rx="5" ry="5"/>
        <polygon points="5,10 15,5 15,15"/>
      </g>

      <g onclick="maze_right()" transform="translate(44,22)" class="button"
         onmousedown="push(evt)" onmouseup="release(evt)" onmouseout="release(evt)">
        <rect x="0" y="0" width="20" height="20" rx="5" ry="5"/>
        <polygon points="15,10 5,5 5,15"/>
      </g>

      <g onclick="maze_down()" transform="translate(22,44)" class="button"
         onmousedown="push(evt)" onmouseup="release(evt)" onmouseout="release(evt)">
        <rect x="0" y="0" width="20" height="20" rx="5" ry="5"/>
        <polygon points="10,15 5,5 15,5"/>
      </g>

      <g onclick="maze_reset()" transform="translate(22,22)" class="button"
         onmousedown="push(evt)" onmouseup="release(evt)" onmouseout="release(evt)">
        <rect x="0" y="0" width="20" height="20" rx="5" ry="5"/>
        <polygon points="7,7 7,13 13,13 13,7"/>
      </g>
    </g>

    <g class="instruct" transform="translate(20,165)">
      <text x="0" y="0">Click Begin button to start</text>
      <text x="0" y="30">Use the arrow keys to move the sprite</text>
      <text x="0" y="50">Hold the shift to move quickly.</text>
      <text x="0" y="70">The mouse must remain over the</text>
      <text x="0" y="90">maze for the keys to work.</text>
      <text x="0" y="120">Use arrow buttons to shift the maze</text>
      <text x="0" y="140">Center button centers view on sprite</text>
      <text x="0" y="160">Save button saves current position</text>
      <text x="0" y="180">Back button restores last position</text>
    </g>
  </g>
  <text id="solvedmsg" x="160" y="217.5" visibility="hidden">Solved!</text>
</svg>
