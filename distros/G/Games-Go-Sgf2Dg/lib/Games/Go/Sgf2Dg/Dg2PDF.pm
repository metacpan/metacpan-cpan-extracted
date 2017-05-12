#===============================================================================
#
#         FILE:  Dg2PDF
#
#     ABSTRACT:  convert Games::Go::Sgf2Dg::Diagrams to PDF (Portable Document Format)
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#===============================================================================
#
#   Copyright (C) 2005 Reid Augustin reid@hellosix.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#

=head1 SYNOPSIS

use Games::Go::Sgf2Dg::Dg2PDF

 my $dg2pdf = B<Games::Go::Sgf2Dg::Dg2PDF-E<gt>new> (options);
 $dg2pdf->convertDiagram($diagram);

=head1 DESCRIPTION

A Games::Go::Sgf2Dg::Dg2PDF object converts a L<Games::Go::Sgf2Dg::Diagram> object
into a PDF file.

=cut

use strict;
require 5.001;

package Games::Go::Sgf2Dg::Dg2PDF;

our $VERSION = '4.252'; # VERSION

eval { require PDF::Create; };   # is this module available?
if ($@) {
    die ("
    Dg2PDF needs the PDF::Create module, but it is not available.
    You can find PDF::Create in the same repository where you found
    Games::Go::Sgf2Dg, or from http://search.cpan.org/\n\n");
}

use Carp;

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

{
    my $v = ($PDF::Create::VERSION =~ m/(^\d*\.\d*)/)[0];
    if (not defined($v)) {
        carp("Hmm, can't extract PDF::Create package version from $PDF::Create::VERSION.  There may be a " .
             "more recent version from http://www.sourceforge.net/projects/perl-pdf.\n");
    } elsif ($v < 0.06) {
        carp("Note: your PDF::Create package is version $PDF::Create::VERSION.  You might want to pick up a " .
             "more recent version from http://www.sourceforge.net/projects/perl-pdf.\n");
    }

# from Slaven on comp.lang.perl.modules:
#       Modify PDF::Create to add changing font/stroke colors
    package PDF::Create;

    sub my_get_data {
        if (defined(&get_data)) {
            return shift->get_data();           # only in newer versions, apparently
        }
        return shift->{'data'};
    }

    sub my_get_page_size {
        my $self = shift;

        if (defined(&get_page_size)) {
            return $self->get_page_size(@_);    # only in newer versions, alas
        }
        my $name = lc(shift);

        my %pagesizes = (
           'a0'         => [ 0, 0, 2380, 3368 ],
           'a1'         => [ 0, 0, 1684, 2380 ],
           'a2'         => [ 0, 0, 1190, 1684 ],
           'a3'         => [ 0, 0, 842,  1190 ],
           'a4'         => [ 0, 0, 595,  842  ],
           'a5'         => [ 0, 0, 421,  595  ],
           'a6'         => [ 0, 0, 297,  421  ],
           'letter'     => [ 0, 0, 612,  792  ],
           'broadsheet' => [ 0, 0, 1296, 1584 ],
           'ledger'     => [ 0, 0, 1224, 792  ],
           'tabloid'    => [ 0, 0, 792,  1224 ],
           'legal'      => [ 0, 0, 612,  1008 ],
           'executive'  => [ 0, 0, 522,  756  ],
           '36x36'      => [ 0, 0, 2592, 2592 ],
        );
        if (!$pagesizes{$name}) {
            $name = "a4";
        }
        $pagesizes{$name};
    }


    package PDF::Create::Page;
    # set colors for drawing commands
    sub set_stroke_color {
        my($page, $r, $g, $b) = @_;
        return if (defined $page->{'current_stroke_color'} &&
                   $page->{'current_stroke_color'} eq join(",", $r, $g, $b));
        $page->{'pdf'}->page_stream($page);
        $page->{'pdf'}->add("$r $g $b RG");
        $page->{'current_stroke_color'} = join(",", $r, $g, $b);

    }

    # set colors for fonts
    sub set_fill_color {
        my($page, $r, $g, $b) = @_;
        return if (defined $page->{'current_fill_color'} &&
                   $page->{'current_fill_color'} eq join(",", $r, $g, $b));
        $page->{'pdf'}->page_stream($page);
        if ($r == 0 and $b == 0 and $g == 0) {
            $page->{'pdf'}->add("0 g ");
        } elsif ($r == 1 and $b == 1 and $g == 1) {
            $page->{'pdf'}->add("1 g ");
        } else {
            $page->{'pdf'}->add("$r $g $b rg ");
        }
        $page->{'current_fill_color'} = join(",", $r, $g, $b);
    }

    # b: closes, fills and strokes the path using the non-zero winding number rule
    sub close_fill_stroke {
      my $self = shift;

      $self->{'pdf'}->page_stream($self);
      $self->{'pdf'}->add("b");
    }

    # b*: closes, fills and strokes the path using the even-odd rule
    sub close_fill_stroke2 {
      my $self = shift;

      $self->{'pdf'}->page_stream($self);
      $self->{'pdf'}->add("b*");
    }

    # raw print - dump directly to PDF page stream
    sub print {
      my $self = shift;

      $self->{'pdf'}->page_stream($self);
      while(@_) {
          $self->{'pdf'}->add(shift);
      }
    }

    package PDF::Create;

    # kludge in some more flexible filename handling
    sub filehandle {
        my ($self, $fh, $filename) = @_;

        $self->{fh} = $fh if (defined($fh));
        $self->{filename} = $filename if (defined($fh));
        return $self->{fh};
    }
}

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
    file            => '',
    filename        => 'unknown',
    print           => sub { return; }, # Hmph...
    # PDF=specific options:
    pageSize        => 'letter',
    topMargin       => 72 * .70,
    bottomMargin    => 72 * .70,
    leftMargin      => 72 * .70,
    rightMargin     => 72 * .70,
    text_fontName   => 'Times-Roman',
    text_fontSize   => 9,
    stone_fontName  => 'Courier-Bold',
    stone_fontSize  => 5,
    lineWidth     => undef,
    lineHeight    => undef,
    );

use constant TEXT_Y_OFFSET  => 1.3;
use constant BLACK          => 'black';
use constant WHITE          => 'white';
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

=item my $dg2pdf = B<Games::Go::Sgf2Dg::Dg2PDF-E<gt>new> (?options?)

=back

A B<new> Games::Go::Sgf2Dg::Dg2PDF takes the following options:

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

=item B<pageSize> =E<gt> 'page size'

May be one of:

=over 12

=item . a0 - a6

=item . letter

=item . broadsheet

=item . ledger

=item . tabloid

=item . legal

=item . executive

=item . 36x36

=back

Default: 'letter'

=item B<topMargin>    =E<gt> points

=item B<bottomMargin> =E<gt> points

=item B<leftMargin>   =E<gt> points

=item B<rightMargin>  =E<gt> points

Margins are set in PDF 'user space units' which are approximately
equivilent to points (1/72 of an inch).

Default for all margins: 72 * .70 (7/10s of an inch)

=item B<text_fontName>  =E<gt> 'font'  Default: 'Times-Roman',

=item B<stone_fontName> =E<gt> 'font'  Default: 'Courier-Bold'

Text and stone fonts names may be one of these (case sensitive):

=over 12

=item . Courier

=item . Courier-Bold

=item . Courier-BoldOblique

=item . Courier-Oblique

=item . Helvetica

=item . Helvetica-Bold

=item . Helvetica-BoldOblique

=item . Helvetica-Oblique

=item . Times-Roman

=item . Times-Bold

=item . Times-Italic

=item . Times-BoldItalic

=back

=item B<text_fontSize>  =E<gt> points

The point size for the comment text.  Diagram titles use this size
plus 4, and the game title uses this size plus 6.

Default: 11

=item B<stone_fontSize> =E<gt> points

The B<stone_fontSize> determines the size of the text inside stones,
and may also determine the size of the stones and diagrams (see
B<lineHeight> and B<lineWidth> below).

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

=back

=cut

sub new {
    my ($proto, %args) = @_;

    my $my = {};
    bless($my, ref($proto) || $proto);
    # $my->{lineWidth} = 1;
    # $my->{lineHeight} = 1;
    $my->{diagram_box_right} = 1;
    $my->{diagram_box_bottom} = 0;
    $my->{text_box_y_last} = 0;
    $my->{curr_set_width} = -1;
    foreach (keys(%options)) {
        $my->{$_} = $options{$_};  # transfer default options
    }
    # transfer user args
    $my->configure(%args);
    return($my);
}

=head1 METHODS

=over 4

=item $dg2pdf-E<gt>B<configure> (option =E<gt> value, ?...?)

Change Dg2PDF options from values passed at B<new> time.

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
            $my->{print} = sub { $_[0]->{currentPage}->add($_[1]) or
                                        die "Error writing to output file:$!\n"; };
        } else {
            require IO::File;
            $my->{filename} = $my->{file};
            $my->{file} = IO::File->new($my->{filename}) or
                die("Error opening $my->{filename}: $!\n");
            $my->{print} = sub { $_[0]->{pdf}->add($_[1]) or
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

=item $dg2pdf-E<gt>B<print> ($text ? , ... ?)

B<print>s raw PDF code to B<file> as defined at B<new> time.
Whether or not B<file> was defined, B<print> accumulates the PDF
code for later retrieval with B<converted>.

=cut

sub print {
    my ($my, @args) = @_;

    unless(exists($my->{pdf})) {
        push(@{$my->{pre_init_print}}, @args);
        return;         # we'll get around to it eventually...
    }
    foreach my $arg (@args) {
        &{$my->{print}} ($my, $arg);
    }
}

=item $dg2pdf-E<gt>B<printComment> ($text ? , ... ?)

Adds $text to the diagram comments.

=cut

sub printComment {
    my ($my, @args) = @_;

    foreach(@args) {
        $my->_flow_text($_);
    }
}

=item $dg2pdf-E<gt>B<comment> ($comment ? , ... ?)

Inserts the PDF comment character ('%') in front of each line of
each comment and B<print>s it to B<file>.

Note that this is I<not> the same as the B<printComment> method.

=cut

sub comment {
    my ($my, @comments) = @_;

    $my->print("\n");
    foreach my $c (@comments) {
        while ($c =~ s/([^\n]*)\n//) {
            $my->print("% $1\n");
        }
        $my->print("%$c\n") if ($c ne '');
    }
}

=item my $canvas = $dg2pdf-E<gt>B<convertDiagram> ($diagram)

Converts a I<Games::Go::Sgf2Dg::Diagram> into PDF.

=cut

sub convertDiagram {
    my ($my, $diagram) = @_;

    my @name = $diagram->name;
    $name[0] = 'Unknown Diagram' unless(defined($name[0]));
    unless(exists($my->{root})) {
        $my->_createPDF;
        $my->{pdf}->add(@{$my->{pre_init_print}});
    }
    $my->comment("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");
    $my->comment(" Start of $name[0]");
    $my->comment("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");

    $my->{diagram_width}  = $my->{lineWidth}  * (1 + $my->{rightLine}  - $my->{leftLine});
    $my->{diagram_height} = $my->{lineHeight} * (1 + $my->{bottomLine} - $my->{topLine});
    if ($my->{coords}) {
        $my->{diagram_width}  += $my->{lineWidth};
        $my->{diagram_height} += $my->{lineHeight};
    }

    $my->_next_diagram_box;      # get location for next diagram
# BUGBUG table of contents?
    my $propRef = $diagram->property;                   # get property list for the diagram
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

    if ($my->{VW}) {    # view control
        $my->{draw_underneath} = 1;     # draw each intersection individually
    } else {
        # draw the underneath part (the board)
        $my->_board;
    }

    foreach my $y ($my->{topLine} .. $my->{bottomLine}) {
        foreach my $x ($my->{leftLine} ..  $my->{rightLine}) {
            $my->_convertIntersection($diagram, $x, $y);
        }
        if ($my->{coords}) {    # right-side coords
            $my->_createText(
                $my->_boardX($my->{rightLine} + 1),
                $my->_boardY($y) + TEXT_Y_OFFSET,
                -font     => $my->{stone_font},
                -fontSize => $my->{stone_fontSize} + 2,
                -text => $diagram->ycoord($y));
        }
    }
    # print bottom coordinates
    if ($my->{coords}) {
        for ($my->{leftLine} .. $my->{rightLine}) {
            $my->_createText(
                $my->_boardX($_),
                $my->_boardY($my->{bottomLine} + 1) + TEXT_Y_OFFSET,
                -font     => $my->{stone_font},
                -fontSize => $my->{stone_fontSize} + 2,
                -text => $diagram->xcoord($_));
        }
    }

    # now handle text associated with this diagram
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
                $my->printComment("$title\n");
            }
            my $pw = $propRef->{0}{PW}[0] || '(unknown)';
            my $pb = $propRef->{0}{PB}[0] || '(unknown)';
            $my->{toc} = $my->{pdf}->new_outline(               # the Table of Contents
                'Title' => "$pw vs. $pb",
                'Destination' => $my->{currentPage});
        }
        $my->{text_fontSize} -= 2;
        # print the diagram title
        $my->printComment($my->convertText(join('', @name, $range, "\n")));

    }
    # the over-lay stones
    $my->_convertOverstones($diagram);
    $my->printComment("\n");
    $my->{toc}->new_outline(    # add diagram to table of contents
        'Title' => join('', @name, $range));
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

=item my $converted_text = $dg2pdf-E<gt>B<convertText> ($text)

Converts $text into text for display.

Returns the converted text.

=cut

sub convertText {
    my ($my, $text) = @_;

    # turn single \n into single space.  multiple \n's are broken during _flow_text
    # $text =~ s/([^\n])\n([^\n])/$1 $2/gs;
    return $text;
}

=item $title = $dg2pdf-E<gt>B<convertGameProps> (\%sgfHash)

B<convertGameProps> takes a reference to a hash of properties as
extracted from an SGF file.  Each hash key is a property ID and the
hash value is a reference to an array of property values:
$hash->{propertyId}->[values].  The following SGF properties are
recognized:

=over 4

=item . GN GameName

=item . EV EVent

=item . RO ROund

=item . DT DaTe

=item . PW PlayerWhite

=item . WR WhiteRank

=item . PB PlayerBlack

=item . BR BlackRank

=item . PC PlaCe

=item . KM KoMi

=item . RU RUles

=item . TM TiMe

=item . OT OverTime (byo-yomi)

=item . RE REsult

=item . AN ANnotator

=item . SO Source

=item . US USer (entered by)

=item . CP CoPyright

=item . GC GameComment

=back

Both long and short property names are recognized, and all
unrecognized properties are ignored with no warnings.  Note that
these properties are all intended as game-level notations.

=cut

sub convertGameProps {
    my ($my, $hashRef) = @_;

    return unless(defined($hashRef));
    my %hash;
    foreach my $key (keys(%{$hashRef})) {
        my $short = $key;
        $short =~ s/[^A-Z]//g;                  # delete everything but upper case letters
        my $text = join('', @{$hashRef->{$key}});
        $text =~ s/\n//gm;
        $text =~ s/0*$// if ($short eq 'KM');   # remove ugly trailing zeros on komi supplied by IGS
        $hash{$short} = $my->convertText($text);
    }
    if (exists($hash{WR})) {
        if (exists($hash{PW})) {
            $hash{PW} = "$hash{PW} $hash{WR}";      # join name and rank
        } else {
            $hash{PW} = $hash{WR};                  # rank only?
        }
    }
    if (exists($hash{BR})) {
        if (exists($hash{PB})) {
            $hash{PB} = "$hash{PB} $hash{BR}";      # join name and rank
        } else {
            $hash{PB} = $hash{BR};                  # rank only?
        }
    }
    if (exists($hash{RO})) {
        if (exists($hash{EV})) {
            $hash{EV} = "$hash{EV} - $hash{RO}";    # join event and round
        } else {
            $hash{EV} = $hash{RO};                  # round only?
        }
    }

    my @lines;
    push(@lines, $hash{GN}) if(exists($hash{GN}));      # GameName
    push(@lines, $hash{EV}) if(exists($hash{EV}));      # Event and Round number
    push(@lines, $hash{DT}) if (exists($hash{DT}));     # DaTe
    push(@lines, "{\\bf White:} $hash{PW}") if (exists($hash{PW})); # PlayerWhite
    push(@lines, "{\\bf Black:} $hash{PB}") if (exists($hash{PB})); # PlayerBlack
    push(@lines, "{\\bf Place:} $hash{PC}") if (exists($hash{PC}));     # PlaCe
    push(@lines, "{\\bf Komi:} $hash{KM}") if (exists($hash{KM}));      # komi
    push(@lines, "{\\bf Rules} $hash{RU}") if (exists($hash{RU}));      # rules
    push(@lines, "{\\bf Time:} $hash{TM}") if (exists($hash{TM}));      # time constraints
    push(@lines, "{\\bf Byo-yomi} $hash{OT}") if (exists($hash{OT}));   # overtime
    push(@lines, "{\\bf Result:} $hash{RE}") if (exists($hash{RE}));    # result
    push(@lines, "{\\bf Annotated by:} $hash{AN}") if (exists($hash{AN})); # annotater
    push(@lines, "{\\bf Source:} $hash{SO}") if (exists($hash{SO}));    # source?
    push(@lines, "{\\bf Entered by:} $hash{US}") if (exists($hash{US})); # user
    push(@lines, "$hash{CP}") if (exists($hash{CP}));                   # Copyright
    push(@lines, $hash{GC}) if (exists($hash{GC}));                     # GameComment
    my ($title)='';
    foreach my $line (@lines) {
        next unless (defined($line));
        $my->printComment($my->convertText($line));
    }
}

=item $dg2pdf-E<gt>B<close>

B<print>s some final PDF code to the diagram and closes the pdf
object (file).

=cut

sub close {
    my ($my) = @_;

    $my->{pdf}->close;
    my $pdf = $my->{pdf}->my_get_data;
    if (ref($my->{file}) eq 'SCALAR') {
        ${$my->{file}} .= $pdf;
    } elsif (ref($my->{file}) eq 'ARRAY') {
        push(@{$my->{file}}, split("\n", $pdf));
    }
    return $pdf;
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
                    $x, $my->{text_box_y},
                    -anchor => 'sw',
                    -font     => $my->{text_font},
                    -fontSize => $my->{text_fontSize},
                    -text => ',');
                $x += $my->{text_fontSize} * $my->{currentPage}->string_width($my->{text_font}, ', ');
            }
            if ($my->{text_box_right} - $x < 3 * $my->{lineWidth}) {
                $my->{text_box_y} -= $my->{lineHeight} * 1.2;  # drop to next line
                $x = $my->{text_box_left};
                $jj -= 2;
                $comma = 0;
                next;   # try again
            }
            $color = $int->{overstones}[$jj];
            $otherColor = ($color eq BLACK) ? WHITE : BLACK;
            local $my->{stoneOffset} = $my->{offset};   # turn off doubleDigits
            $number = $my->_checkStoneNumber($int->{overstones}[$jj+1]);
            # draw the overstone
            my $left = $x;
            my $right = $x + $my->{lineWidth};
            my $top = $my->{text_box_y} + $my->{lineHeight};
            my $bottom = $my->{text_box_y};
            $my->_createOval(
                $left, $top, $right, $bottom,
                -outline => BLACK,
                -fill => $color);
            # put the number on it
            $my->_createText(
                $x + $my->{lineWidth} / 2,
                $my->{text_box_y} + TEXT_Y_OFFSET + $my->{lineHeight} / 2,
                -fill => $otherColor,
                -fontSize => $my->{stone_fontSize} + ((length($number) > 2) ? 0 : 2),
                -text => $number);
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
            -anchor => 'sw',
            -font     => $my->{text_font},
            -fontSize => $my->{text_fontSize},
            -text => ' at ');
        $x += $my->{text_fontSize} * $my->{currentPage}->string_width($my->{text_font}, ' at ');
        # draw the at-stone
        my $left = $x;
        my $right = $x + $my->{lineWidth};
        my $top = $my->{text_box_y} + $my->{lineHeight};
        my $bottom = $my->{text_box_y};
        $my->_createOval(
            $left, $top, $right, $bottom,
           -outline => BLACK,
           -fill => $color);
        if (exists($int->{number})) {
            # put the number on it
            $my->_createText(
                $x + $my->{lineWidth} / 2,
                $my->{text_box_y} + TEXT_Y_OFFSET + $my->{lineHeight} / 2,
                -fill => $otherColor,
                -fontSize => $my->{stone_fontSize} + ((length($int->{number}) > 2) ? 0 : 2),
                -text => $my->_checkStoneNumber($int->{number}));
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
            $my->_createText(
                $x, $my->{text_box_y},
                -anchor => 'sw',
                -font     => $my->{text_font},
                -fontSize => $my->{text_fontSize},
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

sub _stone {
    my ($my, $x, $y, $color) = @_;

    $my->_createOval(
        $x - $my->{lineWidth} / 2,     # left
        $y - $my->{lineHeight} / 2,    # top
        $x + $my->{lineWidth} / 2,     # right
        $y + $my->{lineHeight} / 2,    # bottom
        -fill => $color,
        -outline => BLACK);
}

sub _blank {
    my ($my, $x, $y, $color) = @_;

    # create some whitespace to draw label on
    $my->_createOval(
        $x - $my->{lineWidth} / 3,     # left
        $y - $my->{lineHeight} / 3,    # top
        $x + $my->{lineWidth} / 3,     # right
        $y + $my->{lineHeight} / 3,    # bottom
        -fill    => WHITE,
        -outline => WHITE);
}

sub _label {
    my ($my, $x, $y, $label, $color) = @_;

    $my->_createText(
        $x,
        $y + TEXT_Y_OFFSET,
        -fill => $color,
        -fontSize => $my->{stone_fontSize} + ((length($label) > 2) ? 0 : 2),
        -text => $label
        );
}

# convert intersection hash from $diagram.
sub _convertIntersection {
    my ($my, $diagram, $x, $y) = @_;

    my $int = $diagram->get($my->diaCoords($x, $y));
    return if ($my->{VW} and            # view control AND
               not exists($int->{VW})); # no view on this intersection
    my $color = BLACK;
    my $otherColor = BLACK;
    my $xx = $my->_boardX($x);
    my $yy = $my->_boardY($y);
    if (exists($int->{black})) {
        $otherColor = WHITE;
        $my->_stone($xx, $yy, $color);
    } elsif (exists($int->{white})) {
        $color = WHITE;
        $my->_stone($xx, $yy, $color);
    } else {
        if ($my->{draw_underneath}) {
            # draw the appropriate intersection
            $my->_draw_underneath($int, $x, $y);
        }   # else the whole board underneath has already been drawn for us
        if (exists($int->{hoshi})) {
            $my->_drawHoshi($xx, $yy);
        }
        if (exists($int->{label}) or
             exists($int->{number})) {
            # clear some space at intersection for the number/label
            $my->_blank($xx, $yy);
        }
    }
    if (exists($int->{number})) {
        my $label = $my->_checkStoneNumber($int->{number}); # numbered stone
        $my->_label($xx, $yy, $label, $otherColor);
    } elsif (exists($int->{mark})) {
        $my->_drawMark($int->{mark}, $otherColor, $xx, $yy);
    } elsif (exists($int->{label})) {
        $my->_label($xx, $yy, $int->{label}, $otherColor);
    }
}

sub _board {
    my ($my, $width, $x, $y) = @_;

    foreach my $y ($my->{topLine} .. $my->{bottomLine}) {
        my $width = NORMAL_PEN;
        my $l = $my->_boardX($my->{leftLine});
        my $r = $my->_boardX($my->{rightLine});
        $width = BOARD_EDGE_PEN if ($y <= 1 or $y >= $my->{boardSizeY});
        my $yy = $my->_boardY($y);
        $my->_createLine($l, $yy, $r, $yy, -width => $width);
    }
    foreach my $x ($my->{leftLine} ..  $my->{rightLine}) {
        my $width = NORMAL_PEN;
        $width = BOARD_EDGE_PEN if ($x <= 1 or $x >= $my->{boardSizeX});
        my $t = $my->_boardY($my->{topLine});
        my $b = $my->_boardY($my->{bottomLine});
        my $xx = $my->_boardX($x);
        $my->_createLine($xx, $t, $xx, $b, -width => $width);
    }
}

sub _draw_left {
    my ($my, $width, $x, $y) = @_;
    $my->_createLine(
            $x,
            $y,
            $x - ($my->{lineWidth} / 2),
            $y,
            -width => $width);
}

sub _draw_right {
    my ($my, $width, $x, $y) = @_;
    $my->_createLine(
            $x,
            $y,
            $x + ($my->{lineWidth} / 2) + 1,
            $y,
            -width => $width);
}

sub _draw_up {
    my ($my, $width, $x, $y) = @_;
    $my->_createLine(
            $x,
            $y,
            $x,
            $y + ($my->{lineWidth} / 2),
            -width => $width);
}

sub _draw_down {
    my ($my, $width, $x, $y) = @_;
    $my->_createLine(
            $x,
            $y,
            $x,
            $y - ($my->{lineWidth} / 2) - 1,
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
}

sub _drawMark {
    my ($my, $mark, $color, $x, $y) = @_;

    if ($mark eq 'TR') {        # TR[pt]      triangle
        # triangle has top Y; left, right X; and bottom Y
        my $left   = $x - (.3 * $my->{lineWidth});    # cos(30) = .866
        my $right  = $x + (.3 * $my->{lineWidth});    # cos(30) = .866
        my $top    = $y + ($my->{lineHeight} / 3);
        my $bottom = $y - ($my->{lineHeight} / 6);      # sin(30) = .5
        $my->_createLine(
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
            $my->_createOval(
                               $left,  $top,
                               $right, $bottom,
                               -outline => $color,
                               -width => MARK_PEN
                            );
        } elsif ($mark eq 'SQ') {   # SQ[pt]      square
            $my->_createLine(
                               $left,  $top,
                               $right, $top,
                               $right, $bottom,
                               $left,  $bottom,
                               $left,  $top,
                               -fill => $color,
                               -width => MARK_PEN
                            );
        } else {                    # MA[pt]      mark (X)
            $my->_createLine(
                               $left,  $top,
                               $right, $bottom,
                               -fill => $color,
                               -width => MARK_PEN
                            );
            $my->_createLine(
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

    my $size = $my->{lineWidth} * 0.08;   # 8% size of a stone
    $size = 1 if $size <= 0;
    $my->_createOval(
        $x - $size,
        $y + $size,
        $x + $size,
        $y - $size,
        -fill => BLACK);
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
# Note: default font is $my->{stone_font} and fontSize is $my->{stone_fontSize}
sub _createText {
    my ($my, $x, $y, %args) = @_;

    my $page = $my->{currentPage};
    $page->set_fill_color($my->_get_rgb(delete($args{-fill})));
    my $text = delete($args{-text});
    my $font = delete($args{-font}) || $my->{stone_font};
    my $fontSize = delete($args{-fontSize}) || $my->{stone_fontSize};
    if (exists($args{-anchor})) {
        if ($args{-anchor} eq 'sw') {
        } else {
            carp ("Unknown anchor in _createText: $args{-anchor}");
        }
        delete ($args{-anchor});
    } else {
        # put anchor at center of text
        $x -= $fontSize * $page->string_width($font, $text) / 2;
        $y -= $fontSize / 2;
    }
    foreach (keys(%args)) {
        carp ("Unknown args key in _createText: $_");
    }
    $page->stringl(
        $font, $fontSize,
        $x, $y, $text);
}

# imitate a Tk::Canvas createOval call
use constant SQRT2   => sqrt(2);
use constant BZEL8 => (8 - SQRT2) / 6;
use constant BZEL7 => ((7 * SQRT2) - 8) / 6;
sub _createOval {
    my ($my, $x1, $y1, $x2, $y2, %args) = @_;

    my $page = $my->{currentPage};
    my $fill = exists($args{-fill});
    $page->set_fill_color($my->_get_rgb(delete($args{-fill})));
    my $outline = exists($args{-outline});
    $page->set_stroke_color($my->_get_rgb(delete($args{-outline})));
    $my->_set_width(delete($args{-width}));
    foreach (keys(%args)) {
        carp ("Unknown args key in _createOval: $_");
    }
    # From: "David Hart" <d...@xxxserif.com>
    # Newsgroups: comp.graphics.algorithms
    # Subject: Re: Using bezier curves to approx an ellipse
    # Date: Wed, 3 Jun 1998 12:08:07 +0100
    #
    # for an ellipse defined by:
    #
    #   (x^2 / a^2) + (y^2 / b^2) = 1
    #
    # the Bezier control points for one quarter of the ellipse are:
    #
    #  [+a/sqrt(2),       +b/sqrt(2)]
    #  [+a*(8-sqrt(2))/6, +b*(7*sqrt(2)-8)/6]
    #  [+a*(8-sqrt(2))/6, -b*(7*sqrt(2)-8)/6]
    #  [+a/sqrt(2),       -b/sqrt(2)]
    #
    # repeat four times to get the full ellipse

    my $a = ($x2 - $x1) / 2;
    my $x = $x1 + $a;
    my $b = ($y2 - $y1) / 2;
    my $y = $y1 + $b;
    $page->moveto ($x + ($a / SQRT2), $y + ($b / SQRT2));
    $page->curveto($x + ($a * BZEL8), $y + ($b * BZEL7),        # right quarter of ellipse
                   $x + ($a * BZEL8), $y - ($b * BZEL7),
                   $x + ($a / SQRT2), $y - ($b / SQRT2));
    $page->curveto($x + ($a * BZEL7), $y - ($b * BZEL8),        # bottom quarter of ellipse
                   $x - ($a * BZEL7), $y - ($b * BZEL8),
                   $x - ($a / SQRT2), $y - ($b / SQRT2));
    $page->curveto($x - ($a * BZEL8), $y - ($b * BZEL7),        # left quarter of ellipse
                   $x - ($a * BZEL8), $y + ($b * BZEL7),
                   $x - ($a / SQRT2), $y + ($b / SQRT2));
    $page->curveto($x - ($a * BZEL7), $y + ($b * BZEL8),        # top quarter of ellipse
                   $x + ($a * BZEL7), $y + ($b * BZEL8),
                   $x + ($a / SQRT2), $y + ($b / SQRT2));
    if ($outline and $fill) {
        $page->close_fill_stroke;
    } elsif ($fill) {
        $page->closepath;
        $page->fill;
    } elsif ($outline) {
        $page->closestroke;
    } else {
        $page->closepath;
    }
}

# imitate a Tk::Canvas createLine call
sub _createLine {
    my ($my, $x1, $y1, @args) = @_;

    my $page = $my->{currentPage};
    my @points;
    while (@args) {
       last if ($args[0] =~ m/[^-\d\.]/);
       push(@points, shift(@args), shift(@args));
    }
    my %args = @args;
    $page->set_stroke_color($my->_get_rgb(delete($args{-fill})));
    $my->_set_width(delete($args{-width}));
    foreach (keys(%args)) {
        carp ("Unknown args key in _createLine: $_");
    }
    $page->moveto($x1, $y1);
    while (@points) {
        $page->lineto(shift(@points), shift(@points));
    }
    $page->closestroke;
}

sub _get_rgb {
    my ($my, $color) = @_;

    return (0, 0, 0) unless(defined($color));
    $color = lc($color);
    return (1, 1, 1) if ($color eq WHITE);
    return (1, 0, 0) if ($color eq 'red');
    return (0, 1, 0) if ($color eq 'green');
    return (0, 0, 1) if ($color eq 'blue');
    return (0, 0, 0) if ($color eq BLACK);
    carp ("unknown color $color in _get_rgb");
    return (0, 0, 0);
}

sub _set_width {
    my ($my, $width) = @_;

    $width = 1 unless defined($width);
    if ($width != $my->{curr_set_width}) {
        $my->{currentPage}->set_width($width / 4);
        $my->{curr_set_width} = $width;
    }

}

sub _createPDF {
    my ($my) = @_;

    my $pdf;
    my %opts = (
        Version      => 1.2,
        PageMode     => 'UseOutlines',
        Creator      => 'sgf2dg',
        CreationDate => [ localtime ],);

    if (defined($my->{file})) {
        if ((ref($my->{file}) eq 'GLOB') or
            (ref($my->{file}) eq 'IO::File')) {
            $pdf = $my->{pdf} = new PDF::Create(
                %opts);
            $pdf->filehandle($my->{file}, 'sgf2pdf.pdf');
            $my->{file}->print($pdf->my_get_data);
        } elsif ((ref($my->{file}) eq 'SCALAR') or
                 (ref($my->{file}) eq 'ARRAY')) {
            $pdf = $my->{pdf} = new PDF::Create(
                'filename'     => "",   # to /dev/null
                %opts);
        } else {
            $my->{file} =~ s/^>//;
            $pdf = $my->{pdf} = new PDF::Create(
                'filename'     => $my->{file},
                %opts);
        }
    } else {
        $pdf = $my->{pdf} = new PDF::Create(
            %opts);
    }
    my $pageCoords = $pdf->my_get_page_size(lc($my->{pageSize}));
    my $root = $my->{currentPage} = $my->{root} = $pdf->new_page(
        'MediaBox'  => $pageCoords);
    $my->{page_left}   = $pageCoords->[0] + $my->{leftMargin};
    $my->{page_right}  = $pageCoords->[2] - $my->{rightMargin};
    $my->{page_top}    = $pageCoords->[3] - $my->{topMargin};
    $my->{page_bottom} = $pageCoords->[1] + $my->{bottomMargin};

# Prepare fonts
    $my->{font_helv} = $pdf->font(
        'Subtype'  => 'Type1',
        'Encoding' => 'WinAnsiEncoding',
        'BaseFont' => 'Helvetica');
    $my->{text_font} = $pdf->font(
        'Subtype'  => 'Type1',
        'Encoding' => 'WinAnsiEncoding',
        'BaseFont' => $my->{text_fontName});
    $my->{stone_font} = $pdf->font(
        'Subtype'  => 'Type1',
        'Encoding' => 'WinAnsiEncoding',
        'BaseFont' => $my->{stone_fontName});


    # figure out the font and line width and height
    my $fontWidth = $my->{stone_fontSize} * ($root->string_width($my->{stone_font}, '0123456789')) / 10;
    unless(defined($my->{lineWidth})) {
        $my->{lineWidth} = $my->{doubleDigits} ?
                                $fontWidth * 3.0 :    # need space for two digits (and 100)
                                $fontWidth * 3.5;     # need space for three digits
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
        carp "lineHeight of $my->{lineHeight} won't fit on the page.  I'm setting it to $newH\n";
        $my->{lineHeight} = $newH;
    }
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
        my $tokenWidth = $my->{text_fontSize} * $my->{currentPage}->string_width($my->{text_font},
                                                                                "$space$token");
        if (($space =~ m/\n/) or
            ($width + $tokenWidth > $my->{text_box_width})) {
            if ($width) {
                # put collected tokens on current line
                $my->_flow_text_lf(join('', @line));
                $width = 0;
                @line = ();
                $space =~ s/\n//;       # remove one LF (if there's one here)
            } elsif ($width + $tokenWidth > $my->{text_box_width}) { # no @line, but token is too long
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
    while ($width < $my->{text_box_width}) {
        my $c = substr($text, $idx, 1);
        $width += $my->{text_fontSize} * $my->{currentPage}->string_width($my->{text_font}, $c);
        $idx++;
        if ($idx >= length($text)) {
            return $text;  # fits - force break shouldn't have been called
        }
    }
    $my->_flow_text_lf(substr($text, 0, $idx - 1));
    return substr($text, $idx)
}

# print a line, then update box data to reflect a line-feed
sub _flow_text_lf {
    my ($my, $text) = @_;

# print " flow $text\n";
    $my->_createText($my->{text_box_left}, $my->{text_box_y},
        -anchor   => 'sw',
        -font     => $my->{text_font},
        -fontSize => $my->{text_fontSize},
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
    if ($my->{text_box_used} and
        ($my->{text_box_y_last} < $prev_bottom)) {
        $prev_bottom = $my->{text_box_y_last};  # text is below bottom of diagram
        $prev_bottom -= $my->{lineHeight};     # extra space between text and next diagram
    }
    # some space between diagrams
    $prev_bottom -= $my->{lineHeight} unless ($prev_bottom == $my->{page_top});
    my $need = $my->{diagram_height} - $my->{lineHeight} + $my->{page_bottom};
    if ($prev_bottom > $need) { # enough space on this page still
        $my->{diagram_box_top}    = $prev_bottom;
    } else {                    # need a new page
        $my->_next_page;
        $my->{diagram_box_top}    = $my->{page_top};
    }
    $my->{diagram_box_left}   = $my->{page_left};
    $my->{diagram_box_right}  = $my->{diagram_box_left} + $my->{diagram_width};
    $my->{diagram_box_bottom} = $my->{diagram_box_top} - $my->{diagram_height};
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
        my $min_width = $my->{text_fontSize} * $my->{currentPage}->string_width($my->{text_font}, $min_text);
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

# Add a new page which inherits its attributes from $root
my $page = 0;
sub _next_page {
    my ($my) = @_;

    $page++;
# print "next page($page)\n";
    $my->{currentPage} = $my->{root}->new_page;
    $my->{currentPage}->print(".3 w 1 j\n");        # set width to .3 points, line join mode to rounded corners
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

You think I'd admit it?

