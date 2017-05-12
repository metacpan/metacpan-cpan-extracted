#===============================================================================
#
#         FILE:  Dg2Ps
#
#     ABSTRACT:  convert Games::Go::Sgf2Dg::Diagrams to PostScript

#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#===============================================================================
#
#   Copyright (C) 2005 Reid Augustin reid@hellosix.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#
=head1 SYNOPSIS

use Games::Go::Sgf2Dg::Dg2Ps

 my $dg2ps = B<Games::Go::Sgf2Dg::Dg2Ps-E<gt>new> (options);
 $dg2ps->convertDiagram($diagram);

=head1 DESCRIPTION

B<Games::Go::Sgf2Dg::Dg2Ps> converts a L<Games::Go::Sgf2Dg::Diagram> into PostScript.

=cut

use strict;
require 5.001;

package Games::Go::Sgf2Dg::Dg2Ps;
eval { require PostScript::File; };   # is this module available?
if ($@) {
    die ("
    Dg2Ps needs the PostScript::File module, but it is not available.
    You can find PostScript::File in the same repository where you found
    Games::Go::Sgf2Dg, or from http://search.cpan.org/\n\n");
}

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
    # PDF=specific options:
    pageSize        => 'Letter',
    topMargin       => 72 * .70,
    bottomMargin    => 72 * .70,
    leftMargin      => 72 * .70,
    rightMargin     => 72 * .70,
    text_fontName   => 'Times-Roman',
    text_fontSize   => 11,
    stone_fontName  => 'Courier-Bold',
    stone_fontSize  => 7,
    lineWidth       => 11,
    lineHeight      => 11,
    ps_debug        => 1,
    );

use constant TEXT_Y_OFFSET => -0.5;
use constant WHITE => 1;
use constant BLACK => 0;

######################################################
#
#       Public methods
#
#####################################################

=head1 NEW

=over 4

=item my $dg2ps = B<Games::Go::Sgf2Dg::Dg2Ps-E<gt>new> (?options?)

=back

A B<new> Games::Go::Sgf2Dg::Dg2Ps takes the following options:

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

=item B<print> =E<gt> sub { my ($dg2tex, @tex) = @_; ... }

A user defined subroutine to replace the default printing method.
This callback is called from the B<print> method (below) with the
reference to the B<Dg2TeX> object and a list of lines that are
part of the TeX diagram source.

=back

Dg2Ps-specific options:

=over 8

=item B<pageSize> =E<gt> 'page size'

May be one of:

=over 12

=item . 'A0' - 'A9'

=item . 'B0' - 'B10'

=item . 'Executive'

=item . 'Folio'

=item . ’Half-Letter’

=item . 'Letter'

=item . ’US-Letter’

=item . 'Legal

=item . ’US-Legal’

=item . 'Tabloid'

=item . ’SuperB’

=item . 'Ledger'

=item . ’Comm #10 Envelope’

=item . ’Envelope-Monarch’

=item . ’Envelope-DL’

=item . ’Envelope-C5’

=item . ’EuroPostcard’

=back

Default: 'Letter'

=item B<topMargin>    =E<gt> points

=item B<bottomMargin> =E<gt> points

=item B<leftMargin>   =E<gt> points

=item B<rightMargin>  =E<gt> points

Margins are set in PostScript 'user space units' which are approximately
equivilent to points (1/72 of an inch).

Default for all margins: 72 * .70 (7/10s of an inch)

=item B<text_fontName>  =E<gt> 'font'  Default: 'Times-Roman',

=item B<stone_fontName> =E<gt> 'font'  Default: 'Courier-Bold'

Text and stone fonts names may be one of these (case sensitive):

=over 4

=item Courier

=item Courier-Bold

=item Courier-BoldOblique

=item Courier-Oblique

=item Helvetica

=item Helvetica-Bold

=item Helvetica-BoldOblique

=item Helvetica-Oblique

=item Times-Roman

=item Times-Bold

=item Times-Italic

=item Times-BoldItalic

=back

=item B<text_fontSize>  =E<gt> points

The point size for the comment text.  Diagram titles use this size
plus 4, and the game title uses this size plus 6.

Default: 11

=item B<stone_fontSize> =E<gt> points

The stone_fontSize determines the size of the stones and diagrams.
Stone size is chosen to allow up to three digits on a stone .  The
default stone_fontSize allows for three diagrams (with -coords) per
'letter' page if comments don't take up extra space below diagrams.

If B<doubleDigits> is specified, the stones and board are slightly
smaller (stone 100 may look a bit cramped).

Default: 5

=item B<lineWidth> =E<gt> points

=item B<lineHeight> =E<gt> points

The B<lineWidth> and B<lineHeight> determine the size of the
stones and diagrams.

If B<lineWidth> is not explicitly set, it is calculated from the
B<stone_fontSize> to allow up to three digits on a stone .  The
default B<stone_fontSize> allows for three diagrams (with -coords)
per 'letter' page if comments don't take up extra space below
diagrams.  If B<doubleDigits> is specified, the stones and board are
slightly smaller (stone 100 may look a bit cramped).

If B<lineHeight> is not explicitly set, it will be 1.05 *
B<lineWidth>, creating a slightly rectangular diagram.

Default: undef - determined from B<stone_fontSize>

=item B<ps_debug> =#<gt> number from 0 to 2

When non-zero, code and subroutines are added to the PostScript
output to help debug the PostScript file.  This is very slightly
documented in L<PostScript::File>, but you'll probably need to read
through the PostScript output to make any use of it.

Default: 0

=back

=cut

sub new {
    my ($proto, %args) = @_;

    my $my = {};
    bless($my, ref($proto) || $proto);
    #$my->{lineWidth} = 1;
    #$my->{lineHeight} = 1;
    $my->{diagram_box_right} = 1;
    $my->{diagram_box_bottom} = 0;
    $my->{text_box_y_last} = 0;
    $my->{pre_init_print} = [];         # ref to empty array
    foreach (keys(%options)) {
        $my->{$_} = $options{$_};  # transfer default options
    }
    # transfer user args
    $my->configure(%args);
    return($my);
}

=head1 METHODS

=over 4

=item $dg2ps-E<gt>B<configure> (option =E<gt> value, ?...?)

Change Dg2Ps options from values passed at B<new> time.

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
            $my->{print} = sub { $_[0]->{ps}->add_to_page($_[1]) or
                                        die "Error writing to output file:$!\n"; };
        } else {
            require IO::File;
            $my->{filename} = $my->{file};
            $my->{file} = IO::File->new($my->{filename}) or
                die("Error opening $my->{filename}: $!\n");
            $my->{print} = sub { $_[0]->{ps}->add_to_page($_[1]) or
                                        die "Error writing to $_[0]->{filename}:$!\n"; };
        }
    }
    foreach (keys(%args)) {
        if (exists($options{$_})) {
            $my->{$_} = $args{$_};  # transfer user option
        } else {
            carp("Unknown option: $_");
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

=item $dg2ps-E<gt>B<print> ($text ? , ... ?)

B<print>s raw PostScript code to B<file> as defined at B<new> time.

=cut

sub print {
    my ($my, @args) = @_;

    foreach my $arg (@args) {
        next unless (defined($arg) and
                     ($arg ne ''));
        if(exists($my->{ps})) {
            &{$my->{print}} ($my, $arg);
        } else {
            push(@{$my->{pre_init_print}}, @args);
        }
    }
}

=item $dg2ps-E<gt>B<printComment> ($text ? , ... ?)

Adds $text to the diagram comments.

=cut

sub printComment {
    my ($my, @args) = @_;

    foreach(@args) {
        $my->_flow_text($_);
    }
}

=item $dg2ps-E<gt>B<comment> ($comment ? , ... ?)

Inserts the PostScript comment character ('%') in front of each line of
each comment and B<print>s it to B<file>.

Note that this is I<not> the same as the B<printComment> method.

=cut

sub comment {
    my ($my, @comments) = @_;

    foreach my $c (@comments) {
        while ($c =~ s/([^\n]*)\n//) {
            $my->print("%$1\n");
        }
        $my->print("%$c\n") if ($c ne '');
    }
}

=item my $canvas = $dg2ps-E<gt>B<convertDiagram> ($diagram)

Converts a L<Games::Go::Sgf2Dg::Diagram> into PostScript.

=cut

sub convertDiagram {
    my ($my, $diagram) = @_;

    unless(exists($my->{ps})) {
        $my->_createPostScript;
        $my->{firstPage} = 1;
        # set default font
        $my->print("/$my->{text_fontName} findfont $my->{text_fontSize} scalefont setfont\n");
        $my->print(join("\n", @{$my->{pre_init_print}}));
    }
    my @name = $diagram->name;
    $name[0] = 'Unknown Diagram' unless(defined($name[0]));
    $my->comment("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");
    $my->comment("Start of $name[0]");
    $my->comment("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");

    $my->_next_diagram_box;      # get location for next diagram
    my $propRef = $diagram->property;                   # get property list for the diagram
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

    # these board-drawing constants need to be changed for each new board
    $my->print("/diagram_box_left $my->{diagram_box_left} def /diagram_box_top $my->{diagram_box_top} def\n");
    $my->print("/left_line $my->{leftLine} def /top_line $my->{topLine} def\n");
    if ($my->{VW}) {    # view control
        $my->{draw_underneath} = 1;     # draw each intersection individually
    } else {
        # draw the underneath part (the board)
        my $x = $my->_boardX(-.5);
        my $y = $my->_boardY(-.5);
        $my->print("$my->{leftLine} $my->{topLine} $my->{rightLine} $my->{bottomLine} _board\n");
    }

    # draw the diagram
    foreach my $y ($my->{topLine} .. $my->{bottomLine}) {
        foreach my $x ($my->{leftLine} ..  $my->{rightLine}) {
            $my->_convertIntersection($diagram, $x, $y);
        }
        if ($my->{coords}) {    # right-side coords
            my $coord = $diagram->ycoord($y);
            my $xx = $my->_boardX($my->{rightLine} + 1);
            my $yy = $my->_boardY($y) + TEXT_Y_OFFSET;
            my $color = BLACK;
            $my->print("($coord) $xx $yy $color _label\n");
        }
    }
    # print bottom coordinates
    if ($my->{coords}) {
        for ($my->{leftLine} .. $my->{rightLine}) {
            my $coord = $diagram->xcoord($_);
            my $xx = $my->_boardX($_);
            my $yy = $my->_boardY($my->{bottomLine} + 1) + TEXT_Y_OFFSET;
            my $color = BLACK;
            $my->print("($coord) $xx $yy $color _label\n");
        }
    }

    # now handle text associated with this diagram
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

    {
        local $my->{text_fontSize} = $my->{text_fontSize} + 4;
        unless(exists($my->{titleDone})) {      # first diagram only:
            $my->{titleDone} = 1;
            my @title_lines = $diagram->gameProps_to_title();
            my $title = '';
            foreach (@title_lines) {
                $title .= "$_\n";
            }
            if($title ne '') {
                $my->print("gsave /$my->{text_fontName} findfont $my->{text_fontSize} scalefont setfont\n");
                $my->printComment("$title\n");
                $my->print("grestore\n");
            }
        }
        $my->{text_fontSize} -= 2;
        # print the diagram title
        $my->print("gsave /$my->{text_fontName} findfont $my->{text_fontSize} scalefont setfont\n");
        $my->printComment($my->convertText(join('', @name, $range, "\n")));
        $my->print("grestore\n");

    }
    # the over-lay stones
    $my->_convertOverstones($diagram);
    $my->printComment("\n");
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
}

=item my $converted_text = $dg2ps-E<gt>B<convertText> ($text)

Converts $text into text for display (handles PostScript escape
sequences).

Returns the converted text.

=cut

sub convertText {
    my ($my, $text) = @_;

# PostScript escapes:
#   \\ backslash
#   \( left parenthesis
#   \) right parenthesis
#   \n line feed (LF)
#   \r carriage return (CR)
#   \t horizontal tab
#   \b backspace
#   \f form feed
#   \ddd character code ddd (octal)
    $text =~ s/([)(\\])/\\$1/gs;
    # turn single \n into single space.  multiple \n's are broken during _flow_text
    # $text =~ s/([^\n])\n([^\n])/$1 $2/gs;
    $text =~ s/\r/\\r/gs;
    $text =~ s/\t/\\t/gs;
    # $text =~ s/\b/\\b/gs;     # hmmm, \b is word boundary in perl
    $text =~ s/\f/\\f/gs;

    return $text;
}

=item $dg2ps-E<gt>B<close>

B<print>s final PostScript code to the output file and closes the
file.

=cut

sub close {
    my ($my) = @_;

    my $ps = $my->{ps}->output;
    if ((ref($my->{file}) eq 'GLOB') or
        (ref($my->{file}) eq 'IO::File')) {
        $my->{file}->print($ps);
        $my->{file}->close;
    }
    return $ps;
}

######################################################
#
#       Private methods
#
#####################################################

sub _convertOverstones {
    my ($my, $diagram) = @_;

    return unless (@{$diagram->getoverlist});

    my ($color, $number, $otherColor);
    for (my $ii = 0; $ii < @{$diagram->getoverlist}; $ii++) {
        my $int = $diagram->getoverlist->[$ii];
        $my->{text_box_y} += $my->{text_fontSize};   # un-adjust for text line height
        $my->{text_box_y} -= $my->{lineHeight} * 1.2;# adjust for stone height
        my $x = $my->{text_box_left};
        # all the overstones that were put on this understone:
        my $comma = 0;
        for (my $jj = 0; $jj < @{$int->{overstones}}; $jj += 2) {
            if ($comma ) {
                $my->_createText(
                    $x, $my->{text_box_y} + TEXT_Y_OFFSET,
                    -anchor => 'e',
                    -text => ',');
                $x += $my->{text_fontSize} * $my->_string_width($my->{text_fontName}, ',');
            }
            if ($my->{text_box_right} - $x < 3 * $my->{lineWidth}) {
                $my->{text_box_y} -= $my->{lineHeight} * 1.2;  # drop to next line
                $x = $my->{text_box_left};
                $jj -= 2;
                $comma = 0;
                next;   # try again
            }
            $color = ($int->{overstones}[$jj] eq 'black') ? BLACK : WHITE;
            $otherColor = $color ? BLACK : WHITE;
            local $my->{stoneOffset} = $my->{offset};   # turn off doubleDigits
            $number = $my->_checkStoneNumber($int->{overstones}[$jj+1]);
            # draw the overstone
            $my->print("$x $my->{text_box_y} $color _stone\n");
            # put the number on it
            $my->print("($number) $x $my->{text_box_y} $otherColor _label\n");
            $x += $my->{lineWidth};
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
        $my->_createText(
            $x, $my->{text_box_y} + TEXT_Y_OFFSET,
            -anchor => 'center',
            -text => ' at ');
        $x += $my->{text_fontSize} * $my->_string_width($my->{text_fontName}, ' at');
        # draw the at-stone
        $my->print("$x $my->{text_box_y} $color _stone\n");
        if (exists($int->{number})) {
            $my->print("($int->{number}) $x $my->{text_box_y} $otherColor _label\n");
        } elsif (exists($int->{mark})) {
            $my->_drawMark($int->{mark}, $otherColor, $x, $my->{text_box_y});
        } else {
            my $mv = '';
            $mv .= " black node=$int->{black}" if (exists($int->{black}));
            $mv .= " white node=$int->{white}" if (exists($int->{white}));
            carp("Oops: understone$mv is not numbered or marked? " .
                 "This isn't supposed to be possible!");
        }
        $x += $my->{lineWidth};
        if ($ii < @{$diagram->getoverlist} - 1) {
            $my->_createText(
                $x, $my->{text_box_y} + TEXT_Y_OFFSET,
                -anchor => 'e',
                -text => ',');
        }
        $my->{text_box_y} -= $my->{text_fontSize};   # re-adjust for text line height
        $my->{text_box_y_last} = $my->{text_box_y};
        $my->{text_box_used} = 1;
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
    my $xx = $my->_boardX($x);
    my $yy = $my->_boardY($y);
    return if ($my->{VW} and            # view control AND
               not exists($int->{VW})); # no view on this intersection
    my $color = BLACK;
    my $otherColor = BLACK;
    if (exists($int->{black})) {
        $otherColor = WHITE;
        $my->print("$xx $yy $color _stone\n");
    } elsif (exists($int->{white})) {
        $color = WHITE;
        $my->print("$xx $yy $color _stone\n");
    } else {
        if ($my->{draw_underneath}) {
            # draw the appropriate intersection
            $my->print("$x $y _int\n");
        }   # else the whole board underneath has already been drawn for us
        if (exists($int->{hoshi})) {
            $my->print("$xx $yy _hoshi\n");
        }
        if (exists($int->{label}) or
             exists($int->{number})) {
            # clear some space at intersection for the number/label
            $my->print("$xx $yy _blank\n");
        }
    }
    if (exists($int->{number})) {
        my $num = $my->_checkStoneNumber($int->{number}); # numbered stone
        $my->print("($num) $xx $yy $otherColor _label\n");
    } elsif (exists($int->{mark})) {                    # marked stone or intersection
        $my->_drawMark($int->{mark}, $otherColor, $xx, $yy);
    } elsif (exists($int->{label})) {                   # labeled stone or intersection
        $my->print("($int->{label}) $xx $yy $otherColor _label\n");
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
    $my->print("$x $y $color $func\n");
}

sub _boardX {
    my ($my, $x) = @_;

    return $my->{diagram_box_left} + ($x - $my->{leftLine} + 0.5) * $my->{lineWidth};
}

sub _boardY {
    my ($my, $y) = @_;

    return $my->{diagram_box_top} - ($y - $my->{topLine} + 0.5) * $my->{lineHeight};
}

# imitate a Tk::Canvas createText call
# Note: default font is $my->{text_font} and fontSize is $my->{text_fontSize}
sub _createText {
    my ($my, $x, $y, %args) = @_;

    my $text = delete($args{-text});
    my $x_off = 0;
    my $y_off = 1;          # anchor offset - default to sw
    if ($args{-anchor}) {
        if ($args{-anchor} eq 'center') {
            delete($args{-anchor});
            $x_off = -.5;
            $y_off = .5;          # center anchor
        } elsif ($args{-anchor} eq 'e') {
            delete($args{-anchor});
            $x_off = -2;
            $y_off = .5;          # center anchor
        }
    }
    my $vspace = 3.6 * $my->{text_fontSize};
    foreach (keys(%args)) {
        carp ("Unknown args key in _createText: $_ = $args{$_}");
    }
    $my->print("$x $y [\n[($text)]\n] $vspace $x_off $y_off 0 DrawText\n");
}

sub _createPostScript {

    my ($my) = @_;

    my $ps = $my->{ps} = PostScript::File->new (
        paper    => $my->{pageSize},
        clipping => 1,
        errors   => 1,
        # strip    => 'none',
        order    => 'ascend',
        debug    => $my->{ps_debug},
        );

    $my->{page_left}   = 0 + $my->{leftMargin};
    $my->{page_right}  = $ps->get_width - $my->{rightMargin};
    $my->{page_top}    = $ps->get_height - $my->{topMargin};
    $my->{page_bottom} = 0 + $my->{bottomMargin};

    # figure out the font and line width and height
    my $fontScale = $my->{fontScale} = 0.4;  # approximate size in points when fontSize == 1
    unless(defined($my->{lineWidth})) {
        $my->{lineWidth} = $my->{doubleDigits} ?
                                $fontScale * 4.5 :    # need space for two digits (and 100)
                                $fontScale * 5.0;     # need space for three digits
        $my->{lineWidth} *= $my->{stone_fontSize};
    }
    my $hLines = (1 + $my->{rightLine}  - $my->{leftLine});
    my $vLines = (1 + $my->{bottomLine} - $my->{topLine});
    my $pageH = ($my->{page_top} - $my->{page_bottom});
    my $pageW = ($my->{page_right} - $my->{page_left});
    if ($my->{lineWidth}  * $hLines  > $pageW) {
        my $newW = $pageW / $hLines;
        carp "lineWidth of $my->{lineWidth} won't fit on the page.  I'm setting it to $newW\n";
        $my->{lineWidth} = $newW;
    }
    unless(defined($my->{lineHeight})) {
        $my->{lineHeight} = $my->{lineWidth} * 1.05;   # 95% aspect ratio
    }
    if ($my->{lineHeight}  * $vLines  > $pageH) {
        my $newH = $pageH / $vLines;
        carp "lineWidth of $my->{lineHeight} won't fit on the page.  I'm setting it to $newH\n";
        $my->{lineHeight} = $newH;
    }

    $my->{ps}->add_function('My_Functions', <<END_FUNCTIONS);
%
% Note: these functions are 'borrowed' from the Tk::Canvas
% postscript conversion method.
%
/cstringshow {
    {
    dup type /stringtype eq
    { show } { glyphshow }
    ifelse
    }
    forall
} bind def

/cstringwidth {
    0 exch 0 exch
    {
    dup type /stringtype eq
    { stringwidth } {
        currentfont /Encoding get exch 1 exch put (\001) stringwidth
        }
    ifelse
    exch 3 1 roll add 3 1 roll add exch
    }
    forall
} bind def

% x y strings spacing xoffset yoffset justify DrawText --
% This procedure does all of the real work of drawing text.  The
% color and font must already have been set by the caller, and the
% following arguments must be on the stack:
%
% x, y -    Coordinates at which to draw text.
% strings - An array of strings, one for each line of the text item,
%       in order from top to bottom.
% spacing - Spacing between lines.
% xoffset - Horizontal offset for text bbox relative to x and y: 0 for
%       nw/w/sw anchor, -0.5 for n/center/s, and -1.0 for ne/e/se.
% yoffset - Vertical offset for text bbox relative to x and y: 0 for
%       nw/n/ne anchor, +0.5 for w/center/e, and +1.0 for sw/s/se.
% justify - 0 for left justification, 0.5 for center, 1 for right justify.
%
% Also, when this procedure is invoked, the color and font must already
% have been set for the text.

/DrawText {
    /justify exch def
    /yoffset exch def
    /xoffset exch def
    /spacing exch def
    /strings exch def

    % First scan through all of the text to find the widest line.

    /lineLength 0 def
    strings {
    cstringwidth pop
    dup lineLength gt {/lineLength exch def} {pop} ifelse
    newpath
    } forall

    % Compute the baseline offset and the actual font height.

    gsave
    0 0 moveto (TXygqPZ) false charpath
    pathbbox dup /baseline exch def
    exch pop exch sub /height exch def pop
    newpath

    % Translate coordinates first so that the origin is at the upper-left
    % corner of the text's bounding box. Remember that x and y for
    % positioning are still on the stack.

    translate
    lineLength xoffset mul
    strings length 1 sub spacing mul height add yoffset mul translate

    % Now use the baseline and justification information to translate so
    % that the origin is at the baseline and positioning point for the
    % first line of text.

    justify lineLength mul baseline neg translate

    % Iterate over each of the lines to output it.  For each line,
    % compute its width again so it can be properly justified, then
    % display it.

    strings {
    dup cstringwidth pop
    justify neg mul 0 moveto
    cstringshow
    0 spacing neg translate
    } forall
    grestore
} bind def

/stone_font_size $my->{stone_fontSize} def
% size_adjust stone_font - select stone font with size adjustment
/stone_font {
    stone_font_size add /fsize exch def
    /$my->{stone_fontName} findfont fsize scalefont setfont
} def

% some global constants:
/normal_pen .3 def           % normal pen width
/board_edge_pen normal_pen 3 mul def
/mark_pen normal_pen 2 mul def

% per-diagram constants
/stone_height $my->{lineHeight} def
/stone_width $my->{lineWidth} def
/aspect_ratio stone_width stone_height div def
/b_sizex $my->{boardSizeX} def
/b_sizey $my->{boardSizeY} def

% convert board coords to real coords:
% note: goboard lines are numbered with 1 at the top and increasing
%    towards the bottom of the page. 
/_boardXY { % (m, n)
  top_line sub .5 add stone_height mul diagram_box_top exch sub % adjust n
  exch
  left_line sub .5 add stone_width mul diagram_box_left add     % adjust m
  exch
} def


% how to draw basic shapes
/_stone { % (m, n, color)
    /color exch def
    gsave
    newpath
    translate               % move to board coordinates
    aspect_ratio 1 scale    % scale to proper size
    0 0 .5 stone_height mul 0 360 arc % circle path
    gsave
    color setgray fill      % fill with color argument
    grestore
    stroke                  % outline with original color
    grestore
} def

% triangle at m, n with color
/_triangle { % (m, n, color)
    gsave
    newpath
    setgray                 % set color argument
    translate               % move to board coordinates
    0    stone_width mul  .35  stone_height mul moveto      % draw a triangle - top
     .35 stone_width mul -.225 stone_height mul lineto      % lower right corner
    -.35 stone_width mul -.225 stone_height mul lineto      % lower left corner
    closepath
    mark_pen setlinewidth
    stroke
    grestore
} def

% square at m, n with color
/_square { % (m, n, color)
    gsave
    newpath
    setgray                 % set color argument
    stone_height .25 mul sub exch
    stone_width  .25 mul sub exch
    translate               % move to board coordinates
    0                                    0 moveto   % lower left corner
    stone_width .5 mul                   0 lineto   % lower right
    stone_width .5 mul stone_height .5 mul lineto   % upper right
                     0 stone_height .5 mul lineto   % upper left
    closepath                                       % back home again
    mark_pen setlinewidth
    stroke
    grestore
} def
 
% X mark at m, n with color
/_mark { % (m, n, color)
    gsave
    newpath
    setgray                 % set color argument
    stone_height .25 mul sub exch
    stone_width  .25 mul sub exch
    translate               % move to board coordinates
    0                                    0 moveto   % lower left
    stone_width .5 mul stone_height .5 mul lineto   % upper right
    stone_width .5 mul                   0 moveto   % lower right
                     0 stone_height .5 mul lineto   % upper left
    mark_pen setlinewidth
    stroke
    grestore
} def
 
% circle at m, n with color
/_circle { % (m, n, color)
    gsave
    newpath
    setgray                 % set color argument
    translate               % move to board coordinates
     aspect_ratio 1 scale   % scale to proper size
    0 0 .25 stone_height mul 0 360 arc % circle path
    mark_pen setlinewidth
    stroke
    grestore
} def

% parts of the intersections of the board
/_up    { % (coord)
    1 index 1 index     % copy X,Y
    moveto
    .5 stone_height mul add     % y = y + (.5 * stone_height)
    lineto
    stroke
} def
/_down  { % (coord) = draw (coord--(coord + (0, -.5 * stone_height))) enddef;
    1 index 1 index     % copy X,Y
    moveto
    .5 stone_height mul sub     % y = y - (.5 * stone_height)
    lineto
    stroke
} def
/_right { % (coord) = draw (coord--(coord + ( .5 * stone_width, 0)))  enddef;
    1 index 1 index     % copy X,Y
    moveto
    exch
    .5 stone_width mul add     % x = x + (.5 * stone_width)
    exch
    lineto
    stroke
} def
/_left  { % (coord) = draw (coord--(coord + (-.5 * stone_width, 0)))  enddef;
    1 index 1 index     % copy X,Y
    moveto
    exch
    .5 stone_width mul sub     % x = x - (.5 * stone_width)
    exch
    lineto
    stroke
} def


% draw an intersection - may be an edge or corner
% m, n are board coords
/_int { % (m, n)
    /n exch def
    /m exch def
    m n _boardXY    % convert board coordinates to XY
    /yy exch def
    /xx exch def
    m 1 le
    {   % left edge
        n 1 le
        {           % left top
            board_edge_pen setlinewidth
            xx yy _down
            xx yy _right
            %xx yy board_edge_pen .04 mul 0 360 arc
            normal_pen setlinewidth
        } {
            n b_sizey ge
            { % left bottom
                board_edge_pen setlinewidth
                xx yy _right
                xx yy _up
                %xx yy board_edge_pen .04 mul 0 360 arc
                normal_pen setlinewidth
            } {             % left middle
                board_edge_pen setlinewidth
                xx yy _up
                xx yy _down
                normal_pen setlinewidth
                xx yy _right
            } ifelse
        } ifelse
    } { % not left edge
        m b_sizex ge
        { % right edge
            n 1 le
            {       % right top
                board_edge_pen setlinewidth
                xx yy _left
                xx yy _down
                %xx yy board_edge_pen .04 mul 0 360 arc
                normal_pen setlinewidth
            } { % not right bottom
                n b_sizey ge { % right bottom
                board_edge_pen setlinewidth
                xx yy _left
                xx yy _up
                %xx yy board_edge_pen .04 mul 0 360 arc closepath
                normal_pen setlinewidth
                } {         % right middle
                board_edge_pen setlinewidth
                xx yy _up
                xx yy _down
                normal_pen setlinewidth
                xx yy _left
                } ifelse
            } ifelse
        } { % not right edge
            n 1 le
            {       % top middle
                board_edge_pen setlinewidth
                xx yy _left
                xx yy _right
                normal_pen setlinewidth
                xx yy _down
            } { % not top
                n b_sizey ge
                { % bottom middle
                    board_edge_pen setlinewidth
                    xx yy _left
                    xx yy _right
                    normal_pen setlinewidth
                    xx yy _up
                } {         % middle
                    xx yy _left
                    xx yy _right
                    xx yy _up
                    xx yy _down
                } ifelse
            } ifelse
        } ifelse
    } ifelse
}def


% draw the board, given a global b_sizeX/Y and the
%    left, right, top, and bottom boundary lines
/_board { % ( b_left, b_top, b_right, b_bottom)
    /b_bottom exch def
    /b_right exch def
    /b_top exch def
    /b_left exch def
    b_top 1 b_bottom {
        b_left 1 b_right {
            1 index  % dup n (below m)
            _int     % draw the intersections
        } for
        pop         % remove n
    } for
} def

% draw a hoshi point
/_hoshi { % (m, n)
    gsave
    newpath
    0 setgray               % fill with black
    translate               % get board coordinates
    aspect_ratio 1 scale    % scale to proper size
    0 0 1 board_edge_pen mul 0 360 arc % circle path
    fill  % fill with black
    grestore
} def

% create some blank space (like for under a label)
/_blank { % (m, n)
    gsave
    newpath
    1 setgray               % fill with white
    translate               % get board coordinates
    aspect_ratio 1 scale    % scale to proper size
    0 0 .40 stone_height mul 0 360 arc % circle path
    fill                    % fill with white
    grestore
} def


% label at m, n with k and color
/_label { % (k, m, n, color)
    gsave
    setgray
    translate
    aspect_ratio 1 scale    % scale to proper size
    0 stone_font
    dup stringwidth pop     % Y change is probably 0 anyway
    /y_offset stone_font_size def
    dup 1.2 mul stone_width ge {
        pop
        -2 stone_font
        dup stringwidth pop
        /y_offset stone_font_size 2 sub def
    } if
    2 div neg           % divide X by 2 to get the offset
    y_offset -3 div
    moveto
    show
    grestore
} def

% set default font for text
/$my->{text_fontName} findfont $my->{text_fontSize} scalefont setfont
0 setgray
END_FUNCTIONS
}

# handle text reflow
sub _flow_text {
    my ($my, $text) = @_;

    my $width = 0;
    my @line = ();
    my $token = my $space = '';
    until (($text eq '') and
           ($token eq '')) {
        if ($token eq '') {
            $text =~ s/^(\s*)(\S*)//s;      # whitespace, then non-whitespace
            $space = $1;
            $token = $2;
            $space =~ s/ +/ /gs;        # turn multiple spaces into single space
            $space =~ s/ \n/\n/gs;      # remove preceding and intervening blanks
            $space =~ s/\n /\n/gs;      # and trailing blanks
        }
        my $tokenWidth = $my->{text_fontSize} * $my->_string_width($my->{text_fontName}, "$space$token");
        if (($space =~ m/\n/) or
            ($width + $tokenWidth > $my->{text_box_width})) {
            if ($width) {
                # put collected tokens on current line
                $my->_flow_text_lf(join('', @line));
                $width = 0;
                @line = ();
                $space =~ s/\n//;       # remove one LF (if there's one here)
            } else {            # no @line, but token is too long
                # put first part of token on current line:
                $token = $my->_flow_force_break($token); 
            }
            while ($space =~ s/\n//) {
                $my->_flow_text_lf(''); # extra LFs?
            }
            $space = '';    # no preceding space on next line
        } else {
            push(@line, "$space$token");
            $width += $tokenWidth;
            $token = '';
        }
    }
    $my->_flow_text_lf(join('', @line)) if (@line);
}

# force a break in a chunk that's too wide for the box, return the remainder
sub _flow_force_break {
    my ($my, $text) = @_;

    my $idx = 0;
    my $width = 0;
    while (($width < $my->{text_box_width}) and
           ($idx < length($text))) {
        my $c = substr($text, $idx, 1);
        $width += $my->{text_fontSize} * $my->_string_width($my->{text_fontName}, $c);
        $idx++;
    }
    $my->_flow_text_lf(substr($text, 0, $idx - 1));
    return substr($text, $idx)
}

# print a line, then update box data to reflect a line-feed
sub _flow_text_lf {
    my ($my, $text) = @_;

# print " flow $text\n";
    $my->_createText($my->{text_box_left}, $my->{text_box_y},
        -text     => $text);
    if ($text =~ m/\S/) {       # non-whitespace here
        $my->{text_box_y_last} = $my->{text_box_y};
        $my->{text_box_used} = 1;
    }
    $my->{text_box_y} -= 1.2 * $my->{text_fontSize};
    if ($my->{text_box_y} <= $my->{text_box_bottom}) {
        $my->_next_text_box();
    }
}

# figure out where the next diagram box should be.
sub _next_diagram_box {
    my ($my) = @_;

# print "next diagram box\n";
    $my->{text_box_state} = 0;  # next text box should be to right of diagram
    # is there enough space under the latest text?
    my $prev_bottom = $my->{diagram_box_bottom};
    $prev_bottom = $my->{text_box_y} if (exists($my->{text_box_y}) and
                                         $my->{text_box_y} < $prev_bottom);
    if ($my->{text_box_used} and
        ($my->{text_box_y_last} < $prev_bottom)) {
        $prev_bottom = $my->{text_box_y_last};  # text is below bottom of diagram
        $prev_bottom -= $my->{lineHeight};     # extra space between text and next diagram
    }
    my $diagram_width  = $my->{lineWidth}  * (1 + $my->{rightLine}  - $my->{leftLine});
    my $diagram_height = $my->{lineHeight} * (1 + $my->{bottomLine} - $my->{topLine});
    if ($my->{coords}) {
        $diagram_width  += $my->{lineWidth};
        $diagram_height += $my->{lineHeight};
    }
    # some space between diagrams
    $prev_bottom -= $my->{lineHeight} unless ($prev_bottom == $my->{page_top});
    my $need = $diagram_height - $my->{lineHeight} + $my->{page_bottom};
    if ($prev_bottom > $need) { # enough space on this page still
        $my->{diagram_box_top}    = $prev_bottom;
    } else {                    # need a new page
        $my->_next_page;
        $my->{diagram_box_top}    = $my->{page_top};
    }
    $my->{diagram_box_left}   = $my->{page_left};
    $my->{diagram_box_right}  = $my->{diagram_box_left} + $diagram_width;
    $my->{diagram_box_bottom} = $my->{diagram_box_top} - $diagram_height;
    $my->_next_text_box;     # need a new text box for this diagram
}

# figure out where the next text box should be.  box may be to the right of a
#       diagram, underneath a diagram, or it may be a new page.
sub _next_text_box {
    my ($my) = @_;

# print "next text box: ";
    $my->{text_box_state}++;
    if ($my->{text_box_state} == 1) {   # try for the area to the right of the diagram
        my $min_text = 'revive his dead stones';        # at least this wide...
        my $min_width = $my->{text_fontSize} * $my->_string_width($my->{text_fontName}, $min_text);
        my $dia_right = $my->{diagram_box_right} + $my->{lineWidth};
        if ($my->{page_right} - ($dia_right + 10) < $min_width) {
            $my->{text_box_bottom} = $my->{diagram_box_bottom};
            $my->_next_text_box;                 # not enough room, try next box
        } else {
            $my->{text_box_left}   = $dia_right;
            $my->{text_box_right}  = $my->{page_right} - 10;
            $my->{text_box_top}    = $my->{diagram_box_top} - $my->{lineHeight};
            $my->{text_box_bottom} = $my->{diagram_box_bottom} - $my->{text_fontSize} * 1.2;;
            $my->{text_box_bottom} = $my->{page_bottom} if ($my->{text_box_bottom} < $my->{page_bottom});
# print "right\n";
        }
    } elsif ($my->{text_box_state} == 2) {      # try for the area under the diagram
        $my->{text_box_left}   = $my->{page_left} + 10;
        $my->{text_box_right}  = $my->{page_right} - 10;
        $my->{text_box_top}    = $my->{text_box_y};
        while ($my->{text_box_top} > $my->{text_box_bottom}) {
            $my->{text_box_top}    -= $my->{text_fontSize} * 1.2;
        }
        $my->{text_box_bottom} = $my->{page_bottom};
        if ($my->{text_box_top} < $my->{page_bottom}) {
            $my->_next_text_box;                 # not enough space, try next
        }
# print "under\n";
    } else {                                    # gotta start a new page...
# print "new page\n";
        $my->_next_page;
        $my->{text_box_left}   = $my->{page_left} + 10;
        $my->{text_box_right}  = $my->{page_right} - 10;
        $my->{text_box_top}    = $my->{page_top} - $my->{lineHeight};
        $my->{text_box_bottom} = $my->{page_bottom};
        $my->{diagram_box_bottom} = $my->{page_top};    # no diagram on this page
    }
    $my->{text_box_width} = $my->{text_box_right} - $my->{text_box_left};
    $my->{text_box_y} = $my->{text_box_top};
    $my->{text_box_used} = 0;
}

# measure string width in points
sub _string_width {
    my ($my, $font, $text) = @_;

    my $w = 0;
    for (my $ii = 0; $ii < length($text); $ii++) {
        $w++;
        $ii++ if (substr($text, $ii, 1) eq '\\');       # skip escape chars
    }
    return $my->{fontScale} * $w;       # well, approximately...
}

# Add a new page which inherits its attributes from $root
my $page = 0;
sub _next_page {
    my ($my) = @_;

    $page++;
# print "next page($page)\n";
    $my->{ps}->newpage unless(exists($my->{firstPage}));
    delete($my->{firstPage});
    # set width to .3 points, line join mode to rounded corners
    $my->print(".3 setlinewidth 1 setlinejoin\n");
    $my->{text_box_y} = $my->{text_box_y_last} = $my->{page_top} - $my->{lineHeight};
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

Bugs?  In I<my> code?

