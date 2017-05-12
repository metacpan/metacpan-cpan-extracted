package Games::Nonogram::BruteForce;

use strict;
use warnings;
use Storable ();

sub run {
  my ($class, $grid) = @_;

  my $data = _freeze( $grid );

  return if $grid->stash->{bruteforce}->{$data};

  $grid->stash->{bruteforce}->{$data} = 1;

  $grid->log( "Start brute forcing" );

  my ($target, $free);
  foreach my $clue ( $grid->clues ) {
    next if $clue->is_done;
    if ( !$free or $free > $clue->{free} ) {
      $free   = $clue->{free};
      $target = $clue;
    }
  }
  return unless $target;  # should be solved already

  $grid->log( "target: ", $target->id );

  my @candidates = $target->candidates;

  foreach my $candidate ( @candidates ) {
    $target->line->as_vec( $candidate );
    $grid->update;

    eval {
      my $str = '';
      my $prev = $grid->as_string;
      while( $str ne $prev and !$grid->is_done ) {
        $grid->update;
        $prev = $str;
        $str  = $grid->as_string;
        $grid->log( $str ) if $grid->debug;
      }
      if ( $grid->is_done ) {
        $grid->log( "Found an answer" );
        push @{ $grid->stash->{answers} ||= [] }, $str;
      }
      else {
        $class->run( $grid );
      }
    };
    if ( $@ ) {
      $grid->log( "Skip" );
    }

    _thaw( $grid, $data );
  }
}

sub _freeze {
  my $grid = shift;

  my @data;
  foreach my $clue ( $grid->clues ) {
    push @data, $clue->line->as_vec;
  }
  return Storable::freeze( \@data );
}

sub _thaw {
  my ($grid, $data) = @_;

  my @data = @{ Storable::thaw( $data ) };

  foreach my $clue ( $grid->clues ) {
    $clue->reset_blocks;
    $clue->line->as_vec( shift @data );
  }
}

1;

__END__

=head1 NAME

Games::Nonogram::BruteForce

=head1 SYNOPSIS

  use Games::Nonogram::BruteForce;
  Games::Nonogram::BruteForce->run($grid);

=head1 DESCRIPTION

Even the simplest Nonogram may require brute force to solve it. The best known and smallest one looks like below:

    1 1
  1 _ _
  1 _ _

This module is used internally to try all (but hopefully least) possibilities of the puzzle, after every other means.

=head1 METHOD

=head2 run

takes a puzzle grid and sets possible solutions to the stash of the grid. If this fails, the puzzle is probably broken... or is too large to solve on the memory.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Kenichi Ishigaki

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
