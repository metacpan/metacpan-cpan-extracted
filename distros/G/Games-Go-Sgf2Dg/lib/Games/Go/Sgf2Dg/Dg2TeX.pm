#===============================================================================
#
#         FILE:  Dg2TeX
#
#     ABSTRACT:  convert Games::Go::Sgf2Dg::Diagrams to TeX
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#===============================================================================
#
#   Copyright (C) 2005 Reid Augustin reid@hellosix.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#

=head1 SYNOPSIS

use Games::Go::Sgf2Dg::Dg2TeX

 my $dg2tex = B<Games::Go::Sgf2Dg::Dg2TeX-E<gt>new> (options);
 my $tex = $dg2tex->convertDiagram($diagram);

=head1 DESCRIPTION

A Games::Go::Sgf2Dg::Dg2TeX object converts a L<Games::Go::Sgf2Dg::Diagram> object
into TeX source code which can be used stand-alone, or it can be
incorporated into larger TeX documents.

=cut

use strict;
require 5.001;

package Games::Go::Sgf2Dg::Dg2TeX;
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

use constant TOPLEFT     => '<';
use constant TOPRIGHT    => '>';
use constant TOP         => '(';
use constant BOTTOMLEFT  => ',';
use constant BOTTOMRIGHT => '.';
use constant BOTTOM      => ')';
use constant LEFT        => '[';
use constant RIGHT       => ']';
use constant MIDDLE      => '+';
use constant HOSHI       => '*';
use constant EMPTY       => "\\0??";    # empty intersection
use constant WHITE       => "\\- !";    # numberless white stone
use constant BLACK       => "\\- @";    # numberless black stone
use constant CIR         => "\\- 1";    # circle
use constant CIR_BLACK   => "\\- C";    # circled black stone
use constant CIR_WHITE   => "\\- c";    # circled white stone
use constant SQR         => "\\- 2";    # square
use constant SQR_BLACK   => "\\- S";    # squared black stone
use constant SQR_WHITE   => "\\- s";    # squared white stone
use constant TRI         => "\\- 3";    # triangle
use constant TRI_BLACK   => "\\- T";    # triangled black stone
use constant TRI_WHITE   => "\\- t";    # triangled white stone
use constant X           => "\\- 4";    # X-mark
use constant X_BLACK     => "\\- X";    # Xed black stone
use constant X_WHITE     => "\\- x";    # Xed white stone

use constant COMMON_MACROS =>
"% goWhiteInk changes from black to white ink, but it's not supported by
%   all output drivers (notably pdftex).  Dg2TeX only uses it for long
%   labels on black stones, so it may not matter...
\\def\\goWhiteInk#1{\\special{color push rgb 1 1 1} {#1} \\special{color pop}}%
% goLap is used to overlap a long label on a stone or intersection
\\def\\goLap#1#2{\\setbox0=\\hbox{#1} \\rlap{#1} \\raise 2\\goTextAdj\\hbox to \\wd0{\\hss\\eightpoint{#2}\\hss}}%
% goLapWhite overlaps like goLap, but also changes to white ink for the label
\\def\\goLapWhite#1#2{\\setbox0=\\hbox{#1}\\rlap{#1}\\raise 2\\goTextAdj\\hbox to \\wd0{\\hss\\eightpoint\\goWhiteInk{#2}\\hss}}%
% rc places right-hand side coordinates
\\def\\rc#1{\\raise \\goTextAdj\\hbox to \\goIntWd{\\kern \\goTextAdj\\hss\\rm#1\\hss}}%
% bc places bottom coordinates
\\def\\bc#1{\\hbox to \\goIntWd{\\hss#1\\hss}}%
\\lineskip=0pt
\\parindent=0pt
\\raggedbottom        % allow pages to end short (if next diagram doesn't fit)
";
use constant NORMAL_MACROS =>
"\\input gooemacs
\\gool
\\newbox\\boardBox        % a box to put the board into
\\newbox\\floatBox
\\newdimen\\floatWd
\\newdimen\\floatHt
\\newdimen\\ftextWd       % width of text alongside float
\\newif\\iffloatRight     % controls whether to float on left or right
\\floatRighttrue         % starting default
\\def\\floatLeft#1#2{     % text on the right side, float on the left
    \\floatRightfalse \\float{#1}{#2}
}
\\def\\floatRight#1#2{    % text on the left side, float on the right
    \\floatRighttrue \\float{#1}{#2}
}
% from http://www.tug.org/utilities/plain/cseq.html#vss-rp:
\\def\\hcropmark(#1,#2,#3){% (x,y,width)   line from x,y to width
     \\vbox to 0pt{%
          \\kern #2\\hbox{%
               \\kern #1\\vrule height 0.1pt width #3%
          }%
          \\vss% \\vss is often used in a \\vbox to 0pt{}.
     }%
     \\ifvmode\\nointerlineskip\\fi%
}
\\def\\vcropmark(#1,#2,#3){% (x,y,height)   line from x,y to height
     \\vbox to 0pt{%
          \\kern #2\\hbox{%
               \\kern #1\\vrule height #3 width 0.1pt%
          }%
          \\vss%
     }%
     \\ifvmode\\nointerlineskip\\fi%
}
\\def\\fbox(#1,#2,#3,#4){ %   (x, y, width, height)
    \\begingroup
    \\hcropmark(#1,#2,#3)
    \\dimen0=#2
    \\advance\\dimen0 #4
    \\hcropmark(#1,\\dimen0,#3)
    \\vcropmark(#1,#2,#4)
    \\dimen0=#1
    \\advance\\dimen0 #3
    \\vcropmark(\\dimen0,#2,#4)
    \\endgroup
}
\\def\\fbox(#1,#2,#3,#4){}%   (x, y, width, height)  % comment this line out to show outlines around floats
% the float macro
\\def\\float#1#2{%
    \\setbox\\floatBox=\\vbox{#1}          % insert float into box
    \\floatWd=\\wd\\floatBox               % width of float, add gap between text and float
    \\floatHt=\\ht\\floatBox
    \\advance\\floatHt \\dp\\floatBox       % height plus depth of float
    \\vskip 0pt plus \\floatHt \\penalty-60 \\vskip 0pt plus -\\floatHt% make sure there's enough vertical space for the full diagram
    \\ftextWd=\\hsize                     % width of text alongside float
    \\global\\advance\\ftextWd -\\floatWd   % total width - (float width)
    \\iffloatRight \\fbox(\\ftextWd,0pt,\\floatWd,\\floatHt)%
    \\else         \\fbox(0pt,0pt,\\floatWd,\\floatHt)%
    \\fi
    \\vbox to 0pt{%
       \\iffloatRight
            \\moveright\\ftextWd% move right to where float should be
       \\fi
       \\hbox{\\tolerance=10000\\hbadness=10000%
            \\box\\floatBox       % place the float - leave boxed to prevent page-breaks in the middle
       }
       \\vss
    }
    \\advance\\floatHt \\baselineskip     % add padding below float
    \\setbox\\floatBox=\\vbox{%                % box for text
        \\tolerance=10000\\hbadness=10000
        \\advance\\floatWd 3em                % add gap to float width
        \\global\\advance\\ftextWd -3em        % and remove it from text width
        \\iffloatRight \\hangindent -\\floatWd % indent right side
        \\else         \\hangindent  \\floatWd % indent left side
        \\fi
        \\hangafter=\\floatHt
        \\advance \\hangafter \\baselineskip    % round up to nearest line
        \\advance \\hangafter -1               % round up to nearest line
        \\divide\\hangafter -\\baselineskip
        \\vskip\\goIntHt \\vskip -\\goTextAdj \\noindent#2%            % place the text
    }
    \\dimen255=\\ht\\floatBox \\advance\\dimen255 \\dp\\floatBox  % text height
    \\unvbox\\floatBox
    \\ifdim\\dimen255 < \\floatHt       % is text shorter than float height?
        \\advance\\floatHt -\\dimen255  % float height minus text height
        \\kern\\floatHt                % get down to the bottom of the float
    \\fi
}
";

use constant SIMPLE_MACROS =>
"\\input gooemacs
\\parindent=0pt\n";

use constant TWO_COLUMN_MACROS =>
"\\input gotcmacs
\\tolerance=10000\n";

our %options = (
    mag             => 1000,
    boardSizeX      => 19,
    boardSizeY      => 19,
    doubleDigits    => 0,
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
    simple          => 0,
    twoColumn       => 0,
    coords          => 0,
    bigFonts        => 0,
    texComments     => 0,
    floatControl    => 'rx',    # float right (text left), then random
    );

######################################################
#
#       Public methods
#
#####################################################

=head1 NEW

=over 4

=item my $dg2tex = B<Games::Go::Sgf2Dg::Dg2TeX-E<gt>new> (?options?)

=back

A B<new> Games::Go::D2TeX takes the following options:

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

=item B<file> =E<gt> 'filename' | $descriptor | \$string | \@array

If B<file> is defined, the TeX source is dumped into the target.
The target can be any of:

=over 4

=item filename

The filename will be opened using IO::File->new.  The filename
should include the '>' or '>>' operator as described in 'perldoc
IO::File'.  TeX source is written into the file.

=item descriptor

A file descriptor as returned by IO::File->new, or a \*FILE
descriptor.  TeX source is written into the file.

=item reference to a string scalar

TeX source is concatenated to the end of the string.

=item reference to an array

TeX source is split on "\n" and each line is pushed onto the array.

=back

Default: undef

=item B<print> =E<gt> sub { my ($dg2tex, @tex) = @_; ... }

A user defined subroutine to replace the default printing method.
This callback is called from the B<print> method (below) with the
reference to the B<Dg2TeX> object and a list of lines that are
part of the TeX diagram source.

=back

=over 8

=item B<simple> =E<gt> true | false

This generates very simple TeX which may not look so good on the page,
but is convenient if you intend to edit the TeX.

Default: false

=item B<twoColumn> =E<gt> true | false

This generates a two-column format using smaller fonts. This
option forces B<simple> true.

Default: false

=item B<coords> =E<gt> true | false

Adds coordinates to right and bottom edges.

Default: false

=item B<bigFonts> =E<gt> true | false

Use fonts magnified 1.2 times.

Default: false

=item B<texComments> =E<gt> true | false

Certain characters, when found in comments, are normally remapped as
follows:

    \   =>  $\backslash$
    {   =>  $\lbrace$
    }   =>  $\rbrace$
    $   =>  \$
    &   =>  \&
    #   =>  \#
    ^   =>  $\wedge$
    _   =>  \_
    %   =>  \%
    ~   =>  $\sim$
    <   =>  $<$
    >   =>  $>$
    |   =>  $|$

(see the TeX Book page 38).  When B<texComments> is specified, the mappings
are supressed so you can embed normal TeX source (like {\bf change fonts})
directly inside the comments.

=item B<floatControl> =E<gt> controls which side diagrams will float on

B<floatControl> is a string that controls which side diagrams floats on.
An 'l' puts the diagram on the left side (text on the right), 'r' puts the
diagram on the right side, 'a' alternates, and any other character places
the diagram randomly.  The first character is for the first diagram, second
character is for the second diagram, and so on. When there is only one
character left, that character controls all remaining diagrams.

B<floatControl> is used only during 'normal' formatting.  It is not used
with 'simple' or 'twoColumn' formats.

Default: 'rx'    # first diagram on the right, all others are random

Default: 12

=back

=head2 Interactions between options

If B<twoColumn> is true, B<simple> is turned on (no warning).

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

=item $dg2tex-E<gt>B<configure> (option =E<gt> value, ?...?)

Change Dg2TeX options from values passed at B<new> time.

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
    if ($my->{twoColumn}) {
        $my->{simple} = 1;
    }
    $my->{fontSize} = ($my->{twoColumn}) ? 10 : 12;
    # make sure edges of the board don't exceed boardSize
    $my->{leftLine}   = 1 if ($my->{leftLine} < 1);
    $my->{topLine}    = 1 if ($my->{topLine} < 1);
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

=item $dg2tex-E<gt>B<print> ($tex ? , ... ?)

B<print>s raw TeX code to B<file> as defined at B<new> time.
Whether or not B<file> was defined, B<print> accumulates the TeX
code for later retrieval with B<converted>.

=cut

sub print {
    my ($my, @args) = @_;

    # one-time init:
    unless(exists($my->{macrosDone}) and
           ($my->{macrosDone} eq 1)) {
        $my->{macrosDone} = 1;
        $my->print("\\magnification=$my->{mag}\n");
        $my->print(COMMON_MACROS);
        if (not $my->{simple}) {
            $my->print(NORMAL_MACROS);
        } elsif ($my->{twoColumn}) {
            $my->print(TWO_COLUMN_MACROS); 
        } else {
            $my->print(SIMPLE_MACROS);
        }
    }
    foreach my $arg (@args) {
        $my->{converted} .= $arg;
        &{$my->{print}} ($my, $arg);
    }
}

=item my $tex = $dg2tex-E<gt>B<converted> ($replacement_tex)

Returns the TeX source code converted so far for the B<Dg2TeX>
object.  If $replacement_tex is defined, the accumulated TeX source
code is replaced by $replacement_tex.

=cut

sub converted {
    my ($my, $tex) = @_;

    $my->{converted} = $tex if (defined($tex));
    return ($my->{converted});
}

=item $dg2tex-E<gt>B<comment> ($comment ? , ... ?)

Inserts the TeX comment character ('%') in front of each line of
each comment and B<print>s it to B<file>.

=cut

sub comment {
    my ($my, @comments) = @_;

    local $my->{macrosDone} = 1;        # allow comments before one-time init
    foreach my $c (@comments) {
        while ($c =~ s/([^\n]*)\n//) {
            $my->print("%$1\n");
        }
        $my->print("%$c\n") if ($c ne '');
    }
}

=item my $tex_source = $dg2tex-E<gt>B<convertDiagram> ($diagram)

Converts a I<Games::Go::Sgf2Dg::Diagram> into TeX.  If B<file> was defined
in the B<new> method, the TeX source is dumped into the B<file>.
In any case, the TeX source is returned as a string scalar.

=cut

sub convertDiagram {
    my ($my, $diagram) = @_;

    my @name = $diagram->name;
    $name[0] = 'Unknown Diagram' unless(defined($name[0]));
    my $propRef = $diagram->property;                   # get property list for the diagram
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

    $my->print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n");
    $my->print("%  Start of ", @name, "$range\n");
    $my->print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n");

    # adjust diagram title
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

    # figure out whether we need odd or even parity for this diagram
    delete($my->{goFont});
    foreach my $y ($my->{topLine} .. $my->{bottomLine}) {
        foreach my $x ($my->{leftLine} ..  $my->{rightLine}) {
            my $int = $diagram->get($my->diaCoords($x, $y));
            if (exists($int->{number})) {
                $my->_intersectionFont($int);   # to set goFont
            }
            last if (exists($my->{goFont}));
        }
        last if (exists($my->{goFont}));
    }
    $my->{goFont} = 'goo' unless (exists($my->{goFont}));

    # prepare TeX for the diagram
    $my->_diagram_preamble();
    # lay out the board
    $my->_board_preamble();
    foreach my $y ($my->{topLine} .. $my->{bottomLine}) {
        $my->print("\\hbox{");
        foreach my $x ($my->{leftLine} ..  $my->{rightLine}) {
            $my->_TeXifyIntersection($diagram, $x, $y);
        }
        if ($my->{coords}) {    # right-side coords
            $my->print("\\rc{", $diagram->ycoord($y), "}");
        }
        $my->print("}\n");
    }
    # print coordinates along the bottom
    if ($my->{coords}) {
        $my->print("\\vskip 4pt\n");
        $my->print("\\hbox{");
        for ($my->{leftLine} .. $my->{rightLine}) {
            $my->print("\\bc ", $diagram->xcoord($_));
        }
        $my->print("}");
    }
    $my->_board_postamble();
    # format the diagram caption
    $my->_caption(join('', @name, $range));
    # finish the diagram portion
    $my->_diagram_postamble();

    # prepare the text section
    $my->_text_preamble(join('', @name, $range));
    # if this is the first diagram, print the game inforamation
    unless(exists($my->{titleDone})) {      # first diagram only:
        $my->{titleDone} = 1;
        my @title_lines = $diagram->gameProps_to_title(sub { "{\\bf $_[0]}" });
        my $title = '';
        foreach (@title_lines) {
            s/(.*?})(.*)/$1 . $my->convertText($2)/e;
            $title .= "$_\\hfil\\break\n";
        }
        if($title ne '') {
            $my->print("$title\\hfil\\break\n\\hfil\\break\n");
        }
    }
    # deal with the over-lay stones
    $my->_TeXifyOverstones($diagram);
    # print the game comments for this diagram
    if (($my->{twoColumn}) or ($my->{simple})) {
        $my->print("\\hfil\\break\n");  # some space after caption or overstones
    }
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
            $my->print($my->convertText($c), "\\hfil\\break\n");
        }
    }
    # finish the text portion
    $my->_text_postamble();
}

=item my $tex = $dg2tex-E<gt>B<convertText> ($text)

Converts $text into TeX code by changing certain characters that are
not available in TeX cmr10 font, and by converting \n\n into
\hfil\break.  B<convertText> behavior is modified by B<texComments>
and B<simple> options.

Returns the converted text.

=cut

sub convertText {
    my ($my, $text) = @_;

    unless ($my->{texComments}) {
        $text =~ s/\$/Q\$Q/gm;              # change dollar signs to Q$Q
        $text =~ s/\\/\$\\backslash\$/gm;   # \   =>  $\backslash$
        $text =~ s/Q\$Q/\\\$/gm;            #  escape $ ($ was changed to Q$Q above)
        $text =~ s/([&#_%])/\\$1/gm;        #  escape &#_%
        $text =~ s/{/\$\\lbrace\$/gm;       # {   =>  $\lbrace$
        $text =~ s/}/\$\\rbrace\$/gm;       # }   =>  $\rbrace$
        $text =~ s/\^/\$\\wedge\$/gm;       # ^   =>  $\wedge$
        $text =~ s/\~/\$\\sim\$/gm;         # ~   =>  $\sim$
        $text =~ s/([<>|])/\$$1\$/gm;       # <>| =>  $<$  $>$ $|$
    }
    unless ($my->{simple}) {
        $text =~ s/\n/\\hfil\\break\n/gm;      # replace \n by \hfil\break
    }
    return($text);
}

=item $dg2tex-E<gt>B<close>

B<print> the TeX closer (\bye) and close the dg2tex object.  Also
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
}

######################################################
#
#       Private methods
#
#####################################################
# this method prints the stones in the text alongside the diagram that indicate
# over-lay stones ("24, 36 at 44" or "13, 15 at triangled stone", etc)
sub _TeXifyOverstones {
    my ($my, $diagram) = @_;

    my $textFont = $my->{bigFont} ? "\\bigtextstone" : " \\textstone";     # choose font

    my $group_preamble;
    my $group_postamble;
    if ($my->{simple} or $my->{twocolumn}) {
        $group_preamble = '\\nobreak';
        $group_postamble = "\\hfil\\break\n";
    } else {
        $group_preamble = "\\nobreak\\vbox{\\hsize=\\ftextWd \\baselineskip=\\goIntHt \\advance\\baselineskip 3pt\\noindent\\iffloatRight\\hfil\\fi\n";
        $group_postamble = "\\iffloatRight\\else\\hfil\\fi\\break\\vskip -8pt}\n";
    }
    foreach my $int (@{$diagram->getoverlist()}) {
        my $overStones = $group_preamble;
        for(my $ii = 0; $ii < @{$int->{overstones}}; $ii += 2) {
            # all the overstones that were put on this understone:
            my $overColor = $int->{overstones}[$ii];
            my $overNumber = $int->{overstones}[$ii+1];
            $overStones .= ", " if ($overStones ne $group_preamble);
            local $my->{stoneOffset} = $my->{offset};
            $my->_stoneFont($overColor, $overNumber);   # make sure font is right
            $overStones .= sprintf("$textFont\{\\$my->{goFont}\\%03d=\}", $my->_checkStoneNumber($overNumber));
            $overStones .= "\n" if ($ii % 4 == 3);
        }
        my $atStone = '';
        if (exists($int->{number})) {
            # numbered stone in text
            $atStone = $my->_intersectionFont($int) . sprintf("\\%03d=", $my->_checkStoneNumber($int->{number}));
        } else {
            unless (exists($int->{mark})) {
                my $mv = '';
                $mv .= " black node=$int->{black}" if (exists($int->{black}));
                $mv .= " white node=$int->{white}" if (exists($int->{white}));
                carp("Oops: understone$mv is not numbered or marked? " .
                     "This isn't supposed to be possible!");
            }
            my $color;
            if (exists($int->{black})) {
                $color = 'black';               # marked black stone in text
            }elsif (exists($int->{white})) {
                $color = 'white';               # marked white stone in text
            } else {
                carp("Oops: understone is not black or white? " .
                     "This isn't supposed to be possible!");
            }
            $atStone = $my->_drawMark($int->{mark}, $color);
            $atStone .= substr($atStone, length($atStone) - 1, 1);  # dup last char
        }
        $atStone = "$textFont\{\\$my->{goFont}$atStone\}";
        # collect all the overstones in the diagram
        $my->print("$overStones at $atStone$group_postamble");
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
sub _TeXifyIntersection {
    my ($my, $diagram, $x, $y) = @_;

    my $int = $diagram->get($my->diaCoords($x, $y));
    my $stone;
    my $color;
    my $label;
    if (exists($int->{black})) {
        $color = 'black';
    } elsif (exists($int->{white})) {
        $color = 'white';
    }
    if (exists($int->{number})) {
        $stone = $my->_intersectionFont($int) . sprintf("\\%03d", $my->_checkStoneNumber($int->{number})); # numbered stone
    } elsif (exists($int->{mark})) {
        $stone = $my->_drawMark($int->{mark}, $color);
    } elsif (exists($int->{label})) {
        $label = $int->{label};
        if ((length($label) > 1) or     # we only have single-letter labels available in the fonts
            ord($label) < ord('A') or
            ord($label) > ord('Z')) {
            # OK, label probably won't fit.  Draw the stone or intersection
            # and overlap the label.  for black stones use special to
            # change font color to white (not supported in all display
            # drivers, including pdftex - hope no one notices...)
            # We'll do this at the end by leaving label defined here
            if (exists($int->{white})) {
                $stone = WHITE;
            } elsif (exists($int->{black})) {
                $stone = BLACK;
            }
        } else {
            $label = ((ord(lc($int->{label})) - ord('a')) % 26) + 401;
            if (exists($int->{black})) {
                $stone = sprintf("\\%03d", $label);         # black labels are 401 to 426
            } elsif (exists($int->{white})) {
                $stone = sprintf("\\%03d", $label + 100);   # white labels are 501 to 526
            } else {
                $my->print("\\!  $int->{label}");           # no underneath for labeled intersections
                return;
            }
            undef $label;       # label is handled, so we can undef it now
        }
    } elsif (exists($int->{white})) {
        $stone = WHITE;
    } elsif (exists($int->{black})) {
        $stone = BLACK;
    }

    unless (defined($stone)) {
        $stone = EMPTY;       # empty intersection
    }
    if (exists($int->{hoshi})) {
        $stone .= HOSHI;
    } else {
        $stone .= $my->_underneath($x, $y);
    }
    if (defined($label)) {      # need to overlap label on top of stone or intersection
        if (exists($int->{black})) {
            $stone = "\\goLapWhite{\\gooegb $stone}{$label}";    # draw label with white ink
        } else {
            $stone = "\\goLap{\\gooegb $stone}{$label}";
        }
    }
    $my->print($stone);
}

# return the appropriate font char for the intersection
sub _underneath {
    my ($my, $x, $y) = @_;

    if ($y <= 1) {
        return TOPLEFT if ($x <= 1);            # upper left corner
        return TOPRIGHT if ($x >= $my->{boardSizeX}); # upper right corner
        return TOP;                             # upper side
    } elsif ($y >= $my->{boardSizeY}) {
        return BOTTOMLEFT if ($x <= 1);         # lower left corner
        return BOTTOMRIGHT if ($x >= $my->{boardSizeX}); # lower right corner
        return BOTTOM;                          # lower side
    }
    return LEFT if ($x <= 1);                   # left side
    return RIGHT if ($x >= $my->{boardSizeX});   # right side
    return MIDDLE;                              # somewhere in the middle
}

# sort out what to use for marked stone or intersection
my @mark_selection =
    (CIR,       SQR,       TRI,       X,        # mark on empty intersection
     CIR_BLACK, SQR_BLACK, TRI_BLACK, X_BLACK,  # mark on black stones
     CIR_WHITE, SQR_WHITE, TRI_WHITE, X_WHITE); # mark on white stones
sub _drawMark {
    my ($my, $mark, $color) = @_;

    my $idx = 3;                # default to the X mark column
    if ($mark eq 'CR') {        # CR[pt]      circle
        $idx = 0;               # circle column
    } elsif ($mark eq 'SQ') {   # SQ[pt]      square
        $idx = 1;               # square column
    } elsif ($mark eq 'TR') {   # TR[pt]      triangle
        $idx = 2;               # square column
    }
    if (defined($color)) {
        $idx += 4;              # mark on black stones row
        $idx += 4 if ($color eq 'white');   # white row
    }
    return($mark_selection[$idx]);
}


sub _intersectionFont {
    my ($my, $int) = @_;

    my $parity;
    my $color;

    if (exists($int->{black})) {
        $color = 'black';
    }
    if (exists($int->{white})) {
        if (defined($color)) {
            carp "intersection has both white and black stones!\n";
        }
        $color = 'white';
    }
    unless(defined($color)) {
        carp("can't set font for intersection with no stone");
        return '';
    }
    unless(exists($int->{number})) {
        carp("can't set font for intersection with un-numbered stone");
        return '';
    }
    return $my->_stoneFont($color, $int->{number});
}

sub _stoneFont {
    my ($my, $color, $number) = @_;

    my $parity = ($color eq 'black') ^ (($number - $my->{stoneOffset}) & 1);
    my $font = $parity ? 'goe' : 'goo';         # choose font based on color and odd/even number
    return('') if (exists($my->{goFont}) and ($font eq $my->{goFont}));
    $my->{goFont} = $font;
    return("\\$font");
}

sub _diagram_preamble {
    my ($my) = @_;

    my $b = $my->{bigFonts} ? 'b' : ''; # 'b' modifer for bigFonts
    if ($my->{twoColumn}) {
        $my->print("\\vbox{\\vbox{\\$my->{goFont}\n");
    } elsif ($my->{simple}) {
        $my->print("\\vbox{\\$b$my->{goFont}\n");
    } else {
        my $control = lc(substr($my->{floatControl}, 0, 1));
        if ($control eq 'l') {
            $my->{floatSide} = 'Left';
        } elsif ($control eq 'r') {
            $my->{floatSide} = 'Right';
        } elsif ($control eq 'a') {
            $my->{floatSide} = ($my->{floatSide} eq 'Right') ? 'Left' : 'Right';
        } else {
            $my->{floatSide} = (rand(2) < 1) ? 'Left' : 'Right';
        }
        if (length($my->{floatControl}) > 1) {
            $my->{floatControl} = substr($my->{floatControl}, 1);   # chop off first char
        }
        $my->print("\\float$my->{floatSide}\{\\setbox\\boardBox");
    }
}

sub _board_preamble {
    my ($my) = @_;

    if ($my->{twoColumn}) {
    } elsif ($my->{simple}) {
    } else {
        my $b = $my->{bigFonts} ? 'b' : ''; # 'b' modifer for bigFonts
        $my->print("\\vbox{\\$b$my->{goFont}\n");
    }
}

sub _board_postamble {
    my ($my) = @_;

    if ($my->{twoColumn}) {
    } elsif ($my->{simple}) {
    } else {
        $my->print("}");
    }
    $my->print("\\smallskip\n");
}

sub _caption {
    my ($my, $title) = @_;

    # print the diagram title
    if (($my->{twoColumn}) or ($my->{simple})) {
        # put the title in the text instead of under the diagram
    } else {
        $my->print("\\nobreak\\vbox{\\hsize=\\wd\\boardBox\n",
                   "\\box\\boardBox\\rm\n",
                   "{\\centerline{$title}}\n",
                   "}");
    }
}

sub _diagram_postamble {
    my ($my) = @_;

    if ($my->{twoColumn}) {
        $my->print("}\n");
    } elsif ($my->{simple}) {
        $my->print("\\break\n");
    } else {
    }
    $my->print("}\n");
}

sub _text_preamble {
    my ($my, $title) = @_;

    # print the diagram title
    if (($my->{twoColumn}) or ($my->{simple})) {
        $my->print("\\nobreak$title\\hfil\\break\n");
    } else {
        $my->print("{\\noindent\n");
    }
}

sub _text_postamble {
    my ($my) = @_;

    if ($my->{twoColumn}) {
        $my->print("\n\n");
    } elsif ($my->{simple}) {
        $my->print("\n\n");
    } else {
        $my->print("}\n");
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

Nah.  At least, I don't think so.  Well, I hope not.

