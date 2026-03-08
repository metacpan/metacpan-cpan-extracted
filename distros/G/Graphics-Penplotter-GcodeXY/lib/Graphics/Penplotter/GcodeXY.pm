package Graphics::Penplotter::GcodeXY v0.7.2;

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
with 'Graphics::Penplotter::GcodeXY::Hatch';       # needs: Geometry2D (gsave/grestore/_getsegintersect)
with 'Graphics::Penplotter::GcodeXY::Font';        # needs: Hatch (_dohatching), Geometry2D (gsave/grestore/translate)
with 'Graphics::Penplotter::GcodeXY::SVG';         # needs: Font (stroketext/setfont), Geometry2D (geometry methods)
with 'Graphics::Penplotter::GcodeXY::Postscript';  # no inter-role deps
with 'Graphics::Penplotter::GcodeXY::Split';       # no inter-role deps
with 'Graphics::Penplotter::GcodeXY::Vpype';       # no inter-role deps
with 'Graphics::Penplotter::GcodeXY::Optimize';    # no inter-role deps
#use Data::Dumper;

our @EXPORT_OK = qw(translate translateC stroketextfill stroketext strokefill stroke split
                    skewX skewY sethatchsep sethatchangle setfontsize setfont scale rotate polygonR polygonC
                    polygon penup pendown pageborder exportsvg exporteps output newsegpath
                    movetoR moveto lineR line initmatrix importsvg gsave grestore getsegpath
                    ellipse curveto curve currentpoint boxround boxR box arcto arc addtopage
                    addfontpath addcomment textwidth arrowhead polygonround vpype_linesort
                    polygon_clip polygon_clip_end);

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
Readonly my $EPSILON   => 0.000001;         # equality for floating point
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
    #$self->{csegments}   = [];    # list of clipping segments
    $self->{gstate}      = [];    # graphics state
    $self->{CTM} = [ [ 1, 0, 0 ], [ 0, 1, 0 ], [ 0, 0, 1 ] ]; # current transformation matrix
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
        #print {$out} $i;
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

=head1 BUGS AND LIMITATIONS

As noted above, the SVG specification (900 pages) is only partially implemented, and just one layer
can be used. I suspect that diagnostics about pen travel distance may not always be correct.
Clipping is not supported. Layering is not supported officially, but can be simulated.

=head1 SEE ALSO

L<Graphics::Penplotter::GcodeXY::Geometry2D>,
L<Graphics::Penplotter::GcodeXY::Postscript>,
L<Graphics::Penplotter::GcodeXY::SVG>,
L<Graphics::Penplotter::GcodeXY::Split>,
L<Graphics::Penplotter::GcodeXY::Hatch>,
L<Graphics::Penplotter::GcodeXY::Font>,
L<Graphics::Penplotter::GcodeXY::Vpype>,
L<Graphics::Penplotter::GcodeXY::Optimize>

=head1 AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com).

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.

=cut

1;
