#!perl

use Test::More;
eval 'use Test::MockModule;';
if($@)
{
    plan( skip_all => q{missing Test::MockModule} );
}
else
{
    plan( tests => 1 );
}
use FindBin;
use lib "$FindBin::Bin/lib";
use MazeTestUtils;
use TestString;

use Games::Maze::SVG;

use strict;
use warnings;

my $gmaze = Test::MockModule->new( 'Games::Maze' );

my $rectgrid = 

my $output = do { local $/ = undef; <DATA>; };

$gmaze->mock(
    make => sub { my $self = shift; $self->{entry} = [4,0]; $self->{exit} = [4,5]; },
    to_ascii => sub { normalize_maze( <<'EOM' ); },
 __    __    
/  \__/  \
\  /   __   \
/  \  /   __/
\  /  \__   \
/  \__   \  /
\  /   __/  \
/  \  /  \  /
\__   \__   \
   \__/  \  /

EOM
);

# Default constructor.
my $maze = Games::Maze::SVG->new( 'RectHex', cols => 3, rows => 3 );
$maze->set_interactive();

#open( my $fh, '>recthex1.svg' ) or die;
#print $fh $maze->toString();

is_string( $maze->toString(), $output, "Full transform works." );


__DATA__
<?xml version="1.0"?>
<svg width="380" height="365"
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

    <maze:board start="11,-4" end="11,22" tile="10,10">
      01110001110
      11011011011
      10001110001
      11011011011
      01110001110
      11011011011
      10001110001
      11011011011
      01110001110
      11011011011
      10001110001
      11011011011
      01110001110
      00011011000
      00001110000
      00000000000
      00000000000
    </maze:board>

  </defs>
  <svg x="250" y="0" width="130" height="210"
       viewBox="-10 -20 130 210" id="maze">
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
      <path id="hz" d="M0,5 h10"/>
      <path id="hzr" d="M5,5 h5"/>
      <path id="hzl" d="M0,5 h5"/>
      <path id="tl" d="M10,5 h-5 L2.5,10"/>
      <path id="tr" d="M0,5 h5 L7.5,10"/>
      <path id="br" d="M0,5 h5 L7.5,0"/>
      <path id="bl" d="M10,5 h-5 L2.5,0"/>
      <path id="sl" d="M7.5,0 L12.5,10"/>
      <path id="sr" d="M12.5,0 L7.5,10"/>
      <path id="slt" d="M5,5 L7.5,10"/>
      <path id="slb" d="M5,5 L2.5,0"/>
      <path id="srt" d="M5,5 L2.5,10"/>
      <path id="srb" d="M5,5 L7.5,0"/>
      <path id="cr" d="M2.5,0 L5,5 L2.5,10"/>
      <path id="cl" d="M7.5,0 L5,5 L7.5,10"/>
      <path id="yr" d="M2.5,0 L5,5 L2.5,10 M5,5 h5"/>
      <path id="yl" d="M7.5,0 L5,5 L7.5,10 M5,5 h-5"/>
    </defs>
    <rect id="mazebg" class="mazebg" x="-10" y="-20" width="100%" height="100%"/>

    <use x="10" y="0" xlink:href="#tl"/>
    <use x="20" y="0" xlink:href="#hz"/>
    <use x="30" y="0" xlink:href="#tr"/>
    <use x="70" y="0" xlink:href="#tl"/>
    <use x="80" y="0" xlink:href="#hz"/>
    <use x="90" y="0" xlink:href="#tr"/>
    <use x="0" y="10" xlink:href="#sr"/>
    <use x="30" y="10" xlink:href="#sl"/>
    <use x="60" y="10" xlink:href="#sr"/>
    <use x="90" y="10" xlink:href="#sl"/>
    <use x="0" y="20" xlink:href="#cl"/>
    <use x="40" y="20" xlink:href="#yr"/>
    <use x="50" y="20" xlink:href="#hz"/>
    <use x="60" y="20" xlink:href="#yl"/>
    <use x="100" y="20" xlink:href="#cr"/>
    <use x="0" y="30" xlink:href="#sl"/>
    <use x="30" y="30" xlink:href="#sr"/>
    <use x="60" y="30" xlink:href="#sl"/>
    <use x="90" y="30" xlink:href="#sr"/>
    <use x="10" y="40" xlink:href="#yr"/>
    <use x="20" y="40" xlink:href="#hz"/>
    <use x="30" y="40" xlink:href="#yl"/>
    <use x="70" y="40" xlink:href="#yr"/>
    <use x="80" y="40" xlink:href="#hz"/>
    <use x="90" y="40" xlink:href="#yl"/>
    <use x="0" y="50" xlink:href="#sr"/>
    <use x="30" y="50" xlink:href="#sl"/>
    <use x="60" y="50" xlink:href="#sr"/>
    <use x="90" y="50" xlink:href="#sl"/>
    <use x="0" y="60" xlink:href="#cl"/>
    <use x="40" y="60" xlink:href="#yr"/>
    <use x="50" y="60" xlink:href="#hz"/>
    <use x="60" y="60" xlink:href="#yl"/>
    <use x="100" y="60" xlink:href="#cr"/>
    <use x="0" y="70" xlink:href="#sl"/>
    <use x="30" y="70" xlink:href="#sr"/>
    <use x="60" y="70" xlink:href="#sl"/>
    <use x="90" y="70" xlink:href="#sr"/>
    <use x="10" y="80" xlink:href="#yr"/>
    <use x="20" y="80" xlink:href="#hz"/>
    <use x="30" y="80" xlink:href="#yl"/>
    <use x="70" y="80" xlink:href="#yr"/>
    <use x="80" y="80" xlink:href="#hz"/>
    <use x="90" y="80" xlink:href="#yl"/>
    <use x="0" y="90" xlink:href="#sr"/>
    <use x="30" y="90" xlink:href="#sl"/>
    <use x="60" y="90" xlink:href="#sr"/>
    <use x="90" y="90" xlink:href="#sl"/>
    <use x="0" y="100" xlink:href="#cl"/>
    <use x="40" y="100" xlink:href="#yr"/>
    <use x="50" y="100" xlink:href="#hz"/>
    <use x="60" y="100" xlink:href="#yl"/>
    <use x="100" y="100" xlink:href="#cr"/>
    <use x="0" y="110" xlink:href="#sl"/>
    <use x="30" y="110" xlink:href="#sr"/>
    <use x="60" y="110" xlink:href="#sl"/>
    <use x="90" y="110" xlink:href="#sr"/>
    <use x="10" y="120" xlink:href="#bl"/>
    <use x="20" y="120" xlink:href="#hz"/>
    <use x="30" y="120" xlink:href="#yl"/>
    <use x="70" y="120" xlink:href="#yr"/>
    <use x="80" y="120" xlink:href="#hz"/>
    <use x="90" y="120" xlink:href="#br"/>
    <use x="30" y="130" xlink:href="#sl"/>
    <use x="60" y="130" xlink:href="#sr"/>
    <use x="40" y="140" xlink:href="#bl"/>
    <use x="50" y="140" xlink:href="#hz"/>
    <use x="60" y="140" xlink:href="#br"/>

    <polyline id="crumb" class="crumbs" stroke="#f3f" points="115,-35"/>
    <use id="me" x="110" y="-40" xlink:href="#sprite" visibility="hidden"/>

    <g transform="translate(110,-50)" class="entry sign">
      <rect x="-16" y="-8" width="35" height="16" rx="3" ry="3"/>
      <text x="2" y="4">Entry</text>
    </g>
    <g transform="translate(110,240)" class="exit sign">
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
  <text id="solvedmsg" x="180" y="217.5" visibility="hidden">Solved!</text>
</svg>
