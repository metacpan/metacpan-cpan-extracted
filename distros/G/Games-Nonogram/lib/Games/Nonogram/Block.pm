package Games::Nonogram::Block;

use strict;
use warnings;
use base qw( Games::Nonogram::Base );

sub new {
  my ($class, %options) = @_;

  my $self = bless {
    id        => $options{id},
    length    => $options{length},
    line_size => $options{line_size},
    left      => 0,
    right     => 0,
    forbidden => {},
  }, $class;
}

sub id    { shift->{id} }

sub clear {
  my $self = shift;

  $self->{left} = $self->{right} = 0;
  $self->{forbidden} = {};
}

sub length {
  my ($self, $value) = @_;

  if ( defined $value ) {
    $self->die_if_overflowed( $value );
    $self->{length} = $value;
  }
  $self->{length};
}

sub left {
  my ($self, $value) = @_;

  if ( defined $value ) {
    $self->die_if_overflowed( $value );
    $self->{left} = $value;
  }
  $self->{left};
}

sub right {
  my ($self, $value) = @_;

  if ( defined $value ) {
    $self->die_if_overflowed( $value );
    $self->{right} = $value;
  }
  $self->{right};
}

sub die_if_overflowed {
  my ($self, $value) = @_;

  if ( $self->is_overflowed( $value ) ) {
    my ( $package, $file, $line, $subr ) = caller(1);

    die <<"__MESSAGE__";
Block $$self{id} is broken. ($subr overflow: $value)
Unless you're trying to solve by brute force,
there may be something wrong in the puzzle data.
LEFT:   $$self{left}
RIGHT:  $$self{right}
LENGTH: $$self{length}
__MESSAGE__
  }
}

sub is_overflowed {
  my ($self, $value) = @_;

  return 1 if $value > $self->{line_size} || $value < 1;

  my $left  = $self->{left} or return;
  my $right = $self->{right} or return;

  return 1 if $left > $right;
}

sub cant_have {
  my $self = shift;

  if ( @_ == 1 ) {
    my $id = shift;
    $self->{forbidden}->{$id} = 1;
  }
  elsif ( @_ ) {
    $self->{forbidden}->{$_} = 1 for ( $self->range( @_ ) );
  }

  if ( $self->length > 1 ) {
    my @forbiddens = sort { $a <=> $b }
                     grep { $_ > $self->left && $_ < $self->right }
                     keys %{ $self->{forbidden} || {} };
    push @forbiddens, $self->right + 1;

    my $prev = $self->left - 1;
    foreach my $pos ( @forbiddens ) {
      if ( $prev + 1 == $pos ) {
        $prev = $pos;
        next;
      }
      if ( ( $pos - 1 ) - ( $prev + 1 ) + 1 < $self->length ) {
        $self->log(
          'block ', $self->id, ': ',
          ( $prev + 1 ), "-", ( $pos - 1 ),
          " cannot have ", $self->length
        );
        $self->{forbidden}->{$_} = 1 for ( $prev + 1 .. $pos - 1 );
      }
      $prev = $pos;
    }

    while( $self->{forbidden}->{ $self->left } ) {
      $self->left( $self->left + 1 );
    }
    while( $self->{forbidden}->{ $self->right } ) {
      $self->right( $self->right - 1 );
    }
  }
}

sub might_have {
  my ($self, $id) = @_;

  return 0 if $self->{forbidden}->{$id};

  ( $self->left > $id or $self->right < $id ) ? 0 : 1;
}

sub must_have {
  my ($self, $id) = @_;

  return 0 if $self->{forbidden}->{$id};

  my $offset = $self->length - 1;

  ( $self->left  + $offset < $id
                 or
    $self->right - $offset > $id ) ? 0 : 1;
}

sub try {
  my ($self, $from, $length) = @_;

  if ( $length > $self->length ) {
    $self->cant_have( from => $from - 1, length => $length + 2 );
  }
  elsif ( $length == $self->length ) {
    $self->cant_have( $from - 1 );
    $self->cant_have( $from + $length );
  }
}

1;

__END__

=head1 NAME

Games::Nonogram::Block

=head1 SYNOPSIS

  use Games::Nonogram::Block;
  my $block = Games::Nonogram::Block->new(
    id        => 'row 1 block 1',
    length    => 2,
    line_size => 20,
  );

=head1 DESCRIPTION

This is used internally to decide where each box (block) be placed in a row or a column. For example, in a row of 5 cells with two clues (1, 2), the first block should not be placed at cell 3, 4 and 5: see all the possible combinations.

  1 2 3 4 5
  X . X X .
  X . . X X
  . X . X X

In this case, the first ::Block object should have properties like

  * left:  1
  * right: 2

and the second,

  * left:  3
  * right: 5
  * must_have: 4

Actually this ::Block can handle a bit more complicated cases, though I don't explain here.

=head1 METHODS

=head2 new

creates an object.

=head2 clear

clears information of the block.

=head2 die_if_overflowed

sometimes this block may receive an out-of-range value (while brute-forcing, or when the puzzle is broken, perhaps). In that case, it dies to notify an error, which should be caught somewhere else.

=head2 is_overflowed

is used to see if the block is overflowed or not.

=head2 cant_have

sets forbidden area for the block (which is (or, should be) occupied by other blocks, or is known to be blank).

=head2 might_have

returns if the given cell (id) may belong to the block or not.

=head2 must_have

returns if the given cell (id) belongs to the block or not.

=head2 try

sees if the given area (cells) can belong to the block or not, and sets the result. If it can't belong to the block, all the cells in the area "cant_have" the block, and if the area is exactly the same as the block, both of the adjacent cells must be blank by the rule.

=head1 ACCESSORS

=head2 id

returns a block id.

=head2 length

returns of the length of the block.

=head2 left

returns the leftmost id the block can stay.

=head2 right

returns the rightmost id the block can stay.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
