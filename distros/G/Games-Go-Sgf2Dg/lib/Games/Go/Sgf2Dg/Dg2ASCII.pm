#===============================================================================
#
#         FILE:  Dg2ASCII
#
#     ABSTRACT:  convert Games::Go::Sgf2Dg::Diagrams to ASCII diagrams
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#===============================================================================
#
#   Copyright (C) 2005 Reid Augustin reid@hellosix.com
#                      1000 San Mateo Dr.
#                      Menlo Park, CA 94025 USA
#

=head1 SYNOPSIS

use Games::Go::Sgf2Dg::Dg2ASCII

 my $dg2ascii = B<Games::Go::Sgf2Dg::Dg2ASCII-E<gt>new> (options);
 my $ascii = $dg2ascii->convertDiagram($diagram);

=head1 DESCRIPTION

A Games::Go::Sgf2Dg::Dg2ASCII object converts a L<Games::Go::Sgf2Dg::Diagram> object
into ASCII diagrams.

=cut

use strict;
require 5.001;

package Games::Go::Sgf2Dg::Dg2ASCII;
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

use constant TOPLEFT     => ' +--';
use constant TOPRIGHT    => '-+  ';
use constant TOP         => '----';
use constant BOTTOMLEFT  => ' +--';
use constant BOTTOMRIGHT => '-+  ';
use constant BOTTOM      => '----';
use constant LEFT        => ' |  ';
use constant RIGHT       => ' |  ';
use constant MIDDLE      => ' +  ';
use constant HOSHI       => ' *  ';
use constant WHITE       => " O  ";    # numberless white stone
use constant BLACK       => " X  ";    # numberless black stone
use constant MARKEDWHITE => " @  ";    # marked white stone
use constant MARKEDBLACK => " #  ";    # marked black stone
use constant MARKEDEMPTY => " ?  ";    # marked empty intersection
use constant WHITE1      => "O"   ;    # numberless white stone
use constant BLACK1      => "X"   ;    # numberless black stone

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

######################################################
#
#       Public methods
#
#####################################################

=head1 NEW

=over 4

=item my $dg2ascii = B<Games::Go::Sgf2Dg::Dg2ASCII-E<gt>new> (?options?)

=back

A B<new> Games::Go::Sgf2Dg::Dg2ASCII takes the following options:

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

=item B<file> =E<gt> 'filename' | $descriptor | \$string | \@array

If B<file> is defined, the ASCII diagram is dumped into the target.
The target can be any of:

=over 4

=item filename

The filename will be opened using IO::File->new.  The filename
should include the '>' or '>>' operator as described in 'perldoc
IO::File'.  The ASCII diagram is written into the file.

=item descriptor

A file descriptor as returned by IO::File->new, or a \*FILE
descriptor.  The ASCII diagram is written into the file.

=item reference to a string scalar

The ASCII diagram is concatenated to the end of the string.

=item reference to an array

The ASCII diagram is split on "\n" and each line is pushed onto the array.

=back

Default: undef

=item B<print> =E<gt> sub { my ($dg2ascii, @lines) = @_; ... }

A user defined subroutine to replace the default printing method.
This callback is called from the B<print> method (below) with the
reference to the B<Dg2ASCII> object and a list of lines that are
part of the ASCII diagram lines.

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
        croak("I don't understand option $_\n") unless(exists($options{$_}));
        $my->{$_} = $args{$_};  # transfer user option
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

=item $dg2ascii-E<gt>B<print> ($text ? , ... ?)

B<print>s the input $text directly to B<file> as defined at B<new>
time.  Whether or not B<file> was defined, B<print> accumulates the
$text for later retrieval with B<converted>.

=cut

sub print {
    my ($my, @args) = @_;

    foreach my $arg (@args) {
        $my->{converted} .= $arg;
        &{$my->{print}} ($my, $arg);
    }
}

=item my $ascii = $dg2ascii-E<gt>B<converted> ($replacement)

Returns the entire ASCII diagram converted so far for the
B<Dg2ASCII> object.  If $replacement is defined, the accumulated
ASCII is replaced by $replacement.

=cut

sub converted {
    my ($my, $text) = @_;

    $my->{converted} = $text if (defined($text));
    return ($my->{converted});
}

=item $dg2ascii-E<gt>B<comment> ($comment ? , ... ?)

Inserts the comment character (which is nothing for ASCII) in front
of each line of each comment and B<print>s it to B<file>.

=cut

sub comment {
    my ($my, @comments) = @_;

    foreach my $c (@comments) {
        while ($c =~ s/([^\n]*)\n//) {
            $my->print("$1\n");
        }
        $my->print("$c\n") if ($c ne '');
    }
}

=item my $dg2ascii-E<gt>B<convertDiagram> ($diagram)

Converts a I<Games::Go::Sgf2Dg::Diagram> into ASCII.  If B<file> was defined
in the B<new> method, the ASCII is dumped into the B<file>.  In any
case, the ASCII is returned as a string scalar.

Labels are restricted to one character (any characters after the first
are discarded).


=cut

sub convertDiagram {
    my ($my, $diagram) = @_;

    unless($my->{firstDone}) {
        $my->print("
Black -> X   Marked black -> #   Labeled black -> Xa, Xb
White -> O   Marked white -> @   Labeled white -> Oa, Ob
             Marked empty -> ?   Labeled empty ->  a,  b\n");
        $my->{firstDone} = 1;
    }
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

    # get some measurements based on font size
    my ($diaHeight, $diaWidth) = (($my->{bottomLine} - $my->{topLine} + 1), ($my->{rightLine} - $my->{leftLine} + 1));
    if ($my->{coords}) {
        $diaWidth += 4;
        $diaHeight += 2;
    }
    unless(exists($my->{titleDone})) {      # first diagram only:
        $my->{titleDone} = 1;
        my @title_lines = $diagram->gameProps_to_title();
        my $title = '';
        foreach (@title_lines) {
            $title .= "$_\n";
        }
        if($title ne '') {
            $my->print("\n\n$title\n");
        }
    }
    $my->_preamble($diaHeight, $diaWidth);
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
    $my->print(join('', @name, $range, "\n"));
    foreach my $y ($my->{topLine} .. $my->{bottomLine}) {
        foreach my $x ($my->{leftLine} ..  $my->{rightLine}) {
            $my->_convertIntersection($diagram, $x, $y);
        }
        if ($my->{coords}) {    # right-side coords
            $my->print($diagram->ycoord($y));
        }
        $my->print("\n");
        if ($y < $my->{bottomLine}) {
            if ($my->{rightLine} - $my->{leftLine} > 1) {
                $my->print(($my->{leftLine} == 1) ? LEFT : '    ',
                           '    ' x ($my->{rightLine} - $my->{leftLine} - 1),
                           ($my->{rightLine} == $my->{boardSizeY}) ? RIGHT : '',
                           "\n");
            } else {
                $my->print(LEFT, "\n");       # doesn't seem very likely!
            }
        }
    }
    # print coordinates along the bottom
    if ($my->{coords}) {
        my ($l, $r) = ($my->{leftLine}, $my->{rightLine});
        $my->print(' ');
        for ($my->{leftLine} .. $my->{rightLine}) {
            $my->print($diagram->xcoord($_), '   ');
        }
    }

    # deal with the over-lay stones
    $my->_convertOverstones($diagram);
    $my->print("\n");
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
            $my->print($my->convertText("$c\n"));
        }
    }
    $my->_postamble();
}

=item my $ascii = $dg2ascii-E<gt>B<convertText> ($text)

Converts $text into ASCII code - gee, that's not very hard.  In
fact, this method simply returns whatever is passed to it.  This is
really just a place-holder for more complicated converters.

Returns the converted text.

=cut

sub convertText {
    my ($my, $text) = @_;

    return $text;
}

=item $dg2ascii-E<gt>B<close>

B<print>s any final text to the diagram (currently none) and closes
the dg2ascii object.  Also closes B<file> if appropriate.

=cut

sub close {
    my ($my) = @_;

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

sub _convertOverstones {
    my ($my, $diagram) = @_;

    my @converted;

    foreach my $int (@{$diagram->getoverlist()}) {
        my $overStones = '';
        for(my $ii = 0; $ii < @{$int->{overstones}}; $ii += 2) {
            # all the overstones that were put on this understone:
            my $overColor = $int->{overstones}[$ii];
            my $overNumber = $int->{overstones}[$ii+1];
            $overStones .= ", " if ($overStones ne '');
            local $my->{stoneOffset} = $my->{offset};
            $overStones .= $my->_checkStoneNumber($overNumber);
        }
        my $atStone = '';
        if (exists($int->{number})) {
            # numbered stone in text
            $atStone = $my->_checkStoneNumber($int->{number});
        } else {
            unless (exists($int->{mark})) {
                my $mv = '';
                $mv .= " black node=$int->{black}" if (exists($int->{black}));
                $mv .= " white node=$int->{white}" if (exists($int->{white}));
                carp("Oops: understone$mv is not numbered or marked? " .
                     "This isn't supposed to be possible!");
            }
            if (exists($int->{black})) {
                $atStone = '#';        # marked black stone in text
            }elsif (exists($int->{white})) {
                $atStone = '@';        # marked white stone in text
            } else {
                carp("Oops: understone is not black or white? " .
                     "This isn't supposed to be possible!");
            }
        }
        # collect all the overstones in the diagram
        push(@converted, "$overStones at $atStone");
    }
    return '' unless(@converted);
    $my->print("\n", join(",\n", @converted), "\n");
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


sub _formatNumber {
    my ($my, $number) = @_;

    return " $number  " if ($number < 10);
    return  "$number  " if ($number < 100);
    return   "$number ";
}

# get text for intersection hash from $diagram.
sub _convertIntersection {
    my ($my, $diagram, $x, $y) = @_;

    my $int = $diagram->get($my->diaCoords($x, $y));
    if ($my->{VW} and               # view control AND
        not exists($int->{VW})) {   # no view on this intersection
        $my->print('    ');
        return;
    }
    my $stone;
    if (exists($int->{number})) {
        $stone = $my->_formatNumber($my->_checkStoneNumber($int->{number})); # numbered stone
    } elsif (exists($int->{mark})) {
        if (exists($int->{black})) {
            $stone = MARKEDBLACK;                       # marked black stone
        }elsif (exists($int->{white})) {
            $stone = MARKEDWHITE;                       # marked white stone
        } else {
            $stone = MARKEDEMPTY;                       # marked empty intersection
        }
    } elsif (exists($int->{label})) {
        if (exists($int->{black})) {
            $stone = ' ' . BLACK1 . substr($int->{label}, 0, 1) . ' ';     # labeled black stone
        } elsif (exists($int->{white})) {
            $stone = ' ' . WHITE1 . substr($int->{label}, 0, 1) . ' ';     # labeled white stone
        } else {
            $stone = ' ' . substr($int->{label}, 0, 1) . '  ';               # labeled intersection
        }
    } elsif (exists($int->{white})) {
        $stone = WHITE;       # numberless white stone
    } elsif (exists($int->{black})) {
        $stone = BLACK;        # numberless black stone
    }

    unless (defined($stone)) {
        if (exists($int->{hoshi})) {
            $stone = HOSHI;
        } else {
            $stone = $my->_underneath($x, $y);
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

# don't need any preamble for text diagrams
sub _preamble {
    my ($my, $diaHeight, $diaWidth) = @_;

    return;
}

# this one's pretty easy too
sub _postamble {
    my ($my) = @_;

    $my->print("\n\n");
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

Seems unlikely.

