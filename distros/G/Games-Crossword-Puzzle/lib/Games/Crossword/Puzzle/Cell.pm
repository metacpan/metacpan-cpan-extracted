use strict;
use warnings;
package Games::Crossword::Puzzle::Cell;
{
  $Games::Crossword::Puzzle::Cell::VERSION = '0.003';
}
# ABSTRACT:  one of those little square bits with a number

use Carp ();


sub new {
  my ($class, $arg) = @_;

  my $data = {
    map { $_ => $arg->{$_} } qw(across down number value guess)
  };

  bless $data => $class;
}


sub across { $_[0]->{across} }
sub down   { $_[0]->{down} }


sub number { $_[0]->{number} }


sub value  { $_[0]->{value} }


sub guess  { $_[0]->{guess} }

1;

__END__

=pod

=head1 NAME

Games::Crossword::Puzzle::Cell - one of those little square bits with a number

=head1 VERSION

version 0.003

=head1 METHODS

=head2 new

  my $cell = Games::Crossword::Puzzle::Cell->new(\%arg);

You probably don't mean to use this directly.

Valid arguments are:

  across - the across clue
  down   - the down clue
  number - the cell's number
  value  - the value that belongs in the cell
  guess  - the value that a user has put into the cell

In the future, this may return a singleton for The Black Cell.

=head2 across

=head2 down

These methods return the clues for the word beginning in this cell, if any.

=head2 number

This method returns the cell's number, if it is numbered.

=head2 value

This returns the value that should appear in the cell.  It returns undef for
black cells.  Note that this may be more than one character, in case of a
rebus.

=head2 guess

This returns the value that has been filled into the cell by the user.  It
returns undef for black or empty cells.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
