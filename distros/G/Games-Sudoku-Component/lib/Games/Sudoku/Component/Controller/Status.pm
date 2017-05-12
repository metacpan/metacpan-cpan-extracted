package Games::Sudoku::Component::Controller::Status;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.02';

  my $S_NULL   = 0;
  my $S_OK     = 1;
  my $S_REWIND = 2;
  my $S_SOLVED = 4;
  my $S_GIVEUP = 8;

  sub new {
    my $class = shift;
    my $this  = bless {}, (ref $class || $class);

    my %options = ref $_[0] ? %{ $_[0] } : @_;

    $this->{status}  = $S_NULL;
    $this->{changed} = 0;

    $this->{rewind_max} = $options{rewind_max} || 9;
    $this->{retry_max}  = $options{retry_max}  || 3;

    $this->{rewind} = 0;
    $this->{retry}  = 0;

    $this;
  }

  sub clear  {
    my $this = shift;

    $this->{status} = $S_NULL;
    $this->{rewind} = 0;
    $this->{retry}  = 0;
  }

  sub turn_to_ok     { $_[0]->{status} = $S_OK;     $_[0]->{changed} = 1; }
  sub turn_to_rewind { $_[0]->{status} = $S_REWIND; $_[0]->{changed} = 1; }
  sub turn_to_solved { $_[0]->{status} = $S_SOLVED; $_[0]->{changed} = 1; }
  sub turn_to_giveup { $_[0]->{status} = $S_GIVEUP; $_[0]->{changed} = 1; }

  sub is_null   { ($_[0]->{status} == $S_NULL); }
  sub is_ok     { ($_[0]->{status} == $S_OK); }
  sub is_rewind { ($_[0]->{status} == $S_REWIND); }
  sub is_solved { ($_[0]->{status} == $S_SOLVED); }
  sub is_giveup { ($_[0]->{status} == $S_GIVEUP); }

  sub is_changed  { my $prev = $_[0]->{changed}; $_[0]->{changed} = 0; $prev; }
  sub is_finished { $_[0]->{status} & ($S_GIVEUP|$S_SOLVED) }

  sub can_rewind {
    my $this = shift;
    ($this->{rewind}++ < $this->{rewind_max});
  }

  sub can_retry {
    my $this = shift;
    $this->{rewind} = 0;
    ($this->{retry}++ < $this->{retry_max});
  }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Controller::Status

=head1 SYNOPSIS

  use Games::Sudoku::Component::Controller;

  my $c = Games::Sudoku::Component::Controller->new;
  until($c->status->is_finished) {
    $c->next;
  }

=head1 DESCRIPTION

This module is to hold a status of L<Games::Sudoku::Component::Controller>.

=head1 METHODS

=head2 new

Creates an object. Options are:

=over 4

=item rewind_max (I<integer>)

=item retry_max (I<integer>)

Specifies how many times the controller can rewind/retry.
See L<Games::Sudoku::Component::Controller>.

=back

=head2 is_null

Returns true if the controller has no special status.

=head2 is_ok

Returns true if the controller has some cells to do with next.

=head2 is_rewind

Returns true if the controller has failed to solve a puzzle and
is rewinding.

=head2 is_solved

Returns true if the controller has solved a puzzle.

=head2 is_giveup

Returns true if the controller has finally given up to solve a puzzle.

=head2 is_finished

Returns true if the controller has solved a puzzle or given up to solve.

=head2 is_changed

Returns true if the status has just changed. Once checked, this flag
will be turn off.

=head2 turn_to_ok

=head2 turn_to_rewind

=head2 turn_to_solved

=head2 turn_to_giveup

Changes the status to something, respectively.

=head2 can_rewind

Returns true if the controller is still able to rewind.
If the internal counter grows larger than C<rewind_max>,
this returns false.

=head2 can_retry

Returns true if the controller is still able to retry.
If the internal counter grows larger than C<retry_max>,
this returns false.

=head2 clear

Clears the status.

=head1 SEE ALSO

=over 4

=item L<Games::Sudoku::Component>,

=item L<Games::Sudoku::Component::Controller>

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
