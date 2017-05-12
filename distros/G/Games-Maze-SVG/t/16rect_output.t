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

my $rectgrid = 

my $template = do { local $/ = undef; <DATA>; };

$gmaze->mock(
    make => sub { my $self = shift; $self->{entry} = [2,1]; $self->{exit} = [6,8]; },
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
my $maze = Games::Maze::SVG->new( 'Rect', cols => 3, rows => 3 );

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

is_string( $maze->toString(), $output, "Full transform works." );

#open( my $fh, '>rect1.svg' ) or die;
#print $fh $maze->toString();

# ---- Bevel ----
# Because of the outside edge effects, I can't use the template in the
# same way.

$maze = Games::Maze::SVG->new( 'Rect', cols => 3, rows => 3 );
$maze->set_wall_form( 'bevel' );

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

is_string( $maze->toString(), $output, "Full transform, roundcorners wall style." );

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
<svg width="90" height="110"
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

  <svg x="0" y="0" width="90" height="110"
       viewBox="-10 -20 90 110" id="maze">
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

    <polyline id="crumb" class="crumbs" stroke="#f3f" points="35,5"/>
    <use id="me" x="30" y="0" xlink:href="#sprite" visibility="hidden"/>

    <g transform="translate(35,-10)" class="entry sign">
      <rect x="-16" y="-8" width="35" height="16" rx="3" ry="3"/>
      <text x="2" y="4">Entry</text>
    </g>
    <g transform="translate(115,180)" class="exit sign">
      <rect x="-16" y="-8" width="32" height="16" rx="3" ry="3"/>
      <text x="0" y="4">Exit</text>
    </g>
  </svg>
</svg>
