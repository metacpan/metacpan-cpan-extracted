# -*- Perl -*-
#
# generate patterns of text
#
# Run perldoc(1) on this file for additional documentation.

package Game::TextPatterns;

use 5.14.0;
use warnings;
use Carp qw(croak);
use Moo;
use namespace::clean;
use Scalar::Util qw(looks_like_number);

our $VERSION = '0.01';

with 'MooX::Rebuild';    # for ->rebuild (which differs from clone)

has pattern => (
    is     => 'rw',
    coerce => sub {
        my $type = ref $_[0];
        if ( $type eq "" ) { return [ split $/, $_[0] ] }
        elsif ( $type eq 'ARRAY' )      { return [ @{ $_[0] } ] }
        elsif ( $_[0]->can("pattern") ) { return [ @{ $_[0]->pattern } ] }
        else                            { die "unknown pattern type '$type'" }
    },
);

sub BUILD {
    my ( $self, $param ) = @_;
    croak "a pattern must be supplied" unless exists $param->{pattern};
}

########################################################################
#
# METHODS

# TODO append by cols or by rows with handling of not-same-size cases somehow
sub append_cols {
    my ( $self, $pattern ) = @_;
    my $pat = $self->pattern;
    my $len = length $pat->[0];
    return $self;
}

sub append_rows {
    my ( $self, $new ) = @_;
    my $pat = $self->pattern;
    push @$pat, @{ $new->pattern };
    return $self;
}

sub border {
    my ( $self, $width, $char ) = @_;
    if ( defined $width ) {
        die "width must be a positive integer"
          if !looks_like_number($width)
          or $width < 1;
        $width = int $width;
    } else {
        $width = 1;
    }
    if ( defined $char and length $char ) {
        $char = substr $char, 0, 1;
    } else {
        $char = '#';
    }
    my $pat = $self->pattern;
    my ( $cols, $rows ) = ( length $pat->[0], scalar @$pat );
    my ( $newcols, $newrows ) = map { $_ + ( $width << 1 ) } $cols, $rows;
    my @np = ( $char x $newcols ) x $width;
    for my $row (@$pat) {
        push @np, ( $char x $width ) . $row . ( $char x $width );
    }
    push @np, ( $char x $newcols ) x $width;
    $self->pattern( \@np );
    return $self;
}

sub clone { __PACKAGE__->new( pattern => $_[0]->pattern ) }

sub cols       { length $_[0]->pattern->[0] }
sub dimensions { length $_[0]->pattern->[0], scalar @{ $_[0]->pattern } }
sub rows       { scalar @{ $_[0]->pattern } }

# "mirrors are abominable" (Jorge L. Borges. "Tlön, Uqbar, Orbis Tertuis")
# so the term flip is here used instead
sub flip_both {
    my ($self) = @_;
    my $pat = $self->pattern;
    for my $row (@$pat) {
        $row = reverse $row;
    }
    @$pat = reverse @$pat if @$pat > 1;
    return $self;
}

sub flip_cols {
    my ($self) = @_;
    for my $row ( @{ $self->pattern } ) {
        $row = reverse $row;
    }
    return $self;
}

sub flip_rows {
    my ($self) = @_;
    my $pat = $self->pattern;
    @$pat = reverse @$pat if @$pat > 1;
    return $self;
}

sub multiply {
    my ( $self, $cols, $rows ) = @_;
    die "cols must be a positive integer"
      if !defined $cols
      or !looks_like_number($cols)
      or $cols < 1;
    $cols = int $cols;
    if ( defined $rows ) {
        die "rows must be a positive integer"
          if !looks_like_number($rows)
          or $rows < 1;
        $rows = int $rows;
    } else {
        $rows = $cols;
    }
    if ( $cols > 1 ) {
        for my $row ( @{ $self->pattern } ) {
            $row = $row x $cols;
        }
    }
    if ( $rows > 1 ) {
        $self->pattern( [ ( @{ $self->pattern } ) x $rows ] );
    }
    return $self;
}

# TODO rotate -- 90, 180, 270 -- is 180 same as flip_both?
# make direction the same as motion on unit circle so 90 is to the left?

sub string {
    my ( $self, $sep ) = @_;
    $sep //= $/;
    return join( $sep, @{ $self->pattern } ) . $sep;
}

1;
__END__

=head1 NAME

Game::TextPatterns - generate patterns of text

=head1 SYNOPSIS

  use Game::TextPatterns;

  my $v = Game::TextPatterns->new( pattern => ".#\n#." );

  $v->multiply(7,3)
    ->border(1,'#')->border(1,'.')->border(1,'#');

  print $v->string;

Ta-da! You should now have an Angband checker type vault. (Doors not
included. Monsters and items may cost extra.)

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

The B<pattern> text can be most any string value.

=head1 CONSTRUCTORS

These return new objects. Some require an existing object.

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
B<pattern> method that ideally returns one of the previous types.

L<File::Slurper> may help read pattern data directly from a file.

B<pattern> can be called as a method to return the current B<pattern> as
an array reference. It may be a bad idea to modify the contents of that
reference directly.

=back

=head1 METHODS

Call these on something returned by a constructor. Those that modify the
pattern in-place can be chained with other methods.

=over 4

=item B<append_cols>

TODO

=item B<append_rows>

TODO

=item B<border> I<width> I<character>

Creates a border of the given I<width> (1 by default) and I<character>
(C<#> by default) around the B<pattern>.

=item B<cols>

Returns the width (x, or number of columns) in the B<pattern>. This is
based on the length of the first line of the B<pattern>.

=item B<dimensions>

Returns the B<cols> and B<rows> of the current B<pattern>.

=item B<flip_both>

Flips the B<pattern> by columns and by rows.

=item B<flip_cols>

Flips the columns (vertical mirror) in the B<pattern>.

=item B<flip_rows>

Flips the rows (horizontal mirror).

=item B<multiply> I<cols> [ I<rows> ]

Multiplies the existing data in the columns or rows, unless I<cols> or
I<rows> is C<1>. With no I<rows> set multiplies both the columns and
rows by the given value.

=item B<rows>

Returns the height (y, or number of rows) in the B<pattern>.

=item B<string> I<sep>

Returns the B<pattern> as a string with rows joined by the I<sep> value
(a newline by default).

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-game-textpatterns at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Game-TextPatterns>.

Patches might best be applied towards:

L<https://github.com/thrig/Game-TextPatterns>

=head2 Known Issues

The newly being written thing (look for TODO or otherwise absent
methods).

=head1 SEE ALSO

L<https://github.com/thrig/ministry-of-silly-vaults/>

Consult the C<t/> directory under this module's distribution for
example code.

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
