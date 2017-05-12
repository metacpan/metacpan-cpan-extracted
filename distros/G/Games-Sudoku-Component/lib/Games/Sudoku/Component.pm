package Games::Sudoku::Component;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.02';

  use Games::Sudoku::Component::Controller;

  sub new {
    my $class = shift;
    my $this  = bless {}, (ref $class || $class);

    $this->{ctrl} = Games::Sudoku::Component::Controller->new(@_);

    $this;
  }

  sub generate {
    my $this = shift;

    my %options = ref $_[0] ? %{ $_[0] } : @_;

    my $size    = $this->{ctrl}->table->size;
    my $blanks  = $options{blanks} || ($size ** 2) * 0.75;

    $this->{ctrl}->solve;
    $this->{ctrl}->make_blank($blanks);
  }

  sub load {
    my $this = shift;

    $this->{ctrl}->load(@_);
  }

  sub solve {
    my $this = shift;

    $this->{ctrl}->solve;
  }

  sub is_solved {
    my $this = shift;

    $this->{ctrl}->status->is_solved;
  }

  sub clear {
    my $this = shift;

    $this->{ctrl}->clear;
  }

  sub as_string {
    my $this = shift;

    $this->{ctrl}->table->as_string(@_);
  }

  sub as_HTML {
    my $this = shift;

    $this->{ctrl}->table->as_HTML(@_);
  }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component - provides APIs for Sudoku solver/generator

=head1 SYNOPSIS

  use Games::Sudoku::Component;

  # Let's create a Sudoku object first.

  my $sudoku = Games::Sudoku::Component->new(
    size => 9,
  );

  # Then, generate a new Sudoku puzzle. This may take minutes.

  $sudoku->generate(
    blanks => 50,
  );

  # Or, you can load puzzle data from text file.

  $sudoku->load(
    filename => 'puzzle.txt',
  );

  # Let's see if the puzzle is created successfully.

  print $sudoku->as_string(
    separator => ' ',
    linebreak => "\n",
  );

  # Then solve the puzzle. This may take minutes, too.
  # Solver may fail sometimes, especially the puzzle is large,
  # but it automatically tries another solution(s) if possible.

  $sudoku->solve;

  # Check the result.

  print $sudoku->is_solved ? 'solved' : 'gave up';

  # You can output the result as an HTML table, too.

  print $sudoku->as_HTML;

=head1 DESCRIPTION

This is yet another Sudoku (Numberplace) solver/generator.
L<Games::Sudoku::Component> provides common (but rather limited)
methods to make it easy to play Sudoku -- just for example.

Actually, this module set is written to provide 'controller'
APIs to other applications. You can easily integrate this with
CGI or Perl/Tk application. See appropriate PODs for details.

=head1 METHODS

=head2 new (I<hash> or I<hashref>)

Creates an object. Options are:

=over 4

=item size

Specifies the size of a puzzle board (table). The default is 9.
Actually this value is assumed to be a square of another integer.

=item block_width

=item block_height

Specify the width/height of internal blocks, respectively.
(C<block_width> x C<block_height> = C<size>)

=back

=head2 generate (I<hash> or I<hashref>)

Generates a puzzle. Options are:

=over 4

=item blanks

Specifies how many blanks are there in the puzzle. The default is
(C<size> x C<size> x 0.75).

=back

=head2 load (I<string> or I<hash> or I<hashref>)

Loads and parses puzzle data from file or string. If there is only one 
argument, it is assumed to be raw puzzle data.

=over 4

  $sudoku->load(<<'EOT');
  4 . . . . 1
  2 1 . . 5 .
  3 5 1 2 6 .
  1 . . . 3 .
  6 . . 5 1 2
  5 . . . 4 6
  EOT

=back

If the argument seems to be a hash, data will be loaded from
$hash{filename} (or $hash{file}, for short).

=head2 solve

Solves the puzzle that you generated or loaded. You can solve
a 'blank' puzzle. In fact, that is how it generates a new puzzle.

=head2 is_solved

Returns true if the puzzle is solved.

=head2 clear

Clears the generated or loaded puzzle.

=head2 as_string (I<hash> or I<hashref>)

Returns the stringified puzzle. Options are:

=over 4

=item separator

Specifies a separator between table columns. The default is a
whitespace (' ').

=item linebreak

Specifies a separator between table rows. The default is a
line break ("\n").

=back

=head2 as_HTML

Almost same as above but returns an HTML table. Options are:

=over 4

=item border

Specifies a size of the table borders. The default is 1.

=item linebreak

Specifies a separator between table tags. The default is a
line break ("\n").

=item color_by_block

=item color_by_cell

If set true, each cell has an 'even' or 'odd' class attribute.
If your prepare an appropriate CSS, the table will be two-toned.

=back

=head1 SEE ALSO

There are many Sudoku implementations around there. I haven't seen
them all yet, but the POD of L<Games::Sudoku::General> is a good
starting point.

As for the details of L<Games::Sudoku::Component> modules, see:

=over 4

=item L<Games::Sudoku::Component::Base>

=item L<Games::Sudoku::Component::Controller>

=item L<Games::Sudoku::Component::Controller::History>

=item L<Games::Sudoku::Component::Controller::Loader>

=item L<Games::Sudoku::Component::Controller::Status>

=item L<Games::Sudoku::Component::Result>

=item L<Games::Sudoku::Component::Table>

=item L<Games::Sudoku::Component::Table::Cell>

=item L<Games::Sudoku::Component::Table::Item>

=item L<Games::Sudoku::Component::Table::Permission>

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
