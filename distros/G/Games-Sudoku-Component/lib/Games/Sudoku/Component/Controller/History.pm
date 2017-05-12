package Games::Sudoku::Component::Controller::History;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.01';

  sub new {
    my $class = shift;
    my $this  = bless {}, (ref $class || $class);

    $this->{history} = [];

    $this;
  }

  sub push {
    my ($this, $item) = @_;
    push @{ $this->{history} }, $item;
  }

  sub pop {
    my $this = shift;
    pop @{ $this->{history} };
  }

  sub clear {
    my $this = shift;
    $this->{history} = [];
  }

  sub count {
    my $this = shift;

    return 0 unless defined $this->{history};

    scalar @{ $this->{history} };
  }

  sub latest {
    my ($this, $count) = @_;

    my @history = @{ $this->{history} };

    $count = @history if !$count || $count > @history;

    my @latest = reverse @history[-$count..-1];
  }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Controller::History

=head1 SYNOPSIS

  use Games::Sudoku::Component::Controller::History;
  my $history = Games::Sudoku::Component::Controller::History->new;

  my $item = Games::Sudoku::Component::Table::Item->new(
    row => 1,
    col => 2,
    allowed => [1,3],
  );

  $history->push($item);

  my $item2 = $history->pop;

=head1 DESCRIPTION

This module provides a history stack for L<Games::Sudoku::Component::Controller>.

=head1 METHODS

=head2 new

Creates an object.

=head2 push (I<object>)

Stores an object (supposedly of L<Games::Sudoku::Component::Table::Item>)
in the stack.

=head2 pop

Retrieves an object (supposedly of L<Games::Sudoku::Component::Table::Item>)
from the stack.

=head2 latest (I<integer>)

Returns an array of the number of objects stored in the stack. 

=head2 count

Returns how many items are stored in the stack.

=head2 clear

Clears the stack.

=head1 SEE ALSO

=over 4

=item L<Games::Sudoku::Component>,

=item L<Games::Sudoku::Component::Controller>,

=item L<Games::Sudoku::Component::Table>

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
