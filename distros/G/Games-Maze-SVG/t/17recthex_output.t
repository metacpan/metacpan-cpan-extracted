#!perl

use Test::More;
eval 'use Test::MockModule;';
if($@)
{
    plan( skip_all => q{missing Test::MockModule} );
}
else
{
    plan( tests => 4 );
}
use FindBin;
use lib "$FindBin::Bin/lib";
use MazeTestUtils;
use TestString;

use Games::Maze::SVG;

use strict;
use warnings;

my $gmaze = Test::MockModule->new( 'Games::Maze' );

my $template = do { local $/ = undef; <DATA>; };

$gmaze->mock(
    make => sub { my $self = shift; $self->{entry} = [2,1]; $self->{exit} = [6,8]; },
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

#open( my $fh, '>recthex1.svg' ) or die;
#print $fh $maze->toString();

my $output = resolve_template( qq{      <path id="hz" d="M0,5 h10"/>
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
      <path id="yl" d="M7.5,0 L5,5 L7.5,10 M5,5 h-5"/>});

is_string( $maze->toString(), $output, "Full transform works." );

# ---- Round Corners ----

$output = resolve_template( qq{      <path id="hz" d="M0,5 h10"/>
      <path id="hzr" d="M5,5 h5"/>
      <path id="hzl" d="M0,5 h5"/>
      <path id="tl" d="M10,5 Q6,6 2.5,10"/>
      <path id="tr" d="M0,5 Q4,6 7.5,10"/>
      <path id="br" d="M0,5 Q5,5 7.5,0"/>
      <path id="bl" d="M10,5 Q6,4 2.5,0"/>
      <path id="sl" d="M7.5,0 L12.5,10"/>
      <path id="sr" d="M12.5,0 L7.5,10"/>
      <path id="slt" d="M5,5 L7.5,10"/>
      <path id="slb" d="M5,5 L2.5,0"/>
      <path id="srt" d="M5,5 L2.5,10"/>
      <path id="srb" d="M5,5 L7.5,0"/>
      <path id="cr" d="M2.5,0 Q4,5 2.5,10"/>
      <path id="cl" d="M7.5,0 Q6,5 7.5,10"/>
      <path id="yr" d="M2.5,0 L5,5 L2.5,10 M5,5 h5"/>
      <path id="yl" d="M7.5,0 L5,5 L7.5,10 M5,5 h-5"/>} );

$maze = Games::Maze::SVG->new( 'RectHex', cols => 3, rows => 3 );
$maze->set_wall_form( 'roundcorners' );

is_string( $maze->toString(), $output, "Full transform, roundcorners wall style." );

# ---- Round ----

$output = resolve_template( qq{      <path id="hz" d="M0,5 h10"/>
      <path id="hzr" d="M5,5 h5"/>
      <path id="hzl" d="M0,5 h5"/>
      <path id="tl" d="M10,5 Q6,6 2.5,10"/>
      <path id="tr" d="M0,5 Q4,6 7.5,10"/>
      <path id="br" d="M0,5 Q5,5 7.5,0"/>
      <path id="bl" d="M10,5 Q6,4 2.5,0"/>
      <path id="sl" d="M7.5,0 L12.5,10"/>
      <path id="sr" d="M12.5,0 L7.5,10"/>
      <path id="slt" d="M5,5 L7.5,10"/>
      <path id="slb" d="M5,5 L2.5,0"/>
      <path id="srt" d="M5,5 L2.5,10"/>
      <path id="srb" d="M5,5 L7.5,0"/>
      <path id="cr" d="M2.5,0 Q4,5 2.5,10"/>
      <path id="cl" d="M7.5,0 Q6,5 7.5,10"/>
      <path id="yr" d="M2.5,0 Q4,5 2.5,10 Q6,5 10,5 Q5,4 2.5,0"/>
      <path id="yl" d="M7.5,0 Q6,5 7.5,10 Q4,6 0,5 Q4,4 7.5,0"/>} );

$maze = Games::Maze::SVG->new( 'RectHex', cols => 3, rows => 3 );
$maze->set_wall_form( 'round' );

is_string( $maze->toString(), $output, "Full transform, round wall style." );

# ---- Straight ----

$output = resolve_template( qq{      <path id="hz" d="M0,5 h10"/>
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
      <path id="yl" d="M7.5,0 L5,5 L7.5,10 M5,5 h-5"/>} );

$maze = Games::Maze::SVG->new( 'RectHex', cols => 3, rows => 3 );
$maze->set_wall_form( 'straight' );

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
<svg width="130" height="210"
     xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink">
  <title>An SVG Maze</title>
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

  <svg x="0" y="0" width="130" height="210"
       viewBox="-10 -20 130 210" id="maze">
    <defs>
      <style type="text/css">
        path    { stroke: black; fill: none; }
        polygon { stroke: black; fill: grey; }
        #sprite { stroke: grey; stroke-width:0.2px; fill: orange; }
        .crumbs { fill:none; stroke-width:1px; stroke-dasharray:5px,3px; }
        .mazebg { fill:#fff; stroke:none; }
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

    <polyline id="crumb" class="crumbs" stroke="#f3f" points="55,5"/>
    <use id="me" x="50" y="0" xlink:href="#sprite" visibility="hidden"/>

    <g transform="translate(50,-10)" class="entry sign">
      <rect x="-16" y="-8" width="35" height="16" rx="3" ry="3"/>
      <text x="2" y="4">Entry</text>
    </g>
    <g transform="translate(170,360)" class="exit sign">
      <rect x="-16" y="-8" width="32" height="16" rx="3" ry="3"/>
      <text x="0" y="4">Exit</text>
    </g>
  </svg>
</svg>
