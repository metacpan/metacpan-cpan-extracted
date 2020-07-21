package Game::Battleship::Craft;
$Game::Battleship::Craft::VERSION = '0.0602';
our $AUTHORITY = 'cpan:GENE';

use Carp;
use Moo;
use Types::Standard qw( ArrayRef Int Num Str );

has id => (
    is  => 'ro',
    isa => Str,
);

has name => (
    is  => 'ro',
    isa => Str,
);

has position => (
    is  => 'ro',
    isa => ArrayRef[Num],
);

has orient => (
    is  => 'ro',
    isa => Int,
);

has points => (
    is  => 'ro',
    isa => Int,
);

has hits => (
    is  => 'ro',
    isa => Int,
);

sub BUILD {
    my $self = shift;
    # Default the id to the upper-cased first char of name.
    # XXX This is brittle!
    unless ( $self->id ) {
        $self->{id} = ucfirst substr( $self->{name}, 0, 1 );
    }
}

sub hit {
    my $self = shift;
    # Tally the hit.
    $self->{hits}++;
    # Hand back the remainder of the craft's value.
    return $self->points - $self->hits;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Game::Battleship::Craft

=head1 VERSION

version 0.0602

=head1 SYNOPSIS

  use Game::Battleship::Craft;
  my $craft = Game::Battleship::Craft->new(
      id => 'T',
      name => 'tug boat',
      points => 1,
  )
  my $points_remaining = $craft->hit;

=head1 DESCRIPTION

A C<Game::Battleship::Craft> object represents the profile of a Battleship craft.

=head1 PUBLIC METHODS

=head2 new

=over 4

=item * id => $STRING

A scalar identifier to use to indicate position on the grid.  If one
is not provided, the upper-cased first name character will be used by
default.

Currently, it is required that this be a single uppercase letter (the
first letter of the craft name, probably), since a C<hit> will be
indicated by "lower-casing" this mark on a player grid.

=item * name => $STRING

A required attribute provided to give the craft a name.

=item * points => $INTEGER

The number of total points that a craft is worth.

=item * position => [$X, $Y]

The position of the craft bow ("nose") on the grid.

=item * orient => $BOOLEAN

The vertical or horizontal orientation of the craft.

Set this to C<0> for vertical and C<1> for horizontal.

If not defined, the craft is randomly oriented on creation.

=item * hits => $INTEGER

Computed

=back

=for Pod::Coverage BUILD

=head2 hit

  $points_remaining = $craft->hit;

Increment the craft's C<hit> attribute value and return what's left of
the craft (total point value minus the number of hits).

=head1 TO DO

Have different numbers of different weapons.

Allow a craft to have a width.

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
