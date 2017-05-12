use strict;
use warnings;
package Games::Crossword::Puzzle;
{
  $Games::Crossword::Puzzle::VERSION = '0.003';
}
# ABSTRACT: six letters for "reusable unit of code"


use Carp ();
use Games::Crossword::Puzzle::Cell;


sub from_file {
  my ($class, $filename) = @_;

  my $self = bless {} => $class;

  open my $fh, $filename or die "couldn't open file: $!";

  seek $fh, 2, 0;
  read $fh, (my $magic), 12;
  die "file is not a valid puzzle" unless $magic eq "ACROSS&DOWN\0";

  {
    seek $fh, 0x2C, 0;
    read $fh, (my $size), 2;
    $self->{width}  = ord substr $size, 0, 1;
    $self->{height} = ord substr $size, 1, 1;
  }

  seek $fh, 0x34, 0;
  read $fh, (my $solution), $self->height * $self->width;
  read $fh, (my $guess), $self->height * $self->width;

  seek $fh, 0x2E, 0;
  read $fh, (my $clues), 2;
  $clues = unpack 'v2', $clues;

  seek $fh, 0x34  +  2 * $self->height * $self->width, 0;
  $self->{title}     = $self->_read_nul_string($fh);
  $self->{author}    = $self->_read_nul_string($fh);
  $self->{copyright} = $self->_read_nul_string($fh);

  my @clues;
  for (1 .. $clues) {
    my $clue = $self->_read_nul_string($fh);
    push @clues, $clue;
  }

  $self->{notes} = $self->_read_nul_string($fh);

  my $tables = $self->_read_tables($fh);

  $self->__build_grid(\$solution, \$guess, \@clues, $tables);

  return $self;
}

sub _read_tables {
  my ($self, $fh) = @_;

  my %return;

  while (! eof $fh) {
    read($fh, my $front, 8) or die "error reading table: $!";

    my ($title, $len, $ck) = unpack "A4SS", $front;
    read($fh, my $data, $len) or die "error reading table $title: $!";

    read($fh, my $nul, 1) or die "error reading table $title: $!";
    die "data for $title table not nul-terminated" unless $nul eq "\0";

    $return{ $title } = $data;
  }

  return \%return;
}


sub height { $_[0]->{height} }
sub width  { $_[0]->{width} }


sub rows {
  my ($self) = @_;

  return @{ $self->{grid} };
}


sub cell {
  my ($self, $number) = @_;

  Carp::croak "invalid cell ($number) requested"
    unless exists $self->{number}{$number};

  return $self->{number}{$number};
}


sub title     { $_[0]->{title} }
sub author    { $_[0]->{author} }
sub copyright { $_[0]->{copyright} }
sub note      { $_[0]->{note} }

# Iterate through the grid, building the Cell objects.
# Figure out which cells are going to have clues and assign the clues from the
# input stack to cells.
sub __build_grid {
  my ($self, $solution_ref, $guess_ref, $clues, $tables) = @_;
  my @grid;
  $#grid = $self->height - 1;

  my %number;

  my $current_number = 1;

  for my $row (0 .. $#grid) {
    my @row;
    $#row = $self->width - 1;

    for my $col (0 .. $#row) {
      my $byte = $row * $self->width  +  $col;
      my %square = (
        value  => $self->_grid_xy_char($solution_ref, $col, $row, $tables),
        guess  => $self->_grid_xy_char($guess_ref,    $col, $row),
      );

      delete $square{value} if $square{value} eq '.';
      delete $square{guess} if $square{guess} eq '.' or $square{guess} eq '-';

      my $across = $self->_has_across_clue(\%square, $solution_ref, $col, $row);
      my $down   = $self->_has_down_clue(\%square, $solution_ref, $col, $row);

      $square{number} = $current_number++ if $across or $down;

      if ($square{number}) {
        $number{ $square{number} } = \%square;

        $square{across} = shift @$clues if $across;
        $square{down} = shift @$clues if $down;
      }

      $row[ $col ] = Games::Crossword::Puzzle::Cell->new(\%square);
    }

    $grid[ $row ] = \@row;
  }

  $self->{grid}   = \@grid;
  $self->{number} = \%number;
}

# I'd worry more about the efficiency of doing this if it wasn't always for
# such short strings. -- rjbs, 2007-04-27
sub _read_nul_string {
  my ($self, $fh) = @_;

  my $string;
  while (read $fh, my $char, 1) {
    last if $char eq "\0";
    $string .= $char;
  }

  return $string;
}

sub _grid_xy_char {
  my ($self, $str_ref, $x, $y, $tables) = @_;

  return if $x >= $self->width or $y >= $self->height;

  my $index = $y * $self->width  +  $x;

  if ($tables and $tables->{GRBS} and $tables->{RTBL}) {
    my $rebus = substr $tables->{GRBS}, $index, 1;
    if (my $which = ord $rebus) {
      # do this elsewhere, cache it; forget about it, Jake, it's Chinatown
      my %for;
      for my $pair (split /;/, $tables->{RTBL}) {
        my ($k, $v) = split /:/, $pair;
        $k =~ s/ //g;
        $for{$k} = $v;
      }
      die "can't resolve rebus" unless defined $for{ $which - 1 };
      return $for{ $which - 1 }
    }
  }

  return substr $$str_ref, $index, 1;
}

sub _has_across_clue {
  my ($self, $square, $sol_ref, $x, $y) = @_;

  return unless defined $square->{value};
  return if $x >= $self->width - 1;
  return if $self->_grid_xy_char($sol_ref, $x+1, $y) eq '.';
  return 1 if $x == 0;
  return if $self->_grid_xy_char($sol_ref, $x-1, $y) ne '.';
  return 1;
}

sub _has_down_clue {
  my ($self, $square, $sol_ref, $x, $y) = @_;

  return unless defined $square->{value};
  return if $y >= $self->height - 1;
  return if $self->_grid_xy_char($sol_ref, $x, $y+1) eq '.';
  return 1 if $y == 0;
  return if $self->_grid_xy_char($sol_ref, $x, $y-1) ne '.';
  return 1;
}


1;

__END__

=pod

=head1 NAME

Games::Crossword::Puzzle - six letters for "reusable unit of code"

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $puzzle = Games::Crossword::Puzzle->from_file('nyt-sunday.puz');

  for my $row ($puzzle->rows) {
    for my $cell (@$row) {
      die "Nope, not completed properly"
        if $cell->value and (not $cell->guess) || $cell->guess ne $cell->value;
    }
  }

=head1 DESCRIPTION

The F<.PUZ> file format is used by many crossword programs and, more
importantly, is offered by many newspapers.  It servers as both a puzzle and a
"saved game," storing the grid, the answers, the clues, and guesses.

Games::Crossword::Puzzle reads F<.PUZ> files and produces
Games::Crossword::Puzzle objects.

A puzzle is a rectangular grid of L<Games::Crossword::Puzzle::Cell> objects.

=head1 METHODS

=head2 from_file

  my $puzzle = Games::Crossword::Puzzle->from_file($filename);

This method reads in a puzzle file and returns a puzzle object.  It will raise
an exception if the file does not appear to be a valid puzzle file.

=head2 height

=head2 width

These methods return the height and width of the puzzle grid.

=head2 rows

This method returns a list of arrayrefs, each representing one row of the grid.
Each arrayref is populated with Games::Crossword::Puzzle::Cell objects.

=head2 cell

  my $cell = $puzzle->cell($number);

This method returns the cell with the given number.  Not every cell is
numbered!  Only cells that have clues are numbered.

This method will raise an exception if an invalid cell is requested.

=head2 title

This method returns the puzzle's title.

=head2 author

This method returns the puzzle's author.

=head2 copyright

This method returns the puzzle's copyright information.

=head2 note

This method returns the puzzle's "note," if any.

=head1 CAVEATS

While there is some basic checking that the input file really is a puzzle file,
the checksums aren't checked, which could lead to loading an invalid file.  I
may get around to fixing this in the future.

=head1 THANKS

Josh Myer is a nerd and reverse engineered the PUZ format enough for this
module to be written.  I used his notes, found here:
L<http://www.joshisanerd.com/puz/>

=head1 SECRET ORIGINS

Daniel Jalkut, an internet-famous blogger, hyped up a forthcoming product for a
while, finally revealing that it was Black Ink, a nice crossword program for OS
X.  I like crosswords, but I didn't want to spend $25 on it, so I had a look
into the weird "PUZ" format it used.  I wrote this module as phase one in
producing my own free crossword software, possibly a PUZ-to-DHTML sort of
thing.  (Warning: I have been known to quit after phase one.)

(My loving wife later bought me a copy of Black Ink, so I didn't have much
reason to keep working on this, but I did finally add some basic rebus cell
parsing six years later.)

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
