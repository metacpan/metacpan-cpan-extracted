#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );
use POSIX ();

# ---------------------------------------------------------------------------
# 03-svg.t  --  Tests for the enhanced SVG importer in GcodeXY
#
# Tests cover: basic elements, transforms, <defs>/<use>/<symbol>, viewBox,
# CSS/style suppression, container elements, and error handling.
#
# Coordinate convention: all test SVG files use 'in' (inch) units explicitly
# so that expected gcode values are simply the numeric inch values.  The
# GcodeXY object is always created with units=>'in', giving a 1:1 mapping
# from SVG user units to gcode coordinates.
#
# 96 SVG px = 1 inch (standard SVG px definition).
# Bare numbers in SVG default to px, so 96 bare = 1 in if needed.
# ---------------------------------------------------------------------------

BEGIN {
    eval { require Graphics::Penplotter::GcodeXY; 1 }
        or plan( skip_all => 'Graphics::Penplotter::GcodeXY not available' );
}

use Graphics::Penplotter::GcodeXY;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Write an SVG body into a temp file and return the filename.
# The body is wrapped in a standard SVG root element.
sub make_svg {
    my ($body, %svg_attr) = @_;
    my $width  = $svg_attr{width}  // '10in';
    my $height = $svg_attr{height} // '10in';
    my $extra  = '';
    $extra .= qq{ viewBox="$svg_attr{viewBox}"}               if $svg_attr{viewBox};
    $extra .= qq{ preserveAspectRatio="$svg_attr{par}"}       if $svg_attr{par};

    my $svg = <<"SVG";
<svg xmlns='http://www.w3.org/2000/svg'
     xmlns:xlink='http://www.w3.org/1999/xlink'
     width='$width' height='$height'$extra>
$body
</svg>
SVG
    my ($fh, $fname) = tempfile( SUFFIX => '.svg', UNLINK => 1 );
    print $fh $svg;
    close $fh;
    return $fname;
}

# Create a fresh GcodeXY object with a generous page.
sub new_g {
    return Graphics::Penplotter::GcodeXY->new(
        xsize   => 20,
        ysize   => 20,
        units   => 'in',
        optimize => 0,    # disable optimiser so move order is predictable
    );
}

# Import SVG body into a fresh object, flush segments, return the object.
sub do_import {
    my ($body, %svg_attr) = @_;
    my $g    = new_g();
    my $file = make_svg($body, %svg_attr);
    eval { $g->importsvg($file) };
    if ($@) { return (undef, $@) }
    $g->stroke();    # flush psegments -> currentpage
    return ($g, undef);
}

# Extract all G00/G01 moves from currentpage as [{type,x,y}, ...].
# Skips penup/pendown commands; only the XY-positioning moves.
sub get_moves {
    my ($g) = @_;
    my @moves;
    for my $line (@{ $g->{currentpage} }) {
        if ($line =~ /^(G0[01])\s+X\s*([-\d.]+)\s+Y\s*([-\d.]+)/) {
            push @moves, { type => $1, x => $2 + 0, y => $3 + 0 };
        }
    }
    return @moves;
}

# Return only the G01 (draw) moves.
sub draw_moves { grep { $_->{type} eq 'G01' } get_moves(@_) }

# Return only the G00 (travel) moves.
sub fast_moves { grep { $_->{type} eq 'G00' } get_moves(@_) }

# Toleranced floating-point equality.
sub near { abs($_[0] - $_[1]) < 0.002 }

# True if any move in @$moves is within tolerance of ($x,$y).
sub has_move_near {
    my ($moves, $x, $y) = @_;
    return scalar grep { near($_->{x}, $x) && near($_->{y}, $y) } @$moves;
}

# ---------------------------------------------------------------------------
# SECTION 1 -- Module availability and object construction
# ---------------------------------------------------------------------------

ok( defined &Graphics::Penplotter::GcodeXY::importsvg,
    'importsvg sub exists' );

my $g0 = new_g();
isa_ok( $g0, 'Graphics::Penplotter::GcodeXY', 'object created' );

# ---------------------------------------------------------------------------
# SECTION 2 -- Basic geometric elements
# ---------------------------------------------------------------------------

note('--- line element ---');
{
    my ($g, $err) = do_import(
        q{<line x1='1in' y1='2in' x2='3in' y2='4in'/>}
    );
    ok( !$err, 'line: no import error' );
    my @d = draw_moves($g);
    ok( @d >= 1, 'line: at least one draw move' );
    ok( has_move_near(\@d, 3, 4), 'line: endpoint (3in,4in) reached' );
    my @f = fast_moves($g);
    ok( has_move_near(\@f, 1, 2), 'line: startpoint (1in,2in) is a fast move' );
}

note('--- rect element ---');
{
    my ($g, $err) = do_import(
        q{<rect x='1in' y='2in' width='3in' height='2in'/>}
    );
    ok( !$err, 'rect: no import error' );
    my @d = draw_moves($g);
    ok( @d >= 4, 'rect: at least 4 draw moves (4 sides)' );
    # box() calls polygon(x1,y1, x2,y1, x2,y2, x1,y2, x1,y1)
    # => polygon(1,2, 4,2, 4,4, 1,4, 1,2)
    ok( has_move_near(\@d, 4, 2), 'rect: top-right x reached' );
    ok( has_move_near(\@d, 4, 4), 'rect: top-right corner reached' );
    ok( has_move_near(\@d, 1, 4), 'rect: top-left corner reached' );
    ok( has_move_near(\@d, 1, 2), 'rect: return to origin' );
}

note('--- rect with rx rounding ---');
{
    my ($g, $err) = do_import(
        q{<rect x='1in' y='1in' width='4in' height='2in' rx='0.5in'/>}
    );
    ok( !$err, 'rounded rect: no import error' );
    my @d = draw_moves($g);
    ok( @d > 4, 'rounded rect: more than 4 draw moves (curves add segments)' );
}

note('--- circle element ---');
{
    my ($g, $err) = do_import(
        q{<circle cx='3in' cy='3in' r='2in'/>}
    );
    ok( !$err, 'circle: no import error' );
    my @d = draw_moves($g);
    ok( @d > 4, 'circle: multiple draw moves' );
    # All draw endpoints must lie within r+epsilon of centre
    my $ok = 1;
    for my $m (@d) {
        my $dist = sqrt(($m->{x}-3)**2 + ($m->{y}-3)**2);
        $ok = 0 if $dist > 2.05;
    }
    ok( $ok, 'circle: all draw moves within radius of centre' );
}

note('--- ellipse element ---');
{
    my ($g, $err) = do_import(
        q{<ellipse cx='3in' cy='3in' rx='2in' ry='1in'/>}
    );
    ok( !$err, 'ellipse: no import error' );
    my @d = draw_moves($g);
    ok( @d > 4, 'ellipse: multiple draw moves' );
    # x range should be within cx±rx, y within cy±ry
    my $xok = !grep { $_->{x} < 0.9 || $_->{x} > 5.1 } @d;
    my $yok = !grep { $_->{y} < 1.9 || $_->{y} > 4.1 } @d;
    ok( $xok, 'ellipse: x coordinates within rx of centre' );
    ok( $yok, 'ellipse: y coordinates within ry of centre' );
}

note('--- polyline element ---');
{
    my ($g, $err) = do_import(
        q{<polyline points='1in,1in 3in,1in 3in,3in'/>}
    );
    ok( !$err, 'polyline: no import error' );
    my @d = draw_moves($g);
    ok( @d >= 2, 'polyline: at least 2 draw moves' );
    ok( has_move_near(\@d, 3, 1), 'polyline: second point reached' );
    ok( has_move_near(\@d, 3, 3), 'polyline: third point reached' );
}

note('--- polygon element (auto-closed) ---');
{
    my ($g, $err) = do_import(
        q{<polygon points='1in,1in 3in,1in 3in,3in'/>}
    );
    ok( !$err, 'polygon: no import error' );
    my @d = draw_moves($g);
    # polygon appends the first point, so should return to (1,1)
    ok( has_move_near(\@d, 1, 1), 'polygon: closed back to first point' );
}

note('--- path M/L/Z ---');
{
    my ($g, $err) = do_import(
        q{<path d='M 1in 1in L 3in 1in L 3in 3in Z'/>}
    );
    ok( !$err, 'path MLZ: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 3, 1), 'path MLZ: second vertex' );
    ok( has_move_near(\@d, 3, 3), 'path MLZ: third vertex' );
    ok( has_move_near(\@d, 1, 1), 'path MLZ: closed (Z) returns to start' );
}

note('--- path H/V commands ---');
{
    my ($g, $err) = do_import(
        q{<path d='M 1in 1in H 3in V 3in'/>}
    );
    ok( !$err, 'path HV: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 3, 1), 'path H: horizontal to x=3in' );
    ok( has_move_near(\@d, 3, 3), 'path V: vertical to y=3in' );
}

note('--- path cubic bezier C ---');
{
    my ($g, $err) = do_import(
        q{<path d='M 0in 0in C 0in 1in 2in 1in 2in 0in'/>}
    );
    ok( !$err, 'path C: no import error' );
    my @d = draw_moves($g);
    ok( @d > 2, 'path C: bezier approximated by multiple segments' );
    ok( has_move_near(\@d, 2, 0), 'path C: endpoint reached' );
}

note('--- path arc A ---');
{
    # A semicircle of radius 1in from (0,0) to (2,0)
    my ($g, $err) = do_import(
        q{<path d='M 0in 0in A 1in 1in 0 0 1 2in 0in'/>}
    );
    ok( !$err, 'path A: no import error' );
    my @d = draw_moves($g);
    ok( @d > 2, 'path A: arc approximated by multiple segments' );
    ok( has_move_near(\@d, 2, 0), 'path A: arc endpoint reached' );
}

# ---------------------------------------------------------------------------
# SECTION 3 -- Transforms
# ---------------------------------------------------------------------------

note('--- translate transform ---');
{
    # Line from (0,0) to (1,0), group translated by (2,3)
    # -> expected draw move at (3,3)
    my ($g, $err) = do_import(
        q{<g transform='translate(2in,3in)'>
            <line x1='0' y1='0' x2='1in' y2='0'/>
          </g>}
    );
    ok( !$err, 'translate: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 3, 3), 'translate: endpoint shifted correctly' );
}

note('--- scale transform ---');
{
    # Line to (1in,1in), group scaled by 2 -> endpoint at (2,2)
    my ($g, $err) = do_import(
        q{<g transform='scale(2)'>
            <line x1='0' y1='0' x2='1in' y2='1in'/>
          </g>}
    );
    ok( !$err, 'scale: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 2, 2), 'scale: endpoint doubled' );
}

note('--- non-uniform scale transform ---');
{
    my ($g, $err) = do_import(
        q{<g transform='scale(2,3)'>
            <line x1='0' y1='0' x2='1in' y2='1in'/>
          </g>}
    );
    ok( !$err, 'scale(sx,sy): no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 2, 3), 'scale(2,3): x and y scaled independently' );
}

note('--- rotate transform (1-arg) ---');
{
    # Line along +x axis to (2in,0), rotated 90deg -> endpoint near (0,2)
    my ($g, $err) = do_import(
        q{<g transform='rotate(90)'>
            <line x1='0' y1='0' x2='2in' y2='0'/>
          </g>}
    );
    ok( !$err, 'rotate(90): no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 0, 2), 'rotate(90): x-axis line maps to y-axis' );
}

note('--- rotate transform (3-arg, rotate around point) ---');
{
    # Line from (3in,1in) to (3in,3in), rotated 90 around (3in,1in)
    # -> endpoint (3+2, 1+0) = (5,1)
    my ($g, $err) = do_import(
        q{<g transform='rotate(90, 3in, 1in)'>
            <line x1='3in' y1='1in' x2='3in' y2='3in'/>
          </g>}
    );
    ok( !$err, 'rotate(a,cx,cy): no import error' );
    my @d = draw_moves($g);
    # SVG rotate(90, cx, cy) = translate(cx,cy) . rotate(90) . translate(-cx,-cy)
    # Vector from (3,1) to (3,3) is (0,2) [downward in SVG y-down space].
    # SVG positive rotation is CW in y-down: downward -> leftward -> (-2,0).
    # New endpoint: (3,1) + (-2,0) = (1,1).
    ok( has_move_near(\@d, 1, 1), 'rotate(90,3,1): rotated endpoint correct' );
}

note('--- skewX transform ---');
{
    my ($g, $err) = do_import(
        q{<g transform='skewX(45)'>
            <line x1='0' y1='0' x2='0' y2='1in'/>
          </g>}
    );
    ok( !$err, 'skewX: no import error' );
    my @d = draw_moves($g);
    # skewX(45) shifts x by tan(45)*y = y, so (0,1) -> (1,1)
    ok( has_move_near(\@d, 1, 1), 'skewX(45): vertical line sheared to diagonal' );
}

note('--- matrix transform ---');
{
    # matrix(a,b,c,d,e,f): SVG column-major
    # matrix(1,0,0,1,2in,3in) is a pure translate by (2,3)
    my ($g, $err) = do_import(
        q{<g transform='matrix(1,0,0,1,2in,3in)'>
            <line x1='0' y1='0' x2='1in' y2='1in'/>
          </g>}
    );
    ok( !$err, 'matrix: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 3, 4), 'matrix translate: endpoint at (3,4)' );
}

note('--- chained transforms ---');
{
    # translate(1in,0) then scale(2): point (1in,0) -> scale(1,0)=(2,0) + translate=(3,0)
    # Actually transforms compose right-to-left in SVG; 'translate scale' means
    # scale first, then translate.
    my ($g, $err) = do_import(
        q{<g transform='translate(1in,0) scale(2)'>
            <line x1='0' y1='0' x2='1in' y2='0'/>
          </g>}
    );
    ok( !$err, 'chained transform: no import error' );
    my @d = draw_moves($g);
    # scale(2) maps (1in,0) to (2,0); translate(1,0) maps that to (3,0)
    ok( has_move_near(\@d, 3, 0), 'chained transforms: result correct' );
}

note('--- element-level transform attribute ---');
{
    # Transform on the element itself, not on a group
    my ($g, $err) = do_import(
        q{<line x1='0' y1='0' x2='1in' y2='0' transform='translate(2in,1in)'/>}
    );
    ok( !$err, 'element transform: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 3, 1), 'element transform: translate applied' );
}

# ---------------------------------------------------------------------------
# SECTION 4 -- <defs>, <use>, and <symbol>
# ---------------------------------------------------------------------------

note('--- basic <defs> + <use> ---');
{
    my ($g, $err) = do_import( <<'SVG' );
<defs>
  <line id='myline' x1='0' y1='0' x2='2in' y2='0'/>
</defs>
<use href='#myline'/>
SVG
    ok( !$err, 'defs/use line: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 2, 0), 'defs/use: referenced line rendered' );
}

note('--- <use> with x/y offset ---');
{
    my ($g, $err) = do_import( <<'SVG' );
<defs>
  <rect id='sq' x='0' y='0' width='1in' height='1in'/>
</defs>
<use href='#sq' x='2in' y='3in'/>
SVG
    ok( !$err, 'use with offset: no import error' );
    my @d = draw_moves($g);
    # rect corners after (2,3) offset: (2,3),(3,3),(3,4),(2,4)
    ok( has_move_near(\@d, 3, 3), 'use offset: right side x=3in' );
    ok( has_move_near(\@d, 3, 4), 'use offset: top-right corner' );
    ok( has_move_near(\@d, 2, 4), 'use offset: top-left corner' );
}

note('--- multiple <use> of same def ---');
{
    my ($g, $err) = do_import( <<'SVG' );
<defs>
  <circle id='dot' cx='0' cy='0' r='0.5in'/>
</defs>
<use href='#dot' x='1in' y='1in'/>
<use href='#dot' x='4in' y='1in'/>
SVG
    ok( !$err, 'multiple use: no import error' );
    my @d = draw_moves($g);
    # Two circles: each has multiple draw segments
    my $near_1 = grep { $_->{x} < 2 && $_->{x} > 0 } @d;
    my $near_4 = grep { $_->{x} > 3 && $_->{x} < 5 } @d;
    ok( $near_1 > 0, 'multiple use: first instance rendered (x~1)' );
    ok( $near_4 > 0, 'multiple use: second instance rendered (x~4)' );
}

note('--- forward reference: <use> before <defs> ---');
{
    # The new 2-pass implementation resolves this; the old code could not.
    my ($g, $err) = do_import( <<'SVG' );
<use href='#late'/>
<defs>
  <line id='late' x1='0' y1='0' x2='3in' y2='0'/>
</defs>
SVG
    ok( !$err, 'forward ref: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 3, 0), 'forward ref: line rendered despite use-before-defs' );
}

note('--- <use> with unknown id does not crash ---');
{
    my ($g, $err) = do_import(
        q{<use href='#does-not-exist'/>}
    );
    ok( !$err, 'unknown use id: no crash' );
}

note('--- <use> of a <g> group ---');
{
    my ($g, $err) = do_import( <<'SVG' );
<defs>
  <g id='cross'>
    <line x1='-0.5in' y1='0' x2='0.5in' y2='0'/>
    <line x1='0' y1='-0.5in' x2='0' y2='0.5in'/>
  </g>
</defs>
<use href='#cross' x='3in' y='3in'/>
SVG
    ok( !$err, 'use of group: no import error' );
    my @d = draw_moves($g);
    # horizontal line of cross at y=3: from (2.5,3) to (3.5,3)
    ok( has_move_near(\@d, 3.5, 3), 'use of group: horizontal arm rendered' );
    # vertical line of cross at x=3: from (3,2.5) to (3,3.5)
    ok( has_move_near(\@d, 3, 3.5), 'use of group: vertical arm rendered' );
}

note('--- <symbol> + <use> ---');
{
    my ($g, $err) = do_import( <<'SVG' );
<defs>
  <symbol id='mysym'>
    <line x1='0' y1='0' x2='2in' y2='0'/>
  </symbol>
</defs>
<use href='#mysym' x='1in' y='2in'/>
SVG
    ok( !$err, 'symbol/use: no import error' );
    my @d = draw_moves($g);
    # symbol contents at (1,2) offset: line endpoint at (3,2)
    ok( has_move_near(\@d, 3, 2), 'symbol/use: symbol contents rendered at offset' );
}

note('--- <symbol> is not rendered directly ---');
{
    my ($g, $err) = do_import( <<'SVG' );
<symbol id='s'>
  <line x1='0' y1='0' x2='5in' y2='0'/>
</symbol>
SVG
    ok( !$err, 'symbol not directly rendered: no import error' );
    my @d = draw_moves($g);
    ok( !@d, 'symbol not directly rendered: no draw moves' );
}

# ---------------------------------------------------------------------------
# SECTION 5 -- viewBox
# ---------------------------------------------------------------------------

note('--- viewBox uniform scaling ---');
{
    # viewBox maps 0..100 x 0..100 onto 2in x 2in viewport.
    # A line to (100,100) in viewBox coords should end at (2in,2in).
    my ($g, $err) = do_import(
        q{<line x1='0' y1='0' x2='100' y2='100'/>},
        width   => '2in',
        height  => '2in',
        viewBox => '0 0 100 100',
    );
    ok( !$err, 'viewBox: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 2, 2), 'viewBox: (100,100) maps to (2in,2in)' );
}

note('--- viewBox with non-zero min-x/min-y ---');
{
    # viewBox '50 50 100 100' on a 2in x 2in viewport.
    # A line to (150,150) (which is at the far corner of the viewBox)
    # -> should map to (2in,2in).
    my ($g, $err) = do_import(
        q{<line x1='50' y1='50' x2='150' y2='150'/>},
        width   => '2in',
        height  => '2in',
        viewBox => '50 50 100 100',
    );
    ok( !$err, 'viewBox offset: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 2, 2), 'viewBox offset: far corner maps to (2in,2in)' );
}

note('--- viewBox preserveAspectRatio=none (stretch) ---');
{
    # viewBox 0 0 200 100 onto 4in x 1in with par=none: sx=4/200=0.02, sy=1/100=0.01
    # i.e. at 96px/in, viewBox is in "user px" while viewport is in inches.
    # Point (200,100) -> (4in, 1in)
    my ($g, $err) = do_import(
        q{<line x1='0' y1='0' x2='200' y2='100'/>},
        width   => '4in',
        height  => '2in',
        viewBox => '0 0 200 100',
        par     => 'none',
    );
    ok( !$err, 'viewBox par=none: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 4, 2), 'viewBox par=none: point stretched to (4in,2in)' );
}

# ---------------------------------------------------------------------------
# SECTION 6 -- CSS and style handling
# ---------------------------------------------------------------------------

note('--- display:none suppresses element ---');
{
    my ($g, $err) = do_import(
        q{<line x1='0' y1='0' x2='5in' y2='0' style='display:none'/>}
    );
    ok( !$err, 'display:none: no import error' );
    my @d = draw_moves($g);
    ok( !has_move_near(\@d, 5, 0), 'display:none: element not rendered' );
}

note('--- display:none on group suppresses all children ---');
{
    my ($g, $err) = do_import(
        q{<g style='display:none'>
            <line x1='0' y1='0' x2='5in' y2='0'/>
            <circle cx='2in' cy='2in' r='1in'/>
          </g>}
    );
    ok( !$err, 'display:none group: no import error' );
    my @d = draw_moves($g);
    ok( !@d, 'display:none group: no draw moves from any child' );
}

note('--- visibility:hidden suppresses element ---');
{
    my ($g, $err) = do_import(
        q{<line x1='0' y1='0' x2='5in' y2='0' style='visibility:hidden'/>}
    );
    ok( !$err, 'visibility:hidden: no import error' );
    my @d = draw_moves($g);
    ok( !has_move_near(\@d, 5, 0), 'visibility:hidden: element not rendered' );
}

note('--- visible elements alongside hidden ones ---');
{
    my ($g, $err) = do_import(
        q{<line x1='0' y1='0' x2='5in' y2='0' style='display:none'/>
          <line x1='0' y1='0' x2='2in' y2='0'/>}
    );
    ok( !$err, 'mixed visible/hidden: no import error' );
    my @d = draw_moves($g);
    ok(  has_move_near(\@d, 2, 0), 'mixed: visible line rendered' );
    ok( !has_move_near(\@d, 5, 0), 'mixed: hidden line not rendered' );
}

note('--- <style> block class rule ---');
{
    my ($g, $err) = do_import( <<'SVG' );
<style>
  .invisible { display: none; }
</style>
<line class='invisible' x1='0' y1='0' x2='5in' y2='0'/>
<line x1='0' y1='0' x2='2in' y2='0'/>
SVG
    ok( !$err, 'style block: no import error' );
    my @d = draw_moves($g);
    ok(  has_move_near(\@d, 2, 0), 'style block: normal line rendered' );
    ok( !has_move_near(\@d, 5, 0), 'style block: .invisible class suppressed' );
}

note('--- inline style overrides presentation attribute ---');
{
    # display attribute + style inline: inline wins (display:none in style wins)
    my ($g, $err) = do_import(
        q{<line x1='0' y1='0' x2='5in' y2='0'
               display='inline'
               style='display:none'/>}
    );
    ok( !$err, 'inline style override: no import error' );
    my @d = draw_moves($g);
    ok( !has_move_near(\@d, 5, 0), 'inline style wins over presentation attr' );
}

# ---------------------------------------------------------------------------
# SECTION 7 -- Container and structural elements
# ---------------------------------------------------------------------------

note('--- nested <g> groups ---');
{
    my ($g, $err) = do_import(
        q{<g transform='translate(1in,0)'>
            <g transform='translate(0,1in)'>
              <line x1='0' y1='0' x2='1in' y2='0'/>
            </g>
          </g>}
    );
    ok( !$err, 'nested groups: no import error' );
    my @d = draw_moves($g);
    # endpoint (1,0) after nested translate(1,0)+translate(0,1) -> (2,1)
    ok( has_move_near(\@d, 2, 1), 'nested groups: transforms compose' );
}

note('--- <a> element treated as passthrough group ---');
{
    my ($g, $err) = do_import(
        q{<a href='http://example.com'>
            <line x1='0' y1='0' x2='2in' y2='0'/>
          </a>}
    );
    ok( !$err, '<a>: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 2, 0), '<a>: child element rendered' );
}

note('--- <switch> element renders its children ---');
{
    my ($g, $err) = do_import(
        q{<switch>
            <line x1='0' y1='0' x2='2in' y2='0'/>
          </switch>}
    );
    ok( !$err, '<switch>: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 2, 0), '<switch>: child rendered' );
}

note('--- <title>, <desc>, <metadata> silently ignored ---');
{
    my ($g, $err) = do_import(
        q{<title>My Drawing</title>
          <desc>A test SVG</desc>
          <metadata>some metadata</metadata>
          <line x1='0' y1='0' x2='1in' y2='0'/>}
    );
    ok( !$err, 'metadata tags: no import error' );
    my @d = draw_moves($g);
    ok( scalar(@d) == 1, 'metadata tags: only the line is rendered' );
}

note('--- <image> silently ignored ---');
{
    my ($g, $err) = do_import(
        q{<image href='photo.png' x='0' y='0' width='2in' height='2in'/>
          <line x1='0' y1='0' x2='1in' y2='0'/>}
    );
    ok( !$err, '<image>: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 1, 0), '<image>: vector content still rendered' );
}

note('--- <defs> content not directly rendered ---');
{
    my ($g, $err) = do_import(
        q{<defs>
            <line x1='0' y1='0' x2='5in' y2='0'/>
          </defs>}
    );
    ok( !$err, 'defs not rendered: no import error' );
    my @d = draw_moves($g);
    ok( !@d, 'defs not rendered: no draw moves' );
}

note('--- gradient / clipPath definitions silently skipped ---');
{
    my ($g, $err) = do_import(
        q{<linearGradient id='grad'><stop/></linearGradient>
          <clipPath id='clip'><rect x='0' y='0' width='1in' height='1in'/></clipPath>
          <line x1='0' y1='0' x2='1in' y2='0'/>}
    );
    ok( !$err, 'gradient/clip: no import error' );
    my @d = draw_moves($g);
    # Only the explicit line should be rendered
    ok( scalar(@d) == 1, 'gradient/clip: only line rendered' );
}

# ---------------------------------------------------------------------------
# SECTION 8 -- Error handling and edge cases
# ---------------------------------------------------------------------------

note('--- missing file ---');
{
    my $g = new_g();
    eval { $g->importsvg('/no/such/file/___test___.svg') };
    ok( $@, 'missing file: importsvg croaks' );
}

note('--- malformed SVG ---');
{
    my ($fh, $fname) = tempfile( SUFFIX => '.svg', UNLINK => 1 );
    print $fh '<svg><rect unclosed';
    close $fh;
    my $g = new_g();
    eval { $g->importsvg($fname) };
    ok( $@, 'malformed SVG: importsvg croaks on parse error' );
}

note('--- empty SVG (no elements) ---');
{
    my ($g, $err) = do_import('');
    ok( !$err, 'empty SVG: no import error' );
    my @d = draw_moves($g);
    ok( !@d, 'empty SVG: no draw moves' );
}

note('--- unknown element does not crash ---');
{
    my ($g, $err) = do_import(
        q{<weirdElement foo='bar'/>
          <line x1='0' y1='0' x2='1in' y2='0'/>}
    );
    ok( !$err, 'unknown element: no crash' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 1, 0), 'unknown element: other content still rendered' );
}

note('--- multiple root-level shapes ---');
{
    my ($g, $err) = do_import(
        q{<line x1='0' y1='0' x2='1in' y2='0'/>
          <line x1='0' y1='1in' x2='2in' y2='1in'/>
          <line x1='0' y1='2in' x2='3in' y2='2in'/>}
    );
    ok( !$err, 'multiple shapes: no import error' );
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 1, 0), 'multiple shapes: first line endpoint' );
    ok( has_move_near(\@d, 2, 1), 'multiple shapes: second line endpoint' );
    ok( has_move_near(\@d, 3, 2), 'multiple shapes: third line endpoint' );
}

note('--- zero-dimension shapes do not crash ---');
{
    my ($g, $err) = do_import(
        q{<rect x='1in' y='1in' width='0' height='0'/>
          <circle cx='1in' cy='1in' r='0'/>
          <ellipse cx='1in' cy='1in' rx='0' ry='0'/>}
    );
    ok( !$err, 'zero-dimension shapes: no crash' );
}

note('--- gsave/grestore balance: state restored after import ---');
{
    my $g = new_g();
    $g->translate(1, 0);
    my $file = make_svg( q{<line x1='0' y1='0' x2='1in' y2='0'/>} );
    eval { $g->importsvg($file) };
    ok( !$@, 'gsave balance: no import error' );
    # After import, translate(1,0) should still be in effect.
    # A subsequent line to (1,0) in user space -> paper (2,0).
    $g->line(0, 0, 1, 0);
    $g->stroke();
    my @d = draw_moves($g);
    ok( has_move_near(\@d, 2, 0), 'gsave balance: pre-import transform restored' );
}

done_testing();
