#===============================================================================
#
#         FILE:  Dg2Mp
#
#     ABSTRACT:  convert Games::Go::Sgf2Dg::Diagrams to John Hobby's MetaPost (which is adapted from Donald Knuth's Metafont).
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#===============================================================================
#
#   Copyright (C) 2005 Reid Augustin reid@hellosix.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#

=head1 NAME

Games::Go::Sgf2Dg::Dg2Mp - Perl extension to convert Games::Go::Sgf2Dg::Diagrams to
John Hobby's MetaPost (which is adapted from Donald Knuth's
Metafont).

=head1 SYNOPSIS

use Games::Go::Sgf2Dg::Dg2Mp

 my $dg2mp = B<Games::Go::Sgf2Dg::Dg2Mp-E<gt>new> (options);
 $dg2mp->convertDiagram($diagram);

=head1 DESCRIPTION

A Games::Go::Sgf2Dg::Dg2Mp object converts a L<Games::Go::Sgf2Dg::Diagram> object
into a TeX (.tex) and a MetaPost (.mp) file.  The MetaPost file
contains figures for each of the diagrams and overstones required to
make the complete game diagram.  Running MetaPost (mpost or possibly
mp) on the .mp file creates a set of figure files, each of which is
an Encapsulated PostScript figure.  Running TeX (tex) on the .tex
file creates a .dvi file which tries to include the Encapsulated
PostScript figures.  Running dvips on the .dvi file (from TeX)
creates the final PostScript (.ps) file containing the complete game
diagram.

See 'man mpost' (or possibly 'man 'mp') for more details of the
overall MetaPost system and environment.

=cut

use strict;
require 5.001;

package Games::Go::Sgf2Dg::Dg2Mp;
use Carp;

our $VERSION = '4.252'; # VERSION

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use PackageName ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

use constant BLACK          => 'black';
use constant WHITE          => 'white';
use constant DEFAULT_FONT   => 'cmssbx10';      # default font for numerals
use constant BIGNUMBER_FONT => 'cmr10';         # font for numbers > 99
use constant ITALIC_FONT    => 'cmbxti10';      # font for letters
use constant MP_FUNCS       => "

% some global constants:
numeric normal_pen, board_edge_pen,  mark_pen;
normal_pen = 0.3;           % normal pen width
board_edge_pen = normal_pen * 3.5;
mark_pen = normal_pen * 2.5;

% convert board coords to real coords:
% note: goboard lines are numbered with 1 at the top and increasing
%    towards the bottom of the page.  vline_count allows us to
%    invert Y for PostScript coordinates that increase going up
def boardXY (expr m, n) =
   ((m - 0.5) * stone_width, (vline_count - n - 0.5) * stone_height)
enddef;

% how to draw basic shapes
def _stone (expr m, n, color) =
    fill fullcircle xscaled (stone_width) yscaled(stone_height) shifted boardXY(m, n) withcolor color;
    draw fullcircle xscaled (stone_width) yscaled(stone_height) shifted boardXY(m, n);  % outline
enddef;

% triangle at m, n with color
def _triangle (expr m, n, color) =
    pickup pencircle scaled mark_pen;
    draw  ((0, .45)--(.39, -.225)--(-.39,-.225)--cycle)
        xscaled (stone_width) yscaled (stone_height)
        shifted boardXY(m, n) withcolor color;
    pickup pencircle scaled normal_pen;
enddef;

% square at m, n with color
def _square (expr m, n, color) =
    pickup pencircle scaled mark_pen;
    draw  ((-.5, .5)--(.5, .5)--(.5, -.5)--(-.5, -.5)--cycle)
        xscaled (stone_width * .5) yscaled (stone_height * .5)
        shifted boardXY(m, n) withcolor color;
    pickup pencircle scaled normal_pen;
enddef;

% X mark at m, n with color
def _mark(expr m, n, color) =
    pickup pencircle scaled mark_pen;
    draw  ((-.5, -.5)--(.5, .5))  xscaled (stone_width * .4) yscaled (stone_height * .4) shifted boardXY(m, n) withcolor color;
    draw  ((-.5, .5)--(.5, -.5))  xscaled (stone_width * .4) yscaled (stone_height * .4) shifted boardXY(m, n) withcolor color;
    pickup pencircle scaled normal_pen;
enddef;

% circle at m, n with color
def _circle (expr m, n, color) =
    pickup pencircle scaled mark_pen;
    draw  fullcircle xscaled (stone_width * .5) yscaled (stone_height * .5) shifted boardXY(m, n) withcolor color;
    pickup pencircle scaled normal_pen;
enddef;

% parts of the intersections of the board
def _up    (expr coord) = draw (coord--(coord + (0,  .5 * stone_height))) enddef;
def _down  (expr coord) = draw (coord--(coord + (0, -.5 * stone_height))) enddef;
def _right (expr coord) = draw (coord--(coord + ( .5 * stone_width, 0)))  enddef;
def _left  (expr coord) = draw (coord--(coord + (-.5 * stone_width, 0)))  enddef;

def _int (expr m, n) =

    pair coord;  % coords of point on board
    coord = boardXY(m, n); 
    if (m <= 1) :
        if (n <= 1) :               % topLeft
            pickup pencircle scaled board_edge_pen;
            _right(coord);
            _down(coord);
        elseif (n >= b_sizey) :           % bottomLeft
            pickup pencircle scaled board_edge_pen;
            _right(coord);
            _up(coord);
        else :                      % left
            _right(coord);
            pickup pencircle scaled board_edge_pen;
            _up(coord);
            _down(coord);
        fi;
    elseif (m >= b_sizex):
        if (n <= 1) :           % topRight
            pickup pencircle scaled board_edge_pen;
            _left(coord);
            _down(coord);
        elseif (n >= b_sizey) :     % bottomRight
            pickup pencircle scaled board_edge_pen;
            _left(coord);
            _up(coord);
        else :                      % right
            _left(coord);
            pickup pencircle scaled board_edge_pen;
            _up(coord);
            _down(coord);
        fi;
    else :
        if (n <= 1) :               % top
            _down(coord);
            pickup pencircle scaled board_edge_pen;
            _left(coord);
            _right(coord);
        elseif (n >= b_sizey) :     % bottom
            _up(coord);
            pickup pencircle scaled board_edge_pen;
            _left(coord);
            _right(coord);
        else :                      % middle
            _up(coord);
            _down(coord);
            _left(coord);
            _right(coord);
        fi;
    fi;
    pickup pencircle scaled normal_pen;
enddef;

% draw the board, given a global b_sizeX/Y and the
%    left, right, top, and bottom boundary lines
def _board (expr b_left, b_top, b_right, b_bottom) =
    % place an illusory stone in upper left so the figures
    %   line up after stones are on the edges
    undraw fullcircle xscaled (stone_width) yscaled(stone_height) shifted boardXY(b_left, b_top);
    for n = b_top upto b_bottom:
        for m = b_left upto b_right:
            _int(m, n);     % draw the intersections
        endfor;
    endfor;
enddef;

% draw a hoshi point
def _hoshi(expr m, n) =
    fill fullcircle xscaled (stone_width / 20) yscaled(stone_height / 20) shifted boardXY(m, n);
enddef;

% create some blank space (like for under a label)
def _blank(expr m, n) =
    unfill fullcircle xscaled (stone_width * 0.7) yscaled(stone_height * 0.7) shifted boardXY(m, n);
enddef;

% label at m, n with k and color
def _label(expr m, n, k, color) =
    label(k, boardXY(m, n)) withcolor color;
enddef;
";


######################################################
#
#       Class Variables
#
#####################################################

our %options = (
    boardSizeX      => 19,
    boardSizeY      => 19,
    doubleDigits    => 0,
    coords          => 0,
    topLine         => 1,
    bottomLine      => 19,
    leftLine        => 1,
    rightLine       => 19,
    diaCoords       => sub { my ($x, $y) = @_;
                             $x = chr($x - 1 + ord('a'));
                             $y = chr($y - 1 + ord('a'));
                             return("$x$y"); },
    file            => undef,
    filename        => 'unknown',
    print           => sub { return; }, # Hmph...
    # Mp=specific options:
    stone_fontName  => 'cmssbx10',
    stone_fontSize  => 8,
    stone_width     => undef,
    stone_height    => undef,
    );

use constant NORMAL_MACROS =>
"\\magnification=1200
\\newdimen\\diagdim
\\newdimen\\fulldim
\\newbox\\diagbox
\\newbox\\captionbox\n";

use constant SIMPLE_MACROS =>
"\\magnification=1200
\\raggedbottom
\\parindent=0pt\n";

use constant TWO_COLUMN_MACROS =>
"\\magnification=1200
\\input gotcmacs
\\raggedbottom
\\tolerance=10000
\\parindent=0pt\n";


######################################################
#
#       Public methods
#
#####################################################

=head1 NEW

=over 4

=item my $dg2mp = B<Games::Go::Sgf2Dg::Dg2Mp-E<gt>new> (?options?)

A B<new> Games::Go::Sgf2Dg::Dg2Mp takes the following options:

=back

=over 8

=item B<boardSizeX> =E<gt> number

=item B<boardSizeY> =E<gt> number

Sets the size of the board.

Default: 19

=item B<doubleDigits> =E<gt> true | false

Numbers on stones are wrapped back to 1 after they reach 100.
Numbers associated with comments and diagram titles are not
affected.

Default: false

=item B<stone_width> =E<gt> points

=item B<stone_height> =E<gt> points

The B<stone_width> and B<stone_height> determine the size of the
stones and diagrams.

If B<stone_width> is not explicitly set, it is calculated from the
B<stone_fontSize> to allow up to three digits on a stone .  The
default B<stone_fontSize> allows for three diagrams (with -coords)
per 'letter' page if comments don't take up extra space below
diagrams.  If B<doubleDigits> is specified, the stones and board are
slightly smaller (stone 100 may look a bit cramped).

If B<stone_height> is not explicitly set, it will be 1.05 *
B<stone_width>, creating a slightly rectangular diagram.

Default: undef - determined from B<stone_fontSize>

=item B<coords> =E<gt> true | false

Generates a coordinate grid.

Default: false

=item B<topLine>     =E<gt> number (Default: 1)

=item B<bottomLine>  =E<gt> number (Default: 19)

=item B<leftLine>    =E<gt> number (Default: 1)

=item B<rightLine>   =E<gt> number (Default: 19)

The edges of the board that should be displayed.  Any portion of the
board that extends beyond these numbers is not included in the
output.

=item B<diaCoords> =E<gt> sub { # convert $x, $y to Diagram coordinates }

This callback defines a subroutine to convert coordinates from $x,
$y to whatever coordinates are used in the Games::Go::Sgf2Dg::Diagram
object.  The default B<diaCoords> converts 1-based $x, $y to the
same coordinates used in SGF format files.  You only need to define
this if you're using a different coordinate system in the Diagram.

Default:

    sub { my ($x, $y) = @_;
          $x = chr($x - 1 + ord('a')); # convert 1 to 'a', etc
          $y = chr($y - 1 + ord('a'));
          return("$x$y"); },           # concatenate two letters

See also the B<diaCoords> method below.

=item B<print> =E<gt> sub { my ($dg2mp, @tex) = @_; ... }

A user defined subroutine to replace the default printing method.
This callback is called from the B<print> method (below) with the
reference to the B<Dg2Mp> object and a list of lines that are
part of the TeX diagram source.

=item B<stone_fontName> =E<gt> 'font'  Default: 'cmssbx10'

Quoting from the discussion on fonts in section 7 of _A User's
Manual for MetaPost_ (by John D. Hobby):

"...the new font name should be something that TEX would understand
since MetaPost gets height and width information by reading the tfm
file. (This is explained in The TEXbook. [5] ) It should be possible
to use built-in PostScript fonts, but the names for them are
system-dependent. Some systems may use rptmr or ps-times-roman
instead of Times-Roman. A TEX font such as cmr10 is a little
dangerous because it does not have a space character or certain
ASCII symbols. In addition, MetaPost does not use the ligatures and
kerning information that comes with a TEX font."

=item B<stone_fontSize> =E<gt> points

The stone_fontSize determines the size of the stones and diagrams.
Stone size is chosen to allow up to three digits on a stone.

If B<doubleDigits> is specified, the stones and board are slightly
smaller (stone 100 may look a bit cramped).

Default: 8

=back

=cut

sub new {
    my ($proto, %args) = @_;

    my $my = {};
    bless($my, ref($proto) || $proto);
    $my->{converted} = '';
    foreach (keys(%options)) {
        $my->{$_} = $options{$_};  # transfer default options
    }
    # transfer user args
    $my->configure(%args);
    return($my);
}

=head1 METHODS

=over 4

=item $dg2mp-E<gt>B<configure> (option =E<gt> value, ?...?)

Change Dg2Mp options from values passed at B<new> time.

=cut

sub configure {
    my ($my, %args) = @_;

    if (exists($args{file})) {
        $my->{file} = delete($args{file});
        if (ref($my->{file}) eq 'SCALAR') {
            $my->{filename} = $my->{file};
            $my->{print} = sub { ${$_[0]->{file}} .= $_[1]; };
        } elsif (ref($my->{file}) eq 'ARRAY') {
            $my->{filename} = 'ARRAY';
            $my->{print} = sub { push @{$_[0]->{file}}, split("\n", $_[1]); };
        } elsif (ref($my->{file}) eq 'GLOB') {
            $my->{filename} = 'GLOB';
            $my->{print} = sub { $_[0]->{file}->print($_[1]) or
                                        die "Error writing to output file:$!\n"; };
        } elsif (ref($my->{file}) =~ m/^IO::/) {
            $my->{filename} = 'IO';
            $my->{print} = sub { $_[0]->{file}->print($_[1]) or
                                        die "Error writing to output file:$!\n"; };
        } else {
            require IO::File;
            $my->{filename} = $my->{file};
            $my->{file} = IO::File->new($my->{filename}) or
                die("Error opening $my->{filename}: $!\n");
            $my->{print} = sub { $_[0]->{file}->print($_[1]) or
                                        die "Error writing to $_[0]->{filename}:$!\n"; };
        }
    }
    foreach (keys(%args)) {
        croak("I don't understand option $_\n") unless (exists($options{$_}));
        $my->{$_} = $args{$_};  # transfer user option
    }
    if ($my->{coords} and
        $my->{twoColumn}) {
        carp("\nWarning: -coords and -twoColumn cannot be used together - turning off coords.");
        delete($my->{coords});
    }
    if ($my->{longComments} and
        $my->{simple}) {
        carp("\nWarning: -longComments and -simple cannot be used together - turning off longComments.");
        delete($my->{longComments});
    }
    if ($my->{longComments} and
        $my->{twoColumn}) {
        carp("\nWarning: -longComments and -twoColumn cannot be used together - turning off -longComments.");
        delete($my->{longComments});
    }
    if ($my->{twoColumn}) {
        $my->{simple} = 1;
    }
    $my->{fontSize} = ($my->{twoColumn}) ? 10 : 12;
    # make sure edges of the board don't exceed boardSize
    $my->{topLine}    = 1 if ($my->{topLine} < 1);
    $my->{leftLine}   = 1 if ($my->{leftLine} < 1);
    $my->{rightLine}  = $my->{boardSizeX} if ($my->{rightLine} > $my->{boardSizeX});
    $my->{bottomLine} = $my->{boardSizeY} if ($my->{bottomLine} > $my->{boardSizeY});
}

=item my $coord = $dg2mp-E<gt>B<diaCoords> ($x, $y)

Provides access to the B<diaCoords> option (see above).  Returns
coordinates in the converter's coordinate system for board coordinates ($x,
$y).  For example, to get a specific intersection structure:

    my $int = $diagram->get($dg2mp->diaCoords(3, 4));

=cut

sub diaCoords {
    my ($my, $x, $y) = @_;

    return &{$my->{diaCoords}}($x, $y);
}

=item $dg2mp-E<gt>B<print> ($tex ? , ... ?)

B<print>s raw TeX code to B<file> as defined at B<new> time.
Whether or not B<file> was defined, B<print> accumulates the TeX
code for later retrieval with B<converted>.
The TeX output filename is derived from the MetaPost filename by
changing the .mp extension to .tex.

=cut

sub print {
    my ($my, @args) = @_;

    # one-time init:
    unless(exists($my->{macrosDone})) {
        $my->{macrosDone} = 1;
        if (not $my->{simple}) {
            $my->print(NORMAL_MACROS);
        } elsif ($my->{twoColumn}) {
            $my->print(TWO_COLUMN_MACROS); 
        } else {
            $my->print(SIMPLE_MACROS);
        }
        $my->print("\\input epsf\n");
    }
    foreach my $arg (@args) {
        $my->{converted} .= $arg;
        &{$my->{print}} ($my, $arg);
    }
}


=item $dg2mp-E<gt>B<print> ($tex ? , ... ?)

B<print>s raw MetaPost code to MetaPost output file (as defined at
->B<new> or ->B<configure> time).

=cut

sub mpprint {
    my ($my, @args) = @_;

    $my->{mpFile}->print(@args);
}

=item my $tex = $dg2mp-E<gt>B<converted> ($replacement_tex)

Returns the TeX source code converted so far for the B<Dg2Mp>
object.  If $replacement_tex is defined, the accumulated TeX source
code is replaced by $replacement_tex.

=cut

sub converted {
    my ($my, $tex) = @_;

    $my->{converted} = $tex if (defined($tex));
    return ($my->{converted});
}

=item $dg2mp-E<gt>B<comment> ($comment ? , ... ?)

Inserts the TeX comment character ('%') in front of each line of
each comment and B<print>s it to B<file>.

=cut

sub comment {
    my ($my, @comments) = @_;

    if (exists($my->{mpFile})) {
        if (exists($my->{pre_comments})) {
            my @c = @{delete($my->{pre_comments})};
            $my->comment(@c);
            local $my->{file} = $my->{mpFile};  # also copy to MetaPost output file
            $my->comment(@c);
        } else {
            local $my->{macrosDone} = 1;        # allow comments before one-time init
            foreach my $c (@comments) {
                while ($c =~ s/([^\n]*)\n//) {
                    $my->print("%$1\n");
                }
                $my->print("%$c\n") if ($c ne '');
            }
        }
    } else {
        push(@{$my->{pre_comments}}, @comments);
    }
}

=item my $tex_source = $dg2mp-E<gt>B<convertDiagram> ($diagram)

Converts a I<Games::Go::Sgf2Dg::Diagram> into TeX/MetaPost.  If B<file> was
defined in the B<new> method, the TeX source is dumped into the
B<file>.tex and the MetaPost source into B<file>.mp.  In any case,
the TeX source is returned as a string scalar.

=cut

sub convertDiagram {
    my ($my, $diagram) = @_;

    $my->_createMp($diagram) unless(exists($my->{mpFile}));
    my @name = $diagram->name;
    $name[0] = 'Unknown Diagram' unless(defined($name[0]));
    my $propRef = $diagram->property;           # get property list for the diagram
    $my->{VW} = exists($propRef->{0}{VW});      # view control?
    my $first = $diagram->first_number;
    my $last = $diagram->last_number;
    $my->{offset} = $diagram->offset;
    $my->{stoneOffset} = $diagram->offset;
    if ($my->{doubleDigits}) {
        while ($first - $my->{stoneOffset} >= 100) {
            $my->{stoneOffset} += 100;      # first to last is not supposed to cross 101
        }
    }
    my $range = '';
    if ($first) {
        $range = ': ' . ($first - $my->{offset});
        if ($last != $first) {
            $range .= '-' . ($last - $my->{offset});
        }
    } else {
        # carp("Hmmm! No numbered moves in $name[0]");
    }

    $my->mpprint("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n");
    $my->mpprint("%  Start of ", @name, "$range\n");
    $my->mpprint("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n");

    unless(exists($my->{titleDone})) {      # first diagram only:
        $my->{titleDone} = 1;
        my @title_lines = $diagram->gameProps_to_title(sub { "{\\bf $_[0]}" });
        my $title = '';
        foreach (@title_lines) {
            s/(.*?})(.*)/$1 . $my->convertText($2)/e;
            $title .= "$_\\hfil\\break\n";
        }
        if($title ne '') {
            $my->print("{\\noindent\n$title\\par}\n\\nobreak\n");
        }
    }
    $my->_preamble();

    if ($my->{VW}) {    # view control
        $my->{draw_underneath} = 1;     # draw each intersection individually
        $my->mpprint("% add illusory stone so figure is positioned correctly even if no stones are on the edges\n");
        $my->mpprint("undraw fullcircle xscaled (stone_width) yscaled(stone_height) shifted boardXY($my->{leftLine}, $my->{topLine});\n");
    } else {
        # draw the underneath part (the board)
        $my->mpprint("_board($my->{leftLine}, $my->{topLine}, $my->{rightLine}, $my->{bottomLine});\n");
    }

    # draw the diagram
    foreach my $y ($my->{topLine} .. $my->{bottomLine}) {
        foreach my $x ($my->{leftLine} ..  $my->{rightLine}) {
            $my->_convertIntersection($diagram, $x, $y);
        }
        if ($my->{coords}) {    # right-side coords
            my $x = $my->{rightLine} + 1;
            my $ycoord = $diagram->ycoord($y);
            $my->mpprint("_label($x, $y, \"$ycoord\", black);   % coord\n");
        }
    }
    # print coordinates along the bottom
    if ($my->{coords}) {
        $my->mpprint("% bottom coordinates:\n");
        my $y = $my->{bottomLine} + 1;
        for ($my->{leftLine} .. $my->{rightLine}) {
            my $xcoord = $diagram->xcoord($_);
            $my->mpprint("_label($_, $y, \"$xcoord\", black);\n");
        }
    }
    $my->mpprint("endfig;\n\n");

    # now handle text associated with this diagram
    $my->print("\\hfil\\break\n");          # line break after the diagram
    # the diagram title
    $name[0] = "{\\bf $name[0]}";      # boldface the first name line
    if (defined($diagram->var_on_move) and
        defined($diagram->parent)) {
        my $varOnMove = $diagram->var_on_move;
        my $parentOffset = $diagram->parent->offset;
        my $parentName = $diagram->parent->name->[0];
        if (defined($parentOffset) and
            defined($parentName)) {
            $name[0] .= ' at move ' .
                        ($varOnMove - $parentOffset) .
                        ' in ' .
                        $parentName;
        }
    }
    my $title = join('', @name, $range);
    # print the diagram title
    if (($my->{twoColumn})or ($my->{simple})) {
        $my->print("\n$title\\hfil\\break\n");
    } else {
        # BUGBUG my $hangIndentLines = int(1 + $my->{bigFonts} + ($diaHeight - (1+.2*$my->{bigFonts})*$my->{gap})/ $my->{fontSize});
        $my->print(
       #        "\\vfil\n",
       #        "\\setbox\\captionbox=\\vbox{\\tolerance=10000\\vglue-8pt\n",
       #        "\\parindent=0pt\\parskip=8pt\\vglue6pt\\lineskip=0pt\\baselineskip=12pt\n",
       # BUGBUG "\\hangindent $diaWidth pt",
       # BUGBUG "\\hangafter-$hangIndentLines\n",
       #        "\\hfil\\break\n",
                "\\noindent$title\\hfil\\break\n");
    }

    # deal with the over-lay stones
    $my->_convertOverstones($diagram);
    if ($my->{twoColumn}) {
        $my->print("\n");
    } else { 
        # $my->print("\\hfil\\break\n");
    }
    # print the game comments for this diagram
    foreach my $n (sort { $a <=> $b } keys(%{$propRef})) {
        my @comment;
        if (exists($propRef->{$n}{B}) and
            ($propRef->{$n}{B}[0] eq 'pass')) {
            push(@comment, "Black Pass\n\n");
        }
        if (exists($propRef->{$n}{W}) and
             ($propRef->{$n}{W}[0] eq 'pass')) {
            push(@comment, "White Pass\n\n");
        }
        if (exists($propRef->{$n}{N})) {
            push(@comment, "$propRef->{$n}{N}[0]\n"); # node name
        }
        if (exists($propRef->{$n}{C})) {
            push(@comment, @{$propRef->{$n}{C}});
        }
        if (@comment) {
            my $c = '';
            my $n_off = $n - $my->{offset};
            $c = "$n_off: " if (($n > 0) and
                                ($n >= $first) and
                                ($n <= $last));
            $c .= join('', @comment);
            $my->print($my->convertText($c), $my->{simple} ? "\n" : "\\hfil\\break\n");
        }
    }
    if (($my->{twoColumn})or ($my->{simple})) {
    } else {
        $my->print("\n");
    }
    $my->_postamble();
}

=item my $tex = $dg2mp-E<gt>B<convertText> ($text)

Converts $text into TeX code by changing certain characters that are
not available in TeX cmr10 font, and by converting \n\n into
\hfil\break.  B<convertText> behavior is modified by B<texComments>
and B<simple> options.

Returns the converted text.

=cut

sub convertText {
    my ($my, $text) = @_;

    if ($my->{texComments}) {
        $text =~ tr/<>_/[]-/            # \{} are untouched if texComments is true
    } else {
        $text =~ s/\\/\//gm;            #  \\ -> / since cmr10 has no backslash
        $text =~ tr/{<>}_/[[]]-/;       #  cmr10 has no {<>}_ so substitute [[]]-
    }
    $text =~ s/([&~^\$%#])/\\$1/gm;     #  escape &~^$%#

    unless ($my->{simple}) {
        $text =~ s/\n/\\hfil\\break\n/gm;      # replace \n by \hfil\break
    }
    return($text);
}

=item $dg2mp-E<gt>B<close>

B<print> the TeX closer (\bye) and close the dg2mp object.  Also
closes B<file> if appropriate.

=cut

sub close {
    my ($my) = @_;

    $my->print("\\bye\n");
    if (defined($my->{file}) and
        ((ref($my->{file}) eq 'GLOB') or
         (ref($my->{file}) eq 'IO::File'))) {
        $my->{file}->close;
    }
    $my->mpprint("end;\n");
    $my->{mpFile}->close;
}

######################################################
#
#       Private methods
#
#####################################################

sub _createMp {
    my ($my, $diagram) = @_;

    $my->{mpFile} = $my->{file};
    my $texName = $my->{filename} || 'sgf2mp';
    $texName =~ s/\.mp$//;
    $texName =~ s/>//g;
    $my->{mpfigname} = $texName;
    $texName = ">$texName.tex";
    $my->{file} = IO::File->new($texName) or
        die ("Couldn't open TeX file $texName: $!");
    $my->comment();                 # print comments so far to both files
    my $fontScale = $my->{fontScale} = 0.4;  # approximate size in points when fontSize == 1
    unless(defined($my->{stone_width})) {
        $my->{stone_width} = $my->{doubleDigits} ?
                                $fontScale * 4.5 :    # need space for two digits (and 100)
                                $fontScale * 5.0;     # need space for three digits
        $my->{stone_width} *= $my->{stone_fontSize};
    }
    $my->{stone_height} = $my->{stone_width} * 1.00 unless(defined($my->{stone_height}));
    $my->mpprint("defaultfont  :=\"$my->{stone_fontName}\";\n",
                 "defaultscale := $my->{stone_fontSize}pt/fontsize defaultfont;\n",
                 "numeric b_sizex, bsizey, stone_width, stone_height, vline_count;\n",
                 "b_sizex      := $my->{boardSizeX};\n",
                 "b_sizey      := $my->{boardSizeY};\n",
                 "stone_width  := $my->{stone_width};\n",
                 "stone_height := $my->{stone_height};\n",
                 "vline_count  := 1 + $my->{bottomLine} - $my->{topLine};\n",
                 "\n",
                 );
    $my->mpprint(MP_FUNCS);         # meta-post prolog
}

sub _convertOverstones {
    my ($my, $diagram) = @_;

    return unless (@{$diagram->getoverlist});

    my ($color, $otherColor, $number);
    my $text_x = 0;
    my $text_y = $my->{bottomLine} + 1;
    $text_y++ if ($my->{coords});
    for (my $ii = 0; $ii < @{$diagram->getoverlist}; $ii++) {
        my $int = $diagram->getoverlist->[$ii];
        $text_y += 1.2;# adjust for stone height
        my $x = $text_x;
        my $comma = 0;
        # all the overstones that were put on this understone:
        for (my $jj = 0; $jj < @{$int->{overstones}}; $jj += 2) {
            if ($comma ) {
                $my->print(', ');
            }
            $color = $int->{overstones}[$jj];
            $otherColor = ($color eq BLACK) ? WHITE : BLACK;
            local $my->{stoneOffset} = $my->{offset};   # turn off doubleDigits
            $number = $my->_checkStoneNumber($int->{overstones}[$jj+1]);
            # draw the overstone
            $my->_preamble();    # start another figure
            $my->mpprint("_stone(0, 0, $color);\n");
            $my->mpprint("_label(0, 0, \"$number\", $otherColor);\n");
            $my->mpprint("endfig;\n");
            $comma = 1;
        }
        # the 'at' stone
        if (exists($int->{black})) {
            $color = BLACK;
            $otherColor = WHITE;
        } elsif (exists($int->{white})) {
            $color = WHITE;
            $otherColor = BLACK;
        } else {
            carp("Oops: understone is not black or white? " .
                 "This isn't supposed to be possible!");
            next;
        }
        # at
        $my->print(' at ');
        # draw the at-stone
        $my->_preamble();    # start another figure
        $my->mpprint("_stone(0, 0, $color);\n");
        if (exists($int->{number})) {
            $my->mpprint("_label(0, 0, \"$int->{number}\", $otherColor);\n");
        } elsif (exists($int->{mark})) {
            $my->_drawMark($int->{mark}, $otherColor, 0, 0);
        } else {
            my $mv = '';
            $mv .= " black node=$int->{black}" if (exists($int->{black}));
            $mv .= " white node=$int->{white}" if (exists($int->{white}));
            carp("Oops: understone$mv is not numbered or marked? " .
                 "This isn't supposed to be possible!");
        }
        $my->mpprint("endfig;\n");
        if ($ii < @{$diagram->getoverlist} - 1) {
            $my->print(',');
        }
        $my->print("\\hfil\\break\n");
    }
}

sub _checkStoneNumber {
    my ($my, $number) = @_;

    if ($number - $my->{stoneOffset} > 0) {
        return $number - $my->{stoneOffset};
    }
    if ($number < 1) {
        carp "Yikes: stone number $number is less than 1.  Intersection/stone will be missing!";
    } else {
        carp "Stone number $number and offset $my->{stoneOffset} makes less than 1 - not using offset";
    }
    return $number;
}

# get tex for intersection hash from $diagram.
sub _convertIntersection {
    my ($my, $diagram, $x, $y) = @_;

    my $int = $diagram->get($my->diaCoords($x, $y));
    return if ($my->{VW} and            # view control AND
               not exists($int->{VW})); # no view on this intersection
    my $color = BLACK;
    my $otherColor = BLACK;
    if (exists($int->{black})) {
        $otherColor = WHITE;
        $my->mpprint("_stone($x, $y, $color);\n");
    } elsif (exists($int->{white})) {
        $color = WHITE;
        $my->mpprint("_stone($x, $y, $color);\n");
    } else {
        if ($my->{draw_underneath}) {
            # draw the appropriate intersection
            $my->mpprint("_int($x, $y);\n");
        }   # else the whole board underneath has already been drawn for us
        if (exists($int->{hoshi})) {
            $my->mpprint("_hoshi($x, $y);\n");
        }
        if (exists($int->{label}) or
             exists($int->{number})) {
            # clear some space at intersection for the number/label
            $my->mpprint("_blank($x, $y);\n");
        }
    }
    if (exists($int->{number})) {
        my $num = $my->_checkStoneNumber($int->{number}); # numbered stone
        $my->mpprint("_label($x, $y, \"$num\", $otherColor);\n");
    } elsif (exists($int->{mark})) {
        $my->_drawMark($int->{mark}, $otherColor, $x, $y);
    } elsif (exists($int->{label})) {
        $my->mpprint("_label($x, $y, \"$int->{label}\", $otherColor);\n");
    }
}

sub _drawMark {
    my ($my, $mark, $color, $x, $y) = @_;

    my $func = '_mark';     # MA[pt]    default mark type
    if ($mark eq 'TR') {        # TR[pt]      triangle
        $func = '_triangle';
    } elsif ($mark eq 'CR') {   # CR[pt]      circle
        $func = '_circle';
    } elsif ($mark eq 'SQ') {   # SQ[pt]      square
        $func = '_square';
    }
    $my->mpprint("$func($x, $y, $color)\n");
}

sub _preamble {
    my ($my) = @_;

    $my->{mpfignum} = 0 unless(exists($my->{mpfignum}));
    $my->{mpfignum}++;
    $my->print("\\epsffile{$my->{mpfigname}.$my->{mpfignum}}\n");
    $my->mpprint("beginfig($my->{mpfignum});\n");
}

sub _postamble {
    my ($my) = @_;

    if ($my->{twoColumn}) {
        $my->print("\n\n");
    } elsif ($my->{longComments}) {
        $my->print(
               # "\\par\\vfil\n",
               # "\\diagdim=\\ht\\diagbox\n",
               # "\\ifdim\\ht\\captionbox>280pt\n",
               # "\\vbox to 280pt{\\box\\diagbox\\vglue-\\diagdim\\vsplit\\captionbox to 280pt}\n",
               # "\\nointerlineskip\\unvbox\\captionbox\n",
               # "\\else\n",
               # "\\ifdim\\ht\\captionbox>\\diagdim\\fulldim=\\ht\\captionbox\n",
               # "  \\else\\fulldim=\\diagdim\\fi\n",
               # "\\vbox to\\fulldim{\\box\\diagbox\\vglue-\\diagdim\\box\\captionbox}\n",
               # "\\fi\n\n",
                );
    } elsif ($my->{simple}) {
        $my->print("\n\n");
    } else {
        # not LongComments and not Simple
        $my->print("\\par\\vfil\n",
                "\\diagdim=\\ht\\diagbox\n",
                "\\ifdim\\ht\\captionbox>\\diagdim\\fulldim=\\ht\\captionbox\n",
                "  \\else\\fulldim=\\diagdim\\fi\n",
                "\\vbox to\\fulldim{\\box\\diagbox\\vglue-\\diagdim\\box\\captionbox}\n\n");
    }
}

1;

__END__

=back

=head1 SEE ALSO

=over

=item L<sgf2dg>(1)

Script to convert SGF format files to Go diagrams

=back

=head1 BUGS

Is this a trick question?

