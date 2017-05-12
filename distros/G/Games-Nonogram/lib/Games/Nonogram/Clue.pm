package Games::Nonogram::Clue;

use strict;
use warnings;
use base qw( Games::Nonogram::Base );

use Games::Nonogram::Line;
use Games::Nonogram::Block;

sub new {
  my ($class, %options) = @_;

  my $size = $options{size};
  my $line = Games::Nonogram::Line->new( size => $size );

  my $self = bless {
    id      => $options{id},
    size    => $size,
    line    => $line,
    is_done => 0,
  }, $class;

  if ( $options{blocks} ) {
    $self->set( @{ $options{blocks} || [] } );
  }

  $self;
}

sub id { shift->{id} || '' }

sub set {
  my ($self, @clues) = @_;

  my $id = 0;
  my @blocks = map {
    Games::Nonogram::Block->new(
      id        => ++$id,
      length    => $_,
      line_size => $self->size,
    )
  } @clues;
  $self->{blocks} = \@blocks;

  $self->reset_blocks;

  my $free;
  unless ( @blocks ) {
    $self->line->off( from => 1, length => $self->size );
    $free = 0;
  }
  else {
    $free = $blocks[0]->right - $blocks[0]->length;
  }

  $self->{free} = $free;
}

sub reset_blocks {
  my $self = shift;

  my $left = 1;
  foreach my $block ( $self->blocks ) {
    $block->clear;
    $block->left( $left );
    $left += ( $block->length + 1 );
  }

  my $right = $self->size;
  foreach my $block ( reverse $self->blocks ) {
    $block->right( $right );
    $right -= ( $block->length + 1 );
  }

  $self->{is_done} = 0;
}

sub blocks { @{ shift->{blocks} || [] } }
sub size   { shift->{size} }
sub line   { shift->{line} }

sub block {
  my ($self, $id) = @_;
  $self->{blocks}->[$id];
}

sub as_string {
  my $self = shift;

  my $str = $self->line->as_string;

  if ( $self->debug ) {
    $str .= ' '. join ' ', map { $_->length } $self->blocks;
  }
  return $str;
}

sub dump_blocks {
  my $self = shift;

  my $str = $self->id . "\n";
  foreach my $block ( $self->blocks ) {
    for my $ct ( 1 .. $self->size ) {
      if ( $block->must_have( $ct ) ) {
        $str .= "X";
      }
      elsif ( $block->might_have( $ct ) ) {
        $str .= "_";
      }
      else {
        $str .= ".";
      }
    }
    $str .= sprintf " (%s, %s: %s)\n", $block->left, $block->right, $block->length;
  }

  $str .= $self->as_string . "\n";

  defined wantarray ? return $str : print $str;
}

sub is_done {
  my $self = shift;

  unless ( $self->{is_done} ) {
    return unless $self->line->is_done;
    $self->die_if_invalid;

    $self->{is_done} = 1;
  }
  $self->{is_done};
}

sub die_if_invalid {
  my $self = shift;

  my $ct = 1;
  foreach my $block ( $self->blocks ) {
    while ( $ct < $block->left ) {
      my $value = $self->line->value( $ct );
      if ( $value != 0 ) {
        $self->dump_blocks if $self->debug;
        die "failed at $ct: $value != 0";
      }
      $ct++;
    }
    while ( $ct <= $block->right ) {
      my $value = $self->line->value( $ct );
      if ( $value != 1 ) {
        $self->dump_blocks if $self->debug;
        die "failed at $ct: $value != 1";
      }
      $ct++;
    }
  }
  while ( $ct <= $self->size ) {
    my $value = $self->line->value( $ct );
    if ( $value != 0 ) {
      $self->dump_blocks if $self->debug;
      die "failed at $ct: $value != 0";
    }
    $ct++;
  }
  return 1;
}

sub on {
  my ($self, $id) = @_;

  $self->line->on( $id );

  my $block = $self->might_have( $id );

  return unless ref $block;

  my $offset = $block->length - 1;

  my $left = $id - $offset;
  $block->left( $left ) if $block->left < $left;

  my $right = $id + $offset;
  $block->right( $right ) if $block->right > $right;

  if ( $block->left == $id ) {
    my $left = $block->left;
    $self->line->on( $_ ) for ( $left .. $left + $offset );
  }

  if ( $block->right == $id ) {
    my $right = $block->right;
    $self->line->on( $_ ) for ( $right - $offset .. $right );
  }
}

sub off {
  my ($self, $id) = @_;

  $self->line->off( $id );

  foreach my $block ( $self->blocks ) {
    $block->cant_have( $id );
  }

  my $block = $self->might_have( $id );

  return unless ref $block;

  my $offset = $block->length - 1;

  my $left = $id + 1;
  $block->left( $left ) if $block->left + $offset > $left;

  my $right = $id - 1;
  $block->right( $right ) if $block->right - $offset < $right;
}

sub value {
  my ($self, $id, $value) = @_;

  if ( defined $value ) {
    if    ( $value == 0 ) { $self->off( $id ) }
    elsif ( $value == 1 ) { $self->on( $id ) }
  }
  else {
    $self->line->value( $id );
  }
}

sub might_have {
  my ($self, $id) = @_;

  my $hit;
  foreach my $block ( $self->blocks ) {
    if ( $block->might_have( $id ) ) {
      return -1 if $hit; # multiple candidates; cannot decide

      $hit = $block;
    }
  }
  return $hit ? $hit : 0;
}

sub update {
  my ($self, $mode) = @_;

  unless ( $mode ) {
    $self->_update_basic;
  }
  elsif ( $mode eq 'more' ) {
    $self->_update_more;
  }

  foreach my $ct ( 1 .. $self->size ) {
    my $block = $self->might_have( $ct );

    unless ( $block ) {
      $self->off( $ct );
    }
    elsif ( ref $block ) {
      my $value = $self->line->value( $ct );
      if ( $value == -1 ) {
        $self->on( $ct ) if $block->must_have( $ct );
      }
      elsif ( $value == 0 ) {
        $self->off( $ct );
      }
      elsif ( $value == 1 ) {
        $self->on( $ct ) unless $block->must_have( $ct );
      }
    }
  }
}

sub _update_basic {
  my $self = shift;

  my $left = 1;
  foreach my $block ( $self->blocks ) {
    $left = $block->left if $block->left > $left;
    while (
      $self->line->value( $left ) == 0
        or
      $left > 1 && $self->line->value( $left - 1 ) == 1
    ) {
      $left++;
      if ( $left > $self->size ) {
        die "puzzle data may be broken, unless you're trying to solve by brute force";
      }
    }

    $block->left( $left );
    $left += ( $block->length + 1 );
  }

  my $right = $self->size;
  foreach my $block ( reverse $self->blocks ) {
    $right = $block->right if $block->right < $right;

    while (
      $self->line->value( $right ) == 0
        or
      $right < $self->size && $self->line->value( $right + 1 ) == 1
    ) {
      $right--;
      if ( $right < 1 ) {
        die "puzzle data may be broken, unless you're trying to solve by brute force";
      }
    }

    $block->right( $right );
    $right -= ( $block->length + 1 );
  }

  foreach my $block ( $self->blocks ) {
    my ($from, $length) = (0, 0);
    foreach my $ct ( $block->left .. $block->right ) {
      my $value = $self->line->value( $ct );
      if ( $value == 1 ) {
        $from ||= $ct;
        $length++;
      }
      else {
        $block->try( $from, $length );
        ($from, $length) = (0, 0);
      }
    }
    $block->try( $from, $length );
  }
}

sub _update_more {
  my $self = shift;

  my ($toggle, $from, @blocks);
  foreach my $ct ( 1 .. $self->size ) {
    $from ||= $ct;

    my $value = $self->line->value( $ct );
    if ( $value == 1 ) {
      $toggle = 1;
    }
    elsif ( $value == 0 ) {
      if ( $toggle ) {
        push @blocks, { from => $from, to => $ct - 1 };
      }
      $from = $toggle = 0;
    }
  }
  if ( $toggle ) {
    push @blocks, { from => $from, to => $self->size };
  }

  if ( @blocks == $self->blocks ) {
    foreach my $block ( $self->blocks ) {
      my $href = shift @blocks;
      $block->left( $href->{from} ) if $block->left < $href->{from};
      $block->right( $href->{to} )  if $block->right > $href->{to};
    }
  }
}

sub candidates {
  my $self = shift;

  my @candidates = $self->_candidates(
    $self->line->clone,
    1,
    $self->{free},
    $self->blocks
  );
}

sub _candidates {
  my ($self, $line, $pos, $free, @blocks) = @_;

  my $clone = $line->clone;
  unless ( $free ) {
    while( my $block = shift @blocks ) {
      foreach my $ct ( 0 .. $block->length - 1 ) {
        return if $clone->value( $pos + $ct ) == 0;  # conflicted;
        $clone->on( $pos + $ct );
      }
      $pos += $block->length;
      unless ( $pos > $self->size ) {
        return if $clone->value( $pos ) == 1; # conflicted;
        $clone->off( $pos );
      }
      $pos++;
    }
  }
  unless ( @blocks ) {
    foreach my $ct ( $pos .. $self->size ) {
      return if $clone->value( $ct ) == 1;    # conflicted
      $clone->off( $ct );
    }
    return $clone->as_vec;
  }

  my @candidates;
  LOOP:
  foreach my $ct ( 0 .. $free ) {
    $clone = $line->clone;
    my @clone_blocks = @blocks;
    my $clone_pos    = $pos;

    foreach my $space_ct ( 1 .. $ct ) {
      next LOOP if $clone->value( $clone_pos ) == 1;   # conflicted
      $clone->off( $clone_pos );
      $clone_pos++;
    }

    my $block = shift @clone_blocks;
    foreach my $block_ct ( 1 .. $block->length ) {
      next LOOP if $clone->value( $clone_pos ) == 0; # conflicted
      $clone->on( $clone_pos );
      $clone_pos++;
    }
    unless ( $clone_pos > $self->size ) {
      next LOOP if $clone->value( $clone_pos ) == 1; # conflicted
      $clone->off( $clone_pos );
      $clone_pos++;

      push @candidates, $self->_candidates(
        $clone,
        $clone_pos,
        $free - $ct,
        @clone_blocks
      );
    }
    else {
      push @candidates, $clone->as_vec;
    }
  }
  return @candidates;
}

1;

__END__

=head1 NAME

Games::Nonogram::Clue

=head1 DESCRIPTION

This is used internally to handle clues in a row or in a column.

=head1 METHODS

=head2 new

creates an object.

=head2 set

sets an array of the length of clues in a row/column.

=head2 reset_blocks

initializes the positions of clues. Actually this may fix them when there're no free cells, as this tries to put blocks so as not to cross each other.

=head2 as_string

returns a stringified form of the line for the clues.

=head2 dump_blocks

similar to above but returns more detailed information of the blocks of the clues.

=head2 is_done

returns if each block in the line is fixed or not.

=head2 die_if_invalid

dies if any of the blocks in the line can not have enough spaces (while brute-forcing, or when the puzzle is broken).

=head2 on

tells each block in the line that the given id (cell) should belong to one of the blocks.

=head2 off

tells each block in the line that the given id (cell) should not belong to one of the blocks.

=head2 value

returns if the given id (cell) belongs to a block or not.

=head2 might_have

returns if the given id (cell) can belong to a block or not.

=head2 update

sees through the line and turns on/off the cells it can surely tell.

=head2 candidates

returns all the possible patterns of the line.

=head1 ACCESSORS

=head2 id

returns a clue id.

=head2 blocks

returns all the blocks in the clues.

=head2 size

returns how many cells are there in a row/column for the clues.

=head2 line

returns a row/column for the clues.

=head2 block

returns a block of the given (block) id.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
