# -*- Perl -*-
#
# generate patterns of text. run perldoc(1) on this file for documentation

package Game::TextPatterns;
our $VERSION = '1.47';

use 5.24.0;
use warnings;
use Carp qw(croak);
use Game::TextPatterns::Util ();
use List::Util qw(min);
use Moo;
use namespace::clean;
use Scalar::Util qw(looks_like_number);

with 'MooX::Rebuild';    # for ->rebuild (which differs from ->clone)

has pattern => (
    is     => 'rw',
    coerce => sub {
        my $type = ref $_[0];
        if ($type eq "") {
            my @pat = split $/, $_[0];
            my $len = length $pat[0];
            for my $i (1 .. $#pat) {
                die "columns must be of equal length" if length $pat[$i] != $len;
            }
            return \@pat;
        } elsif ($type eq 'ARRAY') {
            my $len = length $_[0]->[0];
            for my $i (1 .. $_[0]->$#*) {
                die "columns must be of equal length" if length $_[0]->[$i] != $len;
            }
            return [ $_[0]->@* ];
        } elsif ($_[0]->can("pattern")) {
            return [ $_[0]->pattern->@* ];
        } else {
            die "unknown pattern type '$type'";
        }
    },
);

sub BUILD {
    my ($self, $param) = @_;
    croak "a pattern must be supplied" unless exists $param->{pattern};
}

########################################################################
#
# METHODS

sub append_cols {
    my ($self, $fill, $pattern) = @_;
    croak "need append_cols(fill, pattern)" if !defined $pattern;
    my ($fill_cur, $fill_new);
    if (ref $fill eq 'ARRAY') {
        ($fill_cur, $fill_new) = $fill->@*;
    } else {
        $fill_cur = $fill_new = $fill;
    }
    my $pat     = $self->pattern;
    my @cur_dim = (length $_[0]->pattern->[0], scalar $_[0]->pattern->@*);
    my @new_dim = $pattern->dimensions;
    if ($cur_dim[1] > $new_dim[1]) {
        for my $i (1 .. $cur_dim[1] - $new_dim[1]) {
            $pat->[ -$i ] .= $fill_new x $new_dim[0];
        }
    } elsif ($cur_dim[1] < $new_dim[1]) {
        for my $i (1 .. $new_dim[1] - $cur_dim[1]) {
            push $pat->@*, $fill_cur x $cur_dim[0];
        }
    }
    my $new = $pattern->pattern;
    for my $i (0 .. $new_dim[1] - 1) {
        $pat->[$i] .= $new->[$i];
    }
    return $self;
}

sub append_rows {
    my ($self, $fill, $pattern) = @_;
    croak "need append_rows(fill, pattern)" if !defined $pattern;
    my ($fill_cur, $fill_new);
    if (ref $fill eq 'ARRAY') {
        ($fill_cur, $fill_new) = $fill->@*;
    } else {
        $fill_cur = $fill_new = $fill;
    }
    my $pat     = $self->pattern;
    my @cur_dim = (length $_[0]->pattern->[0], scalar $_[0]->pattern->@*);
    my @new_dim = $pattern->dimensions;
    push $pat->@*, $pattern->pattern->@*;
    if ($cur_dim[0] > $new_dim[0]) {
        for my $i (0 .. $new_dim[1] - 1) {
            $pat->[ $cur_dim[1] + $i ] .= $fill_new x ($cur_dim[0] - $new_dim[0]);
        }
    } elsif ($cur_dim[0] < $new_dim[0]) {
        for my $i (0 .. $cur_dim[1] - 1) {
            $pat->[$i] .= $fill_cur x ($new_dim[0] - $cur_dim[0]);
        }
    }
    return $self;
}

sub as_array {
    my ($self) = @_;
    my $pat = $self->pattern;
    my @array;
    for my $row ($pat->@*) {
        push @array, [ split //, $row ];
    }
    return \@array;
}

sub border {
    my ($self, $width, $char) = @_;
    if (defined $width) {
        die "width must be a positive integer"
          if !looks_like_number($width)
          or $width < 1;
        $width = int $width;
    } else {
        $width = 1;
    }
    if (defined $char and length $char) {
        $char = substr $char, 0, 1;
    } else {
        $char = '#';
    }
    my $pat = $self->pattern;
    my ($cols, $rows) = (length $pat->[0], scalar $pat->@*);
    my ($newcols, $newrows) = map { $_ + ($width << 1) } $cols, $rows;
    my @np = ($char x $newcols) x $width;
    for my $row ($pat->@*) {
        push @np, ($char x $width) . $row . ($char x $width);
    }
    push @np, ($char x $newcols) x $width;
    $self->pattern(\@np);
    return $self;
}

sub clone { __PACKAGE__->new(pattern => $_[0]->pattern) }

sub cols       { length $_[0]->pattern->[0] }
sub dimensions { length $_[0]->pattern->[0], scalar $_[0]->pattern->@* }
sub rows       { scalar $_[0]->pattern->@* }

sub _normalize_rectangle {
    my ($self, $p1, $p2, $cols, $rows) = @_;
    for my $p ($p1, $p2) {
        $p->[0] += $cols if $p->[0] < 0;
        $p->[1] += $rows if $p->[1] < 0;
        if ($p->[0] < 0 or $p->[0] >= $cols or $p->[1] < 0 or $p->[1] >= $rows) {
            local $" = ',';
            return undef, "crop point @$p out of bounds";
        }
    }
    ($p1->[0], $p2->[0]) = ($p2->[0], $p1->[0]) if $p1->[0] > $p2->[0];
    ($p1->[1], $p2->[1]) = ($p2->[1], $p1->[1]) if $p1->[1] > $p2->[1];
    return $p1, $p2;
}

sub crop {
    my ($self, $p1, $p2) = @_;
    my $pat = $self->pattern;
    my ($cols, $rows) = (length $pat->[0], scalar $pat->@*);
    if (!$p2) {
        $p2 = $p1;
        $p1 = [ 0, 0 ];
    }
    ($p1, $p2) = $self->_normalize_rectangle($p1, $p2, $cols, $rows);
    croak $p2 unless defined $p1;
    my @new;
    unless ($p2->[0] == 0 or $p2->[1] == 0) {
        for my $rnum ($p1->[1] .. $p2->[1]) {
            push @new, substr $pat->[$rnum], $p1->[0], $p2->[0] - $p1->[0] + 1;
        }
    }
    $self->pattern(\@new);
    return $self;
}

sub draw_in {
    my ($self, $p1, $p2, $pattern) = @_;
    my $pat = $self->pattern;
    my ($cols, $rows) = (length $pat->[0], scalar $pat->@*);
    if (!defined $pattern) {
        $pattern = $p2;
        croak "need pattern to draw into the object" if !defined $pattern;
        $p2 = [ $cols - 1, $rows - 1 ];
    }
    ($p1, $p2) = $self->_normalize_rectangle($p1, $p2, $cols, $rows);
    my $draw = $pattern->pattern;
    my ($draw_cols, $draw_rows) = (length $draw->[0], scalar $draw->@*);
    my $ccount = min($draw_cols, $p2->[0] - $p1->[0] + 1);
    my $rcount = min($draw_rows, $p2->[1] - $p1->[1] + 1);
    for my $rnum (0 .. $rcount - 1) {
        substr($pat->[ $p1->[1] + $rnum ], $p1->[0], $ccount) =
          substr($draw->[$rnum], 0, $ccount);
    }
    return $self;
}

sub _fill {
    my ($self, $p, $char, $adjfn) = @_;
    my $ref     = $self->as_array;
    my $max_col = $ref->[0]->$#*;
    my $max_row = $ref->$#*;
    if (   $p->[0] < 0
        or $p->[0] > $max_col
        or $p->[1] < 0
        or $p->[1] > $max_row) {
        croak "point @$p out of bounds";
    }
    my @queue   = $p;
    my $replace = $ref->[ $p->[1] ][ $p->[0] ];
    while (my $p = pop @queue) {
        if ($ref->[ $p->[1] ][ $p->[0] ] eq $replace) {
            $ref->[ $p->[1] ][ $p->[0] ] = $char;
            push @queue, $adjfn->($p, $max_col, $max_row);
        }
    }
    $self->from_array($ref);
    return $self;
}

sub fill_4way { push @_, \&Game::TextPatterns::Util::adj_4way; return &_fill }
sub fill_8way { push @_, \&Game::TextPatterns::Util::adj_8way; return &_fill }

# "mirrors are abominable" (Jorge L. Borges. "Tlön, Uqbar, Orbis Tertuis")
# so the term flip is here used instead
sub flip_both {
    my ($self) = @_;
    my $pat = $self->pattern;
    for my $row ($pat->@*) {
        $row = reverse $row;
    }
    $pat->@* = reverse $pat->@* if $pat->@* > 1;
    return $self;
}

sub flip_cols {
    my ($self) = @_;
    for my $row ($self->pattern->@*) {
        $row = reverse $row;
    }
    return $self;
}

sub flip_four {
    my ($self, $reduce_col, $reduce_row) = @_;
    $reduce_row //= $reduce_col;
    my $q1 = $self->clone;
    my $q2 = $q1->clone->flip_cols;
    if ($reduce_col) {
        $q2->crop([ 0, 0 ], [ -2, -1 ]);
    }
    my $q3 = $q2->clone->flip_rows;
    my $q4 = $q1->clone->flip_rows;
    if ($reduce_row) {
        $q3->crop([ 0, 1 ], [ -1, -1 ]);
        $q4->crop([ 0, 1 ], [ -1, -1 ]);
    }
    $q2->append_cols('?', $q1);
    $q3->append_cols('?', $q4);
    $q2->append_rows('?', $q3);
    return $q2;
}

sub flip_rows {
    my ($self) = @_;
    my $pat = $self->pattern;
    $pat->@* = reverse $pat->@* if $pat->@* > 1;
    return $self;
}

sub four_up {
    my ($self, $fill, $do_crop, $reduce) = @_;
    if (defined $fill) {
        croak "fill to four_up must not be a ref" if ref $fill;
    } else {
        $fill = '?';
    }
    my @quads = $self->clone;
    my $pat   = $quads[0]->pattern;
    my ($cols, $rows) = (length $pat->[0], scalar $pat->@*);
    if ($do_crop) {
        my $rownum = $rows - 1;
        if ($cols > $rows) {    # wide
            $quads[0]->crop([ 0, 0 ], [ $rownum, $rownum ]);
        } elsif ($cols < $rows) {    # tall
            my $colnum = $cols - 1;
            $quads[0]->crop([ 0, $rownum - $colnum ], [ $colnum, $rownum ]);
        }
    } else {
        if ($cols > $rows) {         # wide
            my $add = $cols - $rows;
            my $pad = __PACKAGE__->new(pattern => $fill)->multiply($cols, $add)
              ->append_rows($fill, $quads[0]);
            $quads[0] = $pad;
        } elsif ($cols < $rows) {    # tall
            my $add = $rows - $cols;
            my $pad = __PACKAGE__->new(pattern => $fill)->multiply($add, $rows);
            $quads[0]->append_cols($fill, $pad);
        }
    }
    for my $r (1 .. 3) {
        push @quads, $quads[0]->clone->rotate($r);
    }
    $quads[1]->append_cols($fill, $quads[0]);
    $quads[2]->append_cols($fill, $quads[3]);
    $quads[1]->append_rows($fill, $quads[2]);
    return $quads[1];
}

sub from_array {
    my ($self, $array) = @_;
    my @pat;
    for my $row ($array->@*) {
        push @pat, join('', $row->@*);
    }
    $self->pattern(\@pat);
    return $self;
}

sub mask {
    my ($self, $mask, $pattern) = @_;
    my $pat = $self->pattern;
    my ($cols, $rows) = (length $pat->[0], scalar $pat->@*);
    my $rep = $pattern->pattern;
    for my $r (0 .. $rows - 1) {
        $pat->[$r] =~ s{([$mask]+)}{substr($rep->[$r], $-[0], $+[0] - $-[0]) || $1}eg;
    }
    return $self;
}

sub multiply {
    my ($self, $cols, $rows) = @_;
    die "cols must be a positive integer"
      if !defined $cols
      or !looks_like_number($cols)
      or $cols < 1;
    $cols = int $cols;
    if (defined $rows) {
        die "rows must be a positive integer"
          if !looks_like_number($rows)
          or $rows < 1;
        $rows = int $rows;
    } else {
        $rows = $cols;
    }
    if ($cols > 1) {
        for my $row ($self->pattern->@*) {
            $row = $row x $cols;
        }
    }
    if ($rows > 1) {
        $self->pattern([ ($self->pattern->@*) x $rows ]);
    }
    return $self;
}

sub overlay {
    my ($self, $p, $overlay, $mask) = @_;
    my ($cols, $rows) = $self->dimensions;
    $p->[0] += $cols - 1 if $p->[0] < 0;
    $p->[1] += $rows - 1 if $p->[1] < 0;
    if ($p->[0] < 0 or $p->[0] >= $cols or $p->[1] < 0 or $p->[1] >= $rows) {
        local $" = ',';
        croak "point @$p out of bounds";
    }
    my ($colnum, $rownum) = map { $_ - 1 } $overlay->dimensions;
    my $subpat =
      $self->clone->crop($p,
        [ min($p->[0] + $colnum, $cols - 1), min($p->[1] + $rownum, $rows - 1) ]);
    my $to_draw = $overlay->clone->mask($mask, $subpat);
    $self->draw_in($p, $to_draw);
    return $self;
}

sub randomly {
    my ($self, $re, $percent, $fn) = @_;
    my $pat = $self->pattern;
    my ($cols, $rows) = (length $pat->[0], scalar $pat->@*);
    my $total   = $cols * $rows;
    my $to_fill = int($total * $percent);
    $cols--;
    $rows--;
    if ($to_fill > 0) {
        while (my ($r, $row) = each $pat->@*) {
            for my $c (0 .. $cols) {
                if (substr($row, $c, 1) =~ m/$re/ and rand() < $to_fill / $total) {
                    # NOTE exposes internals but I have no plans of
                    # changing them
                    $fn->($pat, [ $c, $r ], $cols, $rows);
                    $to_fill--;
                }
                $total--;
            }
        }
    }
    return $self;
}

sub rotate {
    my ($self, $rotate_by) = @_;
    $rotate_by %= 4;
    if ($rotate_by == 0) {    # zero degrees
        return $self;
    } elsif ($rotate_by == 2) {    # 180 degrees
        return $self->flip_both;
    }
    my $pat = $self->pattern;
    my ($cols, $rows) = (length $pat->[0], scalar $pat->@*);
    my @new;
    if ($rotate_by == 1) {         # 90 degrees
        for my $char (split //, $pat->[0]) {
            unshift @new, $char;
        }
        if ($rows > 1) {
            for my $rnum (1 .. $rows - 1) {
                for my $cnum (0 .. $cols - 1) {
                    $new[ $cols - $cnum - 1 ] .= substr $pat->[$rnum], $cnum, 1;
                }
            }
        }
    } elsif ($rotate_by == 3) {    # 270 degrees
        for my $char (split //, $pat->[-1]) {
            push @new, $char;
        }
        if ($rows > 1) {
            for my $rnum (reverse 0 .. $rows - 2) {
                for my $cnum (0 .. $cols - 1) {
                    $new[$cnum] .= substr $pat->[$rnum], $cnum, 1;
                }
            }
        }
    }
    $self->pattern(\@new);
    return $self;
}

sub string {
    my ($self, $sep) = @_;
    $sep //= $/;
    return join($sep, $self->pattern->@*) . $sep;
}

sub trim {
    my ($self, $amount) = @_;
    # -1 is the last index, so need at least one more than that
    my $neg = -($amount + 1);
    return $self->crop([ $amount, $amount ], [ $neg, $neg ]);
}

sub white_noise {
    my ($self, $char, $percent) = @_;
    my $pat = $self->pattern;
    my ($cols, $rows) = (length $pat->[0], scalar $pat->@*);
    my $total   = $cols * $rows;
    my $to_fill = int($total * $percent);
    if ($to_fill > 0) {
        for my $row ($pat->@*) {
            for my $i (0 .. $cols - 1) {
                if (rand() < $to_fill / $total) {
                    substr($row, $i, 1) = $char;
                    $to_fill--;
                }
                $total--;
            }
        }
    }
    return $self;
}

1;
__END__

=head1 NAME

Game::TextPatterns - generate patterns of text

=head1 SYNOPSIS

  use Game::TextPatterns;

  my $pat = Game::TextPatterns->new( pattern => ".#\n#." );

  $pat->multiply(7,3)->border->border(1, '.')->border;

  print $pat->string;

Ta-da! You should now have an Angband checker type vault. (Doors not
included. Items and monsters may cost extra.)

  ####################
  #..................#
  #.################.#
  #.#.#.#.#.#.#.#.##.#
  #.##.#.#.#.#.#.#.#.#
  #.#.#.#.#.#.#.#.##.#
  #.##.#.#.#.#.#.#.#.#
  #.#.#.#.#.#.#.#.##.#
  #.##.#.#.#.#.#.#.#.#                       @
  #.################.#
  #..................#
  ####################

Items might be added by applying an appropriate B<mask>:

  my $i = Game::TextPatterns->new( pattern => "." );
  $i->multiply( 19, 11 );
  $i->white_noise( '?', .1 );
  $pat->mask( '.', $i );
  print $pat->string;

Which could result in

  ####################
  #.?..............?.#
  #.################.#
  #.#.#.#.#.#.#.#.##.#
  #?##.#.#.#.#.#.#.#.#
  #.#.#.#.#.#.#?#.##?#
  #.##.#?#.#.#.#.#.#.#
  #.#.#?#.#.#.#.#.##.#                  #######
  #.##.#.#.#.#.#.#.#.#                  .@...<#
  #.################.#                  #######
  #.?....?.?.........#
  ####################

And this pattern adjusted with B<four_up>, twice

  $pat = Game::TextPatterns->new( pattern => <<"EOF" );
  ..##.
  ...##
  #....
  ##..#
  .#.##
  EOF
  print $pat->four_up->four_up->string;

creates

  .#.##..##..#.##..##.
  ##..#...####..#...##
  #....#....#....#....
  ...####..#...####..#
  ..##..#.##..##..#.##
  ##.#..##..##.#..##..
  #..####...#..####...
  ....#....#....#....#
  ##...#..####...#..##
  .##..##.#..##..##.#.
  .#.##..##..#.##..##.
  ##..#...####..#...##
  #....#....#....#....
  ...####..#...####..#
  ..##..#.##..##..#.##
  ##.#..##..##.#..##..
  #..####...#..####...
  ....#....#....#....#
  ##...#..####...#..##
  .##..##.#..##..##.#.

Consult the C<eg/> and C<t/> directories under this module's
distribution for more example code.

=head1 DESCRIPTION

L<Game::TextPatterns> contains methods that generate and alter text
patterns. Potential uses include the creation of ASCII art or the
construction of vaults for roguelike games.

=head2 Terminology

Columns (x, width) and Rows (y, height) are used in various places.

    columns ...
  r 
  o  ###%#######+######
  w  #...the.pattern..#
  s  #######+##########
  .  #........#.......#
  .  #.......@'...<...#
  .  ##################

The B<pattern> text should be ASCII; Unicode or other such multibyte
encodings may cause problems.

Geometrical terms (quadrant I or Q1 in the following diagram) are used,
though for angles of rotation C<0 1 2 3> are used instead of 0, 90, 180,
270 degress or other forms.

     90 (1)
  Q2 | Q1
  ---+--- 0 (0)
  Q3 | Q4
     270 (3)

=head1 CONSTRUCTORS

These return new objects. Some require an existing object that probably
should not be the same as the object being operated on. If something
goes wrong they will throw an exception.

=over 4

=item B<clone>

Returns a new object from an existing one with the current state of the
B<pattern> attribute.

=item B<new> pattern => ...

Constructor. A B<pattern> attribute must be specified.

=item B<rebuild>

L<MooX::Rebuild> feature that returns a new object with the original
B<pattern> attribute.

=back

=head1 ATTRIBUTES

Only one at the moment.

=over 4

=item B<pattern>

Required. Must be a string (which will be split on C<$/> into an array
reference) or an array reference of strings or an object that has a
B<pattern> method that does the same thing as B<pattern> of this module.

L<File::Slurper> may help read pattern data directly from a file.

B<pattern> can be called as a method to return the current B<pattern> as
an array reference. It may be a bad idea to modify the contents of that
reference directly.

=back

=head1 METHODS

Call these on something returned by a constructor. Those that modify the
pattern in-place (some though do not) can be chained with other methods.
If something goes wrong these will throw an exception.

=over 4

=item B<append_cols> I<fill> I<pattern>

Appends the given I<pattern> to the right of the existing object (or a
sort of a horizontal L<cat(1)>). If the patterns are of unequal size the
I<fill> character (or array reference) will be used to fill in the gaps.
If I<fill> is an array reference the first character of that reference
will be used to fill gaps should the object be smaller, or otherwise the
second character of the array will be used as fill if the object is
larger than the given I<pattern>.

=item B<append_rows> I<fill> I<pattern>

Appends the given I<pattern> below the existing object (much like
L<cat(1)> does for text). Same rules for I<fill> as for B<append_cols>.

=item B<as_array>

Returns the pattern of the object as a reference to a 2D array.
Presumably useful for some other interface that expects a 2D grid. See
also B<from_array>.

=item B<border> I<width> I<character>

Creates a border of the given I<width> (1 by default) and I<character>
(C<#> by default) around the B<pattern>.

=item B<cols>

Returns the width (x, or number of columns) in the B<pattern>. This is
based on the length of the first line of the B<pattern>.

=item B<crop> I<point1> I<point2>

Crops the pattern to the given column and row pairs, which are counted
from zero for the first row or column, or backwards from the end for
negative numbers. Will throw an error if the crop values lie outside the
size of the pattern.

See also B<trim>.

=item B<dimensions>

Returns the B<cols> and B<rows> of the current B<pattern>.

=item B<draw_in> I<point1> [ I<point2> ] I<pattern>

Draws the I<pattern> within the given bounds, though will not extend the
dimensions of the object if the I<pattern> exceeds that (hence the lower
right bound being optional). Should the I<pattern> be smaller than the
given bounds nothing will be changed at those subsequent points (this
differs from other methods that accept a I<fill> argument).

See also the more complicated B<overlay>.

=item B<fill_4way> I<point> I<char>

Replaces the character found at I<point> with I<char> and repeats this
fill for all similar characters found by 4-way motion from the
starting I<point>.

=item B<fill_8way> I<point> I<char>

Replaces the character found at I<point> with I<char> and repeats this
fill for all similar characters found by 8-way motion from the
starting I<point>.

=item B<flip_both>

Flips the B<pattern> by columns and by rows. Similar to a rotate by
180 degrees.

  ###.  ->  ...#
  #...  ->  .###

=item B<flip_cols>

Flips the columns (vertical mirror) in the B<pattern>.

  ###.  ->  .###
  #...  ->  ...#

=item B<flip_four> [ I<reduce-col?> [ I<reduce-row?> ] ]

Treats the object as a pattern in quadrant I of the unit circle and
returns a new object with that pattern flipped as appropriate into the
other three quadrants. See also B<four_up>.

      ###.
      #... becomes:
  
  .######.
  ...##...
  ...##...
  .######.

Note that this does not modify the object in-place, to do that:

  $pat = $pat->flip_four;

The optional I<reduce-col> and I<reduce-row> will cause a row, a column,
or if only I<reduce-col> is supplied and is true, both a row and a
column to be lost. That is C<flip_four(1)> causes

     ###.
     #... to become
  
  .#####.
  ...#...
  .#####.

=item B<flip_rows>

Flips the rows (horizontal mirror).

  ###.  ->  #...
  #...  ->  ###.

=item B<four_up> [ I<fill> ] [ I<crop?> ]

Treats the object as a pattern in quadrant I of the unit circle and
returns a new object with that pattern rotated into the other three
quadrants by an appropriate number of degrees. See also B<flip_four>.

      ###.
      #... becomes:
  
  ??..????
  ??#.????
  ??#.###.
  ??###...
  ...###??
  .###.#??
  ????.#??
  ????..??

I<fill> will be used if the input is not a square during various calls
to B<append_cols> and B<append_rows>, unless I<crop> is a true value, in
which case the object used will be cropped to be a square before the
rotations. The default I<fill> as shown above is C<?>.

Note that this does not modify the object in-place.

=item B<from_array> I<array>

Replaces the pattern of the object with the contents of the given 2D
array. See also B<as_array>.

=item B<mask> I<char> I<pattern>

B<mask> replaces instances of the I<char> in the object with the
corresponding character(s) of the given I<pattern>.

=item B<multiply> I<cols> [ I<rows> ]

Multiplies the existing data in the columns or rows, unless I<cols> or
I<rows> is C<1>. With no I<rows> set multiplies both the columns and
rows by the given value.

=item B<overlay> I<point> I<pattern> I<mask>

Draws the I<pattern> into the object at the given I<point> though
preserving anything from the original object that match the I<mask>
character in the I<pattern>.

See also the simpler B<draw_in>.

=item B<rows>

Returns the height (y, or number of rows) in the B<pattern>.

=item B<rotate> I<amount>

Rotates the pattern by 0, 90, 180, or 270 degrees specified by the
integers C<0>, C<1>, C<2>, and C<3> (or modulus of those).

=item B<randomly> I<match> I<percent> I<callback>

Similar to B<white_noise> but calls a callback function for each
matching cell randomly found. For example to act on 10% of cells that
match C<#> use

    use constant { ROW => 1, COL => 0, };
    $m->randomly(
        qr/#/, 0.1,
        sub {
            my ($pat, $point, $max_cols, $max_rows) = @_;
            substr $pat->[$point->[ROW]], $point->[COL], 1, 'x';
        }
    );

as internally the pattern is stored as an array of strings.

=item B<string> I<sep>

Returns the B<pattern> as a string with rows joined by the I<sep> value
(C<$/> by default which typically is but may not be a newline).

=item B<trim> I<amount>

Convenience method for C<crop( [amount,amount], [-amount,-amount] )>.

=item B<white_noise> I<char> I<percent>

Fills the object with the given percentage of the I<char> randomly.

    # 50% fill with 'x'
    $v->white_noise( 'x', .5 );

See B<randomly> for a similar routine to this one, if more complicated.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-game-textpatterns at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-TextPatterns>.

Patches might best be applied towards:

L<https://github.com/thrig/Game-TextPatterns>

=head2 Known Issues

Probably should have used a 2D array instead of an array of strings,
internally. But that is very unlikely to change at this point.

Probably needs more tests for various edge conditions.

B<flip_four> and B<four_up> probably need better names.

Some of the calling arguments to various methods likely need
improvements which will probably break backwards compatibility.

Humans are really good at mixing up the col,row (x,y) points with
other forms especially given the different orientation of the
internal pattern. Favor non-square patterns for tests to better
expose such mixups.

Unicode is not really supported; would instead need to operate on
characters or potentially even allow for lengths of text in each cell
of the pattern grid (but that gets back to the array of strings
thing, above).

=head1 SEE ALSO

L<Game::DijkstraMap> can path-find across text patterns, handy if one
desires maps that do not completely thwart a player.

  use 5.24.0;
  ...
  $pat = $pat->four_up->four_up;
  my $dm = Game::DijkstraMap->new;
  $dm->map( $pat->as_array );
  # assuming the pattern did not have any goals already on it
  my $uc = $dm->unconnected;
  $dm->update( [ $uc->[0]->@*, $dm->min_cost ] );
  $dm->recalc;
  # then check if anything still unconnected...

Another option might be to use a standard image library and then devise
a conversion such that particular colors become particular ASCII symbols
(or combinations of symbols, with Unicode or control sequences to set
colors or such).

L<Game::PlatformsOfPeril> has some levels built with this module.

And then there is also the
L<https://github.com/thrig/ministry-of-silly-vaults/>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
