package Games::Sudoku::Component::Controller::Loader;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.02';

  use Games::Sudoku::Component::Table::Item;

  sub load {
    my $pkg = shift;

    my $str;

    if (@_ == 1 and !ref $_[0]) {
      $str = shift;
    }
    elsif (@_ == 1 and ref $_[0] eq 'SCALAR') {
      $str = ${ $_[0] };
    }
    else {
      my %options = ref $_[0] ? %{ $_[0] } : @_;

      if (my $file = $options{filename} || $options{file}) {
        $str = $pkg->_load_from_file($file);
      }
      elsif ($options{scalar}) {
        $str = $options{scalar};
      }
      elsif ($options{scalarref}) {
        $str = ${ $options{scalarref} };
      }
    }

    $str ||= '';

    my @cells = ();
    my ($row, $col) = (0,0);
    foreach my $line (split(/\n+/, $str)) {
      $line =~ s/\r//g;
      $row++;
      $col = 0;
      foreach my $value (split(/\s+/, $line)) {
        $col++;
        $value = 0 unless $value =~ /^[0-9]+$/;
        push @cells, Games::Sudoku::Component::Table::Item->new(
          row   => $row,
          col   => $col,
          allowed => [],
          value => $value,
        );
      }
    }
    @cells;
  }

  sub _load_from_file {
    my ($pkg, $file) = @_;

    open my $fh, '<', $file or croak "failed to open $file: $!";
    read $fh, my $str, (-s $file);
    close $fh;

    $str;
  }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Controller::Loader

=head1 SYNOPSIS

  require Games::Sudoku::Component::Controller::Loader;

  # Load from text
  my @cells = Games::Sudoku::Component::Controller::Loader->load(<<'EOT');
  4 . . . . 1
  2 1 . . 5 .
  3 5 1 2 6 .
  1 . . . 3 .
  6 . . 5 1 2
  5 . . . 4 6
  EOT

  # Or load from file
  my @cells = Games::Sudoku::Component::Controller::Loader->load(
    filename => 'file.txt',
  );

  # Or load from scalarref
  my $puzzle =<<'EOT';
  4 . . . . 1
  2 1 . . 5 .
  3 5 1 2 6 .
  1 . . . 3 .
  6 . . 5 1 2
  5 . . . 4 6
  EOT

  my @cells = Games::Sudoku::Component::Controller::Loader->load(\$puzzle);

  # When you finished loading, put the loaded data into a table.
  my $table = Games::Sudoku::Component::Table->new;
  foreach my $item (@cells) {
    $table->cell($item->row,$item->col)->value($item->value);
    $table->cell($item->row,$item->col)->lock if $item->value;
  }

=head1 DESCRIPTION

This module loads and parses puzzle data from file or scalar (reference)
and returns an array of L<Games::Sudoku::Component::Table::Item> objects.

=head1 METHODS

=head2 load (I<scalar> or I<scalarref> or I<hash> or I<hashref>)

Loads and parses puzzle data from file or scalar (reference), and then,
returns an array of L<Games::Sudoku::Component::Table::Item> objects. 

Hash options are:

=over 4

=item filename (or C<file>, for short)

Filename for puzzle data.

=item scalar

Scalar of puzzle data.

=item scalarref

Scalar reference of puzzle data.

=back

=head1 DATA STRUCTURE

Column separator is whitespaces. Row separator is line breaks.
Other characters are treated as number, i.e. [^1-9] = 0.

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
