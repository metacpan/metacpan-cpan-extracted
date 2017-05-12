#===============================================================================
#
#         FILE:  Dg2Tk
#
#     ABSTRACT:  convert Games::Go::Sgf2Dg::Diagrams to perl/Tk windows
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#===============================================================================
#
#   Copyright (C) 2005 Reid Augustin reid@hellosix.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#

=head1 SYNOPSIS

use Games::Go::Sgf2Dg::Dg2Tk

 my $dg2tk = B<Games::Go::Sgf2Dg::Dg2Tk-E<gt>new> (options);
 my $canvas = $dg2tk->convertDiagram($diagram);

=head1 DESCRIPTION

A Games::Go::Sgf2Dg::Dg2Tk object converts a L<Games::Go::Sgf2Dg::Diagram> object
into Tk::Canvas item.  The B<close> method calls Tk::MainLoop to
dispays the collection of Canvases.

Bindings for the normal editing keys: Up, Down, Next (PageDown) and
Prior (PageUp) traverse the NoteBook tabs.  Tab and Shift-tab also
work as expected.

Left and Right keys select the previous or next NoteBook tab, but
don't display it.  Space and Enter (carriage return) display the
selected tab.

=cut

use strict;
require 5.001;

package Games::Go::Sgf2Dg::Dg2Tk;
use Tk;
use Tk::NoteBook;
use Tk::Canvas;
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
    );

use constant TEXT_Y_OFFSET  => 1;
use constant NORMAL_PEN     => 1;
use constant BOARD_EDGE_PEN => NORMAL_PEN * 2;
use constant MARK_PEN       => NORMAL_PEN * 3;

######################################################
#
#       Public methods
#
#####################################################

=head1 NEW

=over 4

=item my $dg2tk = B<Games::Go::Sgf2Dg::Dg2Tk-E<gt>new> (?options?)

Any options passed to Dg2Tk that are not recognized are passed in
turn to the Tk::Canvas widgets as they are created (which may
cause errors if Tk::Canvas also does not recognize them).

=back

A B<new> Games::Go::Sgf2Dg::Dg2Tk takes the following options:

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

=item B<diaCoords> =E<gt> sub { # convert $x, $y to Games::Go::Sgf2Dg::Diagram
coordinates }

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

=back

=cut

sub new {
    my ($proto, %args) = @_;

    my $my = {};
    bless($my, ref($proto) || $proto);
    $my->{fontWidth} = 1;
    $my->{fontHeight} = 1;
    $my->{lineWidth} = 1;
    $my->{lineHeight} = 1;
    $my->{rightEdge} = 1;
    $my->{bottomEdge} = 1;
    foreach (keys(%options)) {
        $my->{$_} = $options{$_};  # transfer default options
    }
    $my->{mw} = MainWindow->new;
    my $nb = $my->{notebook} = $my->{mw}->NoteBook();
    $nb->pack(
            -expand => 'true',
            -fill   => 'both');
    $nb->configure(-takefocus => 1); # for tab-traversal
    # tab traversal bindings:
    $nb->bind( '<Tab>', sub { $nb->raise($nb->info('focusnext')); });
    $nb->bind( '<Next>', sub { $nb->raise($nb->info('focusnext')); });
    #$nb->bind( '<Right>', sub { $nb->raise($nb->info('focusnext')); });
    $nb->bind( '<Down>', sub { $nb->raise($nb->info('focusnext')); });
    $nb->bind( '<Shift-Tab>', sub { $nb->raise($nb->info('focusprev')); });
    $nb->bind( '<Prior>', sub { $nb->raise($nb->info('focusprev')); });
    #$nb->bind( '<Left>', sub { $nb->raise($nb->info('focusprev')); });
    $nb->bind( '<Up>', sub { $nb->raise($nb->info('focusprev')); });
    # bizzare - looks like we need this too:
    $nb->bind( '<<LeftTab>>', sub { $nb->raise($nb->info('focusprev')); });
    # transfer user args
    $my->configure(%args);
    return($my);
}

=head1 METHODS

=over 4

=item $dg2tk-E<gt>B<configure> (option =E<gt> value, ?...?)

Change Dg2Tk options from values passed at B<new> time.

=cut

sub configure {
    my ($my, %args) = @_;

    foreach (keys(%args)) {
        if (exists($options{$_})) {
            $my->{$_} = $args{$_};  # transfer user option
        } else {
            $my->{canvasOpts}{$_} = $args{$_};  # assume it's a canvas option
        }
    }
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

=item $dg2tk-E<gt>B<print> ($text ? , ... ?)

For most Dg2 converters, B<print> inserts diagram source code (TeX,
ASCII, whatever) directly into the diagram source stream.  Since Tk
diplays the diagrams immediately, there is no concept of a source
stream, so B<print> just generates a warning.

=cut

sub print {
    my ($my, @args) = @_;

    carp("->print(...) does nothing");
}

=item $dg2tk-E<gt>B<printComment> ($text ? , ... ?)

Adds $text to the diagram comments.

=cut

sub printComment {
    my ($my, @args) = @_;

    foreach(@args) {
        chomp;
        foreach my $line (@{$my->_commentSplit($_)}) {
            $my->{currentBoard}->createText(2 * $my->{fontWidth}, $my->{textY},
                                            -anchor => 'sw',
                                            -text   => $line);
            $my->{textY} += (1.2 * $my->{fontHeight});
        }
    }
}

sub _commentSplit {
    my ($my, $comment) = @_;

    my @massagedLines;
    my $charsPerLine = ($my->{rightEdge} / $my->{fontWidth});
    my $tab = '';
    my $line = '';
    while ($comment ne '') {
        $comment =~ s/(\s*)(\S*)//m;
        my $space = defined($1) ? $1 : '';
        my $token = defined($2) ? $2 : '';
        defined($token) or $token = '';
        while ($space =~ s/.*?\n//) {
            push(@massagedLines, $line);
            $line = '';
            $tab = $space;      # space after newlines tabs over following lines
        }
        if (length($line) + length($space) + length($token) > $charsPerLine) {
            push(@massagedLines, $line);
            $line = '';
            $space = $tab;
        }
        $line .= "$space$token";
    }
    push (@massagedLines, $line) if ($line ne '');
    return \@massagedLines
}

=item $dg2tk-E<gt>B<comment> ($comment ? , ... ?)

For most Dg2 converters, B<comment> inserts comments into the
diagram source code (TeX, ASCII, whatever).  Since Tk diplays the
diagrams immediately, there is no concept of a source stream, so
B<comment> does nothing.


=cut

sub comment {
    my ($my, @comments) = @_;

    # carp("->comment(...) does nothing");
}

=item my $canvas = $dg2tk-E<gt>B<convertDiagram> ($diagram)

Converts a I<Games::Go::Sgf2Dg::Diagram> into a Tk::Canvas widget.  Returns
a reference to the Canvas.  The Canvas is also added to the
Tk::NoteBook collection of diagrams that are displayed (at B<close>
time).

=cut

sub convertDiagram {
    my ($my, $diagram) = @_;

    my @name = $diagram->name;
    $name[0] = 'Unknown Diagram' unless(defined($name[0]));
    my $pageLabel = '?';
    if ($name[0] =~ m/^Variation\s*(\S*)/) {
        $pageLabel = "V$1";
    } elsif ($name[0] =~ m/^Diagram\s*(\S*)/) {
        $pageLabel = "D$1";
    }
    $my->{currentPage} = $my->{notebook}->add(++$my->{pageNum}, -label => $pageLabel);
    # $my->{currentPage}->pack( # Yikes! packing notebook pages is a # bug!!!
    #         -expand => 'true',
    #         -fill   => 'both');
    my $scroller = $my->{currentPage}->Scrolled('Canvas',
                                                 -scrollbars => 'osoe',
                                                 -takefocus => 0,
                                                 %{$my->{canvasOpts}});
    $scroller->pack(
            -expand => 'true',
            -fill   => 'both');
    $my->{currentBoard} = $scroller->Subwidget('scrolled');
    push (@{$my->{diagrams}}, $scroller);
    $my->{currentBoard}->pack(
            -expand => 'true',
            -fill   => 'both');

    if($my->{fontWidth} == 1) {
        my $idx = $my->{currentBoard}->createText(0, 0, -text => 'AbcDefGhiJkl');
        my ($l, $u, $r, $b) = $my->{currentBoard}->bbox($idx);
        $my->{fontWidth} = abs($r - $l) / 12;
        $my->{fontHeight} = abs($b - $u);
        $my->{lineWidth} = ($my->{fontWidth} * 4);           # need space for three digits
        $my->{lineHeight} = ($my->{lineWidth} * 1.05);       # 95% aspect ratio
        $my->{currentBoard}->delete($idx);
    }
    $my->{rightEdge} = $my->_boardX($my->{rightLine}) + $my->{lineWidth};
    $my->{rightEdge} += 1 if ($my->{coords});
    $my->{textY} = $my->{bottomLine} + 1;
    $my->{textY} += 1 if ($my->{coords});
    $my->{textY} = $my->_boardY($my->{textY}) + $my->{fontHeight};

    unless(exists($my->{titleDone})) {      # first diagram only:
        $my->{titleDone} = 1;
        my @title_lines = $diagram->gameProps_to_title();
        my $title = '';
        foreach (@title_lines) {
            $title .= "$_\n";
        }
        if($title ne '') {
            $my->printComment("$title\n\n");
        }
    }
    my $propRef = $diagram->property;       # get property list for the diagram
    $my->{VW} = exists($propRef->{0}{VW});  # view control?
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

    my ($diaHeight, $diaWidth) = (($my->{bottomLine} - $my->{topLine} + 1), ($my->{rightLine} - $my->{leftLine} + 1));
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

    # print the diagram title
    $my->printComment(join('', @name, $range, "\n"));
    # draw the diagram
    foreach my $y ($my->{topLine} .. $my->{bottomLine}) {
        foreach my $x ($my->{leftLine} ..  $my->{rightLine}) {
            $my->_convertIntersection($diagram, $x, $y);
        }
        if ($my->{coords}) {    # right-side coords
            $my->{currentBoard}->createText($my->_boardX($my->{rightLine} + 1),
                                            $my->_boardY($y),
                                            -text => $diagram->ycoord($y));
        }
    }
    # print bottom coordinates
    if ($my->{coords}) {
        for ($my->{leftLine} .. $my->{rightLine}) {
            $my->{currentBoard}->createText($my->_boardX($_),
                                            $my->_boardY($my->{bottomLine} + 1),
                                            -text => $diagram->xcoord($_));
        }
    }

    # deal with the over-lay stones
    $my->_convertOverstones($diagram);
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
            $c .= join("\n", @comment);
            $my->printComment($my->convertText("$c\n"));
        }
    }
    $my->{bottomEdge} = $my->{textY} + $my->{fontHeight};
    $my->{bottomEdge} += $my->{lineHeight} if ($my->{coords});
    $my->{currentBoard}->configure(-scrollregion => [0, 0, $my->{rightEdge}, $my->{bottomEdge}],);
    unless($my->{resizeDone}) {
        $my->{currentBoard}->configure(-width => $my->{rightEdge} + 5,
                                       -height => $my->{bottomEdge} + 5);
        $my->{resizeDone} = 1;
    }
    $my->{mw}->update;
    unless(exists($my->{canvas_bg})) {
        $my->{canvas_bg} = $my->{currentBoard}->cget('-background');
        # on the first board, we may not be able to color background items correctly:
        $my->{currentBoard}->itemconfigure('bg', -fill => $my->{canvas_bg});
    }
    Tk::focus($my->{notebook});
}

=item my $converted_text = $dg2tk-E<gt>B<convertText> ($text)

Converts $text into text for display - gee, that's not very hard.
In fact, this method simply returns whatever is passed to it.  This
is really just a place-holder for more complicated converters.

Returns the converted text.

=cut

sub convertText {
    my ($my, $text) = @_;

    return $text;
}

=item $dg2tk-E<gt>B<close>

B<print>s any final text to the diagram (currently none) and closes
the dg2tk object.  Also closes B<file> if appropriate.

=cut

sub close {
    my ($my) = @_;

    $my->{mw}->MainLoop;      # never to return...
}

=item $dg2tk-E<gt>B<notebook>

Returns a reference to the notebook of L<Tk::Canvas> objects.

=cut

sub notebook {
    my ($my) = @_;

    return $my->{notebook}; # the notebook object
}

=item $dg2tk-E<gt>B<diagrams>

Returns a reference to the list of L<Tk::Canvas> objects that make
up the Tk::NoteBook of diagrams.  Note that each item in the list is
actually a L<Tk::Scrolled> object, the actual Tk::Canvas object is:

    my $canvas = $dg2tk->diagrams->[$idx]->Subwidget('scrolled');

=cut

sub diagrams {
    my ($my) = @_;

    return $my->{diagrams}; # the list of diagrams
}

######################################################
#
#       Private methods
#
#####################################################

sub _convertOverstones {
    my ($my, $diagram) = @_;

    my @converted;

    return unless (@{$diagram->getoverlist});

    my ($color, $number, $otherColor);
    for (my $ii = 0; $ii < @{$diagram->getoverlist}; $ii++) {
        my $int = $diagram->getoverlist->[$ii];
        $my->{textY} += $my->{lineHeight} - $my->{fontHeight};  # adjust for stone height
        my $x = 2 * $my->{fontWidth};
        # all the overstones that were put on this understone:
        for (my $jj = 0; $jj < @{$int->{overstones}}; $jj += 2) {
            if ($jj > 0 ) {
                $my->{currentBoard}->createText($x, $my->{textY},
                                                -anchor => 'sw',
                                                -text => ',');
                $x += $my->{fontWidth};
            }
            $color = $int->{overstones}[$jj];
            local $my->{stoneOffset} = $my->{offset};   # turn off doubleDigits
            $number = $my->_checkStoneNumber($int->{overstones}[$jj+1]);
            # draw the overstone
            my $left = $x;
            my $right = $x + $my->{lineWidth};
            my $top = $my->{textY} - $my->{lineHeight};
            my $bottom = $my->{textY};
            $my->{currentBoard}->createOval($left, $top, $right, $bottom,
                            -fill => $color,
                            );
            # put the number on it
            $otherColor = ($color eq 'black') ? 'white' : 'black';
            $my->{currentBoard}->createText(
                            $x + ($my->{lineWidth} / 2),
                            $my->{textY} + TEXT_Y_OFFSET - ($my->{lineHeight} / 2),
                            -fill => $otherColor,
                            -text => $number
                            );
            $x += $my->{lineWidth};
        }
        # the 'at' stone
        if (exists($int->{black})) {
            $color = 'black';
            $otherColor = 'white';
        } elsif (exists($int->{white})) {
            $color = 'white';
            $otherColor = 'black';
        } else {
            carp("Oops: understone is not black or white? " .
                 "This isn't supposed to be possible!");
            next;
        }
        # at
        $my->{currentBoard}->createText($x, $my->{textY},
                                        -anchor => 'sw',
                                        -text => ' at ');
        $x += 3 * $my->{fontWidth};
        # draw the at-stone
        my $left = $x;
        my $right = $x + $my->{lineWidth};
        my $top = $my->{textY} - $my->{lineHeight};
        my $bottom = $my->{textY};
        $my->{currentBoard}->createOval($left, $top, $right, $bottom,
                        -fill => $color,
                        );
        if (exists($int->{number})) {
            # put the number on it
            $my->{currentBoard}->createText(
                            $x + ($my->{lineWidth} / 2),
                            $my->{textY} + TEXT_Y_OFFSET - ($my->{lineHeight} / 2),
                            -fill => $otherColor,
                            -text => $my->_checkStoneNumber($int->{number})
                            );
        } elsif (exists($int->{mark})) {
            # draw the mark on it
            $my->_drawMark($int->{mark}, $otherColor,
                            ($left + $right) / 2,
                            ($top + $bottom) / 2);
        } else {
            my $mv = '';
            $mv .= " black node=$int->{black}" if (exists($int->{black}));
            $mv .= " white node=$int->{white}" if (exists($int->{white}));
            carp("Oops: understone$mv is not numbered or marked? " .
                 "This isn't supposed to be possible!");
        }
        $x += $my->{lineWidth};
        if ($ii < @{$diagram->getoverlist} - 1) {
            $my->{currentBoard}->createText($x, $my->{textY},
                                            -anchor => 'sw',
                                            -text => ',');
        }
        $my->{textY} += (1.2 * $my->{fontHeight});
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

# convert intersection hash from $diagram.
sub _convertIntersection {
    my ($my, $diagram, $x, $y) = @_;

    my $int = $diagram->get($my->diaCoords($x, $y));
    return if ($my->{VW} and            # view control AND
               not exists($int->{VW})); # no view on this intersection
    my ($stone, $label, $color, $otherColor);
    if (exists($int->{black})) {
        $color = 'black';
        $otherColor = 'white';
        $stone = 1;
    } elsif (exists($int->{white})) {
        $color = 'white';
        $otherColor = 'black';
        $stone = 1;
    } else {
        $color = 'black';
        $otherColor = 'black';
        $stone = 0;
        $my->_draw_underneath($int, $x, $y);
    }
    if (exists($int->{number})) {
        $label = $my->_checkStoneNumber($int->{number}); # numbered stone
    } elsif (exists($int->{label})) {
        $label = $int->{label};             # labeled stone or intersection
    }

    my $xx = $my->_boardX($x);
    my $yy = $my->_boardY($y);
    if ($stone) {
        $my->{currentBoard}->createOval(
            $xx - $my->{lineWidth} / 2,     # left
            $yy - $my->{lineHeight} / 2,    # top
            $xx + $my->{lineWidth} / 2,     # right
            $yy + $my->{lineHeight} / 2,    # bottom
            -fill => $color,
            );
    } elsif (defined($label)) {
        # create some whitespace to draw label on
        $my->{currentBoard}->createOval(
            $xx - $my->{lineWidth} / 3,     # left
            $yy - $my->{lineHeight} / 3,    # top
            $xx + $my->{lineWidth} / 3,     # right
            $yy + $my->{lineHeight} / 3,    # bottom
            -fill    => $my->{canvas_bg},
            -outline => undef,
            -tags    => ['bg']);
    }
    if (defined($label)) {
        $my->{currentBoard}->createText(
            $xx,
            $yy + TEXT_Y_OFFSET,
            -fill => $otherColor,
            -text => $label
            );
    }
    if (exists($int->{mark})) {
        $my->_drawMark($int->{mark}, $otherColor, $xx, $yy);
    }
}

sub _draw_left {
    my ($my, $width, $x, $y) = @_;
    $my->{currentBoard}->createLine(
            $x + 1,
            $y,
            $x - ($my->{lineWidth} / 2) - 1,
            $y,
            -width => $width);
}

sub _draw_right {
    my ($my, $width, $x, $y) = @_;
    $my->{currentBoard}->createLine(
            $x - 1,
            $y,
            $x + ($my->{lineWidth} / 2) + 1,
            $y,
            -width => $width);
}

sub _draw_up {
    my ($my, $width, $x, $y) = @_;
    $my->{currentBoard}->createLine(
            $x,
            $y + 1,
            $x,
            $y - ($my->{lineWidth} / 2) - 1,
            -width => $width);
}

sub _draw_down {
    my ($my, $width, $x, $y) = @_;
    $my->{currentBoard}->createLine(
            $x,
            $y - 1,
            $x,
            $y + ($my->{lineWidth} / 2) + 1,
            -width => $width);
}

sub _draw_underneath {
    my ($my, $int, $xx, $yy) = @_;

    my $x = $my->_boardX($xx);
    my $y = $my->_boardY($yy);
    if ($yy <= 1) {
        if ($xx <= 1) {                     # upper left corner
            $my->_draw_right(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_down(BOARD_EDGE_PEN, $x, $y);
        } elsif ($xx >= $my->{boardSizeX}) {# upper right corner
            $my->_draw_left(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_down(BOARD_EDGE_PEN, $x, $y);
        } else {                            # upper side
            $my->_draw_left(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_right(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_down(NORMAL_PEN, $x, $y);
        }
    } elsif ($yy >= $my->{boardSizeY}) {
        if ($xx <= 1) {                     # lower left corner
            $my->_draw_right(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_up(BOARD_EDGE_PEN, $x, $y);
        } elsif ($xx >= $my->{boardSizeX}) {# lower right corner
            $my->_draw_left(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_up(BOARD_EDGE_PEN, $x, $y);
        } else {                            # lower side
            $my->_draw_left(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_right(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_up(NORMAL_PEN, $x, $y);
        }
    } else {
        if ($xx <= 1) {                     # left side
            $my->_draw_up(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_down(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_right(NORMAL_PEN, $x, $y);
        } elsif ($xx >= $my->{boardSizeX}) {# right side
            $my->_draw_up(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_down(BOARD_EDGE_PEN, $x, $y);
            $my->_draw_left(NORMAL_PEN, $x, $y);
        } else {                            # somewhere in the middle
            $my->_draw_up(NORMAL_PEN, $x, $y);
            $my->_draw_down(NORMAL_PEN, $x, $y);
            $my->_draw_left(NORMAL_PEN, $x, $y);
            $my->_draw_right(NORMAL_PEN, $x, $y);
        }
    }
    if (exists($int->{hoshi})) {
        $my->_drawHoshi($x, $y);
    }
}

sub _drawMark {
    my ($my, $mark, $color, $x, $y) = @_;

    if ($mark eq 'TR') {        # TR[pt]      triangle
        # triangle has top Y; left, right X; and bottom Y
        my $left   = $x - (.3 * $my->{lineWidth});    # cos(30) = .866
        my $right  = $x + (.3 * $my->{lineWidth});    # cos(30) = .866
        my $top    = $y - ($my->{lineHeight} / 3);
        my $bottom = $y + ($my->{lineHeight} / 6);      # sin(30) = .5
        $my->{currentBoard}->createLine(
                           $x,     $top,
                           $right, $bottom,
                           $left,  $bottom,
                           $x,     $top,
                           -fill => $color,
                           -width => MARK_PEN
                        );
    } else {
        # circle, square, and X mark is centered at X, Y, 50% of usual stone size
        my $left   = $x - (.25 * $my->{lineWidth});
        my $right  = $x + (.25 * $my->{lineWidth});
        my $top    = $y - (.25 * $my->{lineHeight});
        my $bottom = $y + (.25 * $my->{lineHeight});
        if ($mark eq 'CR') {   # CR[pt]      circle
            $my->{currentBoard}->createOval(
                               $left,  $top,
                               $right, $bottom,
                               -outline => $color,
                               -width => MARK_PEN
                            );
        } elsif ($mark eq 'SQ') {   # SQ[pt]      square
            $my->{currentBoard}->createLine(
                               $left,  $top,
                               $right, $top,
                               $right, $bottom,
                               $left,  $bottom,
                               $left,  $top - 1,
                               -fill => $color,
                               -width => MARK_PEN
                            );
        } else {                    # MA[pt]      mark (X)
            $my->{currentBoard}->createLine(
                               $left,  $top,
                               $right, $bottom,
                               -fill => $color,
                               -width => MARK_PEN
                            );
            $my->{currentBoard}->createLine(
                               $right, $top,
                               $left,  $bottom,
                               -fill => $color,
                               -width => MARK_PEN
                            );
        }
    }
}

sub _drawHoshi {
    my ($my, $x, $y) = @_;

    my $size = ($my->{lineWidth} * 0.05);   # 10% size of a stone
    $size = 1 if $size <= 0;
    my $left = $x - $size;
    my $right = $left + 2 * $size;
    my $top = $y - $size;
    my $bottom = $top + 2 * $size;
    $my->{currentBoard}->createOval($left, $top, $right, $bottom,
                    -fill => 'black'
                    );
}

sub _boardX {
    my ($my, $x) = @_;

    return (($x - $my->{leftLine} + 1.5) * $my->{lineWidth});
}

sub _boardY {
    my ($my, $y) = @_;

    return (($y - $my->{topLine} + 1.5) * $my->{lineHeight});
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

We ain't got to show you no stinkin' bugs!

