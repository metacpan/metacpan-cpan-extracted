package Graphics::Penplotter::GcodeXY v0.5.13;

use v5.38.2;  # required by List::Util and Term::ANSIcolor (perl testers matrix)
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;
use Math::Trig qw/deg2rad tan acos/;
use Math::Bezier;
use POSIX qw/ceil/;
use Image::SVG::Transform;
use Image::SVG::Path 'extract_path_info';
use Font::FreeType;
use List::Util qw(min max);
use Readonly;
use Carp;
use Term::ANSIColor qw/:constants/;
use File::Temp qw/ tempfile /;
use parent qw(Exporter);

our @EXPORT_OK = qw(translate translateC stroketextfill stroketext strokefill stroke split
                    skewX skewY sethatchsep setfontsize setfont scale rotate polygonR polygonC
                    polygon penup pendown pageborder exportsvg exporteps output newsegpath
                    movetoR moveto lineR line initmatrix importsvg gsave grestore getsegpath
                    ellipse curveto curve currentpoint boxround boxR box arcto arc addtopage
                    addfontpath addcomment textwidth arrowhead polygonround vpype_linesort);

# definition of page sizes in pt, should be Properly Cased
my %pspaper = (
    '4A0'               => [ 4768, 6741 ],
    '2A0'               => [ 3370, 4768 ],
    A0                  => [ 2384, 3370 ],
    A1                  => [ 1684, 2384 ],
    A2                  => [ 1191, 1684 ],
    A3                  => [ 841,  1190 ],
    A4                  => [ 595,  841 ],
#    A5                  => [ 420,  595 ],
#    A6                  => [ 297,  420 ],
#    A7                  => [ 210,  297 ],
#    A8                  => [ 148,  210 ],
#    A9                  => [ 105,  148 ],
#    B0                  => [ 2920, 4127 ],
#    B1                  => [ 2064, 2920 ],
#    B2                  => [ 1460, 2064 ],
#    B3                  => [ 1032, 1460 ],
#    B4                  => [ 729,  1032 ],
#    B5                  => [ 516,  729 ],
#    B6                  => [ 363,  516 ],
#    B7                  => [ 258,  363 ],
#    B8                  => [ 181,  258 ],
#    B9                  => [ 127,  181 ],
#    B10                 => [ 91,   127 ],
#    Executive           => [ 522,  756 ],
#    Folio               => [ 595,  935 ],
#    'Half-Letter'       => [ 612,  397 ],
#    Letter              => [ 612,  792 ],
#    'US-Letter'         => [ 612,  792 ],
#    Legal               => [ 612,  1008 ],
#    'US-Legal'          => [ 612,  1008 ],
#    Tabloid             => [ 792,  1224 ],
#    'SuperB'            => [ 843,  1227 ],
#    Ledger              => [ 1224, 792 ],
#    'Comm #10 Envelope' => [ 297,  684 ],
#    'Envelope-Monarch'  => [ 280,  542 ],
#    'Envelope-DL'       => [ 312,  624 ],
#    'Envelope-C5'       => [ 461,  648 ],
#    'EuroPostcard'      => [ 298,  420 ],
);

# translate inch to/from other unit (multiplication factor)
# measuring units are two-letter acronyms:
#  pt: postscript point (72 per inch)
#  in: inch (72 postscript points)
#  mm: millimetre (25.4 per inch)
#  cm: centimetre (2.54 per inch)
#  px: standard 96 ppi for a pen plotter, used for SVG
#  pc: pica (6.0 per inch)
my %inches_to_unit = (
    pt => 72.0,
    in => 1.0,
    mm => 25.4,
    cm => 2.54,
    px => 96.0,
    pc => 6.0,
);

my %unit_to_inches = (
    px => 1.0/96.0,  # 1 pixel = 1/96 inch
    pt => 1.0/72.0,  # 1 point = 1/72 inch
    pc => 1.0/6.0,   # 1 pica = 1/6 inch (12 points)
    in => 1.0,       # 1 inch = 1 inch
    cm => 1.0/2.54,  # 1 cm = 1/2.54 inch
    mm => 1.0/25.4,  # 1 mm = 1/25.4 inch
);

# definition of constants
Readonly my $D2R       => 0.01745329251;    # degrees to radians scale factor
Readonly my $R2D       => 57.2957795130;    # radians to degrees scale factor
Readonly my $I2P       => 72.0;             # inches to points scale factor
Readonly my $EMPTY_STR => q{};              # ''
Readonly my $SPACE     => q{ };             # ' '
Readonly my $EOL       => qq{\n};           # "\n"
Readonly my $HALFPI    => 1.57079632680;    # 0.5*π
Readonly my $PI        => 3.14159265359;    # 1.0*π
Readonly my $THREEPI2  => 4.71238898038;    # 1.5*π
Readonly my $TWOPI     => 6.28318530718;    # 2.0*π
Readonly my $PU        => 1;                # penup line opcode
Readonly my $PD        => 2;                # pendown line opcode
Readonly my $G00       => 3;                # G00 line opcode
Readonly my $G01       => 4;                # G01 line opcode
Readonly my $NOOP      => 5;                # "ignore this line" opcode
Readonly my $EPSILON   => 0.000001;         # equality for floating point
Readonly my $OPTLOW    => 0;                # low margin for optimization
Readonly my $LONGEST   => 6;                # longest pattern matching sequence
Readonly my $BBMAX     => 1_000_000.0;      # huge page bounding box
Readonly my $IN        => 0;                # virtual pen is inside the sheet when cutting
Readonly my $OUT       => 1;                # virtual pen is outside the sheet when cutting
Readonly my $PENUP     => 3;                # physical pen is off the paper
Readonly my $PENDOWN   => 4;                # physical pen is on the paper

# bezier numbers
my $m_approxscale     = 1.0;
my $m_disttolscale    = 0.5 / $m_approxscale;
$m_disttolscale      *= $m_disttolscale;
my $curve_colleps     = 1e-30;
my $m_angletol        = 0.0;
my $curve_angletoleps = 0.01;
my $m_cusp_limit      = 0.0;
my $m_count           = 0;
my $curve_reclim      = 50;
my @m_points          = ();

# font handling
my $home      = $ENV{'HOME'};
# where to look for fonts:
my @locations = (   './',
                    $home . '/.fonts/',
                    $home . '/.local/share/fonts/',
                    '/usr/share/fonts/truetype/',
                    '/usr/share/fonts/truetype/liberation/',
                    '/usr/share/fonts/truetype/dejavu/',
                    '/usr/share/fonts/truetype//msttcorefonts/',
                    '/usr/share/fonts/',
                    '/usr/local/share/fonts/',
                    'C:/Windows/Fonts/'
                );

# object allocation
sub new {
    my ( $class, %data ) = @_;
    my $self = {
        # public:
        papersize     => undef,   # paper size e.g. "A3"
        xsize         => undef,   # bounding box x
        ysize         => undef,   # bounding box y
        units         => 'in',    # inches is used internally
        header        => "G20\nG90\nG17\nF 50\nG92 X 0 Y 0 Z 0\nG00 Z 0\n",  # must end with penup
        trailer       => "G00 Z 0\nG00 X 0 Y 0\n",
        penupcmd      => "G00 Z 0\n",
        pendowncmd    => "G00 Z 0.2\n",
        margin        => 1.0,     # margin as a PERCENTAGE
        outfile       => $EMPTY_STR,
        curvepts      => 50,
        check         => 0,
        warn          => 0,       # out of page bounds warning
        hatchsep      => 0.012,   # inches, equivalent to 0.3 mm (the tip of a BIC ballpoint pen)
        id            => $EMPTY_STR,
        optimize      => 1,

        # private:
        dscale        => 1.0,      # device scaling, used when units not "in"
        opt_debug     => 0,        # what is the optimizer doing?
        maxx          => 0.0,      # gcode design bounding box
        maxy          => 0.0,
        minx          => $BBMAX,
        miny          => $BBMAX,
        penlocked     => 0,
        fontsize      => 0,        # default font size
        fontname      => "",       # current font name
        posx          => 0,        # current point, x
        posy          => 0,        # current point, y
        pencount      => 0,        # number of times pen raised/lowered (raise+lower counts as 1)
        slowdistcount => 0,    # distance traveled on paper (in fact, its square)
        fastdistcount => 0,    # distance traveled above paper (in fact, its square)

        # plus others, set in init()
    };
    foreach ( keys %data ) {
        $self->{$_} = $data{$_};
    }
    bless $self, $class;
    $self->init();
    return $self;
}

sub init {
    my $self = shift;
    # Units
    $self->{units} = lc $self->{units};
    if ( defined( $unit_to_inches{ $self->{units} } ) ) {
        $self->{dscale} = $unit_to_inches{ $self->{units} };
    }
    else {
        $self->_croak("unit '$self->{units}' not supported");
    }

    # Paper size
    if ( defined $self->{papersize} ) {
        $self->{papersize} = ucfirst lc $self->{papersize};
    }
    # warn and/or check
    if ( defined $self->{papersize} && defined $pspaper{ $self->{papersize} } )
    {   ( $self->{xsize}, $self->{ysize} ) = @{ $pspaper{ $self->{papersize} } };
        # If the unit is different from pt, adjust xsize and ysize.
        if ($self->{units} ne 'pt') {
            my $t = $inches_to_unit{ $self->{units} };
            $self->{xsize} = $self->{xsize} * $t / $inches_to_unit{'pt'};
            $self->{ysize} = $self->{ysize} * $t / $inches_to_unit{'pt'};
        }
    }
    else {  # paper size was not defined, check xsize and ysize
        if ( $self->{warn} || $self->{check} ) {
            if ( !defined $self->{xsize} || !defined $self->{ysize} ) {
                $self->_croak('cannot warn or check if page size undefined or unsupported');
            }
        }
    }

    # page arrays
    $self->{currentpage} = [];    # list of generated gcode statements
    $self->{psegments}   = [];    # path segments (needing stroking)
    $self->{hsegments}   = [];    # list of segments needing hatching
    $self->{csegments}   = [];    # list of clipping segments
    $self->{gstate}      = [];    # graphics state
    $self->{CTM} = [ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ]; # current transformation matrix
    # add header to page
    $self->_openpage();
    return 1;
}

#------------------------------------------------------------------------------

# graphics state manipulation, saving, restoring
sub gsave {
    my $self = shift;
    push @{ $self->{gstate} }, $self->{fontname};
    push @{ $self->{gstate} }, $self->{fontsize};
    push @{ $self->{gstate} }, $self->{curvepts};
    push @{ $self->{gstate} }, $self->{penlocked};
    push @{ $self->{gstate} }, $self->{posx};
    push @{ $self->{gstate} }, $self->{posy};
    push @{ $self->{gstate} }, $self->{CTM}->[0][0];
    push @{ $self->{gstate} }, $self->{CTM}->[0][1];
    push @{ $self->{gstate} }, $self->{CTM}->[0][2];
    push @{ $self->{gstate} }, $self->{CTM}->[1][0];
    push @{ $self->{gstate} }, $self->{CTM}->[1][1];
    push @{ $self->{gstate} }, $self->{CTM}->[1][2];
    push @{ $self->{gstate} }, $self->{CTM}->[2][0];
    push @{ $self->{gstate} }, $self->{CTM}->[2][1];
    push @{ $self->{gstate} }, $self->{CTM}->[2][2];
    return 1;
}

sub grestore {
    my $self = shift;
    $self->{CTM}->[2][2] = pop @{ $self->{gstate} };
    $self->{CTM}->[2][1] = pop @{ $self->{gstate} };
    $self->{CTM}->[2][0] = pop @{ $self->{gstate} };
    $self->{CTM}->[1][2] = pop @{ $self->{gstate} };
    $self->{CTM}->[1][1] = pop @{ $self->{gstate} };
    $self->{CTM}->[1][0] = pop @{ $self->{gstate} };
    $self->{CTM}->[0][2] = pop @{ $self->{gstate} };
    $self->{CTM}->[0][1] = pop @{ $self->{gstate} };
    $self->{CTM}->[0][0] = pop @{ $self->{gstate} };
    $self->{posy}        = pop @{ $self->{gstate} };
    $self->{posx}        = pop @{ $self->{gstate} };
    $self->{penlocked}   = pop @{ $self->{gstate} };
    $self->{curvepts}    = pop @{ $self->{gstate} };
    $self->{fontsize}    = pop @{ $self->{gstate} };
    $self->{fontname}    = pop @{ $self->{gstate} };
    return 1;
}

#-------------------------------------------------------------------------

#
# Move to a position on the page. Lift the pen first, then lower it on arrival
#
sub moveto {
    my $self = shift;
    if ( @_ != 2 ) {
        $self->_croak('wrong number of args for moveto');
        return 0;
    }
    my ( $x, $y ) = @_;
    $self->penup();
    $self->_genfastmove( $x, $y );
    $self->pendown();
    return 1;
}

#
# Move to a position on the page relative to the current position.
# Lift the pen first, then lower it on arrival
#
sub movetoR {
    my $self = shift;
    if ( @_ != 2 ) {
        $self->_croak('wrong number of args for movetoR');
        return 0;
    }
    my ( $x,  $y )  = @_;
    my ( $cx, $cy ) = $self->currentpoint();
    $self->penup();
    $self->_genfastmove( $x + $cx, $y + $cy );
    $self->pendown();
    return 1;
}

#
# return or set the current point in USER coordinates
#
sub currentpoint {
    my $self = shift;
    if ( @_ == 2 ) {  # set the current point
        $self->{posx} = shift;
        $self->{posy} = shift;
        return 1;
    }
    else {  # return the current point
        return ( $self->{posx}, $self->{posy} );
    }
}

# We use three measures of position here: user, paper and device coordinations.
# User coords are the results of scaling, translation and rotation.
# Paper coords are absolute on the page, and are found by applying the CTM to the user coords.
# e.g. after translate(100,200) the user is at (0,0) and the paper at (100,200).
# Device coords are found by scaling dependent on the units specified in the object.
# GcodeXY uses inches as the device coordinates.

#
# return the paper coordinates of a point in user space, i.e. cumulative transformations
#
sub _u_to_p {
    my $self = shift;
    my ( $x, $y ) = @_;
    my @point = ();
    push @point, ( $x, $y );
    $self->_transform( 1, \@point );
    return @point;
}

#
# return the device coordinates of a point in paper space (e.g. convert pt to inches)
#
sub _p_to_d {
    my $self = shift;
    my ( $x, $y ) = @_;
    my ( $dx, $dy );
    $dx = $x * $self->{dscale};
    $dy = $y * $self->{dscale};
    return ( $dx, $dy );
}

#
# return the device coordinates of a point in user space
#
sub _u_to_d {
    my $self = shift;
    my ( $x,  $y )  = @_;
    my ( $rx, $ry ) = $self->_u_to_p( $x, $y );
    my ( $dx, $dy ) = $self->_p_to_d( $rx, $ry );
    return ( $dx, $dy );
}

#----------------------------------------------------------------------

#
# Create a line. Starts with a move to the starting point if there are 4 parameters.
# If there are 2 parameters, a relative move from the current position is executed,
# and the pen is assumed to be already on the paper.
#
sub line {
    my $self = shift;
    my ( $x1, $y1, $x2, $y2 );
    if ( (@_ != 4) && (@_ != 2)) {
        $self->_croak('wrong number of args for line (2 or 4)');
        return 0;
    }
    # 2 parameters - relative move
    if (@_ == 2) {
        ($x1, $y1) = @_;
        $self->_genslowmove( $x1, $y1 );
    return 1;
    }
    # else we have 4 parameters
    ( $x1, $y1, $x2, $y2 ) = @_;
    $self->moveto( $x1, $y1 );
    $self->_genslowmove( $x2, $y2 );
    return 1;
}

#
# Create a line starting from the current point, in relative coordinates, i.e. the parameters
# are added to the current point..
#
sub lineR {
    my $self = shift;
    if ( @_ != 2 ) {
        $self->_croak('wrong number of args for lineR');
        return 0;
    }
    my ( $x,  $y )  = @_;
    my ( $cx, $cy ) = $self->currentpoint();
    $self->_genslowmove( $x + $cx, $y + $cy );
    return 1;
}

#
# Create a series of consecutive line segments
#
sub polygon {
    my $self = shift;
    if ( scalar @_ < 2 ) {
        $self->_croak('bad polygon - not enough points');
        return 0;
    }
    if ( scalar @_ % 2 ) {
        $self->_croak('bad polygon - odd number of points');
        return 0;
    }
    my $x = shift;
    my $y = shift;
    $self->moveto( $x, $y );
    while ( @_ > 0 ) {
        $x = shift;
        $y = shift;
        $self->line( $x, $y );
    }
    return 1;
}

#
# Create a series of consecutive line segments from the current position,
# in absolute coordinates
#
sub polygonC {
    my $self = shift;
    if ( scalar @_ < 2 ) {
        $self->_croak('bad polygon (C) - not enough points');
        return 0;
    }
    if ( scalar @_ % 2 ) {
        $self->_croak('bad polygon (C) - odd number of points');
        return 0;
    }
    my ( $x, $y );
    while ( @_ > 0 ) {
        $x = shift;
        $y = shift;

        $self->line( $x, $y );
    }
    return 1;
}

#
# Create a series of consecutive line segments specified in terms of increments
# relative to the current position
#
sub polygonR {
    my $self = shift;
    if ( scalar @_ < 2 ) {
        $self->_croak('bad polygon (C) - not enough points');
        return 0;
    }
    if ( scalar @_ % 2 ) {
        $self->_croak('bad polygon (C) - odd number of points');
        return 0;
    }
    my ( $cx, $cy, $x, $y );
    while ( @_ > 0 ) {
        ( $cx, $cy ) = $self->currentpoint();
        $x = shift;
        $y = shift;

        $self->line( $x + $cx, $y + $cy );
    }
    return 1;
}

#
# draw a polygon with rounded corners between the line segments
#
sub polygonround {
    my $self = shift;
    if ( scalar @_ < 3 ) {
        $self->_croak('bad polygonround - not enough parameters');
        return 0;
    }
    my $r = shift;  # corner radius
    if ( scalar @_ % 2 ) {
        $self->_croak('bad polygonround - odd number of points');
        return 0;
    }
    # move to the start
    my $x = shift;
    my $y = shift;
    $self->moveto( $x, $y );
    # plot the first half of the first segment
    my $dx = shift; # destination x of first segment
    my $dy = shift; # destination y of first segment
    # calculate midpoint of first segment
    my $halfx = ( $dx - $x ) / 2.0;
    my $halfy = ( $dy - $y ) / 2.0;
    # draw the first half of the first segment, relative
    $self->lineR($halfx, $halfy);
    # now loop through the rest
    my $len = scalar @_ / 2.0;  # number of (x,y) pairs left
    my ($newhalfx, $newhalfy);
    foreach (1 .. $len) {
        # move on one pair
        $x  = $dx;
        $y  = $dy;
        $dx = shift;
        $dy = shift;
        $newhalfx = ( $dx - $x ) / 2.0;
        $newhalfy = ( $dy - $y ) / 2.0;
        # do an arcto of the second half of the current segment,
        # and the first half of the next segment.
        # we need to be positioned at the start of the first half.
        $self->arcto($x, $y, $x+$newhalfx, $y+$newhalfy, $r);
        # new becomes old
        $halfx = $newhalfx;
        $halfy = $newhalfy;
    }
    # finally, draw the second half of the last segment
    $self->line($dx, $dy);
    return 1;
}

#
# Create a rectangle. Begin by moving to the bottom left hand corner.
#
sub box {
    my $self = shift;
    if ( (@_ != 4) && (@_ != 2) ) {
        $self->_croak('box: wrong number of arguments (must be 2 or 4)');
        return 0;
    }
    my ( $x1, $y1, $x2, $y2 ) = @_;
    if (@_ == 2) {
        $x2 = $x1;
        $y2 = $y1;
        ($x1, $y1 ) = $self->currentpoint();
        $self->polygonC( $x2, $y1, $x2, $y2, $x1, $y2, $x1, $y1 );
    }
    else { # must be 4
        $self->polygon( $x1, $y1, $x2, $y1, $x2, $y2, $x1, $y2, $x1, $y1 );
    }
    return 1;
}

#
# Create a rectangle starting from the current point, using relative coordinates.
#
sub boxR {
    my $self = shift;
    if ( @_ != 2 ) {
        $self->_croak('boxR: wrong number of arguments');
        return 0;
    }
    my ( $x,  $y )  = @_;
    my ( $cx, $cy ) = $self->currentpoint();
    $self->polygonR( $x, 0, 0, $y, -$x, 0, 0, -$y );
    return 1;
}

#
# create a box with rounded corners
# (special and more efficient case of polygonround, also easier to specify)
#
sub boxround {
    my $self = shift;
    if ( @_ != 5 ) {
        $self->_croak('boxround: wrong number of arguments (need 5)');
        return 0;
    }
    my ( $r, $bx, $by, $tx, $ty) = @_;
    my $halfheight = ( $ty - $by ) / 2.0;
    my $halfwidth  = ( $tx - $bx ) / 2.0;
    $self->moveto($bx, $by + $halfheight );
    $self->arcto( $bx, $ty, $bx + $halfwidth, $ty,               $r );
    $self->arcto( $tx, $ty, $tx,              $ty - $halfheight, $r );
    $self->arcto( $tx, $by, $tx - $halfwidth, $by,               $r );
    $self->arcto( $bx, $by, $bx,              $by + $halfheight, $r );
    return 1;
}

#
# create an arrowhead
#
sub arrowhead {
    my $self = shift;
    if ( @_ < 2 || @_ > 3) {
        $self->_croak('arrowhead: wrong number of arguments (need 2 or 3)');
        return 0;
    }
    my ($length, $width, $type) = @_;
    if (!defined $type) { $type = 'open' }
    my ($tailx, $taily, $tipx, $tipy, $dx, $dy, $angle);
    # get the direction form the last segment, if there is one
    if (scalar $self->{psegments} > 0) {
        $tailx = $self->{psegments}[-1]{sx};
        $taily = $self->{psegments}[-1]{sy};
        $tipx  = $self->{psegments}[-1]{dx};
        $tipy  = $self->{psegments}[-1]{dy};
        $dx    = $tipx - $tailx;
        $dy    = $tipy - $taily;
        $angle = atan2($dy, $dx);  # in radians
    }
    else { # horizontal and to the right
        ($tipx, $tipy) = $self->currentpoint();
        $angle = 0.0;
    }
    $self->gsave();
    # segment list has already been scaled to in.
    # Here we need to scale back to original unit
    $self->translate($self->_in_unitfied($tipx),$self->_in_unitfied($tipy));
    $self->rotate($angle * $R2D); # convert to degrees
    $self->line(-$length, $width/2.0);
    # next one depends on $type. 'closed' means draw vertical line
    if ($type eq 'closed') {
        $self->line(-$length, -$width/2.0);
        $self->line(0, 0);
    }
    else {
        $self->line(-$length, -$width/2.0, 0, 0);
    }
    $self->grestore();
    return 1;
}

#
# create a page border. Needs a margin specified in current units
#
sub pageborder {
    my $self = shift;
    if ( @_ != 1 ) {
        $self->_croak('wrong number of args for pageborder');
        return 0;
    }
    my $margin = shift;
    $self->box(
        $margin, $margin,
        $self->{xsize} - $margin, $self->{ysize} - $margin
    );
    return 1;
}

#
# draw a bezier curve
#
sub curve {
    my $self = shift;
    if ( @_ < 6 ) {
        $self->_croak('wrong number of args for curve');
        return 0;
    }
    my @control = @_;                   # begin, end, and control points
    my $pts;
    my @points;
    if ( scalar @control == 6 ) {       # quadratic
        $self->_curve3(@control);
        return 1;
    }
    elsif ( scalar @control == 8 ) {    # cubic
        $self->_curve4(@control);
        return 1;
    }
    else {                              # higher order
        my $b = Math::Bezier->new(@control);
        $pts    = $self->{curvepts};    # number of sampling points
        @points = $b->curve($pts);
        $self->polygon(@points);
    }
    return 1;
}

#
# draw a bezier curve starting from the current position
#
sub curveto {
    my $self = shift;
    if ( @_ < 6 ) {
        $self->_croak('wrong number of args for curveto');
        return 0;
    }
    my @control = @_;                           # begin, end, and control points
    my $pts;
    my @points;
    unshift @control, $self->currentpoint();    # add the start point
    if ( scalar @control == 6 ) {               # quadratic
        $self->_penlock();
        $self->_curve3(@control);
        $self->_penunlock();
        return 1;
    }
    elsif ( scalar @control == 8 ) {            # cubic
        $self->_penlock();
        $self->_curve4(@control);
        $self->_penunlock();
        return 1;
    }
    else {                                      # higher order
        my $b = Math::Bezier->new(@control);
        $pts    = $self->{curvepts};            # number of sampling points
        @points = $b->curve($pts);
        # remove the start points, we're already there
        shift @points;
        shift @points;
        $self->polygonC(@points);
    }
    return 1;
}

#
# draw a quadratic bezier curve
#
sub _curve3 {
    my ( $self, $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4 ) = @_;
    @m_points = ();
    push @m_points, ( $x1, $y1 );
    $self->_recbezier3( $x1, $y1, $x2, $y2, $x3, $y3, 0 );
    push @m_points, ( $x3, $y3 );
    # now plot
    $self->polygon(@m_points);
    return 1;
}

sub _recbezier3 {
    my ( $self, $x1, $y1, $x2, $y2, $x3, $y3, $level ) = @_;
    if ( $level > $curve_reclim ) {
        return;
    }
    # Calculate all the mid-points of the line segments
    my $x12  = ( $x1 + $x2 ) / 2;
    my $y12  = ( $y1 + $y2 ) / 2;
    my $x23  = ( $x2 + $x3 ) / 2;
    my $y23  = ( $y2 + $y3 ) / 2;
    my $x123 = ( $x12 + $x23 ) / 2;
    my $y123 = ( $y12 + $y23 ) / 2;
    my $dx   = $x3 - $x1;
    my $dy   = $y3 - $y1;
    my $d    = _fabs( ( ( $x2 - $x3 ) * $dy - ( $y2 - $y3 ) * $dx ) );
    my $da;
    if ( $d > $curve_colleps ) {
        # Regular case
        if ( $d * $d <= $m_disttolscale * ( $dx * $dx + $dy * $dy ) ) {
            # If the curvature doesnt exceed the distance_tolerance value
            # we tend to finish subdivisions.
            if ( $m_angletol < $curve_angletoleps ) {
                push @m_points, ( $x123, $y123 );
                return;
            }
            # Angle & Cusp Condition
            $da = _fabs(
                atan2( $y3 - $y2, $x3 - $x2 ) - atan2( $y2 - $y1, $x2 - $x1 ) );
            if ( $da >= $PI ) { $da = 2 * $PI - $da }
            if ( $da < $m_angletol ) {
                # Finally we can stop the recursion
                push @m_points, ( $x123, $y123 );
                return;
            }
        }
    }
    else {
        # Collinear case
        $da = $dx * $dx + $dy * $dy;
        if ( $da == 0 ) {
            $d = _calc_sq_distance( $x1, $y1, $x2, $y2 );
        }
        else {
            $d = ( ( $x2 - $x1 ) * $dx + ( $y2 - $y1 ) * $dy ) / $da;
            if ( $d > 0 && $d < 1 ) {
                # Simple collinear case, 1---2---3
                # We can leave just two endpoints
                return;
            }
            if    ( $d <= 0 ) { $d = _calc_sq_distance( $x2, $y2, $x1, $y1 ) }
            elsif ( $d >= 1 ) { $d = _calc_sq_distance( $x2, $y2, $x3, $y3 ) }
            else {
                $d = _calc_sq_distance( $x2, $y2, $x1 + $d * $dx, $y1 + $d * $dy );
            }
        }
        if ( $d < $m_disttolscale ) {
            push @m_points, ( $x2, $y2 );
            return;
        }
    }
    # Continue subdivision
    $self->_recbezier3( $x1,   $y1,   $x12, $y12, $x123, $y123, $level + 1 );
    $self->_recbezier3( $x123, $y123, $x23, $y23, $x3,   $y3,   $level + 1 );
    return 1;
}

#
# draw a cubic bezier curve
#
sub _curve4 {
    my ( $self, $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4 ) = @_;
    @m_points = ();
    push @m_points, ( $x1, $y1 );
    $self->_recbezier4( $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4, 0 );
    push @m_points, ( $x4, $y4 );
    # now plot
    $self->polygon(@m_points);
    return 1;
}

#
# find the best places for splitting up the curve given its shape.
# Code translated from Anti Grain Graphics library.
#
sub _recbezier4 {
    my ( $self, $x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4, $level ) = @_;
    my ( $da1, $da2, $k );
    if ( $level > $curve_reclim ) {
        return;
    }
    # Calculate all the mid-points of the line segments
    my $x12   = ( $x1 + $x2 ) / 2.0;
    my $y12   = ( $y1 + $y2 ) / 2.0;
    my $x23   = ( $x2 + $x3 ) / 2.0;
    my $y23   = ( $y2 + $y3 ) / 2.0;
    my $x34   = ( $x3 + $x4 ) / 2.0;
    my $y34   = ( $y3 + $y4 ) / 2.0;
    my $x123  = ( $x12 + $x23 ) / 2.0;
    my $y123  = ( $y12 + $y23 ) / 2.0;
    my $x234  = ( $x23 + $x34 ) / 2.0;
    my $y234  = ( $y23 + $y34 ) / 2.0;
    my $x1234 = ( $x123 + $x234 ) / 2.0;
    my $y1234 = ( $y123 + $y234 ) / 2.0;
    # Try to approximate the full cubic curve by a single straight line
    my $dx = $x4 - $x1;
    my $dy = $y4 - $y1;
    my $d2 = _fabs( ( ( $x2 - $x4 ) * $dy - ( $y2 - $y4 ) * $dx ) );
    my $d3 = _fabs( ( ( $x3 - $x4 ) * $dy - ( $y3 - $y4 ) * $dx ) );
    my $tmp = ( int( $d2 > $curve_colleps ) << 1 ) + int( $d3 > $curve_colleps );
    if ( $tmp == 0 ) {
        # All collinear OR p1==p4
        $k = $dx * $dx + $dy * $dy;
        if ( $k == 0 ) {
            $d2 = _calc_sq_distance( $x1, $y1, $x2, $y2 );
            $d3 = _calc_sq_distance( $x4, $y4, $x3, $y3 );
        }
        else {
            $k   = 1.0 / $k;
            $da1 = $x2 - $x1;
            $da2 = $y2 - $y1;
            $d2  = $k * ( $da1 * $dx + $da2 * $dy );
            $da1 = $x3 - $x1;
            $da2 = $y3 - $y1;
            $d3  = $k * ( $da1 * $dx + $da2 * $dy );
            if ( $d2 > 0 && $d2 < 1 && $d3 > 0 && $d3 < 1 ) {
                # Simple collinear case, 1---2---3---4
                # We can leave just two endpoints
                return;
            }
            if    ( $d2 <= 0 ) { $d2 = _calc_sq_distance( $x2, $y2, $x1, $y1 ) }
            elsif ( $d2 >= 1 ) { $d2 = _calc_sq_distance( $x2, $y2, $x4, $y4 ) }
            else {
                $d2 = _calc_sq_distance(
                    $x2, $y2,
                    $x1 + $d2 * $dx,
                    $y1 + $d2 * $dy
                );
            }
            if    ( $d3 <= 0 ) { $d3 = _calc_sq_distance( $x3, $y3, $x1, $y1 ) }
            elsif ( $d3 >= 1 ) { $d3 = _calc_sq_distance( $x3, $y3, $x4, $y4 ) }
            else {
                $d3 = _calc_sq_distance(
                    $x3, $y3,
                    $x1 + $d3 * $dx,
                    $y1 + $d3 * $dy
                );
            }
        }
        if ( $d2 > $d3 ) {
            if ( $d2 < $m_disttolscale ) {
                push @m_points, ( $x2, $y2 );
                return;
            }
        }
        else {
            if ( $d3 < $m_disttolscale ) {
                push @m_points, ( $x3, $y3 );
                return;
            }
        }
    }
    if ( $tmp == 1 ) {
        # p1,p2,p4 are collinear, p3 is significant
        if ( $d3 * $d3 <= $m_disttolscale * ( $dx * $dx + $dy * $dy ) ) {
            if ( $m_angletol < $curve_angletoleps ) {
                push @m_points, ( $x23, $y23 );
                return;
            }
            # Angle Condition
            $da1 = _fabs(
                atan2( $y4 - $y3, $x4 - $x3 ) - atan2( $y3 - $y2, $x3 - $x2 ) );
            if ( $da1 >= $PI ) { $da1 = 2 * $PI - $da1 }
            if ( $da1 < $m_angletol ) {
                push @m_points, ( $x2, $y2 );
                push @m_points, ( $x3, $y3 );
                return;
            }
            if ( $m_cusp_limit != 0.0 ) {
                if ( $da1 > $m_cusp_limit ) {
                    push @m_points, ( $x3, $y3 );
                    return;
                }
            }
        }
    }
    if ( $tmp == 2 ) {
        # p1,p3,p4 are collinear, p2 is significant
        if ( $d2 * $d2 <= $m_disttolscale * ( $dx * $dx + $dy * $dy ) ) {
            if ( $m_angletol < $curve_angletoleps ) {
                push @m_points, ( $x23, $y23 );
                return;
            }
            # Angle Condition
            $da1 = _fabs(
                atan2( $y3 - $y2, $x3 - $x2 ) - atan2( $y2 - $y1, $x2 - $x1 ) );
            if ( $da1 >= $PI ) { $da1 = 2 * $PI - $da1 }
            if ( $da1 < $m_angletol ) {
                push @m_points, ( $x2, $y2 );
                push @m_points, ( $x3, $y3 );
                return;
            }
            if ( $m_cusp_limit != 0.0 ) {
                if ( $da1 > $m_cusp_limit ) {
                    push @m_points, ( $x2, $y2 );
                    return;
                }
            }
        }
    }
    if ( $tmp == 3 ) {
        # Regular case
        if ( ( $d2 + $d3 ) * ( $d2 + $d3 ) <= $m_disttolscale * ( $dx * $dx + $dy * $dy ) )
        {   # If the curvature doesnt exceed the distance_tolerance value
            # we tend to finish subdivisions.
            if ( $m_angletol < $curve_angletoleps ) {
                push @m_points, ( $x23, $y23 );
                return;
            }
            # Angle & Cusp Condition
            $k   = atan2( $y3 - $y2, $x3 - $x2 );
            $da1 = _fabs( $k - atan2( $y2 - $y1, $x2 - $x1 ) );
            $da2 = _fabs( atan2( $y4 - $y3, $x4 - $x3 ) - $k );
            if ( $da1 >= $PI ) { $da1 = 2 * $PI - $da1 }
            if ( $da2 >= $PI ) { $da2 = 2 * $PI - $da2 }
            if ( $da1 + $da2 < $m_angletol ) {
                # Finally we can stop the recursion
                push @m_points, ( $x23, $y23 );
                return;
            }
            if ( $m_cusp_limit != 0.0 ) {
                if ( $da1 > $m_cusp_limit ) {
                    push @m_points, ( $x2, $y2 );
                    return;
                }
                if ( $da2 > $m_cusp_limit ) {
                    push @m_points, ( $x3, $y3 );
                    return;
                }
            }
        }
    }
    # Continue subdivision
    $self->_recbezier4( $x1, $y1, $x12, $y12, $x123, $y123, $x1234, $y1234, $level + 1 );
    $self->_recbezier4( $x1234, $y1234, $x234, $y234, $x34, $y34, $x4, $y4, $level + 1 );
    return 1;
}

#---------------------------------------------------------------------------------------------

#
# straightforward arc implementation (incomplete circle)
#
sub arc {
    my $self = shift;
    if ( scalar @_ < 5 ) {
        $self->_croak('bad arc - need x, y, r, start, finish');
        return 0;
    }
    my ( $x, $y, $r, $start, $finish ) = ( shift, shift, shift, shift, shift );
    my $steps = shift;
    if ( !defined $steps ) {
        $steps = $self->_calc_numsteps( $r, $r );    # for a whole circle
        $steps = int( _fabs( $steps * ( $start - $finish ) / 360.0 ) );
    }
    if ( $steps < 20 ) { $steps = 20 }    # ?? is this optimal
    my @points = ();
    my $s      = radians($start);
    my $f      = radians($finish);
    my $inc    = ( $f - $s ) / $steps;
    my ( $tmpx, $tmpy, $curs );
    foreach my $i ( 0 .. $steps ) { # note: not $steps-1
        $curs = $s + $i * $inc;
        $tmpx = $x + $r * cos $curs;
        $tmpy = $y + $r * sin $curs;
        push @points, $tmpx;
        push @points, $tmpy;
    }
    $self->polygon(@points);
    return 1;
}

#
# Joining Two Lines with a Circular Arc Fillet
# Robert D. Miller, Graphics Gems III
#
sub arcto {
    my $self = shift;
    if ( scalar @_ != 5 ) {
        $self->_croak('bad arcto - need x1, y1, x2, y2, r');
        return 0;
    }
    my ( $x2, $y2, $x4, $y4, $r ) = @_;    # x3* are the same as x2*
    my ( $x1, $y1 ) = $self->currentpoint();
    # call fillet for the hard work, and collect return values.
    # line segments are almost always shorter than the originals
    my ( $p1x, $p1y, $p2x, $p2y, $p3x, $p3y, $p4x, $p4y, $xc, $yc, $pa, $aa ) =
                        $self->_fillet( $x1, $y1, $x2, $y2, $x2, $y2, $x4, $y4, $r );

    # now plot
    if (defined $p1x) {
        $self->line( $p2x, $p2y );
        $self->arc( $xc, $yc, $r, $pa, $pa + $aa );
        $self->line( $p4x, $p4y );
        return 1;
    }
    else {
        # $self->_error('arcto: cannot fillet');  # not always an error
        return 0;
    }
}

# cross product
sub _cross2 {
    my ( $self, $v1x, $v1y, $v2x, $v2y ) = @_;
    return ( $v1x * $v2y - $v2x * $v1y );
}

# turn degrees into radians
sub radians {
    my $deg = shift;
    return $deg * $D2R;
}

# turn radians into degrees
sub degrees {
    my $rad = shift;
    return $rad / $D2R;
}

# Return angle subtended by two vectors.
# cos(a) = u.v / (||u||*||v||)
sub _dot2 {
    my ( $self, $ux, $uy, $vx, $vy ) = @_;
    my ( $d, $t );
    $d = sqrt(
        ( ( $ux * $ux ) + ( $uy * $uy ) ) * ( ( $vx * $vx ) + ( $vy * $vy ) ) );    # denominator
    if ( $d != 0.0 ) {
        $t = ( $ux * $vx + $uy * $vy ) / $d;    # cos
        return ( acos($t) );                    # angle
    }
    else {
        return (0.0);
    }
}

# Find a,b,c in Ax + By + C = 0  for line p1,p2.
sub _linecoefs {
    my ( $self, $p1x, $p1y, $p2x, $p2y ) = @_;
    my ( $a, $b, $c );
    $c = ( $p2x * $p1y ) - ( $p1x * $p2y );
    $a = $p2y - $p1y;
    $b = $p1x - $p2x;
    return ( $a, $b, $c );
}

# Return signed distance from line Ax + By + C = 0 to point P.
sub _linetopoint {
    my ( $self, $a, $b, $c, $px, $py ) = @_;
    my ( $d, $lp );
    $d = sqrt( ( $a * $a ) + ( $b * $b ) );
    if ( $d == 0.0 ) {
        $lp = 0.0;
    }
    else {
        $lp = ( $a * $px + $b * $py + $c ) / $d;
    }
    return $lp;
}

# Given line l = ax + by + c = 0 and point p,
# compute x,y so p(x,y) is perpendicular to l.
sub _pointperp {
    my ( $self, $a, $b, $c, $px, $py ) = @_;
    my ( $x, $y, $d, $cp );
    $x  = 0.0;
    $y  = 0.0;
    $d  = $a * $a + $b * $b;
    $cp = $a * $py - $b * $px;
    if ( $d != 0.0 ) {
        $x = ( -$a * $c - $b * $cp ) / $d;
        $y = ( $a * $cp - $b * $c ) / $d;
    }
    return ( $x, $y );
}

#  Compute a circular arc fillet between lines L1 (p1 to p2) and
#  L2 (p3 to p4) with radius R.  The circle center is xc,yc.
sub _fillet {
    my ( $self, $p1x, $p1y, $p2x, $p2y, $p3x, $p3y, $p4x, $p4y, $r ) = @_;
    my ( $a1, $b1, $c1, $a2, $b2, $c2, $c1p, $c2p, $d1, $d2, $xa, $xb, $ya, $yb, $d, $rr );
    my ( $mpx,  $mpy,  $pcx, $pcy, $gv1x, $gv1y, $gv2x, $gv2y, $xc, $yc, $pa, $aa );
    ( $a1, $b1, $c1 ) = $self->_linecoefs( $p1x, $p1y, $p2x, $p2y );
    ( $a2, $b2, $c2 ) = $self->_linecoefs( $p3x, $p3y, $p4x, $p4y );
    if ( ( $a1 * $b2 ) == ( $a2 * $b1 ) ) {    # Parallel or coincident lines
        return (undef);
    }
    $mpx = ( $p3x + $p4x ) / 2.0;              # find midpoint of p3p4
    $mpy = ( $p3y + $p4y ) / 2.0;
    $d1  = $self->_linetopoint( $a1, $b1, $c1, $mpx, $mpy ); # Find distance p1p2 to p3
    if ( $d1 == 0.0 ) {
        return (undef) x 12;
    }
    $mpx = ( $p1x + $p2x ) / 2.0;              # find midpoint of p1p2
    $mpy = ( $p1y + $p2y ) / 2.0;
    $d2  = $self->_linetopoint( $a2, $b2, $c2, $mpx, $mpy ); # Find distance p3p4 to p2
    if ( $d2 == 0.0 ) {
        return (undef) x 12;
    }
    $rr = $r;
    if ( $d1 <= 0.0 ) {
        $rr = -$rr;
    }
    $c1p = $c1 - $rr * sqrt( ( $a1 * $a1 ) + ( $b1 * $b1 ) ) ; # Line perpendicular/parallel? l1 at d
    $rr = $r;
    if ( $d2 <= 0.0 ) {
        $rr = -$rr;
    }
    $c2p =
      $c2 - $rr * sqrt( ( $a2 * $a2 ) + ( $b2 * $b2 ) ); # Line parallel l2 at d
    $d   = $a1 * $b2 - $a2 * $b1;                        # Intersect constructed lines
    $xc  = ( $c2p * $b1 - $c1p * $b2 ) / $d;             # to find center of arc
    $yc  = ( $c1p * $a2 - $c2p * $a1 ) / $d;
    $pcx = $xc;
    $pcy = $yc;
    ( $xa, $ya ) = $self->_pointperp( $a1, $b1, $c1, $pcx, $pcy ); # Clip or extend lines as required
    ( $xb, $yb ) = $self->_pointperp( $a2, $b2, $c2, $pcx, $pcy );
    $p2x  = $xa;
    $p2y  = $ya;
    $p3x  = $xb;
    $p3y  = $yb;
    $gv1x = $xa - $xc;    # find angle wrt x-axis from arc center (xc,yc)
    $gv1y = $ya - $yc;
    $gv2x = $xb - $xc;
    $gv2y = $yb - $yc;
    $pa = atan2( $gv1y, $gv1x );                       # Beginning angle for arc
    $aa = $self->_dot2( $gv1x, $gv1y, $gv2x, $gv2y );  # angle arc subtended
    if ( $self->_cross2( $gv1x, $gv1y, $gv2x, $gv2y ) < 0.0 ) {
        $aa = -$aa;
    }  # direction to draw arc
    return ( $p1x, $p1y, $p2x, $p2y, $p3x, $p3y, $p4x, $p4y, $xc, $yc, $pa * $R2D, $aa * $R2D );
}

#--------------------------------------------------------------------------------

# code from Hearn's book "Computer Graphics with C",
# translated into Perl

# rotate about any point, referenced by optional point in USER coordinates
sub rotate {
    my $self = shift;
    my @m;
    my ( $a, $rx, $ry, $rxx, $ryy );
    if ( scalar @_ < 1 ) {
        $self->_croak('bad rotate - need 1 or 3 parameters');
        return 0;
    }
    if ( scalar @_ == 1 ) {    # no optional point specified
        $a = shift;
        ( $rx, $ry ) = $self->_u_to_p( 0, 0 );    # use origin, translated into device coords
    }
    else {
        $a   = shift;
        $rxx = shift;
        $ryy = shift;
        ( $rx, $ry ) = $self->_u_to_p( $rxx, $ryy );    # translate into device coords
    }

    # algorithm from Hearn's book
    $a = radians($a);
    @m       = ( [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] );
    $m[0][0] = cos $a;
    $m[0][1] = -sin $a;
    $m[0][2] = $rx * ( 1 - cos $a ) + $ry * sin $a;
    $m[1][0] = sin $a;
    $m[1][1] = cos $a;
    $m[1][2] = $ry * ( 1 - cos $a ) - $rx * sin $a;
    $self->_premulmat( \@m, \@{ $self->{CTM} } );
    return 1;
}

sub initmatrix {
    my $self = shift;
    $self->{CTM} = [ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ]; # current transformation matrix
    return 1;
}

#
# move another location to the origin. The params are coords in the current
# coordinate system, and are subject to scaling and rotation.
#
sub translate {
    my $self = shift;
    if ( @_ != 2 ) {
        $self->_croak('wrong number of args for translate');
        return 0;
    }
    my ( $tx, $ty ) = @_;
    $self->moveto( $tx, $ty );    # new current point, scaled and rotated
    $self->translateC();
    return 1;
}

#
# move the current page location (in user coords) to the origin
#
sub translateC {
    my $self = shift;
    my ( $x, $y, $v, $w );
    ( $x, $y ) = $self->currentpoint();       # user
    ( $v, $w ) = $self->_u_to_p( $x, $y );    # page
    $self->{CTM}[0][2] = $v;                  # fix the CTM
    $self->{CTM}[1][2] = $w;
    $self->currentpoint( 0, 0 );
    return 1;
}

#
# scaling, with optional reference point
#
sub scale {
    my $self = shift;
    my ( $sx, $sy, $rx, $ry, $rxx, $ryy );
    my @ma;
    if ( (scalar @_ == 3) || (scalar @_ > 4) ) {
        $self->_croak('bad scaling - need 1, 2 or 4 parameters');
        return 0;
    }
    if ( scalar @_ == 1 ) {
        $sx = shift;
        $sy = $sx;
        ( $rx, $ry ) = $self->_u_to_p( 0, 0 );    # use origin, translated into device coords
    }
    elsif ( scalar @_ == 2 ) {
        $sx = shift;
        $sy = shift;
        ( $rx, $ry ) = $self->_u_to_p( 0, 0 );    # use origin, translated into device coords
    }
    else {
        $sx  = shift;
        $sy  = shift;
        $rxx = shift;
        $ryy = shift;
        ( $rx, $ry ) = $self->_u_to_p( $rxx, $ryy );    # translate into device coords
    }
    @ma       = ( [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] );
    $ma[0][0] = $sx;
    $ma[0][2] = ( 1 - $sx ) * $rx;
    $ma[1][1] = $sy;
    $ma[1][2] = ( 1 - $sy ) * $ry;
    $self->_premulmat( \@ma, \@{ $self->{CTM} } );
    return 1;
}

# skew/shear in the X direction
sub skewX {
    my $self = shift;
    if ( @_ != 1 ) {
        $self->_croak('wrong number of args for skewX');
        return 0;
    }
    my $deg    = shift;
    my $rad    = radians($deg);
    my $tana   = tan $rad;
    my @matrix = ( [ 1, $tana, 0, ], [ 0, 1, 0, ], [ 0, 0, 1, ], );
    $self->_premulmat( \@matrix, \@{ $self->{CTM} } );
    return 1;
}

# skew/shear in the Y direction
sub skewY {
    my $self = shift;
    if ( @_ != 1 ) {
        $self->_croak('wrong number of args for skewY');
        return 0;
    }
    my $deg    = shift;
    my $rad    = radians($deg);
    my $tana   = tan $rad;
    my @matrix = ( [ 1, 0, 0, ], [ $tana, 1, 0, ], [ 0, 0, 1, ], );
    $self->_premulmat( \@matrix, \@{ $self->{CTM} } );
    return 1;
}

# Multiplies matrix a times b, putting result in b
sub _premulmat {
    my ( $self, $aref, $bref ) = @_;
    my @a = @{$aref};
    my @b = @{$bref};
    my @tmp;
    foreach my $r ( 0 .. 2 ) {
        foreach my $c ( 0 .. 2 ) {
            $tmp[$r][$c] =
              $a[$r][0] * $b[0][$c] +
              $a[$r][1] * $b[1][$c] +
              $a[$r][2] * $b[2][$c];
        }
    }
    foreach my $r ( 0 .. 2 ) {
        foreach my $c ( 0 .. 2 ) {
            $bref->[$r][$c] = $tmp[$r][$c];
        }
    }
    return 1;
}

# apply CTM to array of points
sub _transform {
    my ( $self, $npts, $ptsref ) = @_;
    my $tmp;
    foreach my $k ( 0 .. $npts - 1 ) {
        $tmp =
            $self->{CTM}->[0][0] * $ptsref->[ 2 * $k ] +
            $self->{CTM}->[0][1] * $ptsref->[ 2 * $k + 1 ] +
            $self->{CTM}->[0][2];
        $ptsref->[ 2 * $k + 1 ] =
            $self->{CTM}->[1][0] * $ptsref->[ 2 * $k ] +
            $self->{CTM}->[1][1] * $ptsref->[ 2 * $k + 1 ] +
            $self->{CTM}->[1][2];
        $ptsref->[ 2 * $k ] = $tmp;
    }
    return 1;
}

#--------------------------------------------------------------------------------

# floating point abs value
sub _fabs {
    my $val = shift;
    if ( $val >= 0.0 ) { return $val }
    return ( -1.0 * $val );
}

# floating point equality
sub _feq {
    my ( $x, $y ) = @_;
    if ( _fabs( $x - $y ) < $EPSILON ) {
        return 1;
    }
    return 0;
}

# square of distance betwen two points
sub _calc_sq_distance {
    my ( $x1, $y1, $x2, $y2 ) = @_;
    return ( $x2 - $x1 ) * ( $x2 - $x1 ) + ( $y2 - $y1 ) * ( $y2 - $y1 );
}

#
# circle
#
sub circle {
    my $self = shift;
    if ( scalar @_ < 3 ) {
        $self->_croak('bad circle - need x, y, r');
        return 0;
    }
    my ( $x, $y, $r ) = ( shift, shift, shift );
    $self->ellipse( $x, $y, $r, $r );
    return 1;
}

#
# straightforward ellipse implementation
#
sub ellipse {
    my $self = shift;
    if ( scalar @_ < 4 ) {
        $self->_croak('bad ellipse - need x, y, a, b');
        return 0;
    }
    my ( $x, $y, $a, $b ) = ( shift, shift, shift, shift );
    my $angle;
    my $steps = shift || $self->_calc_numsteps( $a, $b );
    if ( $steps < 20 ) { $steps = 20 }    # TODO hack!!
    my @points = ();
    foreach my $i ( 0 .. $steps ) {
        $angle = $i * $PI * 2.0 / $steps;
        push @points, $x + $a * cos($angle);
        push @points, $y + $b * sin($angle);
    }
    $self->polygon(@points);
    return 1;
}

# general estimate of the number of line segments needed for ellipse
# Copied from Anti Grain Graphics library
sub _calc_numsteps {
    my ( $self, $ra, $rb ) = @_;
    my $av    = ( $ra + $rb ) / 2.0;
    my $da    = acos( $av / ( $av + 0.125 ) ) * 2;
    my $m_num = int( 2 * $PI / $da );
    return $m_num;
}

#-----------------------------------------------------------------
# Font handling
#

#
# find and open a font, and set its size
#
sub setfont {
    my ( $self, $font, $size ) = @_;
    if ( !defined $font ) {
        $self->_croak('setfont: no font name specified');
        return undef;
    }
    my $nam = $self->findfont($font);
    if ( $nam eq $EMPTY_STR ) {
        $self->_croak( 'setfont: font ' . $font . ' not found' );
        return undef;
    }
    my $freetype = Font::FreeType->new;
    my $face     = $freetype->face( $nam, load_flags => FT_LOAD_NO_HINTING );
    if ( !defined $size ) {
        $size = $self->{fontsize};
    }
    if ( !defined $size ) {
        $self->_croak('setfont: no font size specified');
        return undef;
    }
    # save name and size in object
    $self->{fontsize} = $size;
    $self->{fontname} = $nam;
    # set in face
    $face->set_char_size( $size, $size, 72, 72 );
    return $face;
}

#
# globally set a font size
sub setfontsize {
    my $self = shift;
    if ( @_ != 1 ) {
        $self->_croak('wrong number of args for setfontsize');
        return 0;
    }
    $self->{fontsize} = shift;
    return 1;
}

#
# do the actual font rendering
#
sub _doglyphs {
    my ( $self, $face, $s, $fill ) = @_;
    my @chars = split //, $s;           # string to array
    my $len   = scalar @chars;
    my $k     = 0;                      # for kerning
    my $hk    = $face->has_kerning();
    my ( $glyph, $gprev, $adv, $d );
    # go through a string plotting the chars
    $gprev = undef;
    foreach my $i ( 0 .. $len - 1 ) {
        $glyph = $face->glyph_from_char_code( ord $chars[$i] );
        if ( !defined $glyph ) {
            $self->_error( 'char not found in font: ' . $chars[$i] );
        }
        $d = $glyph->svg_path();
        # empty $d probably means it was a space
        if ( $d eq $EMPTY_STR ) {
            $d = $SPACE;
        }
        else {
            # here we deal with a font::freetype bug -
            # delete one of duplicate successive entries in $d
            # (like the linux 'uniq' command)
            my @dtmp = split $EOL, $d;
            my $dlen = scalar @dtmp;
            if ( $dlen > 1 ) {
                while ( $dlen > 0 ) {
                    if ( $dtmp[ $dlen - 1 ] eq $dtmp[ $dlen - 2 ] ) {
                        splice @dtmp, $dlen - 1, 1;
                        $dlen--;
                        $d = join $EOL, @dtmp;
                    }
                    $dlen--;
                }
            }
        }
        $adv = $glyph->horizontal_advance();
        if ( $gprev && $hk ) {
            $k = $face->kerning( $glyph->index, $gprev->index );
        }
        if ($k) { $self->translate( $k, 0 ) }  # move to left before doing path
        # render the char, includes optimization
        if ( $d ne $SPACE ) {
            $self->_dopath($d);
        }
        if ($fill) { $self->_dohatching() }    # do hatching if specified
        $self->_flushPsegments();              # flush the path
        $self->newpath();                      # init the path
        $self->translate( $adv, 0 );           # advance for the next char
        $gprev = $glyph;                       # new becomes old
    }
    return 1;
}

#
# locate a font
#
sub findfont {
    my $self = shift;
    if ( @_ != 1 ) {
        $self->_croak('expecting 1 argument for findfont');
        return 0;
    }
    my $name = shift;
    my $s    = $EMPTY_STR;
    # ~ is not recognised
    $name =~ s{\N{TILDE}}{$home};
    # check if name starts with / or with ../ or with ./
    # this means it's a complete pathname
    #if (($name =~ /^\//) || ($name =~ /^\.\.\//) || ($name =~ /^\.\//)) {
    if (   ( $name =~ m{\A\N{SOLIDUS}} )
        || ( $name =~ m{\A\N{FULL STOP}\N{FULL STOP}\N{SOLIDUS}} )
        || ( $name =~ m{\A\N{FULL STOP}\N{SOLIDUS}} ) )
    {   if ( -e $name ) {
            return $name;
        }
        else {
            return $EMPTY_STR;
        }
    }
    # otherwise try to find in the list of locations
    for (@locations) {
        $s = $_ . $name;
        #print STDOUT "findfont: checking $s\n";
        if ( -f $s ) { return $s }
    }
    return $EMPTY_STR;
}

#
# add an absolute file path to the list of dirs to seach
#
sub addfontpath {
    my $self = shift;
    if ( @_ < 1 ) {
        $self->_croak('addfontpath: missing parameter(s)');
        return 0;
    }
    for (@_) {
        my $path = $_;
        # ~ is not recognised
        $path =~ s{\A\N{TILDE}}{$home};
        # add a / at the end if necessary, make sure to check for Windows backslash
        if ( ($path !~ m{\N{SOLIDUS}\z}) && ($path !~ m{\N{REVERSE SOLIDUS}\z})) {
            $path .= '/';
        }
        push @locations, $path;
    }
    return 1;
}

# stroke a text string, or use chr(...) to stroke a char code, without hatching
# The path is cleared after each character.
sub stroketext {
    my ( $self, $face, $string ) = @_;
    if ( !defined $string ) {
        $self->_croak('stroketext: no string specified');
        return 0;
    }
    if ( !defined $face ) {
        $self->_croak('stroketext: no face specified');
        return 0;
    }
    $self->stroke();    # flush the path (necessary??)
    $self->_doglyphs( $face, $string, 0 );
    return 1;
}

# stroke and hatch a text string or char code.
# The path is cleared after each character.
sub stroketextfill {
    my ( $self, $face, $string ) = @_;
    if ( !defined $string ) {
        $self->_croak('stroketextfill: no string specified');
        return 0;
    }
    if ( !defined $face ) {
        $self->_croak('stroketextfill: no face specified');
        return 0;
    }
    $self->stroke();    # flush the path, we don't want to hatch previous shapes
    $self->_doglyphs( $face, $string, 1 );
    return 1;
}

# calculate and return the width of a string
# params are face and string
sub textwidth {
    my $self = shift;
    if ( @_ != 2 ) {
        $self->_croak('wrong number of args for textwidth (2)');
        return 0;
    }
    my ( $face, $s ) = @_;
    my @chars = split //, $s;    # string to array
    my $len   = scalar @chars;   # number of chars in string
    my $k     = 0;               # for kerning
    my $hk    = $face->has_kerning();
    my ( $glyph, $adv, $d );
    # go through a string adding up the widths of the chars,
    # taking account of kerning
    my $width = 0;
    my $gprev = undef;
    foreach my $i ( 0 .. $len - 1 ) {
        $glyph = $face->glyph_from_char_code( ord $chars[$i] );
        if ( !defined $glyph ) {
            $self->_error( 'char not found in font: ' . $chars[$i] );
        }
        $adv = $glyph->horizontal_advance();
        if ( $gprev && $hk ) {
            $k = $face->kerning( $glyph->index, $gprev->index );
        }
        if ($k) { $width += $k }  # move to left
        $width += $adv;           # move to right
        $gprev = $glyph;          # new becomes old
    }
    return $width;
}

# translate 'pt' into whatever unit is currently selected
sub _pt_unitfied {
    my ($self, $p) = @_;
    return $p * $inches_to_unit{$self->{units}} / $inches_to_unit{pt}
}

# translate 'in' into whatever unit is currently selected
sub _in_unitfied {
    my ($self, $p) = @_;
    return $p * $inches_to_unit{$self->{units}}
}

#--------------------------------------------------------------------

# segments

#
# calculate intersection point of 2 line segments
# returns 0 if segments don't intersect
# The theory:
#  Parametric representation of a line
#    if p1 (x1,y1) and p2 (x2,y2) are 2 points on a line and
#       P1 is the vector from (0,0) to (x1,y1)
#       P2 is the vector from (0,0) to (x2,y2)
#    then the parametric representation of the line is P = P1 + k (P2 - P1)
#    where k is an arbitrary scalar constant.
#    for a point on the line segement (p1,p2)  value of k is between 0 and 1
#
#  for the 2 line segements we get
#      Pa = P1 + k (P2 - P1)
#      Pb = P3 + l (P4 - P3)
#
#  For the intersection point Pa = Pb so we get the following equations
#      x1 + k (x2 - x1) = x3 + l (x4 - x3)
#      y1 + k (y2 - y1) = y3 + l (y4 - y3)
#  Which using Cramer's Rule results in
#          (x4 - x3)(y1 - y3) - (y4 - x3)(x1 - x3)
#      k = ---------------------------------------
#          (y4 - y3)(x2 - x1) - (x4 - x3)(y2 - y1)
#   and
#          (x2 - x1)(y1 - y3) - (y2 - y1)(x1 - x3)
#      l = ---------------------------------------
#          (y4 - y3)(x2 - x1) - (x4 - x3)(y2 - y1)
#
#  Note that the denominators are equal.  If the denominator is 0,
#  the lines are parallel.  Intersection is detected by checking if
#  both k and l are between 0 and 1.
#
#  The intersection point p5 (x5,y5) is:
#     x5 = x1 + k (x2 - x1)
#     y5 = y1 + k (y2 - y1)
#
# 'Touching' segments are considered as not intersecting
sub _getsegintersect {
    my ( $self, $p0x, $p0y, $p1x, $p1y, $p2x, $p2y, $p3x, $p3y ) = @_;
    my ( $s02x, $s02y, $s10x, $s10y, $s32x, $s32y, $s_numer, $t_numer, $denom );
    # calculate determinant
    $s10x  = $p1x - $p0x;
    $s10y  = $p1y - $p0y;
    $s32x  = $p3x - $p2x;
    $s32y  = $p3y - $p2y;
    $denom = $s10x * $s32y - $s32x * $s10y;
    if ( $denom == 0 ) {
        return 0;    # Collinear
    }
    my $denomPositive = ( $denom > 0 );
    $s02x    = $p0x - $p2x;
    $s02y    = $p0y - $p2y;
    $s_numer = $s10x * $s02y - $s10y * $s02x;
    if ( ( $s_numer < 0 ) == $denomPositive ) {
        return 0;    # No intersection
    }
    $t_numer = $s32x * $s02y - $s32y * $s02x;
    if ( ( $t_numer < 0 ) == $denomPositive ) {
        return 0;    # No intersection
    }
    if (   ( ( $s_numer > $denom ) == $denomPositive )
        || ( ( $t_numer > $denom ) == $denomPositive ) )
    {
        return 0;    # No intersection
    }
    # intersection detected
    return $t_numer / $denom;
}

# Paths consist of a series of segments, where the end of one may be the start of another.
# These are then checked for intersection with a scanline if hatching is required. Hatching
# segments are stored in a separate array.

#
# initialize the segment path
#
sub newpath {
    my $self = shift;
    @{ $self->{psegments} } = ();
    @{ $self->{hsegments} } = ();
    return 1;
}

#
# close the segment path
#
sub _closepath {
    my $self = shift;
    my ( $x, $y ) = $self->currentpoint();
    my $tx = $self->{psegments}[0]{sx};
    my $ty = $self->{psegments}[0]{sy};
    my $k  = $self->{psegments}[0]{key};
    $self->_addpath( $k, $x, $y, $tx, $ty );
    return 1;
}

#
# add to the segment path
#
sub _addpath {
    my $self = shift;
    my $len  = scalar @{ $self->{psegments} };
    if ( @_ != 5 ) {
        $self->_error('need 5 parameters for addpath');
        return 0;
    }
    my ( $key, $sx, $sy, $dx, $dy ) = @_;
    # could insert LiangBarsky here to do cropping for svg viewbox
    $self->{psegments}[$len] = { key => $key, sx => $sx, sy => $sy, dx => $dx, dy => $dy };
    return 1;
}

#
# add to the segment path
#
sub addcomment {
    my $self = shift;
    my $len  = scalar @{ $self->{psegments} };
    if ( @_ != 1 ) {
        $self->_error('need 1 parameter for addcomment');
        return 0;
    }
    my $s = shift;
    $self->{psegments}[$len] = { key => 'c', s => $s, sx => 0, sy => 0, dx => 0, dy => 0 };
    return 1;
}

# paint the current path, then clear it
sub stroke {
    my $self = shift;
    $self->_flushPsegments();
    $self->newpath();
    return 1;
}

#
# translate the segment queue into gcode
#
sub _flushPsegments {
    my $self = shift;
    my $len  = scalar @{ $self->{psegments} };
    my ( $k, $d );
    if ( !$len ) { return }                  # empty queue
    $self->_optimize();
    $len = scalar @{ $self->{psegments} };   # hopefully, lots have been removed
    SEGMENT:
    foreach my $i ( 0 .. $len - 1 ) {
        # line segment length, for aggregation
        $k = $self->{psegments}[$i]{key};
        if (! defined $k) {
            next SEGMENT;
        }
        if ($k ne 'c') {
            $d = sqrt(
                ( $self->{psegments}[$i]{sx} - $self->{psegments}[$i]{dx} ) *
                ( $self->{psegments}[$i]{sx} - $self->{psegments}[$i]{dx} ) +
                ( $self->{psegments}[$i]{sy} - $self->{psegments}[$i]{dy} ) *
                ( $self->{psegments}[$i]{sy} - $self->{psegments}[$i]{dy} ) );
        }
        if ( $k eq 'l' ) {    # lineto, the most frequent instruction
            $self->_addtopage(
                sprintf "G01 X %.5f Y %.5f\n",
                $self->{psegments}[$i]{dx},
                $self->{psegments}[$i]{dy}
            );
            $self->{slowdistcount} += $d;
            next SEGMENT;
        }
        if ( $k eq 'm' ) {    # moveto
            $self->_addtopage(
                sprintf "G00 X %.5f Y %.5f\n",
                $self->{psegments}[$i]{dx},
                $self->{psegments}[$i]{dy}
            );
            $self->{fastdistcount} += $d;
            next SEGMENT;
        }
        if ( $k eq 'c' ) {    # comment
            $self->_addtopage(
                sprintf "(%s)\n",
                $self->{psegments}[$i]{s}
            );
            next SEGMENT;
        }
        if ( $k eq 'u' ) {    # penup
            if ( !$self->{penlocked} ) {
                $self->_addtopage( $self->{penupcmd} );
                $self->{pencount}++;
            }
            next SEGMENT;
        }
        if ( $k eq 'd' ) {    # pendown
            if ( !$self->{penlocked} ) {
                $self->_addtopage( $self->{pendowncmd} );
            }
            next SEGMENT;
        }
    }
    return 1;
}

#
# get the bounding box of the current path
#
sub _get_bbox {
    my $self  = shift;
    my $maxx  = 0.0;
    my $maxy  = 0.0;
    my $minx  = $BBMAX;
    my $miny  = $BBMAX;
    my $len   = scalar @{ $self->{psegments} };
    my $count = 0;
    if ( !$len ) { return ( -1, -1, -1, -1 ) }    # empty queue
    SEGMENT:
    foreach my $i ( 0 .. $len - 1 ) {
        if ( $self->{psegments}[$i]{key} ne 'l' ) { next SEGMENT }
        ;    # we want the line segments only
        $count++;
        # check the start of the segment
        my $k = $self->{psegments}[$i]{sx};
        if ( $k > $maxx )             { $maxx = $k }
        if ( $k < $minx && $k > 0.0 ) { $minx = $k }
        $k = $self->{psegments}[$i]{sy};
        if ( $k > $maxy )             { $maxy = $k }
        if ( $k < $miny && $k > 0.0 ) { $miny = $k }
        # check the end of the segment
        $k = $self->{psegments}[$i]{dx};
        if ( $k > $maxx )             { $maxx = $k }
        if ( $k < $minx && $k > 0.0 ) { $minx = $k }
        $k = $self->{psegments}[$i]{dy};
        if ( $k > $maxy )             { $maxy = $k }
        if ( $k < $miny && $k > 0.0 ) { $miny = $k }
    }
    if ( !$count ) { return ( -1, -1, -1, -1 ) }    # no line segments found
    return ( $minx, $miny, $maxx, $maxy );
}

#--------------------------------------------------------------------

# hatching

#
# add to the list of hatching segments
#
sub _addhsegmentpath {
    my $self = shift;
    my ( $key, $sx, $sy, $dx, $dy ) = @_;
    my $len = scalar @{ $self->{hsegments} };
    if ( @_ != 5 ) {
        $self->_error(
            'need 4 numbers for addhsegpath, found ' . ( scalar @_ ) );
        return 0;
    }
    $self->{hsegments}[$len] = { key => $key, sx => $sx, sy => $sy, dx => $dx, dy => $dy };
    return 1;
}

#
# initialize the list of hatching segments
#
sub _newhpath {
    my $self = shift;
    @{ $self->{hsegments} } = ();
    return 1;
}

# optimize the plotting of hatch lines
# a good strategy will significantly reduce the plotter's work
sub _hoptimize {  # TODO
    my $self = shift;
    # See vecsort.c for a general procedure:
    # - compare start and end points of all remaining L segments to endpoint of current segment
    #   and locate the nearest one
    # - if it's the endpoint that's closest, reverse the nearest segment
    # - first add M segment to new list, then nearest segment, remove from the normal list
    # - flush the sorted list, empty the normal list
    return 1;
}

#
# render the generated list of hatching segments
# we have only 'l' and 'm' segments here.
# We're working in device coordinates here
sub _flushHsegments {
    my $self = shift;
    my $len  = scalar @{ $self->{hsegments} };
    my $d;
    if ( !$len ) {
        if ($self->{check}) {
            print STDOUT "*** no hsegments found\n"
        }
        return;
    }
    # $self->_prHsegs(); # for debugging
    $self->_hoptimize();
    foreach my $i ( 0 .. $len - 1 ) {
        $d = sqrt(
            ( $self->{hsegments}[$i]{sx} - $self->{hsegments}[$i]{dx} ) *
            ( $self->{hsegments}[$i]{sx} - $self->{hsegments}[$i]{dx} ) +
            ( $self->{hsegments}[$i]{sy} - $self->{hsegments}[$i]{dy} ) *
            ( $self->{hsegments}[$i]{sy} - $self->{hsegments}[$i]{dy} ) );
        if ( $self->{hsegments}[$i]{key} eq 'm' ) {
            if ( !$self->{penlocked} ) {
                $self->_addtopage( $self->{penupcmd} );
                $self->{pencount}++;
            }
            $self->_addtopage(
                sprintf "G00 X %.5f Y %.5f\n",
                $self->{hsegments}[$i]{dx},
                $self->{hsegments}[$i]{dy}
            );
            if ( !$self->{penlocked} ) {
                $self->_addtopage( $self->{pendowncmd} );
            }
            $self->{fastdistcount} += $d;
        }
        if ( $self->{hsegments}[$i]{key} eq 'l' ) {
            $self->_addtopage(
                sprintf "G01 X %.5f Y %.5f\n",
                $self->{hsegments}[$i]{dx},
                $self->{hsegments}[$i]{dy}
            );
            $self->{slowdistcount} += $d;
        }
        # ignore comments
    }
    return 1;
}

# start the hatching process. Parameters are the chosen box around the hatching area.
# Must make sure that the graphics state upon exit is unaltered from entry.
# Note that we are working in device coordinates here.
sub _dohatching {
    my $self = shift;
    my ( $xmind, $ymind, $xmaxd, $ymaxd );
    my ( @crossings, @csorted );
    my $perc    = 0;
    my $margin  = 10 * $self->{dscale};    # extra margin outside bounding box
    my $sep     = $self->{hatchsep};
    my $pathlen = scalar @{ $self->{psegments} };
    my ( $p, $xstart, $xend, $ymindsave );    # xcoords of start and end of segments
    my ( $xmovex, $ymovey, $clen, $same );
    $self->gsave();
    $self->_newhpath();
    # find the bounding box
    ( $xmind, $ymind, $xmaxd, $ymaxd ) = $self->_get_bbox();
    $ymindsave = $ymind;   # original ymind
    # original blhc, for generating the first 'm' segment
    $xmovex    = $xmind;
    $ymovey    = $ymind;
    # need to make the bounding box slightly bigger
    $xmind -= $margin;
    $ymind -= $margin;
    $xmaxd += $margin;
    $ymaxd += $margin;
    # loop through the hatch lines
    while ( $ymind < $ymaxd ) {    # note: horizontal hatch lines assumed
        @crossings = ();
        # check all psegments for intersection with hatch line
        foreach my $i ( 0 .. $pathlen - 1 ) {
            if ( $self->{psegments}[$i]{key} eq 'l' ) {
                $perc = $self->_getsegintersect(
                    $xmind,                     $ymind,
                    $xmaxd,                     $ymind,
                    $self->{psegments}[$i]{sx}, $self->{psegments}[$i]{sy},
                    $self->{psegments}[$i]{dx}, $self->{psegments}[$i]{dy}
                );
                if ( $perc > 0.0 ) {    # we have a crossing
                    push @crossings, { perc => $perc, seg => $i };
                }
            }
        }
        # we now have a (possibly empty) set of crossings
        # empty sets are obviously ignored
        $clen = scalar @crossings;
        if ($clen) {
            # sort @crossings, delete duplicates
            @csorted = sort { $a->{perc} <=> $b->{perc} } @crossings;
            # compare adjacent entries for equality
            HATCH:
            foreach my $i ( 0 .. $clen - 2 ) {
                if ( $csorted[$i]{perc} == $csorted[ $i + 1 ]{perc} )
                {
                    # check for coinciding, opposite direction segments
                    if ($self->_identical($csorted[$i]{seg}, $csorted[ $i + 1 ]{seg})) {
                        splice @csorted, $i, 1;
                        $clen--;
                        splice @csorted, $i, 1;
                        $clen--;
                        # next HATCH;
                    }
                    else {
                        $same = $self->_sameside( $ymind, $csorted[$i]{seg},
                            $csorted[ $i + 1 ]{seg} );
                        if ( $same == 1 ) {
                        # if the line segments are on the same side, delete both
                            splice @csorted, $i, 1;
                            $clen--;
                            splice @csorted, $i, 1;
                            $clen--;
                        }
                        elsif ( !$same ) {    # delete one.
                            splice @csorted, $i, 1;
                            $clen--;
                        }
                        else {
                            # _sameside had a problem, returned -1
                            next HATCH;
                        }
                    }
                }
            }
            # when finished, we should have an even number of entries
            if ( $clen % 2 ) {
                if ($self->{check}) {
                    print STDOUT 'dohatching: odd number of crossings' . $EOL
                }
            }
        }
        # generate segments, store in hsegments using _addhsegmentpath
        # line goes from (xmind, ymind) to (xmaxd,ymind)
        # we deduce from perc where the x coord of the intersection is
        if ($clen) {
            # loop through the crossing points in pairs, generating segments
            #for (my $i=0; $i<$clen-1;$i+=2) {
            PAIR:
            foreach my $i ( 0 .. $clen - 1 ) {
                if ( $i % 2 ) { next PAIR }    # skip the odd numbers (from PBP)
                $p      = $csorted[ $i + 0 ]{perc};
                $xstart = $xmind + $p * ( $xmaxd - $xmind );
                $p      = $csorted[ $i + 1 ]{perc};
                $xend   = $xmind + $p * ( $xmaxd - $xmind );
                # now create the segments. Note, again, these are DEVICE coordinates
                $self->_addhsegmentpath( 'm', $xmovex, $ymovey, $xstart, $ymind );
                $self->_addhsegmentpath( 'l', $xstart, $ymind, $xend, $ymind );
                # set the start of the next move for the next hatch line
                $xmovex = $xend;
                $ymovey = $ymind;
            }
        }
        $ymind += $sep;
    } # while hatch lines
    $self->_flushHsegments();
    $self->grestore();
    return 1;
}

# determine if two line segments are identical, possibly in reverse
sub _identical {
    my $self = shift;
    my ( $seg1, $seg2 ) = @_;
    my %h1 = %{ $self->{psegments}[$seg1] };
    my %h2 = %{ $self->{psegments}[$seg2] };
    # first segment goes from (ax,ay) to (bx,by)
    my $ax = $h1{sx};
    my $ay = $h1{sy};
    my $bx = $h1{dx};
    my $by = $h1{dy};
    # second segment goes from (cx,cy) to (dx,dy)
    my $cx = $h2{sx};
    my $cy = $h2{sy};
    my $dx = $h2{dx};
    my $dy = $h2{dy};
    if ( ( $ax == $dx ) && ( $ay == $dy ) && ( $cx == $bx ) && ( $cy == $by ) )
    { return 1;
    }
    if ( ( $ax == $cx ) && ( $ay == $cy ) && ( $bx == $dx ) && ( $by == $dy ) )
    { return 1;
    }
    return 0;
}

# determine if two line segments with common vertex are on the same
# side of a horizontal line.
sub _sameside {
    my $self = shift;
    my ( $y, $seg1, $seg2 ) = @_;
    my %h1 = %{ $self->{psegments}[$seg1] };
    my %h2 = %{ $self->{psegments}[$seg2] };
    # first segment goes from (ax,ay) to (bx,by)
    my $ay = $h1{sy};
    my $by = $h1{dy};
    # second segment goes from (cx,cy) to (dx,dy)
    my $cy = $h2{sy};
    my $dy = $h2{dy};
    my ( $y1, $y2 );
    # we first determine which of these points is NOT on the horizontal line
    if ( $ay == $y ) {
        $y1 = $by;
    }
    elsif ( $by == $y ) {
        $y1 = $ay;
    }
    else {
        if ($self->{check}) {
            print STDOUT "sameside: cannot determine vertex 1 for $y of $seg1 and $seg2\n"
        }
        return -1;
    }
    if ( $cy == $y ) {
        $y2 = $dy;
    }
    elsif ( $dy == $y ) {
        $y2 = $cy;
    }
    else {
        if ($self->{check}) {
            print STDOUT "sameside: cannot determine vertex 2 for $y of $seg1 and $seg2\n"
        }
        return -1;
    }
    if ( $y1 > $y && $y2 > $y ) { return 1 }
    if ( $y1 < $y && $y2 < $y ) { return 1 }
    return 0;
}

# set the separation between hatch lines, in current units
sub sethatchsep {
    my $self = shift;
    if ( @_ != 1 ) {
        $self->_error('wrong number of args for sethatchsep');
        return 0;
    }
    $self->{hatchsep} = shift;
    return 1;
}

# Add hatches to the current path, stroke the current path, then clear it
sub strokefill {
    my $self = shift;
    my ( $minx, $miny, $maxx, $maxy ) = $self->_get_bbox();

    # calculate the hatching segments
    $self->_dohatching( $minx, $miny, $maxx, $maxy );
    $self->_flushPsegments();    # do this last before clearing the path
    $self->newpath();
    return 1;
}

#-------------------------------------------------------------------

#
# Lift the pen
#
sub penup {
    my $self = shift;
    #$self->{pencount}++;
    if ( !$self->{penlocked} ) { $self->_addpath( 'u', -1, -1, -1, -1 ) }
    return 1;
}

#
# Lower the pen
#
sub pendown {
    my $self = shift;
    if ( !$self->{penlocked} ) { $self->_addpath( 'd', -1, -1, -1, -1 ) }
    return 1;
}

#
# Add a line of text to the output. No checking is done.
# All currently queued segments are flushed first.
#
sub addtopage {
    my $self = shift;
    if ( !@_ ) {
        $self->_croak('addtopage: no data provided');
        return 0;
    }
    my $data = shift;
    $self->_flushPsegments();
    $self->_addtopage($data);
    return 1;
}

#
# Create output file and report statistics
#
sub output {
    my $self = shift;
    my $file = shift || $self->{outfile};
    if ( $file eq $EMPTY_STR ) {
        croak 'Must supply a filename for output';
    }
    my $out;
    $self->_flushPsegments();
    open $out, '>', $file or croak "Cannot write to file $file";
    my $count = scalar @{ $self->{currentpage} };
    foreach my $i ( @{ $self->{currentpage} } ) {
        print {$out} $i;
    }
    $self->_closepage($out);    # write the trailer to file, but not memory
    close $out;
    # report stats if asked for
    if ( $self->{check} ) {
        $self->_stats();
    }
    return 1;
}

#-------------------------------------------------------------------------------
# PRIVATE methods

#
# print statistics about the gcode program
#
sub _stats {
    my $self = shift;
    my $f    = $self->{fastdistcount};
    my $s    = $self->{slowdistcount};
    print STDOUT "=== Object \'" . $self->{id} . "\'===\n";
    print STDOUT sprintf "Bounding box:  (%.3f,%.3f) (%.3f,%.3f)\n",
                    $self->{minx}, $self->{miny}, $self->{maxx}, $self->{maxy};
    $self->_checkp();
    $self->_checkl();
    print STDOUT 'Pen cycles: ' . $self->{pencount} . $EOL;
    print STDOUT 'Distance above the paper: ';
    print STDOUT sprintf "%.1f inches (%.1f cm, %.1f feet)\n", $f, $f * 2.54, $f * 0.0833;
    print STDOUT 'Distance on the paper:    ';
    print STDOUT sprintf "%.1f inches (%.1f cm, %.1f feet)\n", $s, $s * 2.54, $s * 0.0833;
    return 1;
}

#
# set up a page, by adding the header
#
sub _openpage {
    my $self = shift;
    $self->_addtopage( $self->{header} );
    return 1;
}

#
# Close a page by adding a trailer, either by adding to currentpage
# or to an output file
#
sub _closepage {
    my $self = shift;
    my $out  = shift;
    if ( defined $out ) {
        print $out $self->{trailer} . $EOL;
    }
    else {
        $self->_addtopage( $self->{trailer} );
    }
    return 1;
}

#
# Add a line to the page
#
sub _addtopage {
    my ( $self, $data ) = @_;
    my $p = $self->{currentpage};
    push @{$p}, $data;
    return 1;
}

sub _penunlock {
    my $self = shift;
    $self->{penlocked} = 0;
    return 1;
}

sub _penlock {
    my $self = shift;
    $self->{penlocked} = 1;
    return 1;
}

sub _penlocked {
    my $self = shift;
    return $self->{penlocked};
}

#
# Report a serious internal error and quit
#
sub _error {
    my $self = shift;
    my $msg  = shift;
    die RED $msg, RESET;
    return 0;
}

#
# Report a serious user error and quit
#
sub _croak {
    my $self = shift;
    my $msg  = shift;
    croak YELLOW $msg, RESET;
    return 0;
}

#
# generate a pen move -  from user coords
#
sub _genmove {
    my $self = shift;
    my $mode = shift;
    my ( $x, $y ) = @_;
    my @point    = ();
    my @pointold = ();
    my $opcode = 'm';
    my ( $px, $py );
    if ( $mode eq 'slow' ) { $opcode = 'l' }
    # get the current point (user coords) - soon to be updated
    my ( $cx, $cy ) = $self->currentpoint();
    # get the paper coords of the current point and save them
    @pointold = $self->_u_to_p( $cx, $cy );
    #debugging
    $px       = $pointold[0];
    $py       = $pointold[1];
    # get the device coords of the current point
    ( $pointold[0], $pointold[1] ) = $self->_p_to_d(@pointold);
    # set the new current point (the destination)
    $self->currentpoint( $x, $y );
    # get the paper coords of the new current point
    @point = $self->_u_to_p( $x, $y );
    $px    = $point[0];
    $py    = $point[1];
    # get the device coords of the new current point
    ( $point[0], $point[1] ) = $self->_p_to_d(@point);
    # add up the distance
    # warn if out of device bounds for reporting and postscript generation
    $self->_warn( $point[0], $point[1] );
    if ( $self->{check} ) {
        if ( $point[0] > $self->{maxx} ) { $self->{maxx} = $point[0] }
        if ( $point[1] > $self->{maxy} ) { $self->{maxy} = $point[1] }
        if ( $point[0] < $self->{minx} && $point[0] > 0.0 ) {
            $self->{minx} = $point[0];
        }
        if ( $point[1] < $self->{miny} && $point[1] > 0.0 ) {
            $self->{miny} = $point[1];
        }
    }
    # finally, generate the instruction
    $self->_addpath( $opcode, $pointold[0], $pointold[1], $point[0], $point[1] );
    return 1;
}

#
# generate a slow move (pen on paper)
#
sub _genslowmove {
    my $self = shift;
    $self->_genmove( 'slow', @_ );
    return 1;
}

#
# generate a fast move (pen off paper)
#
sub _genfastmove {
    my $self = shift;
    $self->_genmove( 'fast', @_ );
    return 1;
}

#
# Warn if the pen ends up outside the page boundary
# We need DEVICE coordinates here for obvious reasons
#
sub _warn {
    my ( $self, $x, $y ) = @_;
    my ( $x0clip, $y0clip, $x1clip, $y1clip, $info );
    if ( !$self->{warn} ) { return 0 }
    # we check only the endpoint for now.
    # just assume the line started at (0.1, 0.1)
    if ( ( $x < 0 ) || ( $y < 0 ) ) {
        print STDOUT "Out of bound: ($x,$y)\n";
        return 0;
    }
    ( $x0clip, $y0clip, $x1clip, $y1clip, $info ) =
        $self->_LiangBarsky( 0, 0, $self->{xsize}, $self->{ysize}, 0.1, 0.1, $x, $y );
    if ( $info != 1 ) {
        print STDOUT "Out of bound: ($x,$y)\n";
    }
    return 1;
}

# Liang-Barsky line clipping function by Daniel White @
# https://www.skytopia.com/project/articles/compsci/clipping.html
# This code was modified to remove a bug, then translated into Perl.
# use:
# ($x1, $y1, $x2, $y2, $info) = $obj->_LiangBarsky($botx, $boty, $topx, $topy, $x0src, $y0src, $x1src, $y1src);
# The first four parameters are the coordinates of the bottom left and
# top right corners of the rectangle.
# The last four parameters are the coordinates of the start and end of the line segment.
# Meaning of the 'info' return value:
# 1 entire line segment is inside boundary
# 2 line segment is completely outside boundary
# 3 starting point inside, but not endpoint
# 4 endpoint inside, but not starting point
# 5 neither startpoint nor endpoint inside, but other parts are
# The function returns the clipped line segment in the other variables, unless info
# is 2, in which case -1 is returned.
# This code is self contained, so suitable for inclusion elsewhere, and well tested
# (remove $self if necessary).
sub _LiangBarsky {
    my ( $self, $botx, $boty, $topx, $topy, $x0src, $y0src, $x1src, $y1src ) = @_;
    my $t0     = 0.0;
    my $t1     = 1.0;
    my $xdelta = $x1src - $x0src;
    my $ydelta = $y1src - $y0src;
    my ( $p, $q, $r );
    my $info = 0;
    my ( $x0clip, $y0clip, $x1clip, $y1clip );
    foreach my $edge ( 0 .. 3 )
    {    # Traverse through left, right, bottom, top edges.
        if ( $edge == 0 ) {
            $p = -$xdelta;
            $q = -( $botx - $x0src );
        }
        if ( $edge == 1 ) {
            $p = $xdelta;
            $q = ( $topx - $x0src );
        }
        if ( $edge == 2 ) {
            $p = -$ydelta;
            $q = -( $boty - $y0src );
        }
        if ( $edge == 3 ) {
            $p = $ydelta;
            $q = ( $topy - $y0src );
        }
        if ( $p == 0 && $q < 0 ) {
            return ( -1, -1, -1, -1, 2 );   # segment is outside entirely
        }
        if ( $p < 0 ) {
            $r = 1.0 * $q / $p;
            if ( $r > $t1 ) {
                return ( -1, -1, -1, -1, 2 );
            }
            elsif ( $r > $t0 ) {
                $t0 = $r                    # segment is clipped at start
            }
        }
        elsif ( $p > 0 ) {
            $r = 1.0 * $q / $p;
            if ( $r < $t0 ) {
                return ( -1, -1, -1, -1, 2 );
            }
            elsif ( $r < $t1 ) {
                $t1 = $r                    # segment is clipped at end
            }
        }
    }
    if ( $t0 == 0.0 && $t1 == 1.0 ) { $info = 1 }    # segment entirely within boundary
    # info 2 means segment entirely outside boundary - we've already returned for that
    if ( $t0 == 0.0 && $t1 != 1.0 ) { $info = 3 }    # start of segment within boundary
    if ( $t0 != 0.0 && $t1 == 1.0 ) { $info = 4 }    # end of segment within boundary
    if ( $t0 != 0.0 && $t1 != 1.0 ) { $info = 5 }    # "middle" part of segment within boundary
    $x0clip = $x0src + $t0 * $xdelta;
    $y0clip = $y0src + $t0 * $ydelta;
    $x1clip = $x0src + $t1 * $xdelta;
    $y1clip = $y0src + $t1 * $ydelta;
    return ( $x0clip, $y0clip, $x1clip, $y1clip, $info );
}

# sizes in postscript units (pt)
my @a_sizes = (
    { name => 'A4',  width => 595,  height => 842  },
    { name => 'A3',  width => 842,  height => 1191 },
    { name => 'A2',  width => 1191, height => 1684 },
    { name => 'A1',  width => 1684, height => 2384 },
    { name => 'A0',  width => 2384, height => 3370 },
    { name => '2A0', width => 3370, height => 4768 },
    { name => '4A0', width => 4768, height => 6741 },
);

# check if a design fits landscape
sub _checkl {
my $self = shift;
my $y = $self->{maxx} * $I2P;  # swap for landscape
my $x = $self->{maxy} * $I2P;
my $best_fit = 'size too big for 4A0 landscape!';
    foreach my $size (@a_sizes) {
            # find the smallest size that fits
            if (($x <= $size->{width} && $y <= $size->{height}) ||
                ($y <= $size->{width} && $x <= $size->{height})) {
                $best_fit = $size->{name}; 
                last;
            }
    }
    print STDOUT "best fit landscape: $best_fit\n";
    return 1;
}

# check if a design fits portrait
sub _checkp {
my $self = shift;
my $x = $self->{maxx} * $I2P;
my $y = $self->{maxy} * $I2P;
my $best_fit = 'size too big for 4A0 portrait!';
    foreach my $size (@a_sizes) {
            # find the smallest size that fits
            if (($x <= $size->{width} && $y <= $size->{height}) ||
                ($y <= $size->{width} && $x <= $size->{height})) {
                $best_fit = $size->{name}; 
                last;
            }
    }
    print STDOUT "best fit portrait:  $best_fit\n";
    return 1;
}

#---------------------------------------------------------------------------------

# SVG input

my $first;    # for tidy printing of warnings
my $svgw;     # width of the svg
my $svgh;     # height of the svg
my $svgvb;    # viewbox of the svg

sub _svg_value_to_inches {
    my $value = shift;
    my ($num, $unit) = $value =~ /^([\d.]+)(\D*)$/;
    $unit = 'px' if (! defined $unit);                 # px is svg default
    $unit = 'px' unless exists $unit_to_inches{$unit}; # default to px if not specified or unknown
    return $num * $unit_to_inches{$unit};
}

# convert an svg number with unit, like "100mm", into the user specified unit.
# first convert it to inches, then convert the inches to the required unit
sub _svgconvert {
    my ($self, $value) = @_;
    my $inches = _svg_value_to_inches($value);
    return $inches * $inches_to_unit{$self->{units}};   # $value converted to user units
    # ?? need to return both inches and value?
}

# import the svg
sub importsvg {
    my ( $self, $file ) = @_;
    use XML::Parser;
    my $p = XML::Parser->new(
        Handlers => {
            Start => sub { $self->_starttag(@_) },
            End   => sub { $self->_endtag(@_) }
        }
    );
    $first = 1;
    if ($self->{check}) {
        print STDOUT "$file:\n";
    }
    $self->gsave();
    $p->parsefile($file) or die "Error $file: ";
    $self->grestore();
    # if we warned about unimpemented tags, print a newline
    if ( !$first ) {
        if ($self->{check}) {
            print STDOUT $EOL;
        }
    }
    return 1;
}

sub _endtag {
    my ( $self, $expat, $element, %attr ) = @_;
    if ( $element eq 'g' ) {
        $self->grestore();
    }
    return 1;
}

sub _starttag {
    my ( $self, $expat, $element, %attr ) = @_;
    my $x    = undef;    # stores start of path, for closepath later
    my $y    = undef;
    my $curx = 0;
    my $cury = 0;
    my ( $xa, $ya );
    if ( $element eq 'path' ) {
        my $t = $attr{transform};
        if ($t) {
            $self->gsave();
            $self->_dotransform($t);
        }
        $self->_dopath( $attr{d} );
        if ($t) {
            $self->grestore();
        }
        return;
    }    # element eq 'path'
    # group tag
    if ( $element eq 'g' ) {
        $self->gsave();
        my $t = $attr{transform};
        if ($t) {
            $self->_dotransform($t);
        }
        return;
    }
    # line tag
    if ( $element eq 'line' ) {
        my $x1 = $attr{x1} || 0;
        $x1 = $self->_svgconvert($x1);
        my $y1 = $attr{y1} || 0;
        $y1 = $self->_svgconvert($y1);
        my $x2 = $attr{x2} || 0;
        $x2 = $self->_svgconvert($x2);
        my $y2 = $attr{y2} || 0;
        $y2 = $self->_svgconvert($y2);
        my $t  = $attr{transform};
        if ($t) {
            $self->gsave();
            $self->_dotransform($t);
        }
        $self->line( $x1, $y1, $x2, $y2 );
        if ($t) {
            $self->grestore();
        }
        return;
    }
    # rect tag
    if ( $element eq 'rect' ) {
        my $x      = $attr{x} || 0;
        $x = $self->_svgconvert($x);
        my $y      = $attr{y} || 0;
        $y = $self->_svgconvert($y);
        my $width  = $attr{width};
        $width = $self->_svgconvert($width);
        my $height = $attr{height};
        $height = $self->_svgconvert($height);
        my $rx     = $attr{rx};
        $rx = $self->_svgconvert($rx);
        my $ry     = $attr{ry};
        $ry = $self->_svgconvert($ry);
        my $t      = $attr{transform};
        if ($t) {
            $self->gsave();
            $self->_dotransform($t);
        }
        if ( !$rx ) {
            $self->box( $x, $y, $x + $width, $y + $height );
        }
        else {
            $self->boxround( $x, $y, $x + $width, $y + $height, $rx );
        }
        if ($t) {
            $self->grestore();
        }
        return;
    }
    # ellipse tag
    if ( $element eq 'ellipse' ) {
        my $cx = $attr{cx} || 0;
        $cx = $self->_svgconvert($cx);
        my $cy = $attr{cy} || 0;
        $cy = $self->_svgconvert($cy);
        my $rx = $attr{rx};
        $rx = $self->_svgconvert($rx);
        my $ry = $attr{ry};
        $ry = $self->_svgconvert($ry);
        my $t  = $attr{transform};
        if ($t) {
            $self->gsave();
            $self->_dotransform($t);
        }
        $self->ellipse( $cx, $cy, $rx, $ry );
        if ($t) {
            $self->grestore();
        }
        return;
    }
    # circle tag
    if ( $element eq 'circle' ) {
        my $cx = $attr{cx} || 0;
        $cx = $self->_svgconvert($cx);
        my $cy = $attr{cy} || 0;
        $cy = $self->_svgconvert($cy);
        my $r  = $attr{r};
        $r = $self->_svgconvert($r);
        # if there's a transform, save the graphics state,
        # do the work, then restore the graphics state
        my $t = $attr{transform};
        if ($t) {
            $self->gsave();
            $self->_dotransform($t);
        }
        $self->circle( $cx, $cy, $r );
        if ($t) {
            $self->grestore();
        }
        return;
    }
    # polyline tag
    if ( $element eq 'polyline' ) {
        my $p = $attr{points};
        $p =~ s{\N{COMMA}}{\N{SPACE}}g;
        my @c = split / +/, $p;
        foreach my $i (0 .. scalar @c - 1) {$c[$i] = $self->_svgconvert($c[$i])}
        # if there's a transform, save the graphics state,
        # do the work, then restore the graphics state
        my $t = $attr{transform};
        if ($t) {
            $self->gsave();
            $self->_dotransform($t);
        }
        $self->polygon(@c);
        if ($t) {
            $self->grestore();
        }
        return;
    }
    # polygon tag
    if ( $element eq 'polygon' ) {
        my $p = $attr{points};
        $p =~ s{\N{COMMA}}{\N{SPACE}}g;
        my @c = split( / +/, $p );
        push @c, $c[0];    # close the shape
        push @c, $c[1];
        foreach my $i (0 .. scalar @c - 1) {$c[$i] = $self->_svgconvert($c[$i])}
        # if there's a transform, save the graphics state,
        # do the work, then restore the graphics state
        my $t = $attr{transform};
        if ($t) {
            $self->gsave();
            $self->_dotransform($t);
        }
        $self->polygon(@c);
        if ($t) {
            $self->grestore();
        }
        return;
    }
    # svg tag - report on size
    if ( $element eq 'svg' ) {
        $svgw = $attr{width};
        $svgh = $attr{height};
        if ( $svgw && $svgh ) {
            if ($self->{check}) {
                print STDOUT "SVG size: $svgw x $svgh\n"
            }
        }
        $svgvb = $attr{viewBox};
        if ($svgvb) {
            if ($self->{check}) {
                print STDOUT "SVG viewbox ignored" . $EOL
            }
        }
        return;
    }
    # comment
    if ( $element eq 'desc' ) {    # ignore it
        return;
    }
    # if we get here, we have an unimplemented tag. Generate a warning.
    if ($first) {
        if ($self->{check}) {
            print STDOUT "### not implemented: $element"
        }
        $first = 0;
    }
    else {
        if ($self->{check}) {
            print STDOUT ", $element"
        }
    }
    return 1;
}

# perform a series of path commands
sub _dopath {
    my ( $self, $d ) = @_;    # rr is ref to array
    my @r    = extract_path_info( $d, { absolute => 1, no_smooth => 1 } );
    my $x    = undef;         # stores start of path, for closepath later
    my $y    = undef;
    my $curx = 0;
    my $cury = 0;
    my ( $xa, $ya );
    for (@r) {
        # move
        if ( $_->{svg_key} =~ m{\A[mM]\z}i ) {
            $self->moveto( $_->{point}[0], $_->{point}[1] );
            $x    = $_->{point}[0];    # for closing the path later
            $y    = $_->{point}[1];
            $curx = $_->{point}[0];
            $cury = $_->{point}[1];
        }
        # line
        if ( $_->{svg_key} =~ m{\A[lL]\z}i ) {
            $self->line( $_->{point}[0], $_->{point}[1] );
            $curx = $_->{point}[0];
            $cury = $_->{point}[1];
        }
        # vertical line
        if ( $_->{svg_key} =~ m{\A[vV]\z}i ) {
            $self->line( $curx, $_->{y} );
            $cury = $_->{y};
        }
        # horizontal line
        if ( $_->{svg_key} =~ m{\A[hH]\z}i ) {
            $self->line( $_->{x}, $cury );
            $curx = $_->{x};
        }
        # Z has no parameters
        if ( $_->{svg_key} =~ m{\A[zZ]\z}i ) {
            $self->line( $x, $y );
            $curx = $x;
            $cury = $y;
        }
        # cubic bezier
        if ( $_->{svg_key} =~ m{\A[cC]\z}i ) {
            ( $xa, $ya ) = $self->currentpoint();
            $self->curve(
                $xa, $ya,
                $_->{control1}[0],
                $_->{control1}[1],
                $_->{control2}[0],
                $_->{control2}[1],
                $_->{end}[0], $_->{end}[1]
            );
            $curx = $_->{end}[0];
            $cury = $_->{end}[1];
        }
        # quadratic bezier
        if ( $_->{svg_key} =~ m{\A[qQ]\z}i ) {
            ( $xa, $ya ) = $self->currentpoint();
            $self->curve(
                $xa, $ya,
                $_->{control}[0],
                $_->{control}[1],
                $_->{end}[0], $_->{end}[1]
            );
            $curx = $_->{end}[0];
            $cury = $_->{end}[1];
        }
        # continue bezier s/S command
        # we won't see s or S because of the no_smooth option
        if ( $_->{svg_key} =~ m{\A[sS]\z}i ) {
            if ($self->{check}) {
                print STDOUT "path internal error: s or S command found\n"
            }
        }
        # continue bezier t/T command
        # we won't see t or T because of the no_smooth option
        if ( $_->{svg_key} =~ m{\A[tT]\z}i ) {
            if ($self->{check}) {
                print STDOUT "path internal error: t or T command found\n"
            }
        }
        # arc
        # arc parameters are: rx, ry, x_axis_rotation, large_arc_flag, sweep_flag, x, y
        if ( $_->{svg_key} =~ m{\A[aA]\z}i ) {
            ( $xa, $ya ) = $self->currentpoint();
            $self->_a2c( $xa, $ya, $_->{rx}, $_->{ry}, $_->{x_axis_rotation},
                $_->{large_arc_flag}, $_->{sweep_flag}, $_->{x}, $_->{y} );
            $curx = $_->{x};
            $cury = $_->{y};
        }
    }    # for (@r)
    return 1;
}

sub _dotransform {
    my ( $self, $t ) = @_;
    # parse the transform string, create array of hashes
    my $tr = Image::SVG::Transform->new();
    $tr->extract_transforms($t);
    my @tra = @{ $tr->transforms };   # copy of internal array, for convenience
    # go through the transforms and apply them
    for (@tra) {
        if ( $_->{type} eq 'translate' ) {
            my $tx = $_->{params}->[0];
            my $ty = defined $_->{params}->[1] ? $_->{params}->[1] : 0;
            $self->translate( $tx, $ty );
        }
        elsif ( $_->{type} eq 'scale' ) {
            my $sx = $_->{params}->[0];
            my $sy = defined $_->{params}->[1] ? $_->{params}->[1] : $sx;
            $self->scale( $sx, $sy );
        }
        elsif ( $_->{type} eq 'rotate' ) {
            my $angle = $_->{params}->[0];
            $self->rotate($angle);
        }
        elsif ( $_->{type} eq 'skewX' ) {
            my $angle = $_->{params}->[0];
            $self->skewX($angle);
        }
        elsif ( $_->{type} eq 'skewY' ) {
            my $angle = $_->{params}->[0];
            $self->skewY($angle);
        }
        elsif ( $_->{type} eq 'matrix' ) {    # we'll do this one ourselves
            my $p      = $_->{params};
            my @matrix = (
                [ $p->[0], $p->[2], $p->[4], ],
                [ $p->[1], $p->[3], $p->[5], ],
                [ 0,       0,       1, ],
            );
            $self->_premulmat( \@matrix, \@{ $self->{CTM} } );
        }
    }
    return 1;
}

#----------------------------------------------------------------------------------

# SVG path: arc implementation

# converted from a javascript module found on github ('svgpath')
# Convert an arc to a sequence of cubic bézier curves
# the call was: new_segments = _a2c(x, y, nextX, nextY, s[4], s[5], s[1], s[2], s[3]);
# s = array of path values, 7 elements, s[0] = 'a' or 'A'
# everything converted to absolute
# (x,y) is current point, (nextx,nexty) is endpoint.

# Calculate an angle between two unit vectors.
# Since we measure angle between radii of circular arcs,
# we can use simplified math (without length normalization)
#
sub _unit_vector_angle {
    my ( $ux, $uy, $vx, $vy ) = @_;
    my $sign = ( $ux * $vy - $uy * $vx < 0 ) ? -1 : 1;
    my $dot  = $ux * $vx + $uy * $vy;
    # Add this to work with arbitrary vectors:
    $dot /= sqrt( $ux * $ux + $uy * $uy ) * sqrt( $vx * $vx + $vy * $vy );
    # rounding errors, e.g. -1.0000000000000002 can screw up this
    if ( $dot > 1.0 )  { $dot = 1.0; }
    if ( $dot < -1.0 ) { $dot = -1.0; }
    return $sign * acos($dot);
}

# Convert from endpoint to center parameterization,
# see http:#www.w3.org/TR/SVG11/implnote.html#ArcImplementationNotes
# Return [cx, cy, theta1, delta_theta]
sub _get_arc_center {
    my ( $x1, $y1, $x2, $y2, $fa, $fs, $rx, $ry, $sin_phi, $cos_phi ) = @_;
    # Step 1.
    #
    # Moving an ellipse so origin will be the middlepoint between our two
    # points. After that, rotate it to line up ellipse axes with coordinate
    # axes.
    my $x1p    = $cos_phi * ( $x1 - $x2 ) / 2 + $sin_phi * ( $y1 - $y2 ) / 2;
    my $y1p    = -$sin_phi * ( $x1 - $x2 ) / 2 + $cos_phi * ( $y1 - $y2 ) / 2;
    my $rx_sq  = $rx * $rx;
    my $ry_sq  = $ry * $ry;
    my $x1p_sq = $x1p * $x1p;
    my $y1p_sq = $y1p * $y1p;
    # Step 2.
    #
    # Compute coordinates of the centre of this ellipse (cx', cy')
    # in the new coordinate system.
    my $radicant =
      ( $rx_sq * $ry_sq ) - ( $rx_sq * $y1p_sq ) - ( $ry_sq * $x1p_sq );

    if ( $radicant < 0 ) {

        # due to rounding errors it might be e.g. -1.3877787807814457e-17
        $radicant = 0;
    }
    $radicant /= ( $rx_sq * $y1p_sq ) + ( $ry_sq * $x1p_sq );
    $radicant = sqrt($radicant) * ( $fa == $fs ? -1 : 1 );
    my $cxp = $radicant * $rx / $ry * $y1p;
    my $cyp = $radicant * -$ry / $rx * $x1p;
    # Step 3.
    #
    # Transform back to get centre coordinates (cx, cy) in the original
    # coordinate system.
    my $cx = $cos_phi * $cxp - $sin_phi * $cyp + ( $x1 + $x2 ) / 2;
    my $cy = $sin_phi * $cxp + $cos_phi * $cyp + ( $y1 + $y2 ) / 2;
    # Step 4.
    #
    # Compute angles (theta1, delta_theta).
    my $v1x         = ( $x1p - $cxp ) / $rx;
    my $v1y         = ( $y1p - $cyp ) / $ry;
    my $v2x         = ( -$x1p - $cxp ) / $rx;
    my $v2y         = ( -$y1p - $cyp ) / $ry;
    my $theta1      = _unit_vector_angle( 1,    0,    $v1x, $v1y );
    my $delta_theta = _unit_vector_angle( $v1x, $v1y, $v2x, $v2y );
    if ( $fs == 0 && $delta_theta > 0 ) {
        $delta_theta -= $TWOPI;
    }
    if ( $fs == 1 && $delta_theta < 0 ) {
        $delta_theta += $TWOPI;
    }
    return ( $cx, $cy, $theta1, $delta_theta );
}

# Approximate one unit arc segment with bézier curves,
# see http:#math.stackexchange.com/questions/873224
sub _approximate_unit_arc {
    my ( $theta1, $delta_theta ) = @_;
    my $alpha = 4 / 3 * tan( $delta_theta / 4 );
    my $x1    = cos $theta1;
    my $y1    = sin $theta1;
    my $x2    = cos( $theta1 + $delta_theta );
    my $y2    = sin( $theta1 + $delta_theta );
    return (
        $x1, $y1,
        $x1 - $y1 * $alpha,
        $y1 + $x1 * $alpha,
        $x2 + $y2 * $alpha,
        $y2 - $x2 * $alpha,
        $x2, $y2
    );
}

sub _a2c {
    my ( $self, $x1, $y1, $rx, $ry, $phi, $fa, $fs, $x2, $y2 ) = @_;
    my $sin_phi = sin( $phi * $TWOPI / 360 );
    my $cos_phi = cos( $phi * $TWOPI / 360 );
    # Make sure radii are valid
    my $x1p = $cos_phi * ( $x1 - $x2 ) / 2 + $sin_phi * ( $y1 - $y2 ) / 2;
    my $y1p = -$sin_phi * ( $x1 - $x2 ) / 2 + $cos_phi * ( $y1 - $y2 ) / 2;
    if ( $x1p == 0 && $y1p == 0 ) {
        # we're asked to draw line to itself
        return (0);
    }
    if ( $rx == 0 || $ry == 0 ) {
        # one of the radii is zero
        return (0);
    }
    # Compensate out-of-range radii
    $rx = abs $rx;
    $ry = abs $ry;
    my $lambda =
      ( $x1p * $x1p ) / ( $rx * $rx ) + ( $y1p * $y1p ) / ( $ry * $ry );
    if ( $lambda > 1 ) {
        $rx *= sqrt $lambda;
        $ry *= sqrt $lambda;
    }
    # Get center parameters (cx, cy, theta1, delta_theta)
    my @cc = _get_arc_center( $x1, $y1, $x2, $y2, $fa, $fs, $rx, $ry, $sin_phi,
        $cos_phi );
    my $result      = ();
    my $theta1      = $cc[2];
    my $delta_theta = $cc[3];
    # Split an arc to multiple segments, so each segment
    # will be less than pi/4 (= 90°)
    my $segments = max( ceil( abs($delta_theta) / ( $TWOPI / 4 ) ), 1 );
    $delta_theta /= $segments;
    for ( my $i = 0 ; $i < $segments ; $i++ ) {
        my @curve = _approximate_unit_arc( $theta1, $delta_theta );
        # We have a bezier approximation of a unit circle,
        # now need to transform back to the original ellipse
        for ( my $j = 0 ; $j < scalar @curve ; $j += 2 ) {
            my $x = $curve[ $j + 0 ];
            my $y = $curve[ $j + 1 ];
            # scale
            $x *= $rx;
            $y *= $ry;
            # rotate
            my $xp = $cos_phi * $x - $sin_phi * $y;
            my $yp = $sin_phi * $x + $cos_phi * $y;
            # translate
            $curve[ $j + 0 ] = $xp + $cc[0];
            $curve[ $j + 1 ] = $yp + $cc[1];
        }
        $self->curve(@curve);
        $theta1 += $delta_theta;    # next segment
    }    # for i
    return 1;
}

#------------------------------------------------------------------------------------

# Postscript output
sub exporteps {
    my $self  = shift;
    my $gcout = shift || die 'outputpeps: need filename';
    my $op    = $EMPTY_STR;                                 # current op
    my $xn    = $EMPTY_STR;                                 # current x coord
    my $yn    = $EMPTY_STR;                                 # current y coord
    my $maxx  = 0.0;
    my $maxy  = 0.0;
    my $minx  = 100.0;
    my $miny  = 100.0;
    my $linecount = 0;
    my ( $x, $y, $line );
    $self->_flushPsegments();
    my $limit     = scalar @{ $self->{currentpage} };
    open( my $out, '>', $gcout ) or croak "cannot open output file $gcout";
    # process the header
    HEADER:
    while (1) {
        $linecount++;
        $line = $self->{currentpage}[ $linecount - 1 ];
        last HEADER
            if ( $line eq $self->{penupcmd} );     # better make sure it's there
    }
    # start the output
    # should really add a trailer here, but that's not ideal
    print {$out} "%!PS-Adobe-3.0 EPSF-3.0$EOL";
    print {$out} "%%BoundingBox: (atend)$EOL";
    if ($self->{papersize} eq "4A0") {
        print {$out} "%%Orientation: Portrait$EOL";
        print {$out} "%%DocumentMedia: 4a0 4768 6741 80 () ()$EOL";
        print {$out} "%%BeginSetup$EOL";
        print {$out} "<< /PageSize [4768 6741] /Orientation 0 >> setpagedevice$EOL";
        print {$out} "%%EndSetup$EOL";
    }
    elsif ($self->{papersize} eq "2A0") {
        print {$out} "%%Orientation: Portrait$EOL";
        print {$out} "%%DocumentMedia: 2a0 3370  4768 80 () ()$EOL";
        print {$out} "%%BeginSetup$EOL";
        print {$out} "<< /PageSize [3370 4768] /Orientation 0 >> setpagedevice$EOL";
        print {$out} "%%EndSetup$EOL";
    }
    elsif ($self->{papersize} eq "A0") {
        print {$out} "%%Orientation: Portrait$EOL";
        print {$out} "%%DocumentMedia: a0 2384 3370 80 () ()$EOL";
        print {$out} "%%BeginSetup$EOL";
        print {$out} "<< /PageSize [2384 3370] /Orientation 0 >> setpagedevice$EOL";
        print {$out} "%%EndSetup$EOL";
    }
    elsif ($self->{papersize} eq "A1") {
        print {$out} "%%Orientation: Portrait$EOL";
        print {$out} "%%DocumentMedia: a1 1684 2384 80 () ()$EOL";
        print {$out} "%%BeginSetup$EOL";
        print {$out} "<< /PageSize [1684 2384] /Orientation 0 >> setpagedevice$EOL";
        print {$out} "%%EndSetup$EOL";
    }
    elsif ($self->{papersize} eq "A2") {
        print {$out} "%%Orientation: Portrait$EOL";
        print {$out} "%%DocumentMedia: a2 1191 1684 80 () ()$EOL";
        print {$out} "%%BeginSetup$EOL";
        print {$out} "<< /PageSize [1191 1684] /Orientation 0 >> setpagedevice$EOL";
        print {$out} "%%EndSetup$EOL";
    }
    elsif ($self->{papersize} eq "A3") {
        print {$out} "%%Orientation: Portrait$EOL";
        print {$out} "%%DocumentMedia: a3 842 1191 80 () ()$EOL";
        print {$out} "%%BeginSetup$EOL";
        print {$out} "<< /PageSize [842 1191] /Orientation 0 >> setpagedevice$EOL";
        print {$out} "%%EndSetup$EOL";
    }
    elsif ($self->{papersize} eq "A4") {
        print {$out} "%%Orientation: Portrait$EOL";
        print {$out} "%%DocumentMedia: a4 595 842 80 () ()$EOL";
        print {$out} "%%BeginSetup$EOL";
        print {$out} "<< /PageSize [595 842] /Orientation 0 >> setpagedevice$EOL";
        print {$out} "%%EndSetup$EOL";
    }
    while ( $linecount < $limit ) {
        $linecount++;
        $line = $self->{currentpage}[ $linecount - 1 ];
        ( $op, $xn, $yn ) = $self->_parse($line);    # xn and yn in inches
        if ( $op eq $G00 || $op eq $G01 ) {          # find the bounding box
            $x = 0.0 + $xn;
            $y = 0.0 + $yn;
            if ( $x > $maxx )             { $maxx = $x }
            if ( $y > $maxy )             { $maxy = $y }
            if ( $x < $minx && $x > 0.0 ) { $minx = $x }
            if ( $y < $miny && $y > 0.0 ) { $miny = $y }
        }
        # now the postscript
        if ( $op eq $PU ) {
            print {$out} "stroke\n";
        }
        if ( $op eq $PD ) {
            # newpath needs to go before the moveto, see next lines
            # the PD always comes *after* the G00
        }
        if ( $op eq $G00 ) {
            print {$out} 'newpath '
                . $xn * $I2P
                . $SPACE
                . $yn * $I2P
                . " moveto\n";
        }
        if ( $op eq $G01 ) {
            print {$out} $xn * $I2P . $SPACE . $yn * $I2P . " lineto\n";
        }
    }
    # the stroke command added because there is no trailer (hack!)
    print {$out} 'stroke showpage' . $EOL;
    print {$out} "%%BoundingBox: "
        . $minx * $I2P . " "
        . $miny * $I2P . " "
        . $maxx * $I2P . " "
        . $maxy * $I2P
        . $EOL;
    close $out;
    if ( $self->{check} ) {
        print STDOUT sprintf "Bounding box:  (%.3f,%.3f) (%.3f,%.3f)\n",
          $minx * $I2P, $miny * $I2P, $maxx * $I2P, $maxy * $I2P;
        $self->_checkp();
        $self->_checkl();
    }
    return 1;
}

# SVG output
sub exportsvg {
    my $self  = shift;
    my $gcout = shift || die 'exportsvg: output filename missing';
    my $op    = $EMPTY_STR;   # current op
    my $xn    = $EMPTY_STR;   # current x coord
    my $yn    = $EMPTY_STR;   # current y coord
    my $maxx  = 0.0;
    my $maxy  = 0.0;
    my $minx  = $BBMAX;
    my $miny  = $BBMAX;
    my $linecount = 0;
    my ( $x, $y, $line, $st );
    $self->_flushPsegments();
    my $limit = scalar @{ $self->{currentpage} };
    open( my $out, '>', $gcout ) or croak "exportsvg: cannot open output file $gcout";
    # process the gcode header
    HEADER:
    while (1) {
        $linecount++;
        $line = $self->{currentpage}[ $linecount - 1 ];
        last HEADER
            if ( $line eq $self->{penupcmd} );     # better make sure it's there
    }
    # collect the SVG output
    $st = $EMPTY_STR;
    while ( $linecount < $limit ) {
        $linecount++;
        $line = $self->{currentpage}[ $linecount - 1 ];
        ( $op, $xn, $yn ) = $self->_parse($line);    # xn and yn in inches
        # bounding box
        if ( $op eq $G00 || $op eq $G01 ) {
            $x = 0.0 + $xn;
            $y = 0.0 + $yn;
            if ( $x > $maxx ) { $maxx = $x }
            if ( $y > $maxy ) { $maxy = $y }
            if ( $x < $minx ) { $minx = $x }
            if ( $y < $miny ) { $miny = $y }
        }
        # now the SVG path
        if ( $op eq $G01 ) { # the most common case
            $st .= 'L' 
                . ($xn * $I2P)
                . $SPACE 
                . ($yn * $I2P) 
                . $SPACE
        }
        elsif ( $op eq $G00 ) {
            $st .= 'M'
                . ($xn * $I2P)
                . $SPACE
                . ($yn * $I2P)
                . $SPACE
        }
        # ignore PU and PD
    }
    # now print the output:
    # first the header
    my $hdr = "<svg". $EOL;
                $hdr .= "xmlns='http://www.w3.org/2000/svg'>" . $EOL;
                $hdr .= "<path style='fill:white; fill-opacity:0; stroke:black; " . $EOL;
                $hdr .= "stroke-opacity:1; stroke-width: 0.5'" . $EOL;
                $hdr .= "d=\"";
    print {$out} $hdr;

    # body, split long lines
    my $max_length = 120;
    while (length($st) > $max_length) {
        my $chunk = substr($st, 0, $max_length);
        my $break_point = rindex($chunk, ' ');    # find a space on the right
        if ($break_point == -1) {    # if there isn't, just print it
            $break_point = $max_length;
        }
        my $line = substr($st, 0, $break_point, '');
        print {$out} $line, $EOL;
        $st =~ s/^\s+//;  # trim leading spaces
    }
    print {$out} $st, $EOL if $st;  # any remaining chars 

    # trailer
    my $trl = "\"/></svg> ";
    print {$out} $trl . $EOL;
    # finished
    close $out;
    # print the bounding box
    $minx *= $I2P;
    $miny *= $I2P;
    $maxx *= $I2P;
    $maxy *= $I2P;
    if ($self->{check}) {
        print STDOUT "exportsvg: $gcout: bounding box = ($minx,$miny)pt ($maxx,$maxy)pt". $EOL
    }
    return ($minx, $miny, $maxx, $maxy);
}

# parsing of instruction
sub _parse {
    my ( $self, $ss ) = @_;
    my ( $opp, $x, $xcoord, $y, $ycoord, $rest );
    # some lines can be ignored
    if ( $ss =~ m{\A\s*\z} ) { return ( $NOOP, 0, 0 ) }    # ignore empty line
    if ( $ss =~ m{\A\s*\N{LEFT PARENTHESIS}} ) {
        return ( $NOOP, 0, 0 );
    }                                                      # ignore comment line
    # do some standardization, different tools have different gcode formats
    $ss =~ s{X}{X\N{SPACE}};     # in case there is no space after X or Y or Z
    $ss =~ s{Y}{Y\N{SPACE}};
    $ss =~ s{Z0}{Z\N{SPACE}0};
    $ss =~ s{G0\N{SPACE}}{G00\N{SPACE}};    # G0 equivalent to G00
    $ss =~ s{G1\N{SPACE}}{G01\N{SPACE}};    # G1 equivalent to G01
    $ss =~ s{\N{SPACE}\N{FULL STOP}000}{\N{SPACE}0\N{FULL STOP}000}g;  # turns .0 into 0.0
    ( $opp, $x, $xcoord, $y, $ycoord, $rest ) = split( / +/, $ss );    # split on multiple spaces
    if ( $ss eq $self->{penupcmd} ) {
        return ( $PU, '0', '0' );
    }
    if ( $ss =~ m{G00\N{SPACE}Z\N{SPACE}} || $ss =~ m{G01\N{SPACE}Z\N{SPACE}} )
    {
        return ( $PD, '0', '0' );
    }
    if ( $opp eq 'G00' ) {
        return ( $G00, $xcoord, $ycoord );
    }
    if ( $opp eq 'G01' ) {
        return ( $G01, $xcoord, $ycoord );
    }
    # the user can insert own instruction, e.g. in header - we should not complain about that
    # if ($self->{check}) {print STDOUT "parse: unknown instruction \"$ss\""}
    return ( $NOOP, 0, 0 );
}

#
# for convenience
#
sub _fprintf {
    my $info = shift;
    print STDOUT "$info: ";
    foreach (@_) {
        printf STDOUT "%5.2f ", $_
    }
    print STDOUT $EOL;
    return 1;
}

#----------------------------------------------------------------------------------

my $optline = 0;

# Path segment peephole optimization.
# this should be applied immediately before gcode generation.
sub _optimize {
    my $self = shift;
    my ( $op, $xs, $ys, $xn, $yn, $tmpx, $tmpy, $tmpx2, $tmpy2, $xd, $yd );
    my ( $before, $after, $line, $rest );
    if ( !$self->{optimize} ) { return 0 }    # user does not want optimization
    $line    = $OPTLOW;
    $optline = $OPTLOW-1;
    $rest    = scalar @{ $self->{psegments} } - $OPTLOW;   # remaining line count
    $before  = $rest + $OPTLOW;                            # for stats
    INSTRUCTION:
    while ( $rest > 0 ) {    # do one pass over the instructions
        ( $op, $xs, $ys, $xd, $yd ) = $self->_curseg($line);
        $tmpx  = $xs;
        $tmpy  = $ys;        # extra copy of the original sequence
        $tmpx2 = $xd;
        $tmpy2 = $yd;
        $optline++;
        if ($self->{opt_debug}) {
            print STDOUT $EOL;
            $self->_prPseg($line+0);
            $self->_prPseg($line+1);
            $self->_prPseg($line+2);
            $self->_prPseg($line+3);
            $self->_prPseg($line+4);
            $self->_prPseg($line+5);
        }

        # Pattern 10:
        # (0) line from (a,b) to (c,d)
        # (1) line from (c,d) to (c,d)
        # (2) line from (c,d) to (a,b)
        # (3) penup
        # (4) move from (a,b) to (e,f)
        # We need to turn this into
        # (0) line from (a,b) to (c,d)
        # (1) penup
        # (2) move from (c,d) to (e,f)
        if ( $self->_pattern10( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[$optline opt pattern 10] ";
            }
            my $c = $self->{psegments}[ $line + 0 ]{dx};
            my $d = $self->{psegments}[ $line + 0 ]{dy};
            $self->_keep( \$line, \$rest );    # first line ok
            $self->_drop( $line, \$rest );     # useless line
            $self->_drop( $line, \$rest );     # useless line
            $self->_keep( \$line, \$rest );    # keep the penup
            $self->_fastmove(
                $line, $c, $d,
                $self->{psegments}[ $line + 0 ]{dx},
                $self->{psegments}[ $line + 0 ]{dy}
            );
            if ($self->{opt_debug}) {
                print STDOUT $EOL;
            }
            next INSTRUCTION;
        }

        # Pattern 1:
        # here we are looking for the following pattern:
        #  (0)    move from (x,y) to (a,b)
        #  (1)    pen down
        #  (2)    line from (a,b) to (c,d)
        #  (3)    line from (c,d) to (a,b)
        #  (4)    pen up
        # (i.e. lines that are drawn twice, some single line fonts do this)
        # we want to turn this into
        #  (0)    move from (x,y) to (c,d)
        #  (1)    pen down
        #  (2)    line from (c,d) to (a,b)
        #  (3)    pen up
        # The check for PD is made to ensure we don't leave ourselves
        # in the wrong place after the delete
        if ( $self->_pattern1( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[line $optline pattern 1] $EOL"
            }
            $tmpx2 = $self->{psegments}[ $line + 2 ]{dx};
            $tmpy2 = $self->{psegments}[ $line + 2 ]{dy};

            # c,d held in tmpx2,tmpy2
            $self->_fastmove( $line, $xd, $yd, $tmpx2, $tmpy2 );
            $self->_keep( \$line, \$rest );    # flush the generated fastmove
            $self->_keep( \$line, \$rest );    # flush the pendown
            $self->_drop( $line, \$rest );     # get rid of the first draw
            $self->_keep( \$line, \$rest );    # flush the second draw
                # now reset the window pointer just in case we've introduced
                # a new optimizable sequence
            $self->_adjust( \$line, \$rest );
            if ($self->{opt_debug}) {
                print STDOUT $EOL
            }
            next INSTRUCTION;
        }


        # Pattern 3:
        # here we are looking for the following pattern:
        #      line from (x,y) to (a,b)
        #      pen up
        #      move from (a,b) to (a,b)
        #      pen down
        # we want to turn this into
        #      line from (x,y) to (a,b)
        # this pattern is the result of changes made in pattern 1
        if ( $self->_pattern3( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[line $optline pattern 3] $EOL"
            }
            $self->_keep( \$line, \$rest );    # keep the first draw
            $self->_drop( $line, \$rest );     # get rid of PU
            $self->_drop( $line, \$rest );     # get rid of move
            $self->_drop( $line, \$rest );     # get rid of PD
            $self->_adjust( \$line, \$rest );
            if ($self->{opt_debug}) {
                print STDOUT $EOL
            }
            next INSTRUCTION;
        }

        # Pattern 2:
        # here we are looking for the following pattern:
        #   (0)   line from (x,y) to (a,b = xd,yd)
        #   (1)   pen up
        #   (2)   move from (a,b) to (c,d)
        #   (3)   pen down
        #   (4)   line from (c,d) to (a,b)
        #   (5)   pen up
        #         (the pen is at a,b)
        # we want to turn this into
        #   (0)   line from (x,y) to (a,b)
        #   (1)   line from (a,b) to (c,d)
        #   (2)   pen up
        #         (we're at c,d - modify the source of the next instruction if necessary)
        # The check for PU is made to ensure we don't leave ourselves
        # in the wrong place after the delete
        if ( $self->_pattern2( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[line $optline pattern 2] $EOL"
            }
            $self->_keep( \$line, \$rest );    # flush the first draw
            $self->_drop( $line, \$rest );     # get rid of the first PU
            $tmpx2 = $self->{psegments}[ $line + 0 ]{dx};
            $tmpy2 = $self->{psegments}[ $line + 0 ]{dy};

            # a,b held in xd,yd
            # c,d held in tmpx2,tmpy2
            $self->_slowmove( $line, $xd, $yd, $tmpx2, $tmpy2 );
            $self->_keep( \$line, \$rest );    # flush the slow move
            $self->_drop( $line, \$rest );     # get rid of the PD
            $self->_drop( $line, \$rest );     # get rid of the second draw
            # the following gcode is affected - the source of the segment after the PU
            # is now incorrect. This is not a major disaster, but will affect the stats.
            # Let's try and fix it.
            NEXT4:
            for my $i ( 1 .. 4 ) {    # look at the next 4 instructions (max)
                # if we find a move, and the start is shown as (a,b), change it to (c,d).
                if (   $self->{psegments}[ $line + $i ]{key} eq 'm'
                    || $self->{psegments}[ $line + $i ]{key} eq 'l' )
                {
                    if (   $self->{psegments}[ $line + $i ]{sx} == $xd
                        && $self->{psegments}[ $line + $i ]{sy} == $yd )
                    {
                        $self->{psegments}[ $line + $i ]{sx} = $tmpx2;
                        $self->{psegments}[ $line + $i ]{sy} = $tmpy2;
                        last NEXT4;
                    }
                }
            }
            $self->_adjust( \$line, \$rest );
            if ($self->{opt_debug}) {
                print STDOUT $EOL
            }
            next INSTRUCTION;
        }

        # two moves to the same location - delete one. Example from pyth45:
        # pen up
        # move from (x,y) to (a,b)
        # pen down
        # pen up
        # move from (a,b) to (a,b)
        # pen down
        #  - Delete the last 3 instructions
        if ( $self->_pattern4( $line, $rest ) ) {
            $self->_keep( \$line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_drop( $line, \$rest );
            $self->_drop( $line, \$rest );
            $self->_drop( $line, \$rest );
            $self->_adjust( \$line, \$rest );
            next INSTRUCTION;
        }

        # two consecutive fast moves - delete one.
        # pen up
        # move to (a,b)
        # pen down
        # pen up
        # move to (c,d)
        # pen down
        #  - Delete the first 3 instructions
        #  - copy the source of the first move to the second move
        if ( $self->_pattern11( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[line $optline pattern 11] $EOL"
            }
            $self->{psegments}[ $line + 4 ]{sx} = $self->{psegments}[ $line + 1 ]{sx};
            $self->{psegments}[ $line + 4 ]{sy} = $self->{psegments}[ $line + 1 ]{sy};
            $self->_drop( $line, \$rest );
            $self->_drop( $line, \$rest );
            $self->_drop( $line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ($self->{opt_debug}) {
                print STDOUT $EOL
            }
            next INSTRUCTION;
        }

        # Pattern 5: PU/PD. Delete both.
        if ( $self->_pattern5( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[line $optline pattern 5] $EOL"
            }
            $self->_drop( $line, \$rest );
            $self->_drop( $line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ($self->{opt_debug}) {
                print STDOUT $EOL
            }
            next INSTRUCTION;
        }

        # Pattern 8: PD/PU. Delete both.
        if ( $self->_pattern8( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[line $optline pattern 8] $EOL"
            }
            $self->_drop( $line, \$rest );
            $self->_drop( $line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ($self->{opt_debug}) {
                print STDOUT $EOL
            }
            next INSTRUCTION;
        }

        # Pattern 6: PU/PU. Delete one.
        if ( $self->_pattern6( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[line $optline pattern 6] $EOL"
            }
            $self->_drop( $line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ($self->{opt_debug}) {
                print STDOUT $EOL
            }
            next INSTRUCTION;
        }

        # Pattern 7: PD/PD. Delete one.
        if ( $self->_pattern7( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[line $optline pattern 7] $EOL"
            }
            $self->_drop( $line, \$rest );
            $self->_keep( \$line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ($self->{opt_debug}) {
                print STDOUT $EOL
            }
            next INSTRUCTION;
        }

        # Pattern 9: m/l where source and dest are the same. Delete.
        if ( $self->_pattern9( $line, $rest ) ) {
            if ($self->{opt_debug}) {
                print STDOUT "[line $optline pattern 9] $EOL"
            }
            $self->_drop( $line, \$rest );
            $self->_adjust( \$line, \$rest );
            if ($self->{opt_debug}) {
                print STDOUT $EOL
            }
            next INSTRUCTION;
        }

        # if we get here, no patterns were matched. Move forward.
        $line++;
        $rest--;
    } # while
    if ( $self->{check} ) {
        $after = scalar @{ $self->{psegments} };
        print STDOUT 'optimization removed '
            . ( $before - $after )
            . " instructions\n"
    }
    return 1;
}

# The patterns.
# Note that the order in which these are executed matters: generally start with the longest.

sub _pattern1 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 5 ) { return 0 }
    if (
            ( $self->{psegments}[ $line + 0 ]{key} eq 'm' )
        &&  ( $self->{psegments}[ $line + 1 ]{key} eq 'd' )
        &&  ( $self->{psegments}[ $line + 2 ]{key} eq 'l' )
        &&  ( $self->{psegments}[ $line + 3 ]{key} eq 'l' )
        &&  ( $self->{psegments}[ $line + 4 ]{key} eq 'u' )
        &&  ( $self->{psegments}[ $line + 3 ]{dx} == $self->{psegments}[ $line + 0 ]{dx} )
        &&  ( $self->{psegments}[ $line + 3 ]{dy} == $self->{psegments}[ $line + 0 ]{dy} ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern2 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 6 ) { return 0 }
    if (
            ( $self->{psegments}[ $line + 0 ]{key} eq 'l' )
        &&  ( $self->{psegments}[ $line + 1 ]{key} eq 'u' )
        &&  ( $self->{psegments}[ $line + 2 ]{key} eq 'm' )
        &&  ( $self->{psegments}[ $line + 3 ]{key} eq 'd' )
        &&  ( $self->{psegments}[ $line + 4 ]{key} eq 'l' )
        &&  ( $self->{psegments}[ $line + 5 ]{key} eq 'u' )
        &&  ( $self->{psegments}[ $line + 4 ]{dx} ==  $self->{psegments}[ $line + 0 ]{dx} )
        &&  ( $self->{psegments}[ $line + 4 ]{dy} ==  $self->{psegments}[ $line + 0 ]{dy} ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern10 {
    my ( $self, $line, $rest ) = @_;
    my ( $a, $b, $c, $d );
    if ( $rest < 5 ) { return 0 }
    $a = $self->{psegments}[ $line + 0 ]{sx};
    $b = $self->{psegments}[ $line + 0 ]{sy};
    $c = $self->{psegments}[ $line + 0 ]{dx};
    $d = $self->{psegments}[ $line + 0 ]{dy};
    if (   ( $self->{psegments}[ $line + 0 ]{key} eq 'l' )
        && ( $self->{psegments}[ $line + 1 ]{key} eq 'l' )
        && ( $self->{psegments}[ $line + 2 ]{key} eq 'l' )
        && ( $self->{psegments}[ $line + 3 ]{key} eq 'u' )
        && ( $self->{psegments}[ $line + 4 ]{key} eq 'm' )
        && ( $self->{psegments}[ $line + 1 ]{sx} == $c )
        && ( $self->{psegments}[ $line + 1 ]{sy} == $d )
        && ( $self->{psegments}[ $line + 1 ]{dx} == $c )
        && ( $self->{psegments}[ $line + 1 ]{dy} == $d )
        && ( $self->{psegments}[ $line + 2 ]{sx} == $c )
        && ( $self->{psegments}[ $line + 2 ]{sy} == $d )
        && ( $self->{psegments}[ $line + 2 ]{dx} == $a )
        && ( $self->{psegments}[ $line + 2 ]{dy} == $b ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern3 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 4 ) { return 0 }
    if (
            ( $self->{psegments}[ $line + 0 ]{key} eq 'l' )
        &&  ( $self->{psegments}[ $line + 1 ]{key} eq 'u' )
        &&  ( $self->{psegments}[ $line + 2 ]{key} eq 'm' )
        &&  ( $self->{psegments}[ $line + 3 ]{key} eq 'd' )
        &&  ( $self->{psegments}[ $line + 2 ]{dx} == $self->{psegments}[ $line + 0 ]{dx} )
        &&  ( $self->{psegments}[ $line + 2 ]{dy} == $self->{psegments}[ $line + 0 ]{dy} ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern4 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 6 ) { return 0 }
    if (
            ( $self->{psegments}[ $line + 0 ]{key} eq 'u' )
        &&  ( $self->{psegments}[ $line + 3 ]{key} eq 'u' )
        &&  ( $self->{psegments}[ $line + 2 ]{key} eq 'd' )
        &&  ( $self->{psegments}[ $line + 5 ]{key} eq 'd' )
        &&  ( $self->{psegments}[ $line + 1 ]{key} eq 'm' )
        &&  ( $self->{psegments}[ $line + 4 ]{key} eq 'm' )
        &&  ( $self->{psegments}[ $line + 1 ]{dx} == $self->{psegments}[ $line + 4 ]{dx} )
        &&  ( $self->{psegments}[ $line + 1 ]{dy} == $self->{psegments}[ $line + 4 ]{dy} ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern11 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 6 ) { return 0 }
    if (
            ( $self->{psegments}[ $line + 0 ]{key} eq 'u' )
        &&  ( $self->{psegments}[ $line + 3 ]{key} eq 'u' )
        &&  ( $self->{psegments}[ $line + 2 ]{key} eq 'd' )
        &&  ( $self->{psegments}[ $line + 5 ]{key} eq 'd' )
        &&  ( $self->{psegments}[ $line + 1 ]{key} eq 'm' )
        &&  ( $self->{psegments}[ $line + 4 ]{key} eq 'm' ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern5 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 2 ) { return 0 }
    if (   ( $self->{psegments}[ $line + 0 ]{key} eq 'u' )
        && ( $self->{psegments}[ $line + 1 ]{key} eq 'd' ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern6 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 2 ) { return 0 }
    if (   ( $self->{psegments}[ $line + 0 ]{key} eq 'u' )
        && ( $self->{psegments}[ $line + 1 ]{key} eq 'u' ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern7 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 2 ) { return 0 }
    if (   ( $self->{psegments}[ $line + 0 ]{key} eq 'd' )
        && ( $self->{psegments}[ $line + 1 ]{key} eq 'd' ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern8 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 2 ) { return 0 }
    if (   ( $self->{psegments}[ $line + 0 ]{key} eq 'd' )
        && ( $self->{psegments}[ $line + 1 ]{key} eq 'u' ) )
    {
        return 1;
    }
    return 0;
}

sub _pattern9 {
    my ( $self, $line, $rest ) = @_;
    if ( $rest < 1 ) { return 0 }
    if (
        (
            ( $self->{psegments}[ $line + 0 ]{key} eq 'm' )
            || ( $self->{psegments}[ $line + 0 ]{key} eq 'l' )
        )
        && ( $self->{psegments}[ $line + 0 ]{sx} ==
            $self->{psegments}[ $line + 0 ]{dx} )
        && ( $self->{psegments}[ $line + 0 ]{sy} ==
            $self->{psegments}[ $line + 0 ]{dy} ) )
    {
        return 1;
    }
    return 0;
}

#
# Adjust the window pointer after a match.
# We reset the window pointer by the length of the longest pattern, just in case
# an optimization has resulted in a pattern that can be further optimized (see
# Tanenbaum's EM paper).
# We also exclude the first few instructions from optimization because they are
# dependent upon the user's manual setting of the pen, so are not the result of
# any actions in this library.
sub _adjust {
    my ( $self, $lref, $rref ) = @_;
    my $len = scalar @{ $self->{psegments} };
    ${$lref} -= $LONGEST;
    ${$rref} = $len - $$lref;
    if ( ${$lref} < $OPTLOW ) {
        ${$lref} = $OPTLOW;
        ${$rref} = $len - $OPTLOW;
    }
    return 1;
}

#
# return current segment, as pointed to by $line
sub _curseg {
    my ( $self, $line ) = @_;
    return (
        $self->{psegments}[$line]{key}, $self->{psegments}[$line]{sx},
        $self->{psegments}[$line]{sy},  $self->{psegments}[$line]{dx},
        $self->{psegments}[$line]{dy}
    );
}

# modify the current instruction to a slow move with the stated values
sub _slowmove {
    my ( $self, $line, $xs, $ys, $x, $y ) = @_;
    $self->{psegments}[$line]{key} = 'l';
    $self->{psegments}[$line]{sx}  = $xs;
    $self->{psegments}[$line]{sy}  = $ys;
    $self->{psegments}[$line]{dx}  = $x;
    $self->{psegments}[$line]{dy}  = $y;
    return 1;
}

# modify the current instruction to a fast move with the stated values
sub _fastmove {
    my ( $self, $line, $xs, $ys, $x, $y ) = @_;
    $self->{psegments}[$line]{key} = 'm';
    $self->{psegments}[$line]{sx}  = $xs;
    $self->{psegments}[$line]{sy}  = $ys;
    $self->{psegments}[$line]{dx}  = $x;
    $self->{psegments}[$line]{dy}  = $y;
    return 1;
}

# remove an item, pointer stays same, rest decreases
sub _drop {
    my $self = shift;
    my ( $line, $refrest ) = @_;
    if ($self->{opt_debug}) {
        print STDOUT "drop ";
        $self->_prPseg($line);
    };
    splice @{ $self->{psegments} }, $line, 1;
    ${$refrest} -= 1;
    return 1;
}

# keep an item, move the pointer, rest decreases
sub _keep {
    my $self = shift;
    my ( $line, $refrest ) = @_;
    if ($self->{opt_debug}) {
        print STDOUT "keep ";
        $self->_prPseg(${$line});
    }
    ${$line}    += 1;
    ${$refrest} -= 1;
    return 1;
}

# debugging
sub _prPseg {
    my ( $self, $index ) = @_;
    my $len = scalar @{ $self->{psegments} };
    if ( ($index > $len-1) || (!defined $self->{psegments}[$index]{key})) {
        print STDOUT "    UNDEFINED$EOL";
        return 0;
    }
    if ( $self->{psegments}[$index]{key} eq 'u' ) {
        print STDOUT "    $index: PENUP$EOL";
        return 1;
    }
    if ( $self->{psegments}[$index]{key} eq 'd' ) {
        print STDOUT "    $index: PENDOWN$EOL";
        return 1;
    }
    printf STDOUT "    %d: %s (%5.2f,%5.2f) -> (%5.2f,%5.2f)$EOL",
        $index,
        $self->{psegments}[$index]{key},
        $self->{psegments}[$index]{sx},
        $self->{psegments}[$index]{sy},
        $self->{psegments}[$index]{dx},
        $self->{psegments}[$index]{dy};
    return 1;
}

#----------------------------------------------------------------------------------

# code for cutting up a sheet into multiple smaller ones

my $location  = $IN;         # location of the virtual pen
my $penstate  = $PENUP;
my $previous  = $EMPTY_STR;  # previous line
my $prevx     = 0.0;         # previous x coord
my $prevy     = 0.0;         # previous y coord
my $prevop    = $PU;
my $current   = $EMPTY_STR;  # current line
my $currx     = 0.0;         # current x coord
my $curry     = 0.0;         # current y coord
my $curop;                   # current opcode
my $linecount = 1;           # gcode line count
my $len       = 2;           # number of instructions
my $mode;                    # portrait or landscape
my $op        = $PU;
my $xn        = $EMPTY_STR;
my $yn        = $EMPTY_STR;

my $scale;                   # scale factor, for keeping things away from paper edge. User settable.
my %corner    = ();
my %sheets    = ();
my ( $sx,      $sy );        # number of sheets in x and y direction
my ( $xoffset, $yoffset );   # adjustments for non-blhc sheets
my ( $xwhite,  $ywhite );    # whitespace margins
my ( $xlen, $ylen );         # length of subsheet

sub _sheetinfo {
    my ($self, $dest) = @_;
    $sheets{'4A0'} = { rank => 12, maxx => 66.22, maxy => 93.62 };
    $sheets{'2A0'} = { rank => 11, maxx => 46.81, maxy => 66.22 };
    $sheets{'A0'}  = { rank => 10, maxx => 33.11, maxy => 46.81 };
    $sheets{'A1'}  = { rank => 9,  maxx => 23.39, maxy => 33.11 };
    $sheets{'A2'}  = { rank => 8,  maxx => 16.54, maxy => 23.39 };
    $sheets{'A3'}  = { rank => 7,  maxx => 11.69, maxy => 16.54 };
    $sheets{'A4'}  = { rank => 6,  maxx => 8.27,  maxy => 11.69 };
    $sheets{'A5'}  = { rank => 5,  maxx => 5.83,  maxy => 8.27 };
    $sheets{'A6'}  = { rank => 4,  maxx => 4.13,  maxy => 5.83 };
    #$sheets{'A7'}  = { rank => 3,  maxx => 2.91,  maxy => 4.13 }; # deleted - excessive
    #$sheets{'A8'}  = { rank => 2,  maxx => 2.05,  maxy => 2.91 };
    #$sheets{'A9'}  = { rank => 1,  maxx => 1.45,  maxy => 2.05 };
    $scale   = 1.0 - 0.02 * $self->{margin};                       # margin specified as percentage
    $xwhite  = ( 1.0 - $scale ) * $sheets{$dest}{maxx} / 2.0;      # whitespace on the LH/RH margin
    $ywhite  = ( 1.0 - $scale ) * $sheets{$dest}{maxy} / 2.0;      # whitespace on the top/bot margin
    return 1;
}

# setup the coordinates of the corners of each sheet, used for Liang-Barsky
sub _corners {
    my ( $self, $dest ) = @_;
    my $bigsheet = $self->{papersize};
    # decide sheets in x and y direction, p or l
    my $diff = $sheets{$bigsheet}{rank} - $sheets{$dest}{rank};
    $mode = 'p';
    if ($diff % 2) {      # odd difference
        if ($diff > 1) {
            $sx = $diff - 1;
        }
        else {
            $sx = 1;
        }
        $sy = 2 * $sx;
        $mode = 'l';
    }
    else {                # even difference
        $sx = $diff;
        $sy = $diff;
        # and mode stays 'p'
    }
    # retrieve maxx and maxy. If landscape, swap x and y. Store in xlen and ylen.
    if ($mode eq 'p') {
        $xlen = $sheets{$dest}{maxx};
        $ylen = $sheets{$dest}{maxy};
    }
    else {
        $xlen = $sheets{$dest}{maxy};
        $ylen = $sheets{$dest}{maxx};
    }
    # now calculate the corners
    foreach my $i ( 0 .. $sx - 1 ) {
        foreach my $j ( 0 .. $sy - 1 ) {
            $corner{$i}{$j}{blx} = $i * $xlen;
            $corner{$i}{$j}{bly} = $j * $ylen;
            $corner{$i}{$j}{tlx} = $corner{$i}{$j}{blx};
            $corner{$i}{$j}{tly} = ( $j + 1 ) * $ylen;
            $corner{$i}{$j}{trx} = ( $i + 1 ) * $xlen;
            $corner{$i}{$j}{try} = $corner{$i}{$j}{tly};
            $corner{$i}{$j}{brx} = $corner{$i}{$j}{trx};
            $corner{$i}{$j}{bry} = $corner{$i}{$j}{bly};
        }
    }
    return 1;
}

# entry point.
sub split {
    my $self = shift;
    # check for sensible parameters
    if (scalar @_ != 2) { $self->_croak("wrong number of args for split")}
    my ( $dest, $file ) = @_;
    if (! defined $self->{papersize}) {$self->_croak("cannot split if paper size undefined")}
    # setup data for sheet sizes
    $self->_sheetinfo( $dest );
    # check that the required sheet size makes sense
    if (! defined $sheets{$dest}) {
        $self->croak("split: cannot handle sheet size: $dest")
    }
    if ($sheets{$dest}{rank} > $sheets{$self->{papersize}}{rank}) {
        $self->_croak("split: cannot split paper into LARGER pieces of paper")
    }
    if ($sheets{$dest}{rank} == $sheets{$self->{papersize}}{rank}) {
        $self->_croak("split: paper sizes are the same. Finished.");
        return 1;
    }
    $self->_corners( $dest );
    # loop through the subpages and use Liang-Barsky to assign (partial) segments
    # we distinguish between the actual pen (which is kept over the sheet)
    # and the virtual pen (which may be outside)
    foreach my $i ( 0 .. $sx - 1 ) {
        foreach my $j ( 0 .. $sy - 1 ) {
            # how far the edges of this sheet are away from the 
            # left and bottom edges of the larger sheet
            $xoffset = $corner{$i}{$j}{blx};
            $yoffset = $corner{$i}{$j}{bly};
            # need to initialize all state vars for each sheet
            if ( $i == 0 && $j == 0 ) {
                $location = $IN;
            }
            else {
                $location = $OUT;
            }
            $prevx     = 0.0;
            $prevy     = 0.0;
            $prevop    = $PU;
            $current   = $EMPTY_STR;
            $penstate  = $PENUP;
            # open a graphics object to write output file
            my $f = new GcodeXY(
                header     => $self->{header},
                trailer    => $self->{trailer},
                penupcmd   => $self->{penupcmd},
                pendowncmd => $self->{pendowncmd},
                margin     => $self->{margin},
                outfile    => $file . '_' . $i . '_' . $j . '.gcode',
            );

            my ( $x1, $y1, $x2, $y2, $info );
            # now process the instruction queue
            $len       = scalar @{$self->{currentpage}};   # the big sheet queue
            $linecount = 1;  # skip the header (which is one entry internally)
            LINE:
            while ( $linecount <= $len - 1 ) {
                $self->_setprevious( $op, $xn, $yn );
                $current = $self->{currentpage}[$linecount];
                ( $op, $xn, $yn ) = $f->_parse($current);
                # deal with pen up/down first
                if ( $op == $PU ) {
                    next LINE if ( $location == $OUT );
                    $f->do_penup();
                    next LINE;
                }
                if ( $op == $PD ) {
                    next LINE if ( $location == $OUT );
                    $f->do_pendown();
                    next LINE;
                }
                # G00 or G01
                ( $x1, $y1, $x2, $y2, $info ) = $f->_LiangBarsky(
                    $corner{$i}{$j}{blx},
                    $corner{$i}{$j}{bly},
                    $corner{$i}{$j}{trx},
                    $corner{$i}{$j}{try},
                    $prevx, $prevy, $xn, $yn
                );
                # take the decisions
                # not much difference between 1 and 3, except location status at the end
                if ( $info == 1 || $info == 3 )
                {    # start within border, virtual pen irrelevant
                    if ( $location == $OUT ) {
                        print STDOUT "%info ($prevx,$prevy) -> ($xn,$yn) "
                                        . "==> ($x1,$y1)->($x2,$y2)\n";
                        quit('location mismatch error 1,3');
                    }
                    if ( $op == $G00 ) {
                        if ( $penstate == $PENDOWN ) { $f->penup() }
                        $f->_addfastmove( $x2, $y2 );
                    }
                    else {    # op == $G01
                        if ( $penstate == $PENUP ) { $f->pendown() }
                        $f->_addslowmove( $x2, $y2 );
                    }
                    $location = $IN;
                    if ( $info == 3 ) { $location = $OUT }
                }
                elsif ( $info == 2 ) {    # totally outside border
                    if ( $location == $IN && $penstate == $PENDOWN ) {
                        $f->do_penup();
                    }                     # ?? perhaps not needed
                    $location = $OUT;
                }
                elsif ( $info == 4 ) {    # start outside, end within
                    if ( $location == $IN ) {
                        print STDOUT "%info ($prevx,$prevy) -> ($xn,$yn) "
                                        . "==> ($x1,$y1)->($x2,$y2)\n";
                        quit('location mismatch error 4');
                    }
                    if ( $op == $G00 ) {
                        if ( $penstate == $PENDOWN ) { $f->do_penup() }
                        $f->_addfastmove( $x2, $y2 );
                    }
                    else {    # op == $G01
                        if ( $penstate == $PENDOWN ) { $f->do_penup() }
                        $f->_addfastmove( $x1, $y1 );
                        $f->do_pendown();
                        $f->_addslowmove( $x2, $y2 );
                    }
                    $location = $IN;
                }
                elsif ( $info == 5 )
                {    # both start and end outside boundary, but crosses inside
                    if ( $location == $IN ) {
                        print STDOUT "%info ($prevx,$prevy) -> ($xn,$yn) "
                                        . "==> ($x1,$y1)->($x2,$y2)\n";
                        quit('location mismatch error 5');
                    }
                    if ( $op == $G00 ) {
                        # ignore completely, nothing is being drawn
                    }
                    else {    # op == $G01
                        if ( $penstate == $PENDOWN ) { $f->do_penup() }
                        $f->addfastmove( $x1, $y1 );
                        $f->do_pendown();
                        $f->_addslowmove( $x2, $y2 );
                    }
                    $location = $OUT;
                }
            }
            continue { $linecount++ }  # end while instructions
            # generate output files, make sure pen goes to (0,0) at the end (not always necessary)
            $f->_addtopage($f->{trailer});
            $f->output();
        } # foreach $j
    } # foreach $i
    return 1;
}

sub do_penup {
    my $self = shift;
    $self->_addpath('u', -1, -1, -1, -1);
    $penstate = $PENUP;
    return 1;
}

sub do_pendown {
    my $self = shift;
    $self->_addpath('d', -1,-1, -1, -1);
    $penstate = $PENDOWN;
    return 1;
}

# we must shift sheets to the origin:
#    must have a margin or reduction in size
#    controlled by $scale, $xwhite, $ywhite variables
# i.e. reduce by 5%, then translate 2.5% in both x and y direction

# generate a G00 or G01
# Move the sheet to the origin and possibly rotate it
sub _addmove {
    my ( $self, $x, $y, $speed ) = @_;
    # calculate new coordinates
    my ($newx, $newy);
    if ($mode eq 'p') { # just shift
        $newx = ( $x - $xoffset ) * $scale + $xwhite;
        $newy = ( $y - $yoffset ) * $scale + $ywhite;
    }
    else {  # 'l' - shift and rotate
        $newx = ( $y - $yoffset ) * $scale + $xwhite;
        $newy = ( $xoffset + $xlen - $x) * $scale + $ywhite;
    }
    # generate the instruction
    if ($speed eq 'slow') {
        $self->_addpath('l', $prevx, $prevy, $newx, $newy);
    }
    else { # 'fast'
        $self->_addpath('m', $prevx, $prevy, $newx, $newy);
    }
    return 1;
}

# generate a G01
sub _addslowmove {
    my ( $self, $x, $y ) = @_;
    $self->_addmove($x, $y, 'slow');
    return 1;
}

# generate a G00
sub _addfastmove {
    my ( $self, $x, $y ) = @_;
        $self->_addmove($x, $y, 'fast');
    return 1;
}

# save the current coords before they are overwritten
sub _setprevious {
    my ( $self, $op, $xn, $yn ) = @_;
    if ( $current eq $EMPTY_STR ) { return }  # first entry after header
    # don't want pen cmds as previous:
    if ( $current eq $self->{penupcmd} || $current eq $self->{pendowncmd} ) {
        return;
    }
    $previous = $current;
    $prevop   = $op;
    $prevx    = $xn;
    $prevy    = $yn;
    return 1;
}

# debugging
sub printcorner {
    my ( $self, $sx, $sy ) = @_;
    foreach my $i ( 0 .. $sx - 1 ) {
        foreach my $j ( 0 .. $sy - 1 ) {
            print STDOUT "$i $j      "
                . $corner{$i}{$j}{blx}
                . $SPACE
                . $corner{$i}{$j}{bly}
                . $SPACE x 5
                .
                #$corner{$i}{$j}{tlx} . $SPACE .
                #$corner{$i}{$j}{tly} . $SPACE .
                $corner{$i}{$j}{trx} . $SPACE . $corner{$i}{$j}{try} . $SPACE .
                #$corner{$i}{$j}{brx} . $SPACE .
                #$corner{$i}{$j}{bry} .
                $EOL;
        }
    }
    return 1;
}

#---------------------------------------------------------------------------------

# vpype interface

# linesort: minimise the amount the pen has to travel
sub vpype_linesort {
    my $self = shift;
    # generate two temp files
    my ($fin,  $vin)  = tempfile(); 
    my ($fout, $vout) = tempfile();
    # write the current design to vin
    $self->exportsvg($vin);
    # compose the vpype command
    my @command = ( 
        'vpype', # '-v', # for debug output
        'read', $vin, 
        'linemerge',
        '-t', '0.01mm', 
        'linesort', 
        'write',
        '--page-size', (lc $self->{papersize}),
        '--format', 'svg',
        $vout
    );
    # Execute the command
    system(@command) == 0 or die "Failed to execute command: $!";
    # declare new graphics object, copying most of $self
    my $v = new GcodeXY(
        papersize     => $self->{papersize},
        xsize         => $self->{xsize}, 
        ysize         => $self->{ysize},
        units         => $self->{units},
        header        => $self->{header}, 
        trailer       => $self->{trailer},
        penupcmd      => $self->{penupcmd},  
        pendowncmd    => $self->{pendowncmd},
        margin        => $self->{margin},
        curvepts      => $self->{curvepts},
        check         => $self->{check}, 
        warn          => $self->{warn},
        hatchsep      => $self->{hatchsep},
        id            => 'vpype-linesort',
        optimize      => $self->{optimize},
        dscale        => $self->{dscale},
        opt_debug     => $self->{opt_debug},
        maxx          => $self->{maxx},
        maxy          => $self->{maxy},
        minx          => $self->{minx},
        miny          => $self->{miny},
        fontsize      => $self->{fontsize},
        fontname      => $self->{fontname},
        pencount      => 0,
        slowdistcount => 0,
        fastdistcount => 0,
    );
    # import the vpype output (second temp file) into the new graphics object
    $v->importsvg($vout);
    # clean up
    unlink($vin);
    unlink($vout);
    # return the new object
    return $v;
}

1;

__END__

#----------------------------------------------------------------------------------

# the rest is the perldoc for this module

=head1 NAME

GcodeXY - Produce gcode files for pen plotters from Perl

=head1 SYNOPSIS

    use Graphics::Penplotters::GcodeXY;
    # create a new GcodeXY object
    $g = new Graphics::Penplotters::GcodeXY( papersize => "A4", units => "in");
    # draw some lines and other shapes
    $g->line(1,1, 1,4);
    $g->box(1.5,1, 2,3.5);
    $g->polygon(1,1, 1,2, 2,2, 2,1, 1,1);
    # write the output to a file
    $g->output("file.gcode");

=head1 DESCRIPTION

C<GcodeXY> provides a method for generating gcode for pen plotters (hence the XY)
from Perl. It has graphics primitives that allow arcs, lines, polygons, and rectangles to
be drawn as line segments. Units used can be specified ("mm" or "in" or "pt").
The default unit is an inch, which is used internally. Other units are scaled accordingly.
The only gcode commands generated are G00 and G01. Fonts are supported, SVG input is possible,
and Postscript output can be generated as well.

=head1 DEPENDENCIES

This module requires C<Math::Bezier>, and C<Math::Trig>. For SVG import you will
need C<Image::SVG::Transform> and C<XML::Parser> and C<Image::SVG::Path> and C<POSIX> and
C<List::Util> and C<Font::FreeType>.

=head1 CONSTRUCTOR

=over 4

=item C<new(options)>

Create a new GcodeXY object. The different options that can be set are:

=over 4

=item check

Print the bounding box of the gcode design; report on what page sizes it would fit;
present an estimate of the distance to pen has to move on and off the paper; report
on the number of pen cycles.

=item curvepts

Set the number of sampling points for curves, default 50. This can be overridden for each
individual curve. The number is reduced for small curves.

=item hatchsep

Specifies the spacing of the hatching lines.

=item header

Specifies a header to be inserted at the start of the output file. The default is
C<G20\nG90\nG17\nF 50\nG92 X 0 Y 0 Z 0\nG00 Z 0\n> which specifies, respectively,
use inches (change to G21 for mm), absolute distance mode, use the XY plane only,
a feedrate of 50 inches per minute (change this if you use other units, or if you are impatient),
and use the current head position as the origin. The last command is the penup command,
which B<must> terminate the header.

=item id

This is an identifying string, useful when you have several objects in your program.
Some diagnostics will print the id.

=item margin

This number indicates a percentage of whitespace that is to be maintained around the page,
when using the C<split> method. This is useful, for example, to stop the pen from overshooting
the edge, cause damage to the paper, or allow glueing together of several sheets. This number will be
doubled, all coordinates will be reduced by this percentage, and the whole page will be centered,
creating the margin on all sides.

=item opt_debug

Enable debugging output from the optimizer. Useful only to the developer of this module.

=item optimize

This flag controls the internal peephole optimizer. The default is 1 (ON). Setting it to 0
switches it off, which may be necessary in some cases, but this may of course result in very
inefficient execution.

=item outfile

The name of the file to which the generated gcode is to be written.

=item papersize

The size of paper to use, if C<xsize> or C<ysize> are not defined. This allows
a document to easily be created using a standard paper size without having to
remember the size of paper. Valid choices are the usual ones such as
C<A3>, C<A4>, C<A5>, and C<Letter>, but the full range is available. Used to warn about
out-of-bound movement. The C<xsize> and C<ysize> will be set accordingly.

=item penupcmd

Lifts the pen off the paper. The default is C<G00 Z 0\n>.

=item pendowncmd

Lowers the pen onto the paper. The default is C<G00 Z 0.2\n>. The distance
of 0.2 inches (i.e. 5 mm) is highly dependent on the plotter and its setup,
so this may well have to be adjusted. 

=item trailer

Specifies a trailer to be inserted at the end of the output file. The default is
C<G00 Z 0\nG00 X 0 Y 0\n> which lifts the pen and returns it to the origin.

=item units

Units that are to be used in the file. Currently supported are C<mm>, C<in>, C<pc>, C<cm>, C<px>
and C<pt>.

=item warn

Generate a warning if an instruction would take the pen outside the boundary specified
with the C<papersize> or the C<xsize> or C<ysize> variables. It is a fatal error if either
one has not been specified.

=item xsize

Specifies the width of the drawing area in units. Used to warn about out-of-bound
movement.

=item ysize

Specifies the height of the drawing area in units. Used to warn about out-of-bound
movement.

=back

Example:

        $ref = new Graphics::Penplotters::GcodeXY( xsize  => 4,
                        ysize      => 3,
                        units      => "in",
                        warn       => 1,
                        check      => 1,
                        pendowncmd => "G00 Z 0.1\n");

=back

=cut

=head1 OBJECT METHODS

Unless otherwise specified, object methods return 1 for success or 0 in some
error condition (e.g. insufficient arguments).

=over 4

=item addcomment(string)

Add a comment to the output. The string will be enclosed in round brackets and a newline
will be added. The current path is not flushed first. This command is useful mainly for
debugging. Note that comments will likely cause the optimizer to be less effective.

=item addfontpath(string, [string, ...])

Add location(s) to search for fonts to the set of builtin paths. This should be an absolute
pathname. The default search path specifies the local directory, the user's private .fonts
directory, and the global font directory in /usr/share/fonts. You will probably have to use
this function if you want to use LaTeX fonts.

=item addtopage(string)

Inserts the C<string>, which should be a gcode command or a comment. In case of a comment,
the string should be enclosed in round brackets. Use with care, needless to say. The string
is inserted directly into the output stream, after the current path has been flushed, so
you are also responsible for making sure that each line is terminated by a newline.
Please note that you may have to adjust the C<currentpoint> after using this command.

=item arc(x, y, r, a, b [, number])

Draws an arc (i.e. part of a circle). This requires an x coordinate, a y coordinate,
a radius, a starting angle and a finish angle. The pen will be moved to the start point.
The optional number overrides the default number of sampling points, and is used in this call only.

=item arcto(x1, y1, x2, y2, r)

Starting from the current position, draw a line to (C<x1>,C<y1>) and then to (C<x2>,C<y2>),
but generate a "shortcut" with an arc of radius C<r>, making a rounded corner. This command is
equivalent to the Postscript instruction of the same name.

=item arrowhead(length, width [, type])

Draw an arrowhead, i.e. two or three small lines, normally at the end of a line segment. The
direction and position of the arrowhead is derived from the last line segment on the current
path. If the path is empty, the current point is used for the position, and the direction will
be horizontal and towards increasing x-coordinate. The type can be 'open' (which causes two
backwards directed lines to be drawn), or 'closed' (where also a line across is drawn).

=item box(x1,y1 [, x2,y2])

Draw a rectangle from lower left co-ordinates (C<x1>,C<y1>) to upper right co-ordinates (C<y2>,C<y2>).
If just two parameters are passed, the current position is assumed to be the lower left hand corner.
The pen will be lifted first, a fast move will be executed to (C<x1>,C<y1>), and the pen will be
lowered. The sides of the rectangle will then be drawn.

Example:

    $g->box(10,10, 20,30);

Note: the C<polygon> method is far more flexible, but this method is more convenient.

=item boxR(x,y)

Draw a rectangle from the current position to the relative upper right co-ordinates (C<x>,C<y>).

Example:

    $g->boxR(2,3);

=item boxround(r, x1,y1, x2,y2)

Draw a rectangle from lower left co-ordinates (C<x1>,C<y1>) to upper right co-ordinates (C<y2>,C<y2>),
using rounded corners as determined by the radius perameter C<r>. The pen will be lifted first,
a fast move will be executed to the midpoint of the bottom edge, and the pen will be lowered.
The sides and arcs of the rectangle will then be drawn in a clockwise direction.

Example (pt units):

    $g->boxround(20, 100,100, 200,300);

=item circle(x, y, r [, number])

Draws a circular arc. This requires an x coordinate, a y coordinate,and a radius.
The pen will be moved to the start point. The required number of sampling points is estimated
based on the value of the radius. The optional C<number> overrides this number of sampling points,
and is used in this call only. The current point is left at (C<x>+C<r>,C<y>).

=item ($x, $y) = currentpoint()

Returns the current location of the pen in user coordinates. It is also possible to pass two
parameters to this method, in which case the current point is set to that position.

=item curve(points)

Calculates a Bezier curve using the array of C<points>. The pen will be moved to the start point.
The number of sampling points is determined by C<curvepoints> which can be set during creation
of the GcodeXY object. For quadratic and cubic curves, the optimal number of sampling points
will be calculated automatically.

=item curveto(points)

Calculates a Bezier curve using the array of C<points>, starting from the current position.
The number of sampling points is determined by C<curvepoints> which can be set during creation
of the GcodeXY object. For quadratic and cubic curves, the optimal number of sampling points
will be calculated automatically.

=item ellipse(x, y, a , b [, number])

Draws an ellipse. This requires an x coordinate, a y coordinate, a horizontal width and
a vertical width. The pen will be moved to the start point. The required number of sampling points
is estimated based on the value of the radius. The optional C<number> overrides this number of
sampling points, and is used in this call only.

=item getsegpath()

Get a copy of the current segment path. This returns an array of hashes containing the start and end
points of the segments.
Example:
    @points = getsegpath();

=item grestore()

Restore the previous graphics state, which should have been saved with C<gsave>.

=item gsave()

Save the current graphics state (e.g. paths, current transformation matrix) onto the graphics stack.

=item importsvg(filename)

Imports an SVG file. Your mileage may vary with this one - not the entire SVG spec (900 pages!)
is implemented. If you get warnings about this, the result may well be be incorrect, especially
with C<use> and C<defs> tags. Just one layer is implemented. The good news is that the 'vpype'
software produces simple SVG output that is 100% compatible, so if you do get problems try
vpype with the '--linesort' option or similar.

All the graphics shapes are implemented, as well as paths and transforms. Note that some SVGs
contain clever tricks that may result in incorrect displays. SVG designs use a different
coordinate system (top down) from the one used in this module. It is therefore essential to
save and restore the graphics state around this function, and also to scale and rotate 
the svg to an appropriate size and orientation. Here is a typical example:

        $g->gsave();                  # save the current graphics state
        $g->initmatrix();             # start a new, pristine graphics state
        $g->translate($my_x, $my_y);  # move to page location where the svg must appear
        $g->rotate($my_degrees);      # rotate the coordinate system as required
        $g->scale($my_scale);         # scale the svg as required, negative creates mirror image
        $g->importsvg('myfile.svg');  # finally import the svg
        $g->grestore();               # restore the previous graphics state

Note that exporting SVG from GcodeXY generates a full page SVG, so no translation or rotation 
will be needed. 

=item initmatrix()

Reset the Current Transformation Matrix (CTM) to the unit matrix, thereby cancelling all previous
C<translate>, C<rotate>, C<scale> and C<skew> operations.

=item line(x1,y1, x2,y2)

Draws a line from the co-ordinates (C<x1>,C<y1>) to (C<x2>,C<y2>). The pen will be lifted first,
a fast move will be executed to (x1,y1), and the pen will be lowered. Then a slow move
to (x2,y2) is performed.

Example:

    $g->line(10,10, 10,20);

=item lineR(x,y)

Draws a line from the current position (cx,cy) to (cx+C<x>,cy+C<y>), i.e. relative coordinates.
The pen is assumed to be lowered.

Example:

    $g->lineR(2,1);

=item moveto(x,y)

Inserts gcode to move the pen to the specified location. The pen will be lifted first, and
lowered at the destination.

=item movetoR(x,y)

Inserts gcode to move the pen to the specified location using relative displacements.
You should not normally need this command, unless you insert your own code. The pen will be
lifted first, and lowered at the destination.

=item newsegpath()

Initialize the segment path, used for hatching. This is done automatically for fonts and for 
all the built-in shapes. Use this function if you define your own series of shapes.

=item output([filename])

Writes the current gcode out to the file named C<filename>, or, if not specified, to the
filename specified using C<outfile> when the gcode object was created. This will destroy
any existing file of the same name. Use this method whenever output to file is required.
The current gcode document in memory is not cleared, and can still be extended. If the
C<check> flag is set, some statistics are printed, including the bounding box.

=item exporteps(filename)

Writes the current gcode out to the file named C<filename> in the form of encapsulated
Postscript. This will destroy any existing file of the same name. The current gcode document
in memory is not cleared, and can still be extended. If the C<check> flag is set, the bounding
box is printed.

=item exportsvg(filename)

Writes the current gcode out to the file named C<filename> in the form of a full page SVG file.
This will destroy any existing file of the same name. The current gcode document in memory is
not cleared, and can still be extended. If the C<check> flag is set, the bounding box is printed.
The boundingbox is returned (bottom left x and y, and top right x and y).

=item pageborder(margin)

Create a border round the page, with a C<margin> specified in current units.

=item pendown()

Inserts the pendown command, causing the pen to be lowered onto the paper.

=item penup()

Inserts the penup command, causing the pen to be lifted from the paper.

=item polygon(x1,y1, x2,y2, ..., xn,yn)

The C<polygon> method is multi-function, allowing many shapes to be created and
manipulated. The pen will be lifted first, a fast move will be executed to (C<x1>,C<y1>),
and the pen will be lowered. Lines will then be drawn from (C<x1>,C<y1>) to (C<x2>,C<y2>) and
then from (C<x2>,C<y2>) to (C<x3>,C<y3>) up to (C<xn-1>,C<yn-1>) to (C<xn>,C<yn>).

Example:

    # draw a square with lower left point at (10,10)
    $g->polygon(10,10, 10,20, 20,20, 20,10, 10,10);

=item polygonR(x1,y1, x2,y2, ..., xn,yn)

This method is multi-function, allowing many shapes to be created and manipulated relative
to the current position (cx,cy). The pen is assumed to be lowered. Lines will then be drawn
to (cx+C<x1>,cy+C<y1>), then to (cx+C<x2>,cy+C<y2>), and so on.

Example:

    # draw a square with lower left point at (10,10)
    $g->polygonR(1,1, 1,2, 2,2, 2,1, 1,1);

=item polygonround(r, x1,y1, x2,y2, ..., xn,yn)

Draws a polygon starting from the current position, using absolute coordinates, with rounded
corners between the line segments whose radius is dtermined by C<r>. Lines with rounded corners
will then be drawn from (C<x1>,C<y1>) to (C<x2>,C<y2>), and so on.

Example:

    # draw a square with lower left point at (10,10)
    $g->polygonround(20, 100,200, 200,200, 200,100, 100,100);

=item rotate(degrees [, refx, refy])

Rotate the coordinate system by C<degrees>. If the optional reference point (C<refx>,C<refy>) is
not specified, the origin is assumed.

=item scale(sx [, sy [, refx, refy]])

Scale the coordinate system by C<sx> in the x direction and C<sy> in the y direction.
If C<sy> is not specified it is assumed to be the same as C<sx>. If the optional reference
point (C<refx>,C<refy>) is not specified, the origin is assumed. Negative parameters will
cause the direction of movement to be reversed.

=item $face = setfont(name, size)

Tries to locate the font called C<name>, and returns a C<face> object if successful. This object
is then used for subsequent rendering using C<stroketext>. Note that the C<size> parameter has
to be in points, which is the unit used by the Freetype library (and is, indeed, the standard
everywhere). It is not advisable to use any other unit when rendering text.

=item setfontsize(size)

Set the default fontsize to be used for rendering to C<size>. See the caveat under C<setfont>:
if you must use other units than 'pt', it is your responsibility to scale the size appropriately.

=item sethatchsep(width)

When hatching, the space between hatch lines is set to C<width>.

=item skewX(degrees)

Schedule a skew (also called shear) in the X direction. This operation works relative to the
origin, so a suitable C<translate> operation may be required first, otherwise the results might
be unexpected.

=item skewY(degrees)

Schedule a skew (also called shear) in the Y direction. This operation works relative to the
origin, so a suitable C<translate> operation may be required first, otherwise the results might
be unexpected.

=item split(size, filestem)

Split the current sheet into smaller sized sheets, and write the results into separate files.
C<size> is, for example, "A4". The C<filestem> prefix will be extended with the sheet numbers,
for example, foo_0_0.gcode, foo_0_1.gcode, etc.

=item stroke()

Render the current path, i.e. translate the path into gcode.

=item strokefill()

Render the current path, i.e. translate the path into gcode, and fill it with a hatch pattern.

=item stroketext(face, string)

Render a C<string> using the C<face> object returned by C<setfont>. To render a character code,
use "chr(charcode)" instead of "string". A C<stroke> operation is applied after each character.

=item stroketextfill(face, string)

Render a C<string> using the C<face> object returned by C<setfont>. To render a character code,
use "chr(charcode)" instead of "string". A C<stroke> operation is applied after each character.
Each character is filled with a hatch pattern. 

=item $w = textwidth(face, string)

Calculate the width of a C<string> using the C<face> object returned by C<setfont>. The returned
value is in page coordinates, i.e. the value is not subject to current transformations.

=item translateC()

Move the origin of the coordinate system to the current location, as returned by C<currentpoint>.

=item translate(x,y)

Move the origin of the coordinate system to (C<x>,C<y>). Both parameters are locations specified
in the current coordinate system, and are thus subjected to rotation and scaling.

=item $v = vpype_linesort()

Sends the current design to vpype in order to sort the line segments in such a way that pen travel
is minimized. Needless to say, vpype needs to be installed and on your path. A new graphics 
object is returned containing the optimized path. This command will be very useful when hatching
of fonts and other shapes has been performed. In the process, two temporary files will be created
and destroyed.

=back

=head1 BUGS AND LIMITATIONS

As noted above, the SVG specification (900 pages) is only partially implemented, and just one layer
can be used. I suspect that diagnostics about pen travel distance may not always be correct.
Clipping is not supported. Layering is not supported officially, but can be simulated.

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com).

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut
