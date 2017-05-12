#===============================================================================
#
#         FILE:  Dg2SL
#
#     ABSTRACT:  
#
#       AUTHOR:  Marcel Gruenauer, <marcel@cpan.org>
#===============================================================================

package Games::Go::Sgf2Dg::Dg2SL;

#
# sgf2dg -converter SL $(sgf_bounds.pl foo.sgf) -m 10 -n foo.sgf

use warnings;
use strict;
require 5.001;
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

use constant TOPLEFT     => ' .';
use constant TOPRIGHT    => ' .';
use constant TOP         => ' .';
use constant BOTTOMLEFT  => ' .';
use constant BOTTOMRIGHT => ' .';
use constant BOTTOM      => ' .';
use constant LEFT        => ' .';
use constant RIGHT       => ' .';
use constant MIDDLE      => ' .';
use constant HOSHI       => ' ,';
use constant WHITE       => " O";    # numberless white stone
use constant BLACK       => " X";    # numberless black stone
use constant MARKEDWHITE => " @";    # marked white stone
use constant MARKEDBLACK => " #";    # marked black stone

our %options = (
    boardSizeX      => 19,
    boardSizeY      => 19,
    doubleDigits    => 0,
    coords          => 0,
    topLine         => 1,
    bottomLine      => 19,
    leftLine        => 1,
    rightLine       => 19,
    diaCoords       => sub {
        my ($x, $y) = @_;
        $x = chr($x - 1 + ord('a'));
        $y = chr($y - 1 + ord('a'));
        return "$x$y" ;
    },
    file            => undef,
    filename        => 'unknown',
    print           => sub { return; }, # Hmph...
    );

######################################################
#
#       Public methods
#
#####################################################


sub new {
    my ($proto, %args) = @_;

    my $self = {};
    bless($self, ref($proto) || $proto);
    $self->{converted} = '';
    foreach (keys %options) {
        $self->{$_} = $options{$_};  # transfer default options
    }
    # transfer user args
    $self->configure(%args);
    return $self;
}


sub configure {
    my ($self, %args) = @_;

    if (exists $args{file}) {
        $self->{file} = delete($args{file});
        if (ref($self->{file}) eq 'SCALAR') {
            $self->{filename} = $self->{file};
            $self->{print} = sub { ${$_[0]->{file}} .= $_[1]; };
        } elsif (ref $self->{file} eq 'ARRAY') {
            $self->{filename} = 'ARRAY';
            $self->{print} = sub { push @{$_[0]->{file}}, split("\n", $_[1]); };
        } elsif (ref $self->{file} eq 'GLOB') {
            $self->{filename} = 'GLOB';
            $self->{print} = sub {
                $_[0]->{file}->print($_[1]) or
                    die "Error writing to output file:$!\n";
            };
        } elsif (ref $self->{file} =~ m/^IO::/) {
            $self->{filename} = 'IO';
            $self->{print} = sub {
                $_[0]->{file}->print($_[1]) or
                    die "Error writing to output file:$!\n";
            };
        } else {
            require IO::File;
            $self->{filename} = $self->{file};
            $self->{file} = IO::File->new($self->{filename}) or
                die("Error opening $self->{filename}: $!\n");
            $self->{print} = sub {
                $_[0]->{file}->print($_[1]) or
                    die "Error writing to $_[0]->{filename}:$!\n";
            };
        }
    }

    foreach (keys %args) {
        croak("I don't understand option $_\n") unless exists $options{$_};
        $self->{$_} = $args{$_};  # transfer user option
    }

    # make sure edges of the board don't exceed boardSize
    $self->{topLine}  = 1 if ($self->{topLine} < 1);
    $self->{leftLine} = 1 if ($self->{leftLine} < 1);
    $my->{rightLine}  = $my->{boardSizeX} if ($my->{rightLine} > $my->{boardSizeX});
    $my->{bottomLine} = $my->{boardSizeY} if ($my->{bottomLine} > $my->{boardSizeY});
}

sub diaCoords {
    my ($my, $x, $y) = @_;

    return &{$my->{diaCoords}}($x, $y);
}


sub print {
    my ($self, @args) = @_;

    foreach my $arg (@args) {
        $self->{converted} .= $arg;
        &{$self->{print}} ($self, $arg);
    }
}


sub converted {
    my ($self, $text) = @_;

    $self->{converted} = $text if defined $text;
    return $self->{converted};
}


sub convertDiagram {
    my ($self, $diagram) = @_;

    unless ($self->{firstDone}) {
        $self->comment(<<EOCOMMENT);
[maruseru]: ''The content of this page has been generated from an SGF file by sgf2dg using the Games::Go::Sgf2Dg::Dg2SL converter. You can edit it and I might "master edit" the SGF file and then regenerate this page. After regeneration, all discussion will have been lost. This is considered a feature, not a bug. :)''

EOCOMMENT

        $self->{firstDone} = 1;
    }

    # any game-level properties? TODO : Check this part!
    unless(exists($my->{titleDone})) {      # first diagram only:
        $my->{titleDone} = 1;
        my @title_lines = $diagram->gameProps_to_title(sub { "__$_[0]__" });    # emph with __XX__
        my $title = '';
        foreach (@title_lines) {
            $title .= "$_\n";
        }
        if($title ne '') {
            $my->print("\n$title\n");
        }
    }

    # print an initial diagram if there are setup stones.

    $self->_print_setup_diagram("Initial setup" => $diagram)
        if defined($diagram->user) && exists($diagram->user->{first});

    my @name = $diagram->name;
    $name[0] = 'Unknown Diagram' unless defined $name[0];
    my $propRef = $diagram->property;      # get property list for the diagram
    my $first = $diagram->first_number;
    my $last = $diagram->last_number;
    $self->{offset} = $diagram->offset;
    $self->{stoneOffset} = $diagram->offset;
    if ($self->{doubleDigits}) {
        while ($first - $self->{stoneOffset} >= 100) {
            # first to last is not supposed to cross 101
            $self->{stoneOffset} += 100;
        }
    }

    my $range = '';
    if ($first) {
        # $range = ': ' . ($first - $self->{offset});
        $range = ': ' . $first;
        if ($last != $first) {
            # $range .= '-' . ($last - $self->{offset});
            $range .= '-' . $last;
        }
    } else {
        # carp "Hmmm! No numbered moves in $name[0]";
    }

    $self->_auto_bounds($diagram);

    # get some measurements based on font size
    my $diaHeight = $self->{bottomLine} - $self->{topLine} + 1;
    my $diaWidth  = $self->{rightLine} - $self->{leftLine} + 1;

    if ($self->{coords}) {
        $diaWidth += 4;
        $diaHeight += 2;
    }

    # determine whether the first move in this diagram is White's or Black's
    my $first_move_color = '';
    my @numbered_int = $self->_get_numbered_stone_intersections($diagram);
    if (@numbered_int) {
        $first_move_color = 'B' if exists $numbered_int[0]->{black};
        if (exists $numbered_int[0]->{white}) {
            if (length($first_move_color)) {
                carp "Intersection has both black and white stones!\n";
            }
            $first_move_color = 'W';
        }
    } else {
        # no numbered stones in this diagram?
        $first_move_color = '';
    }

    $self->_preamble($diaHeight, $diaWidth);

    if (defined($diagram->var_on_move) and
        defined($diagram->parent)) {
        my $varOnMove = $diagram->var_on_move;
        my $parentOffset = $diagram->parent->offset;
        my $parentName = $diagram->parent->name->[0];
        if (defined($parentOffset) and defined($parentName)) {
            $name[0] .= sprintf ' at move %s in %s',
                ($varOnMove - $parentOffset), $parentName;
        }
    }

    # print the diagram title
    $self->print(join('', '$$', $first_move_color, ' ', @name, $range, "\n"));
    foreach my $y ($self->{topLine} .. $self->{bottomLine}) {

        # print top line, if applicable
        if ($y <= 1) {
            $self->print('$$');
            my $did_print_left_corner = 0;
            foreach my $x ($self->{leftLine} ..  $self->{rightLine}) {
                if ($x <= 1) {
                    $self->print('  --');    # UL corner
                    $did_print_left_corner = 1;
                } elsif ($x >= $self->{boardSizeX}) {
                    $self->print('--- ');    # UR corner
                } else {
                    if ($did_print_left_corner) {
                        $self->print('--');    # upper side
                    } else {
                        $self->print(' -');    # upper side, leftmost
                        $did_print_left_corner = 1;
                    }
                }
            }
            $self->print("\n");
        }

        $self->print('$$');
        foreach my $x ($self->{leftLine} ..  $self->{rightLine}) {


            $self->print(' |') if $x <= 1;
            $self->_convertIntersection($diagram, $x, $y);
            $self->print(' |') if $x >= $self->{boardSizeX};
        }
        if ($self->{coords}) {    # right-side coords
            $self->print($diagram->ycoord($y));
        }
        $self->print("\n");

        # print bottom line, if applicable
        if ($y >= $self->{boardSizeY}) {
            $self->print('$$');
            my $did_print_left_corner = 0;
            foreach my $x ($self->{leftLine} ..  $self->{rightLine}) {
                if ($x <= 1) {
                    $self->print('  --');    # LL corner
                    $did_print_left_corner = 1;
                } elsif ($x >= $self->{boardSizeX}) {
                    $self->print('--- ');    # LR corner
                } else {
                    if ($did_print_left_corner) {
                        $self->print('--');    # lower side
                    } else {
                        $self->print(' -');    # lower side, leftmost
                        $did_print_left_corner = 1;
                    }
                }
            }
            $self->print("\n");
        }

    }
    $self->print("\n");

    # print coordinates along the bottom TODO check this
    if ($self->{coords}) {
        $self->print(' ');
        for ($self->{leftLine} .. $self->{rightLine});
            $self->print('   ', $diagram->xcoord($_));
        );
        $self->print("\n");
    }

    # deal with the over-lay stones
    $self->_convertOverstones($diagram);
    $self->print("\n");

    # print the game comments for this diagram
    foreach my $n (sort { $a <=> $b } keys %$propRef) {
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
        push @comment, @{$propRef->{$n}{C}} if exists $propRef->{$n}{C};
        if (@comment) {
            my $c = '';
            my $n_off = $n - $self->{offset};

            # Determine color of stone whose number is $n_off so we can use
            # nice stone images in the text.

            my $color = '';
            for (@numbered_int) {
                next unless $_->{number} == $n_off;
                $color = 'B' if exists $_->{black};
                if (exists $_->{white}) {
                    if (length $color) {
                        carp "stone numbered $_->{number} has both black and white color?\n";
                    }
                    $color = 'W';
                }
                last;
            }

            $c = "$color$n_off: "
                if ($n > 0) and ($n >= $first) and ($n <= $last);
            $c .= join("\n", @comment);
            $self->print($self->convertText("$c\n\n"));
        }
    }
    $self->_postamble();
}


sub convertText {
    my ($self, $text) = @_;

    $text;
}


sub comment {
    my ($self, @comments) = @_;

    foreach my $c (@comments) {
        next if $c =~ /This file was created/;
        while ($c =~ s/([^\n]*)\n//) {
            $self->print("$1\n");
        }
        $self->print("$c\n") if ($c ne '');
    }
}


sub close {
    my $self = shift;

    if (defined $self->{file} and
        ((ref $self->{file} eq 'GLOB') or
         (ref $self->{file} eq 'IO::File'))) {
        $self->{file}->close;
    }
}


######################################################
#
#       Private methods
#
#####################################################


sub _convertOverstones {
    my ($self, $diagram) = @_;

    my @converted;

    foreach my $int (@{$diagram->getoverlist()}) {
        my $overStones = '';
        for(my $ii = 0; $ii < @{$int->{overstones}}; $ii += 2) {
            # all the overstones that were put on this understone:
            my $overColor = $int->{overstones}[$ii];
            my $overNumber = $int->{overstones}[$ii+1];
            $overStones .= ", " if ($overStones ne '');
            local $self->{stoneOffset} = $self->{offset};
            $overStones .= $self->_checkStoneNumber($overNumber);
        }
        my $atStone = '';
        if (exists $int->{number}) {
            # numbered stone in text
            $atStone = $self->_checkStoneNumber($int->{number});
        } else {
            unless (exists $int->{mark}) {
                my $mv = '';
                $mv .= " black node=$int->{black}" if exists $int->{black};
                $mv .= " white node=$int->{white}" if exists $int->{white};
                carp("Oops: understone$mv is not numbered or marked? " .
                     "This isn't supposed to be possible!");
            }
            if (exists $int->{black}) {
                $atStone = '#';        # marked black stone in text
            }elsif (exists $int->{white}) {
                $atStone = '@';        # marked white stone in text
            } else {
                carp("Oops: understone is not black or white? " .
                     "This isn't supposed to be possible!");
            }
        }
        # collect all the overstones in the diagram
        push @converted, "$overStones at $atStone";
    }
    return '' unless(@converted);
    $self->print(join(",\n", @converted), "\n");
}


sub _checkStoneNumber {
    my ($self, $number) = @_;

    if ($number - $self->{stoneOffset} > 0) {
        return $number - $self->{stoneOffset};
    }
    if ($number < 1) {
        carp "Yikes: stone number $number is less than 1. Intersection/stone will be missing!";
    } else {
        carp "Stone number $number and offset $self->{stoneOffset} makes less than 1 - not using offset";
    }
    return $number;
}


sub _formatNumber {
    my ($self, $number) = @_;

    return " $number" if ($number < 10);
    return ' 0' if $number == 10;
    carp "Sensei's Library only supports numbered stones up to 10 (found $number)\n";
    return ' 0';
}


# get text for intersection hash from $diagram.
sub _convertIntersection {
    my ($self, $diagram, $x, $y) = @_;

    my $int = $diagram->get($self->diaCoords($x, $y));
    my $stone;
    if (exists $int->{number}) {
        # numbered stone
        $stone = $self->_formatNumber($self->_checkStoneNumber($int->{number}));
    } elsif (exists $int->{mark}) {
        if (exists $int->{black}) {
            $stone = MARKEDBLACK;                       # marked black stone
        }elsif (exists $int->{white}) {
            $stone = MARKEDWHITE;                       # marked white stone
        } else {
            carp "Can't mark empty intersection";
        }
    } elsif (exists $int->{label}) {
        if (exists $int->{black}) {
            # labeled black stone
            # $stone = ' ' . BLACK . lc($int->{label}) . ' ';
            carp "Sensei's Library doesn't support labelled black stones";
            $stone = BLACK;   # numberless black stone
        } elsif (exists $int->{white}) {
            # labeled white stone
            # $stone = ' ' . WHITE . lc($int->{label}) . ' ';
            carp "Sensei's Library doesn't support labelled white stones";
            $stone = WHITE;   # numberless white stone
        } else {
            # labeled intersection
            $stone = ' ' . $int->{label};
        }
    } elsif (exists $int->{white}) {
        $stone = WHITE;       # numberless white stone
    } elsif (exists $int->{black}) {
        $stone = BLACK;        # numberless black stone
    }

    unless (defined $stone) {
        if (exists $int->{hoshi}) {
            $stone = HOSHI;
        } else {
            $stone = $self->_underneath($x, $y);
        }
    }
    $self->print($stone);
}


# return the appropriate font char for the intersection
sub _underneath {
    my ($self, $x, $y) = @_;

    if ($y <= 1) {
        return TOPLEFT if ($x <= 1);            # upper left corner
        return TOPRIGHT if ($x >= $self->{boardSizeX}); # upper right corner
        return TOP;                             # upper side
    } elsif ($y >= $self->{boardSizeY}) {
        return BOTTOMLEFT if ($x <= 1);         # lower left corner
        return BOTTOMRIGHT if ($x >= $self->{boardSizeX}); # lower right corner
        return BOTTOM;                          # lower side
    }
    return LEFT if ($x <= 1);                   # left side
    return RIGHT if ($x >= $self->{boardSizeX});   # right side
    return MIDDLE;                              # somewhere in the middle
}


# don't need any preamble for text diagrams
sub _preamble {
    my ($self, $diaHeight, $diaWidth) = @_;

    return;
}


# this one's pretty easy too
sub _postamble {
    my $self = shift;

    $self->print("\n\n");
}


sub _get_numbered_stone_intersections {
    my ($self, $diagram) = @_;

    my @intersection;
    foreach my $y ($self->{topLine} .. $self->{bottomLine}) {
        foreach my $x ($self->{leftLine} ..  $self->{rightLine}) {
            my $int = $diagram->get($self->diaCoords($x, $y));
            push @intersection => $int if exists $int->{number};
        }
    }
    my @ordered = sort { $a->{number} <=> $b->{number} } @intersection;
    wantarray ? @ordered : \@ordered;
}


sub _print_setup_diagram {
    my ($self, $name, $diagram) = @_;
    my $setup_diagram = Games::Go::Sgf2Dg::Diagram->new;
    # copy black and white stones, and hoshi points.
    my $did_find_stones = 0;
    foreach my $y (1 .. $self->{boardSize}) {
        foreach my $x (1 ..  $self->{boardSize}) {
            my $coords = $self->diaCoords($x, $y);
            my $int = $diagram->get($coords);
            next if exists $int->{number};

            if (exists $int->{white}) {
                $setup_diagram->put($coords, 'white');
                $did_find_stones = 1;
            }

            if (exists $int->{black}) {
                $setup_diagram->put($coords, 'black');

                # To avoid printing an initial diagram In handicap games,
                # we require black stones other than the hoshi points to
                # be there, so don't count initial black hoshi stones.

                $did_find_stones = 1 unless exists $int->{hoshi};
            }

            if (exists $int->{hoshi}) {
                $setup_diagram->hoshi($coords);
            }

            $setup_diagram->node;   # commit
        }
    }

    $setup_diagram->name($name);
    $self->convertDiagram($setup_diagram) if $did_find_stones;
}


# set topLine, bottomLine, etc. based on the extent of the current diagram

sub _auto_bounds {
    my ($self, $diagram) = @_;
    my ($left, $right, $top, $bottom) = (0, 0, 0, 0);

    # Visit each stone in this diagram to determine the bounds

    foreach my $y (1 .. $self->{boardSize}) {
        foreach my $x (1 ..  $self->{boardSize}) {
            my $coords = $self->diaCoords($x, $y);
            my $int = $diagram->get($coords);
            next unless exists($int->{black}) || exists ($int->{white});

            $_ ||= $x for $left, $right;
            $_ ||= $y for $top,  $bottom;

            if ($x < $left)   { $left   = $x }
            if ($x > $right)  { $right  = $x }
            if ($y < $top)    { $top    = $y }
            if ($y > $bottom) { $bottom = $y }
        }
    }

    # Now we have the boundaries of the stones played. Leave two empty lines
    # on each sides.

    $_ -= 2 for $left, $top;
    $_ += 2 for $right, $bottom;

    # don't leave out just border lines
    $left   = 1 if $left <= 2;
    $right  = $self->{boardSize} if $right >= $self->{boardSize} - 1;
    $top    = 1 if $top <= 2;
    $bottom = $self->{boardSize} if $bottom >= $self->{boardSize} - 1;

    # don't cut off one line away from the border 
    $self->{leftLine}   = $left   if $left   > 2;
    $self->{rightLine}  = $right  if $right  < 18;
    $self->{topLine}    = $top    if $top    > 2;
    $self->{bottomLine} = $bottom if $bottom < 18;
}


1;

__END__

=head1 NAME

Games::Go::Sgf2Dg::Dg2SL - Perl extension to convert Games::Go::Sgf2Dg::Diagrams to Sensei's Library format

=head1 SYNOPSIS

use Games::Go::Sgf2Dg::Dg2SL

 my $dg2sl = B<Games::Go::Sgf2Dg::Dg2SL-E<gt>new> (options);
 my $sl = $dg2sl->convertDiagram($diagram);

=head1 DESCRIPTION

A Games::Go::Sgf2Dg::Dg2SL object converts a L<Games::Go::Sgf2Dg::Diagram> object into
Sensei's Library diagrams (see http://senseis.xmp.net/).

Sensei's Library diagrams only support move numbers from 1-10, so make sure
you call sgf2dg with arguments that specify a maximum of 10 moves per diagram
and starting each diagram with move number 1. Example:

  sgf2dg -converter SL -m 10 -n foo.sgf

Sensei's Library also doesn't support labelled stones.

An initial setup diagram is printed if the initial board isn't empty and
doesn't have a handicap setup - i.e., only black stones, all of which are on
hoshi points.

Diagrams' extents are limited to the stones actually played, plus a margin.
That is, if there are only stones in one corner, only that corner is printed,
not the whole diagram. This is useful for analyses of local positions, but
if the first ten moves of a real game are all in one corner - however
unlikely that may be -, it would produce undesirable results.

=head1 NEW

=over 4

=item my $dg2sl = B<Games::Go::Sgf2Dg::Dg2SL-E<gt>new> (?options?)

=back

A B<new> Games::Go::Sgf2Dg::Dg2SL takes the following options:

=over 8

=item B<boardSize> =E<gt> number

Sets the size of the board.

Default: 19

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
          return "$x$y"; },           # concatenate two letters

See also the B<diaCoords> method below.

=item B<file> =E<gt> 'filename' | $descriptor | \$string | \@array

If B<file> is defined, the Sensei's Library diagram is dumped into the target.
The target can be any of:

=over 4

=item filename

The filename will be opened using IO::File->new. The filename should include
the '>' or '>>' operator as described in 'perldoc IO::File'. The Sensei's
Library diagram is written into the file.

=item descriptor

A file descriptor as returned by IO::File->new, or a \*FILE descriptor. The
Sensei's Library diagram is written into the file.

=item reference to a string scalar

The Sensei's Library diagram is concatenated to the end of the string.

=item reference to an array

The Sensei's Library diagram is split on "\n" and each line is pushed onto the
array.

=back

Default: undef

=item B<print> =E<gt> sub { my ($dg2sl, @lines) = @_; ... }

A user defined subroutine to replace the default printing method.
This callback is called from the B<print> method (below) with the
reference to the B<Dg2SL> object and a list of lines that are
part of the Sensei's Library diagram lines.

=back

=head1 METHODS

=over 4

=item $dg2sl-E<gt>B<configure> (option =E<gt> value, ?...?)

Change Dg2SL options from values passed at B<new> time.

=item my $coord = $dg2mp-E<gt>B<diaCoords> ($x, $y)

Provides access to the B<diaCoords> option (see above).  Returns
coordinates in the converter's coordinate system for board coordinates ($x,
$y).  For example, to get a specific intersection structure:

    my $int = $diagram->get($dg2mp->diaCoords(3, 4));

=item $dg2sl-E<gt>B<print> ($text ? , ... ?)

B<print>s the input $text directly to B<file> as defined at B<new>
time.  Whether or not B<file> was defined, B<print> accumulates the
$text for later retrieval with B<converted>.

=item my $sl = $dg2sl-E<gt>B<converted> ($replacement)

Returns the entire Sensei's Library diagram converted so far for the B<Dg2SL>
object. If $replacement is defined, the accumulated Sensei's Library is
replaced by $replacement.

=item $dg2sl-E<gt>B<comment> ($comment ? , ... ?)

Inserts the comment character (which is nothing for Sensei's Library) in front
of each line of each comment and B<print>s it to B<file>.


=item my $dg2sl-E<gt>B<convertDiagram> ($diagram)

Converts a I<Games::Go::Sgf2Dg::Diagram> into Sensei's Library. If B<file> was defined
in the B<new> method, the Sensei's Library is dumped into the B<file>.  In any
case, the Sensei's Library is returned as a string scalar.


=item my $sl = $dg2sl-E<gt>B<convertText> ($text)

Converts $text into Sensei's Library code - gee, that's not very hard.  In
fact, this method simply returns whatever is passed to it.  This is
really just a place-holder for more complicated converters.

Returns the converted text.


=item $title = $dg2sl-E<gt>B<convertGameProps> (\%sgfHash)

B<convertGameProps> takes a reference to a hash of properties as
extracted from an SGF file.  Each hash key is a property ID and the
hash value is a reference to an array of property values:
$hash->{propertyId}->[values].  The following SGF properties are
recognized:

=over 4

=item GN GameName

=item EV EVent

=item RO ROund

=item DT DaTe

=item PW PlayerWhite

=item WR WhiteRank

=item PB PlayerBlack

=item BR BlackRank

=item PC PlaCe

=item KM KoMi

=item RU RUles

=item TM TiMe

=item OT OverTime (byo-yomi)

=item RE REsult

=item AN ANnotator

=item SO Source

=item US USer (entered by)

=item CP CoPyright

=item GC GameComment

=back

Both long and short property names are recognized, and all
unrecognized properties are ignored with no warnings.  Note that
these properties are all intended as game-level notations.

=item $dg2sl-E<gt>B<close>

B<print>s any final text to the diagram (currently none) and closes
the dg2sl object.  Also closes B<file> if appropriate.

=back

=head1 SEE ALSO

=over

=item L<sgf2dg>(1)

Script to convert SGF format files to Go diagrams

=back

=head1 BUGS

Seems likely.

=head1 AUTHOR

Marcel Gruenauer, E<lt>marcel@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Marcel Gruenauer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.
