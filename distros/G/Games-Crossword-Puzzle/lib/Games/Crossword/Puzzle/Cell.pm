use strict;
use warnings;
package Games::Crossword::Puzzle::Cell 0.004;
# ABSTRACT:  one of those little square bits with a number

use Carp ();

#pod =method new
#pod
#pod   my $cell = Games::Crossword::Puzzle::Cell->new(\%arg);
#pod
#pod You probably don't mean to use this directly.
#pod
#pod Valid arguments are:
#pod
#pod   across - the across clue
#pod   down   - the down clue
#pod   number - the cell's number
#pod   value  - the value that belongs in the cell
#pod   guess  - the value that a user has put into the cell
#pod
#pod In the future, this may return a singleton for The Black Cell.
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;

  my $data = {
    map { $_ => $arg->{$_} } qw(across down number value guess)
  };

  bless $data => $class;
}

#pod =method across
#pod
#pod =method down
#pod
#pod These methods return the clues for the word beginning in this cell, if any.
#pod
#pod =cut

sub across { $_[0]->{across} }
sub down   { $_[0]->{down} }

#pod =method number
#pod
#pod This method returns the cell's number, if it is numbered.
#pod
#pod =cut

sub number { $_[0]->{number} }

#pod =method value
#pod
#pod This returns the value that should appear in the cell.  It returns undef for
#pod black cells.  Note that this may be more than one character, in case of a
#pod rebus.
#pod
#pod =cut

sub value  { $_[0]->{value} }

#pod =method guess
#pod
#pod This returns the value that has been filled into the cell by the user.  It
#pod returns undef for black or empty cells.
#pod
#pod =cut

sub guess  { $_[0]->{guess} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Crossword::Puzzle::Cell - one of those little square bits with a number

=head1 VERSION

version 0.004

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
