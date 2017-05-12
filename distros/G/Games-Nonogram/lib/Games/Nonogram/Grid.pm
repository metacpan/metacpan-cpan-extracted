package Games::Nonogram::Grid;

use strict;
use warnings;
use base qw( Games::Nonogram::Base );

use Games::Nonogram::Clue;

sub new {
  my ($class, %options) = @_;

  my $height = $options{height} || $options{size} or die "illegal height";
  my $width  = $options{width}  || $options{size} or die "illegal width";

  my @rows = map {
    Games::Nonogram::Clue->new( id => "Row $_", size => $width )
  } ( 1 .. $height );
  my @cols = map {
    Games::Nonogram::Clue->new( id => "Col $_", size => $height )
  } ( 1 .. $width );

  my $self = bless {
    height      => $height,
    width       => $width,
    rows        => \@rows,
    cols        => \@cols,
    has_answers => 0,
    is_dirty    => 1,
  }, $class;
}

sub new_from {
  my ($class, $loader, @args) = @_;

  $loader = ucfirst $loader;

  my $pkg = "Games::Nonogram::Loader::$loader";
  eval qq{ require $pkg };
  die $@ if $@;

  my ($height, $width, @lines) = $pkg->load( @args );

  my $self = $class->new( height => $height, width => $width );

  $self->load( @lines );

  $self;
}

sub load {
  my ($self, @lines) = @_;

  my @clues = $self->clues;

  foreach my $line ( @lines ) {
    chomp $line;
    next unless $line =~ /^[\d,]+$/;

    my $clue = shift @clues;

    die "clues mismatch" unless ref $clue;

    $clue->set( split ',', $line );
  }

  die "clues mismatch" if @clues;

  $self->clear_stash;
  $self->is_dirty( 1 );
  $self->{has_answers} = 0;
}

sub rows  { @{ shift->{rows} } }
sub cols  { @{ shift->{cols} } }
sub clues { my $self = shift; return ( $self->rows, $self->cols ) }
sub row   { my ($self, $id) = @_; $self->{rows}->[$id - 1]; }
sub col   { my ($self, $id) = @_; $self->{cols}->[$id - 1]; }

sub is_dirty {
  my $self = shift;
  @_ ? $self->{is_dirty} = shift : $self->{is_dirty};
}

sub as_string {
  my $self = shift;

  my $str = '';
  foreach my $row ( $self->rows ) {
    $str .= sprintf "%s\n", $row->as_string;
  }
  if ( $self->debug ) {
    $str .= "\n";

    foreach my $col ( $self->cols ) {
      $str .= sprintf "%s\n", $col->as_string;
    }
  }

  defined wantarray ? return $str : print $str;
}

sub update {
  my ($self, $mode) = @_;

  $self->log( 'updating' );

  $self->is_dirty( 0 );
  foreach my $row ( 1 .. $self->{height} ) {
    my $clue = $self->row( $row );

    next if $clue->is_done && !$clue->line->is_dirty;

    $self->_update( $clue, $mode );

    foreach my $col ( $clue->line->dirty_items ) {
      $self->is_dirty( 1 );
      $self->_update_dirty_item(
        $self->col( $col ),
        $row,
        $clue->line->value( $col )
      );
    }
  }

  foreach my $col ( 1 .. $self->{width} ) {
    my $clue = $self->col( $col );

    next if $clue->is_done && !$clue->line->is_dirty;

    $self->_update( $clue, $mode );

    foreach my $row ( $clue->line->dirty_items ) {
      $self->is_dirty( 1 );
      $self->_update_dirty_item(
        $self->row( $row ),
        $col,
        $clue->line->value( $row )
      );
    }
  }
  return if $self->is_dirty;
  return if $self->is_done;

  unless ( $mode ) {
    $self->update( 'more' );
  }
  elsif ( $mode eq 'more' ) {
    require Games::Nonogram::BruteForce;
    Games::Nonogram::BruteForce->run( $self );

    if ( $self->answers ) {
      $self->{has_answers} = 1;
    }
  }
}

sub has_answers { shift->{has_answers} }

sub answers {
  my $self = shift;

  my %seen;
  my @answers = grep { defined && !$seen{$_}++ }
                @{ $self->stash->{answers} || [] };
}

sub is_done {
  my $self = shift;

  foreach my $clue ( $self->clues ) {
    return unless $clue->is_done;
  }
  unless ( $self->{has_answers} ) {
    $self->{has_answers} = 1;
    push @{ $self->stash->{answers} ||= [] }, $self->as_string;
  }
  return 1;
}

sub _update {
  my ($self, $clue, $mode) = @_;

  my ($before, $after);
  if ( $self->debug ) {
    $before = $clue->dump_blocks;
    $self->log( $before );
  }

  $clue->update( $mode );

  if ( $self->debug ) {
    $after = $clue->dump_blocks;
    $self->log( "TO: \n$after" ) if $before ne $after;
  }
}

sub _update_dirty_item {
  my ($self, $clue, $id, $value) = @_;

  return unless $clue->value( $id ) != $value;

  $self->log( $clue->dump_blocks ) if $self->debug;

  $clue->value( $id, $value );

  $self->log( "TO:\n", $clue->dump_blocks ) if $self->debug;
}

1;

__END__

=head1 NAME

Games::Nonogram::Grid

=head1 SYNOPSIS

  use Games::Nonogram::Grid;
  my $grid = Games::Nonogram::Grid->new( height => 10, width => 10 );

    or

  my $grid = Games::Nonogram::Grid->new_from( file => 'puzzle.dat' );

=head1 DESCRIPTION

This is used internally to provide the puzzle grid.

=head1 METHODS

=head2 new

creates an object. You should provide height and width of the puzzle as shown above.

=head2 new_from

also creates an object but through a loader (in this case, ::Loader::File).

=head2 load

parses data from the loader and prepares clues.

=head2 as_string

returns (or dumps) the stringified form of the grid.

=head2 update

looks through the grid and takes a step forward to solve.

=head2 answers

returns all the answer(s) found.

=head1 ACCESSORS

=head2 rows

returns all the row clues for the grid.

=head2 cols

returns all the column clues for the grid.

=head2 clues

returns all the clues for the grid.

=head2 row

returns clues in the given row.

=head2 col

returns clues in the given column.

=head2 is_dirty

is a flag which should be true after something is changed.

=head2 has_answers

returns true if the grid has answer(s).

=head2 is_done

returns true if all the blocks are settled.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
