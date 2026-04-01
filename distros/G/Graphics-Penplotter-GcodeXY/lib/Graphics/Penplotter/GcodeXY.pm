package Graphics::Penplotter::GcodeXY v0.9.4;

use v5.38.2;
use feature qw( signatures );
no warnings qw( experimental::signatures );  # required by List::Util and Term::ANSIcolor (perl testers matrix)
use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;
use POSIX qw( ceil );
use List::Util      qw( max );
use Readonly    qw( Readonly );
use Carp        qw( croak );
use Term::ANSIColor qw( RED RESET YELLOW );
use parent qw(Exporter);
use Role::Tiny::With;
with 'Graphics::Penplotter::GcodeXY::Geometry2D';  # geometry primitives and transforms
with 'Graphics::Penplotter::GcodeXY::Geometry3D';
with 'Graphics::Penplotter::GcodeXY::Hatch';       # needs: Geometry2D (gsave/grestore/_getsegintersect)
with 'Graphics::Penplotter::GcodeXY::Font';        # needs: Hatch (_dohatching), Geometry2D (gsave/grestore/translate)
with 'Graphics::Penplotter::GcodeXY::SVG';         # needs: Font (stroketext/setfont), Geometry2D (geometry methods)
with 'Graphics::Penplotter::GcodeXY::Postscript';  # no inter-role deps
with 'Graphics::Penplotter::GcodeXY::Split';       # no inter-role deps
with 'Graphics::Penplotter::GcodeXY::Vpype';       # no inter-role deps
with 'Graphics::Penplotter::GcodeXY::Optimize';    # no inter-role deps
with 'Graphics::Penplotter::GcodeXY::Anamorphic';  # no inter-role deps
with 'Graphics::Penplotter::GcodeXY::Swirl';       # no inter-role deps

our @EXPORT_OK = qw(translate translateC stroketextfill stroketext strokefill stroke split
                    skewX skewY sethatchsep sethatchangle setfontsize setfont scale rotate
                    polygon penup pendown pageborder exportsvg exporteps output newsegpath
                    movetoR moveto lineR line initmatrix importsvg gsave grestore getsegpath
                    ellipse curveto curve currentpoint boxround boxR box arcto arc addtopage
                    addfontpath addcomment textwidth arrowhead polygonround vpype_linesort
                    polygon_clip polygon_clip_end polygonR polygonC
                    initmatrix3 translate3 translateC3 scale3 rotate3 rotate3_euler
                    compose_matrix invert_matrix currentpoint3 transform_point transform_points
                    moveto3 movetoR3 line3 lineR3 polygon3 polygon3C polygon3R project_to_svg
                    box3 cube axis_gizmo mesh prism sphere icosphere cylinder frustum cone capsule
                    plane torus disk pyramid quat_from_axis_angle quat_to_matrix quat_slerp
                    bbox3 compute_normals backface_cull occlusion_clip hidden_line_remove
                    flatten_to_2d draw_polylines mesh_to_obj mesh_from_obj mesh_to_stl mesh_from_stl
                    set_tolerance get_tolerance set_units set_coordinate_convention
                    anamorphic);


# ---------------------------------------------------------------------------
#             SECTION: Data Structures and Constants
# ---------------------------------------------------------------------------

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
Readonly my $EPSILON   => 0.00000001;       # equality for floating point
Readonly my $BBMAX     => 1_000_000.0;      # huge page bounding box
Readonly my $IN        => 0;                # virtual pen is inside the sheet when cutting
Readonly my $OUT       => 1;                # virtual pen is outside the sheet when cutting
Readonly my $PENUP     => 3;                # physical pen is off the paper
Readonly my $PENDOWN   => 4;                # physical pen is on the paper

# object allocation
sub new ($class, %data) {
    my $self = {
        # public:
        papersize     => undef,   # paper size e.g. "A3"
        xsize         => undef,   # bounding box x
        ysize         => undef,   # bounding box y
        units         => 'in',    # inches is used internally
        header        => "G20\nG90\nG17\nF 50\nG92 X 0 Y 0 Z 0\nG00 Z 0\n",  # must end with penup
        trailer       => "G00 Z 0\nG00 X 0 Y 0\n",
        penupcmd      => "G00 Z 0",
        pendowncmd    => "G00 Z 0.2",
        margin        => 1.0,     # margin as a PERCENTAGE
        outfile       => $EMPTY_STR,
        curvepts      => 50,
        check         => 0,
        warn          => 0,       # out of page bounds warning
        hatchsep      => 0.012,   # inches, equivalent to 0.3 mm (the tip of a BIC ballpoint pen)
        hatchangle    => 0,       # degrees; 0 = horizontal hatch lines
        id            => $EMPTY_STR,
        optimize      => 1,
        eps_linewidth => 0.3,     # PostScript line width in points

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
        _g3_posx      => 0,        # 3D current point, x
        _g3_posy      => 0,        # 3D current point, y
        _g3_posz      => 0,        # 3D current point, z
        _g3_tolerance => $EPSILON, # 3D fp tolerance
        _g3_units     => 'in',
        _g3_handedness=> 'right',
        _g3_euler_order => 'XYZ',
        _g3_camera    => undef,
        pencount      => 0,    # number of times pen raised/lowered (raise+lower counts as 1)
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

sub init ($self) {
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
        $self->{papersize} = uc $self->{papersize};
        if ( !defined $pspaper{ $self->{papersize} } ) {
            $self->_croak("paper size '$self->{papersize}' not supported");
        }
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
    $self->{gstate}      = [];    # graphics state
    $self->{CTM}         =  [ [1,0,0],   [0,1,0],   [0,0,1] ];                 # 2D current transformation matrix
    $self->{_g3_CTM}     =  [ [1,0,0,0], [0,1,0,0], [0,0,1,0], [0,0,0,1] ];    # 3D CTM
    $self->{_g3_gstate}  = [];    # 3D graphics state
    $self->{_g3_camera}  = undef; # camera (set via set_camera())
    # add header to page
    $self->_openpage();
    return 1;
}

# ---------------------------------------------------------------------------
#                     Section: Segments
# ---------------------------------------------------------------------------

# Paths consist of a series of segments, where the end of one may be the start of another.
# These are then checked for intersection with a scanline if hatching is required. Hatching
# segments are stored in a separate array.

#
# initialize the segment path
#
sub newpath ($self) {
    @{ $self->{psegments} } = ();
    @{ $self->{hsegments} } = ();
    return 1;
}

#
# close the segment path
#
sub _closepath ($self) {
    my ( $x, $y ) = $self->currentpoint();
    my $tx = $self->{psegments}[0]{sx};
    my $ty = $self->{psegments}[0]{sy};
    my $k  = $self->{psegments}[0]{key};
    $self->_addpath( $k, $x, $y, $tx, $ty );
    return 1;
}

#
# add to the segment path
# this routine is the main way that line segments are added to the path,
# and is used by moveto, lineto, and closepath.
#
sub _addpath ($self, $key, $sx, $sy, $dx, $dy) {
    my $len  = scalar @{ $self->{psegments} };
    if (!defined $dy) {
        $self->_croak('need 5 parameters for addpath');
        return 0;
    }
    # could insert LiangBarsky here to do cropping for svg viewbox
    $self->{psegments}[$len] = { key => $key, sx => $sx, sy => $sy, dx => $dx, dy => $dy };
    return 1;
}

#
# add to the segment path
#
sub addcomment ($self, $s) {
    my $len  = scalar @{ $self->{psegments} };
    if ( !defined $s ) {
        $self->_croak('need 1 parameter for addcomment');
        return 0;
    }
    $self->{psegments}[$len] = { key => 'c', s => $s, sx => 0, sy => 0, dx => 0, dy => 0 };
    return 1;
}

# paint the current path, then clear it
sub stroke ($self) {
    $self->_flushPsegments();
    $self->newpath();
    return 1;
}

#
# translate the segment queue into gcode
#
sub _flushPsegments ($self) {
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
                #sprintf "G01 X %.5f Y %.5f" . $EOL,
                sprintf "G01 X %.5f Y %.5f",
                $self->{psegments}[$i]{dx},
                $self->{psegments}[$i]{dy}
            );
            $self->{slowdistcount} += $d;
            next SEGMENT;
        }
        if ( $k eq 'm' ) {    # moveto
            $self->_addtopage(
                #sprintf "G00 X %.5f Y %.5f" . $EOL,
                sprintf "G00 X %.5f Y %.5f",
                $self->{psegments}[$i]{dx},
                $self->{psegments}[$i]{dy}
            );
            $self->{fastdistcount} += $d;
            next SEGMENT;
        }
        if ( $k eq 'c' ) {    # comment
            $self->_addtopage(
                #sprintf "(%s)" . $EOL,
                sprintf "(%s)",
                $self->{psegments}[$i]{s}
            );
            next SEGMENT;
        }
        if ( $k eq 'u' ) {    # penup
            if ( !$self->{penlocked} ) {
                my $last = $self->{currentpage}[-1] // '';
                unless ( $last eq $self->{penupcmd} ) {
                    $self->_addtopage( $self->{penupcmd} );
                    $self->{pencount}++;
                }
            }
            next SEGMENT;
        }
        if ( $k eq 'd' ) {    # pendown
            if ( !$self->{penlocked} ) {
                my $last = $self->{currentpage}[-1] // '';
                unless ( $last eq $self->{pendowncmd} ) {
                    $self->_addtopage( $self->{pendowncmd} );
                }
            }
            next SEGMENT;
        }
    }
    return 1;
}

# ---------------------------------------------------------------------------
#                 Section: Gcode generation
# ---------------------------------------------------------------------------

#
# Lift the pen
#
sub penup ($self) {
    if ( !$self->{penlocked} ) { $self->_addpath( 'u', -1, -1, -1, -1 ) }
    return 1;
}

#
# Lower the pen
#
sub pendown ($self) {
    if ( !$self->{penlocked} ) { $self->_addpath( 'd', -1, -1, -1, -1 ) }
    return 1;
}

#
# Add a line of text to the output. No checking is done.
# All currently queued segments are flushed first.
#
sub addtopage ($self, $data) {
    if ( !defined $data ) {
        $self->_croak('addtopage: no data provided');
        return 0;
    }
    $self->_flushPsegments();
    $self->_addtopage($data);
    return 1;
}

#
# Create output file and report statistics
#
sub output ($self, $file = undef) {
    $file ||= $self->{outfile};
    if ( $file eq $EMPTY_STR ) {
        $self->_croak('Must supply a filename for output');
    }
    my $out;
    $self->_flushPsegments();
    open $out, '>', $file or croak "Cannot write to file $file";
    my $count = scalar @{ $self->{currentpage} };
    foreach my $i ( @{ $self->{currentpage} } ) {
        print {$out} $i . $EOL;
    }
    $self->_closepage($out);    # write the trailer to file, but not memory
    close $out;
    # report stats if asked for
    if ( $self->{check} ) {
        $self->_stats();
    }
    return 1;
}

#
# print statistics about the gcode program
#
sub _stats ($self) {
    my $f    = $self->{fastdistcount};
    my $s    = $self->{slowdistcount};
    print STDOUT "=== Object \'" . $self->{id} . "\'===" . $EOL;
    print STDOUT sprintf "Bounding box:  (%.3f,%.3f) (%.3f,%.3f)" . $EOL,
                    $self->{minx}, $self->{miny}, $self->{maxx}, $self->{maxy};
    $self->_checkp();
    $self->_checkl();
    print STDOUT 'Pen cycles: ' . $self->{pencount} . $EOL;
    print STDOUT 'Distance above the paper: ';
    print STDOUT sprintf "%.1f inches (%.1f cm, %.1f feet)" . $EOL, $f, $f * 2.54, $f * 0.0833;
    print STDOUT 'Distance on the paper:    ';
    print STDOUT sprintf "%.1f inches (%.1f cm, %.1f feet)" . $EOL, $s, $s * 2.54, $s * 0.0833;
    return 1;
}

#
# set up a page, by adding the header
#
sub _openpage ($self) {
    $self->_addtopage( $self->{header} );
    $self->_addtopage( $self->{penupcmd} );  # added just to be sure
    return 1;
}

#
# Close a page by adding a trailer, either by adding to currentpage
# or to an output file
#
sub _closepage ($self, $out = undef) {
    if ( defined $out ) {
        print {$out} $self->{trailer} . $EOL;
    }
    else {
        $self->_addtopage( $self->{trailer} );
    }
    return 1;
}

#
# Add a line to the page
#
sub _addtopage ($self, $data) {
    my $p = $self->{currentpage};
    push @{$p}, $data;
    return 1;
}

sub _penunlock ($self) {
    $self->{penlocked} = 0;
    return 1;
}

sub _penlock ($self) {
    $self->{penlocked} = 1;
    return 1;
}

sub _penlocked ($self) {
    return $self->{penlocked};
}

#
# Report a serious internal error and quit
#
sub _error ($self, $msg) {
    die RED $msg, RESET;
    return 0;
}

#
# Report a serious user error and quit
#
sub _croak ($self, $msg) {
    croak YELLOW $msg, RESET;
    return 0;
}

#
# generate a pen move -  from user coords
#
sub _genmove ($self, $mode, $x, $y) {
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
sub _genslowmove ($self, $x, $y) {
    $self->_genmove( 'slow', $x, $y );
    return 1;
}

#
# generate a fast move (pen off paper)
#
sub _genfastmove ($self, $x, $y) {
    $self->_genmove( 'fast', $x, $y );
    return 1;
}

#
# Warn if the pen ends up outside the page boundary
# We need DEVICE coordinates here for obvious reasons
#
sub _warn ($self, $x, $y) {
    my ( $x0clip, $y0clip, $x1clip, $y1clip, $info );
    if ( !$self->{warn} ) { return 0 }
    # we check only the endpoint for now.
    # just assume the line started at (0.1, 0.1)
    if ( ( $x < 0 ) || ( $y < 0 ) ) {
        print STDOUT "Out of bound: ($x,$y)" . $EOL;
        return 0;
    }
    ( $x0clip, $y0clip, $x1clip, $y1clip, $info ) =
        $self->_LiangBarsky( 0, 0, $self->{xsize}, $self->{ysize}, 0.1, 0.1, $x, $y );
    if ( $info != 1 ) {
        print STDOUT "Out of bound: ($x,$y)" . $EOL;
    }
    return 1;
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
sub _checkl ($self) {
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
    print STDOUT "best fit landscape: $best_fit" . $EOL;
    return 1;
}

# check if a design fits portrait
sub _checkp ($self) {
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
    print STDOUT "best fit portrait:  $best_fit" . $EOL;
    return 1;
}

# parsing of instruction
sub _parse ($self, $ss) {
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
sub _fprintf ($info, @args) {
    print STDOUT "$info: ";
    foreach (@args) {
        printf STDOUT "%5.2f ", $_
    }
    print STDOUT $EOL;
    return 1;
}

sub getsegpath ($self) {
    if (scalar @{ $self->{psegments} } == 0) {
        return ();
    }
    return @{ $self->{psegments} };
}

__END__

#################### Section: Documentation ####################

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
and Postscript output can be generated as well. Three dimensional mappings are available too.

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

=item hatchangle

Specifies the angle of the hatching lines in degrees.  C<0> (the default)
gives horizontal lines; C<90> gives vertical lines; C<45> gives diagonal
lines running from lower-left to upper-right.  Positive values rotate the
lines counter-clockwise.

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
1;

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
=cut

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

=item polygon_clip(x1,y1, x2,y2, ..., xn,yn)

Add a polygon to an internal clipping queue for hidden-line removal. Polygons added
with C<polygon_clip> are not immediately emitted to the current path; instead they are
kept in a queue. When a new polygon overlaps previously queued polygons, any parts
of the previously queued polygons that lie underneath the new polygon are removed.

The method accepts the same parameters as C<polygon> (a list of coordinate pairs).
Returns 1 on success.

=item polygon_clip_end()

Flush the internal clipping queue into the current segment path. Remaining visible
segments from previously queued polygons are emitted into the current path using
the existing C<_addpath> mechanism (moveto/lineto entries). The clip queue is
cleared. Returns 1 on success.

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

=item polygonround(r, x1,y1, x2,y2, x3,y3, ..., xn,yn)

Draws a polygon starting from the current position, using absolute coordinates, with rounded
corners between the line segments whose radius is determined by C<r>. Lines with rounded corners
will then be drawn from (C<x1>,C<y1>) to (C<x2>,C<y2>), and so on. Specify at least three pairs
of coordinates (i.e. two line segments).

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

=item sethatchangle(degrees)

Set the angle of the hatch lines.  C<0> (the default) gives horizontal
lines; C<90> gives vertical lines.  See also the C<hatchangle> constructor
argument.

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

=head1 3D METHODS

=head2 SYNOPSIS

    $g->gsave();                              # saves both 2-D and 3-D state
    $g->initmatrix3();                        # reset 3-D CTM
    $g->translate3(50, 50, 0);                # move 3-D origin
    $g->rotate3(axis => [0,0,1], deg => 45);  # spin around Z
    $g->scale3(10);                           # uniform scale

    my $m = $g->sphere(0, 0, 0, 1, 12, 24);   # UV sphere mesh
    my $s = $g->flatten_to_2d($m);            # project to 2-D edge list
    $g->draw_polylines($s);                   # draw via host pen hooks

    $g->grestore();
    $g->output('myplot.gcode');

Camera-aware rendering:

    $g->set_camera(
        eye    => [5, 5, 10],   # camera position in world space
        center => [0, 0,  0],   # point to look at
        up     => [0, 1,  0],   # world up hint
    );
    $g->camera_to_ctm();        # bake view matrix into the 3-D CTM

    my $m   = $g->sphere(0, 0, 0, 1);
    my $vis = $g->backface_cull($m);        # uses stored fwd automatically
    $g->draw_polylines($g->flatten_to_2d(
        { verts => $m->{verts},
          faces => [ @{$m->{faces}}[@$vis] ] }
    ));

=head2 CTM and transforms

=over 4

=item initmatrix3()

Reset the 3-D CTM to identity.

=item translate3($tx, $ty [, $tz])

Pre-multiply the 3-D CTM by a translation.

=item translateC3()

Move the 3-D origin to the current 3-D position, then reset the position
to (0,0,0).

=item scale3($sx [, $sy [, $sz]])

Pre-multiply by a scale matrix.  If C<$sy>/C<$sz> are omitted they default
to C<$sx> (uniform scale).

=item rotate3(axis =E<gt> [$ax,$ay,$az], deg =E<gt> $angle)

Pre-multiply by a rotation around an arbitrary axis.

=item rotate3_euler($rx, $ry, $rz [, $order])

Pre-multiply by a sequence of axis-aligned rotations.  C<$order> is a
three-character string such as C<'XYZ'> (default).

=item compose_matrix($aref, $bref)

Multiply two 4x4 matrices; returns a new matrix ref.  Neither input is
modified.

=item invert_matrix($mref)

Invert a 4x4 matrix (Gauss-Jordan with partial pivoting).  Returns a matrix
ref, or C<undef> if the matrix is singular.

=back

=head2 3-D current point

=over 4

=item currentpoint3()

Return the current 3-D position as a list C<($x, $y, $z)>.

=item currentpoint3($x, $y, $z)

Set the current 3-D position.

=back

=head2 Point transformation

=over 4

=item transform_point($pt_ref)

Transform a point (arrayref C<[$x,$y,$z]>) through the current CTM3.
Returns C<($tx, $ty, $tz)>.

=item transform_points($pts_ref)

Transform an arrayref of points; returns an arrayref of C<[$tx,$ty,$tz]>.

=back

=head2 3-D drawing primitives

=over 4

=item moveto3($x, $y [, $z])

Lift the pen, fast-move to the projected 2-D position, lower pen.

=item movetoR3($dx, $dy [, $dz])

Relative C<moveto3> from the current 3-D position.

=item line3($x1,$y1,$z1 [, $x2,$y2,$z2])

Six-arg form: move to start, draw to end.
Three-arg form: draw from the current position.

=item lineR3($dx, $dy [, $dz])

Relative line from the current 3-D position.

=item polygon3(x1,y1,z1, ...)

Move to the first triple, draw through the remaining triples.

=item polygon3C(x1,y1,z1, ...)

Like C<polygon3> but automatically closes back to the first point.

=item polygon3R(dx1,dy1,dz1, ...)

Like C<polygon3> but each triple is relative to the preceding point.

=back

=head2 Wireframe solid drawing (draw directly, no mesh returned)

=over 4

=item box3($x1,$y1,$z1, $x2,$y2,$z2)

Draw a wireframe axis-aligned box between two opposite corners.

=item cube($cx,$cy,$cz,$side)

Draw a wireframe cube centred at C<(cx,cy,cz)>.

=item axis_gizmo($cx,$cy,$cz [, $len [, $cone_r [, $cone_h]]])

Draw three labelled axis arrows (X, Y, Z) as wireframe lines with small
arrow cones.  C<$len> is the total axis length (default 1).  The cone
radius and height default to 5% and 15% of C<$len> respectively.

=back

=head2 Mesh-returning solid primitives

All of the following return a mesh structure
C<{ verts =E<gt> \@v, faces =E<gt> \@f }> which can be passed to
C<flatten_to_2d>, C<hidden_line_remove>, C<mesh_to_obj>, etc.

=over 4

=item mesh($verts_ref, $faces_ref)

Low-level constructor.  Build a mesh from existing arrays.

=item prism($cx,$cy,$cz, $w,$h,$d)

Axis-aligned rectangular prism (box) centred at C<(cx,cy,cz)>, with
dimensions C<w> (X), C<h> (Y), C<d> (Z).  A cube is C<prism> with
C<w == h == d>.  Returns a closed 12-face triangulated mesh.

=item sphere($cx,$cy,$cz, $r [, $lat [, $lon]])

UV-sphere mesh.  C<$lat> and C<$lon> control the tessellation density
(defaults 12 and 24).

=item icosphere($cx,$cy,$cz, $r [, $subdivisions])

Icosphere mesh built by repeated midpoint subdivision of a regular
icosahedron.  C<$subdivisions> defaults to 2 (320 faces).  Produces a more
uniform tessellation than C<sphere>.

=item cylinder($base_ref, $top_ref, $r [, $seg])

Cylinder mesh.  C<$base_ref> and C<$top_ref> are C<[$x,$y,$z]> centre
points.  Side walls only; no end caps.

=item frustum($cx,$cy,$cz, $r_bot,$r_top,$height [, $seg])

General truncated cone (frustum) centred at C<(cx,cy,cz)>.  Both end caps
are included.  When C<$r_top == 0> this is a cone; when
C<$r_bot == $r_top> it is a closed cylinder.

=item cone($cx,$cy,$cz, $r,$height [, $seg])

Convenience wrapper: C<frustum> with C<r_top = 0>.

=item capsule($cx,$cy,$cz, $r,$height [, $seg_r [, $seg_h]])

Cylinder with hemispherical end caps.  C<$height> is the length of the
cylindrical body (not counting the caps).  C<$seg_r> is the number of
radial segments (default 16); C<$seg_h> is the number of latitudinal
segments per hemisphere (default 8).

=item plane($cx,$cy,$cz, $w,$h [, $segs_w [, $segs_h]])

Flat rectangular mesh in the XY plane, centred at C<(cx,cy,cz)>.
Dimensions C<$w> x C<$h>; subdivided into C<$segs_w> x C<$segs_h> quads.
Useful for floors, billboards, and UI surfaces.

=item torus($cx,$cy,$cz, $R,$r [, $maj_seg [, $min_seg]])

Torus mesh in the XY plane.  C<$R> is the major radius (centre of tube to
centre of torus); C<$r> is the minor radius (tube radius).  Defaults:
24 major segments, 12 minor segments.

=item disk($cx,$cy,$cz, $r [, $seg])

Flat circular disk mesh in the XY plane.  Fan-triangulated from the centre.
Vertex 0 is the centre; vertices C<1..$seg> are the rim.

=item pyramid($cx,$cy,$cz, $r,$height [, $sides])

Regular-polygon-base pyramid.  C<(cx,cy,cz)> is the base centre; C<$r> is
the base circumradius; C<$height> is the height in +Z.  C<$sides> defaults
to 4 (square pyramid).  The base cap is included.

=back

=head2 Quaternions

=over 4

=item quat_from_axis_angle($axis_ref, $deg)

Return a unit quaternion C<[$w,$x,$y,$z]>.

=item quat_to_matrix($q)

Convert a quaternion to a 4x4 rotation matrix.

=item quat_slerp($q1, $q2, $t)

Spherical linear interpolation (0 <= t <= 1).

=back

=head2 Mesh utilities

=over 4

=item bbox3($mesh_or_pts)

Returns C<([$minx,$miny,$minz], [$maxx,$maxy,$maxz])>.

=item compute_normals($mesh)

Compute face and averaged vertex normals in-place; returns C<$mesh>.

=back

=head2 Visibility

=over 4

=item backface_cull($mesh [, view_dir =E<gt> \@dir])

Return an arrayref of the face indices (into C<$mesh-E<gt>{faces}>) whose
outward normal points toward the camera, i.e. the visible faces.

The view direction defaults, in order of preference, to the C<fwd> vector
stored by C<set_camera()>, or C<[0, 0, -1]> if no camera has been set.
Supply C<view_dir =E<gt> \@v> to override with an explicit unit vector
pointing I<from> the scene I<toward> the camera.

=item occlusion_clip($mesh [, res =E<gt> N])

Z-buffer rasterisation; returns arrayref of C<[[p1,p2],...]> edge segments.

=item hidden_line_remove($mesh [, %opts])

Back-face cull then occlusion clip; returns edge segments.

=back

=head2 2-D output

=over 4

=item flatten_to_2d($mesh_or_polylines)

Project mesh edges or pass-through polylines; returns C<[[$p1,$p2],...]>.

=item draw_polylines($segs_ref)

Emit segments via the host's pen hooks; calls C<stroke()> at the end.

=item project_to_svg($obj [, %opts])

Return an SVG string of the projected edges.

=back

=head2 Mesh I/O

=over 4

=item mesh_to_obj($mesh [, $name])

Serialise to ASCII OBJ string.

=item mesh_from_obj($str)

Parse an ASCII OBJ string; returns a mesh.

=item mesh_to_stl($mesh [, $name])

Serialise to ASCII STL string.

=item mesh_from_stl($str)

Parse an ASCII STL string; returns a mesh (vertices are de-duplicated).

=back

=head2 Camera

The camera and perspective methods together provide a gluLookAt- and
gluPerspective-style workflow for positioning the viewer and projecting the
scene in 3-D space.  Camera and projection state is saved and restored by
C<gsave()> / C<grestore()> alongside the 3-D CTM and current point.

Typical full workflow:

    $g->initmatrix3();
    $g->set_camera(eye => [5,5,10], center => [0,0,0]);
    $g->camera_to_ctm();
    $g->set_perspective(fov => 45, aspect => 1.0, near => 0.1, far => 100);
    $g->perspective_to_ctm();
    # All drawing calls now produce perspective-foreshortened output.

=over 4

=item set_camera(eye =E<gt> \@e, center =E<gt> \@c [, up =E<gt> \@u])

Position the camera.  C<eye> is the camera position in world space;
C<center> is the point being looked at; C<up> is a world-space up hint
(default C<[0,1,0]>).

The method builds an orthonormal right-handed camera basis, reorthogonalises
the up vector, and stores the resulting 4x4 world-to-camera view matrix in
the object.

Croaks if C<eye> and C<center> are the same point, or if C<up> is parallel
to the view direction.

After the call, C<backface_cull()> uses the stored forward vector
automatically when no explicit C<view_dir> is given.

=item get_camera()

Return the camera record set by the most recent C<set_camera()> call, or
C<undef> if none has been set.  The returned hashref contains:

=over 4

=item C<eye>    - the eye position as supplied

=item C<center> - the look-at point as supplied

=item C<up>     - the I<reorthogonalised> up vector

=item C<fwd>    - unit forward vector (eye toward center); used by C<backface_cull()>

=item C<view>   - 4x4 world-to-camera matrix (arrayref of arrayrefs, row-major)

=back

=item camera_to_ctm()

Pre-multiply the stored view matrix into the 3-D CTM.  After this call all
drawing methods (C<moveto3>, C<line3>, C<flatten_to_2d>, etc.) automatically
include the camera transform; coordinates passed to them are in world space
and come out in camera space.

Typically called once immediately after C<set_camera()>.  Croaks with
C<"no camera"> if called before C<set_camera()>.  Use C<initmatrix3()> or
C<gsave()> / C<grestore()> if you need to reposition the camera.

=item set_perspective(fov =E<gt> $deg [, aspect =E<gt> $r, near =E<gt> $n, far =E<gt> $f])

Build and store a symmetric perspective projection matrix (equivalent to
OpenGL's C<gluPerspective>).  Does I<not> modify the CTM; call
C<perspective_to_ctm()> afterwards to apply it.

=over 4

=item C<fov> (optional, default C<45>)

Vertical field of view in degrees.  Must be in (0, 180).

=item C<aspect> (optional, default C<1.0>)

Viewport width / height ratio.

=item C<near> (optional, default C<0.1>)

Distance to the near clipping plane.  Must be E<gt> 0.

=item C<far> (optional, default C<100>)

Distance to the far clipping plane.  Must be E<gt> C<near>.

=back

The resulting matrix has C<-1> in position [3][2], which causes
C<transform_point()> to compute C<tw = -z>.  The existing perspective divide
(triggered when C<tw != 0> and C<tw != 1>) then yields correctly foreshortened
X and Y coordinates.  Z is discarded by C<flatten_to_2d()>.

=item set_frustum(left =E<gt> $l, right =E<gt> $r, bottom =E<gt> $b, top =E<gt> $t, near =E<gt> $n, far =E<gt> $f)

Build and store an asymmetric (off-axis) perspective projection matrix
(equivalent to OpenGL's C<glFrustum>).  All six named arguments are required;
C<near> and C<far> default to C<0.1> and C<100> respectively.

C<left>, C<right>, C<bottom>, C<top> are the X/Y extents of the view volume
at the near plane.  Setting C<left = -right> and C<bottom = -top> reproduces
a symmetric frustum identical to C<set_perspective()>.

Use this method for off-centre viewports, stereo rendering, or anamorphic
projections.  As with C<set_perspective()>, call C<perspective_to_ctm()>
afterwards to apply it.

=item perspective_to_ctm()

Pre-multiply the projection matrix stored by C<set_perspective()> or
C<set_frustum()> into the 3-D CTM (CTM := P x CTM).

After this call every subsequent C<transform_point()> applies the full
view + projection pipeline, and C<flatten_to_2d()> yields
perspective-correct 2-D coordinates.

Croaks if neither C<set_perspective()> nor C<set_frustum()> has been called.

=item get_projection()

Return the 4x4 projection matrix stored by the most recent
C<set_perspective()> or C<set_frustum()> call, or C<undef> if none has been
set.  The matrix is an arrayref of four arrayrefs (row-major).

=back

=head2 Numeric configuration

=over 4

=item set_tolerance($eps), get_tolerance()

Set/get the floating-point equality tolerance (default 1e-9).

=item set_units($units)

Store a units tag (e.g. C<'mm'>); no automatic scaling is applied.

=item set_coordinate_convention(handedness =E<gt> ..., euler_order =E<gt> ...)

Store convention tags for downstream use.

=back


=head2 Mesh representation

All solid primitives that return a mesh use the structure:

    { verts => \@v, faces => \@f }

where C<@v> is an array of C<[$x,$y,$z]> position arrayrefs and C<@f> is
an array of C<[$i0,$i1,$i2]> triangle index arrayrefs.  Winding order is
counter-clockwise when viewed from the outside (right-hand normal pointing
outward).

=head1 ANAMORPHIC METHODS

An I<anamorphic image> is a distorted drawing which, when viewed from a
specific vantage point via a curved mirror, appears undistorted.  The
methods in this section implement the cylindrical convex mirror variant.
The caller first builds a segment path using any drawing primitives (including
C<importsvg>), then calls C<anamorphic> to replace that path with its
distorted counterpart such that an observer at the configured viewpoint sees
the original image when looking at the mirror.

See L<Graphics::Penplotter::GcodeXY::Anamorphic> for the full description
of the physical model and image coordinate convention.

=over 4

=item anamorphic($cx, $cy, $R [, %opts])

Replace the current segment path with its anamorphic distortion for a
cylindrical mirror of radius C<$R> centred at C<($cx, $cy)>, then flush the
path via C<stroke>.

The intended image is whatever is already in the segment path when this method
is called.  The bounding box of the existing drawable segment endpoints is
used as the image extent.  Each endpoint is independently projected onto the
paper via the cylindrical mirror model; segments whose endpoints cannot be
projected are dropped, and path continuity is maintained automatically.

The C<$cx>, C<$cy>, C<$R>, and observer parameters must be expressed in the
same coordinate space as the segment path (device coordinates as used
internally by GcodeXY).  For typical plots with no active transform this is
equivalent to the drawing unit.

Options:

=over 4

=item C<obs_dist> (default 5*R)

Horizontal distance from the observer to the cylinder axis.  Must exceed C<$R>.

=item C<obs_height> (default 5*R)

Height of the observer's eye above the paper.

=item C<obs_angle> (default 0)

Azimuthal viewing direction in degrees.  0 = observer stands to the right of
the mirror (+x direction); 90 = from the top (+y), etc.

=item C<angle_range> (default: 90% of visible cone)

Total horizontal angular span of the image in degrees.

=item C<elev_range> (default: 80% of base elevation)

Total vertical angular span of the image in degrees.

=item C<step> (default 1.0)

Maximum distance (in drawing units) between consecutive sample points along
a segment.  Smaller values give smoother distorted curves at the cost of
more output moves.

=back

=back

=head1 SWIRL METHODS

A I<swirl> (also called I<pursuit-curve polygon>) is produced by iteratively
constructing a series of nested polygons where each new vertex lies a fixed
fractional distance along an edge of the enclosing polygon.  The corners of
successive polygons trace discrete approximations to logarithmic spirals.

The role is composed automatically when L<Graphics::Penplotter::GcodeXY> is
loaded; no extra C<use> statement is required in user code.

See L<Graphics::Penplotter::GcodeXY::Swirl> for the construction algorithm
and termination conditions.

=over 4

=item swirl(%args)

Draw a whirl from the given polygon.  Named arguments:

=over 4

=item C<points =E<gt> \@pts>  (B<compulsory>)

A reference to a flat array of vertex coordinates in alternating X, Y order:
C<[x0,y0, x1,y1, ...]>.  At least 3 vertices are required.  Coordinates are
in the current drawing units.

=item C<d =E<gt> \@d>  (B<compulsory>)

A reference to an array of I<advance percentages>, one per edge (same count as
vertices).  Each value specifies how far along the corresponding edge the next
polygon's vertex is placed.  Values are percentages in the range C<0>-C<100>.
For example, C<20> means 20% of the way along the edge.

When all values are equal to C<50>, consecutive polygons degenerate to straight
lines (no visible spiral).  Values close to C<0> or C<100> produce densely
packed spirals; values close to C<50> produce loosely spaced ones.

=item C<direction =E<gt> 0|1>  (optional, default C<0>)

Spiral direction.  C<0> (C<$SWIRL_CW>) gives a clockwise whirl; C<1>
(C<$SWIRL_CCW>) gives a counter-clockwise whirl.

=item C<draw =E<gt> \@bool>  (optional, default all C<1>)

A reference to an array of boolean flags, one per edge, that controls whether
each edge of every nested polygon is drawn.  Setting some flags to false can
produce striking visual effects.

=item C<iterations =E<gt> $n>  (optional)

Draw exactly C<$n> nested polygons (not counting the base polygon).  When
given, this takes precedence over C<min_size>.

=item C<min_size =E<gt> $pct>  (optional, default C<1.0>)

Stop iterating once the length of the first edge of the current polygon has
shrunk to C<$pct> percent of the original first-edge length.  Ignored when
C<iterations> is also given.

=back

Returns C<1> on success.  Croaks on invalid input.

=back

=head2 Swirl package variables

=over 4

=item C<$Graphics::Penplotter::GcodeXY::Swirl::SWIRL_CW>

Constant C<0> - clockwise direction (the default).

=item C<$Graphics::Penplotter::GcodeXY::Swirl::SWIRL_CCW>

Constant C<1> - counter-clockwise direction.

=back

=head1 OPTIMIZE

A peephole optimiser applied automatically to the internal segment queue before
gcode generation.  No user-facing API change is needed; the optimiser runs
transparently via C<_flushPsegments>.

The optimiser makes a single pass over the C<psegments> array, matching named
patterns (tested longest-first) and rewriting or deleting redundant
instructions.  After each match the window is retracted so that newly formed
optimisable sequences are not missed (Tanenbaum-style peephole).

The following object attributes configure its behaviour:

=over 4

=item C<optimize>

Set to C<0> to disable the optimiser entirely.  Default is C<1>.

=item C<check>

When set, prints the number of instructions removed to STDOUT.

=item C<opt_debug>

When set, prints a per-instruction trace to STDOUT.

=back

See L<Graphics::Penplotter::GcodeXY::Optimize> for a full description of all
recognised patterns.

=head1 BUGS AND LIMITATIONS

As noted above, the SVG specification (900 pages) is only partially implemented,
and just one layer can be used. I suspect that diagnostics about pen travel distance
may not always be correct. Layering is not supported officially, but can be simulated.

=head1 SEE ALSO

L<Graphics::Penplotter::GcodeXY::Geometry2D>,
L<Graphics::Penplotter::GcodeXY::Geometry3D>,
L<Graphics::Penplotter::GcodeXY::Postscript>,
L<Graphics::Penplotter::GcodeXY::SVG>,
L<Graphics::Penplotter::GcodeXY::Split>,
L<Graphics::Penplotter::GcodeXY::Hatch>,
L<Graphics::Penplotter::GcodeXY::Font>,
L<Graphics::Penplotter::GcodeXY::Vpype>,
L<Graphics::Penplotter::GcodeXY::Optimize>,
L<Graphics::Penplotter::GcodeXY::Anamorphic>,
L<Graphics::Penplotter::GcodeXY::Swirl>

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com).

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

1;
