package Games::Nonogram::Line;

use strict;
use warnings;
use base qw( Games::Nonogram::Base );

sub new {
  my ($class, %options) = @_;

  my $size = $options{size} or die "size unknown";

  my $self = bless {
    size    => $size,
    vec     => '',
    dirty   => '',
    is_done => 0,
  }, $class;

  $self->clear;

  $self;
}

sub size { shift->{size} }

sub value {
  my ($self, $id, $value) = @_;

  if ( defined $value ) {
    my $prev = vec( $self->{vec}, $id, 2 );
    if ( $prev != $value ) {
      vec( $self->{vec}, $id, 2 ) = $value;
      $self->is_dirty( $id );
    }
  }
  else {
    $value = vec( $self->{vec}, $id, 2 );
    $value > 1 ? -1 : $value;
  }
}

sub on {
  my $self = shift;

  if ( @_ == 1 ) {
    $self->value( shift, 1 );
  }
  else {
    $self->value( $_ => 1 ) for ( $self->range( @_ ) );
  }
}

sub off {
  my $self = shift;

  if ( @_ == 1 ) {
    $self->value( shift, 0 );
  }
  else {
    $self->value( $_ => 0 ) for ( $self->range( @_ ) );
  }
}

sub clear {
  my ($self, $id) = @_;

  if ( defined $id ) {
    vec( $self->{vec}, $id, 2 ) = -1;
  }
  else {
    vec( $self->{vec}, $_, 2 ) = -1 for ( 1 .. $self->size );
  }
  $self->{is_done} = 0;
}

sub is_done {
  my $self = shift;

  return if $self->is_dirty;

  unless ( $self->{is_done} ) {
    foreach my $ct ( 1 .. $self->size ) {
      return if $self->value( $ct ) == -1;
    }
    $self->{is_done} = 1;
  }
  $self->{is_done};
}

sub is_dirty {
  my ($self, $id) = @_;

  if ( defined $id ) {
    vec( $self->{dirty}, $id, 1 ) = 1;
  }
  else {
    return $self->{dirty} ne '' ? 1 : 0;
  }
}

sub dirty_items {
  my $self = shift;

  my @dirty;
  foreach my $ct ( 1 .. $self->size ) {
    push @dirty, $ct if vec( $self->{dirty}, $ct, 1 );
  }
  $self->{dirty} = '';

  return @dirty;
}

sub clone {
  my $self = shift;

  my %clone = %{ $self };
  bless \%clone, ref $self;
}

sub as_vec  {
  my $self = shift;

  if ( @_ ) {
    $self->{vec} = shift;
    foreach my $ct ( 1 .. $self->size ) { $self->is_dirty( $ct ) }
    $self->{is_done} = 0;
  }
  $self->{vec};
}

sub as_string {
  my $self = shift;

  my $str = '';
  for my $ct ( 1 .. $self->size ) {
    my $value = $self->value( $ct );
    if ( $value == 0 ) {
      $str .= '.';
    }
    elsif ( $value == 1 ) {
      $str .= 'X';
    }
    else {
      $str .= '_';
    }
  }
  return $str;
}

1;

__END__

=head1 NAME

Games::Nonogram::Line

=head1 DESCRIPTION

This is used internally to store status of the cells in a row/column.

=head1 METHODS

=head2 new

creates an object.

=head2 size

returns the length of the row/column.

=head2 value

returns the value of the cell of the given id.

=head2 on

turns on the cell(s) of the given id.

=head2 off

turns off the cell(s) of the given id.

=head2 clear

clears (undefines) the cell(s) of the given id.

=head2 is_done

returns true if all the cells in the line have turned on/off (i.e. defined).

=head2 is_dirty

returns true if some of the cells in the line have changed.

=head2 dirty_items

returns an array of the changed cells.

=head2 clone

creates a clone of the line object.

=head2 as_vec

returns a bitmap vector form of the line. You can pass another bitmap vector to initialize the object (for example, while brute-forcing).

=head2 as_string

returns a stringified form of the line.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
