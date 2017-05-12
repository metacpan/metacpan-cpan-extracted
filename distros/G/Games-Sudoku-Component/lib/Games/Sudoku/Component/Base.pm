package Games::Sudoku::Component::Base;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.01';

  sub new {
    my $class = shift;
    my $this  = bless {}, (ref $class || $class);

    my %options = ref $_[0] ? %{ $_[0] } : @_;

    my $size      = $options{size}         || 0;
    my $bl_width  = $options{block_width}  || 0;
    my $bl_height = $options{block_height} || 0;

    if ($bl_width and $bl_height and $bl_width && $bl_height) {
      $size = $bl_width * $bl_height;
    }
    elsif ($size and $size == int(sqrt($size)) ** 2) {
      $bl_width = $bl_height = int(sqrt($size));
    }
    elsif ($size or $bl_width or $bl_height) {
      croak "Invalid size: $size" if $size;
      croak "Invalid block: width $bl_width, height $bl_height"
        if $bl_width || $bl_height;
    }
    else {
      $size = 9;
      $bl_width = $bl_height = 3;
    }

    $this->{size}         = $size;
    $this->{block_width}  = $bl_width;
    $this->{block_height} = $bl_height;

    $this->_initialize(%options);

    $this;
  }

  sub _initialize {
    my ($this, %options) = @_;
  }

  sub _check {
    my ($this, $value) = @_;

    croak "Invalid value: undef"  unless defined $value;
    croak "Invalid value: $value" if $value > $this->{size} || $value < 1;

    $value;
  }

  sub _check0 {
    my ($this, $value) = @_;

    croak "Invalid value: undef"  unless defined $value;
    croak "Invalid value: $value" if $value > $this->{size} || $value < 0;

    $value;
  }

  sub _block_id {
    my ($this, $row, $col) = @_;

    croak "Invalid row: $row" unless $this->_check($row);
    croak "Invalid col: $col" unless $this->_check($col);

    my $blockrow  = int(($row - 1) / $this->{block_height});
    my $blockcol  = int(($col - 1) / $this->{block_width});

    $blockrow * $this->{block_height} + $blockcol + 1;
  }

  sub size         { $_[0]->{size} }
  sub block_width  { $_[0]->{block_width} }
  sub block_height { $_[0]->{block_height} }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Base

=head1 SYNOPSIS

  use base qw/Games::Sudoku::Component::Base/;

=head1 DESCRIPTION

This is a base class for L<Games::Sudoku::Component::Table>,
L<Games::Sudoku::Component::Table::Cell>, 
L<Games::Sudoku::Component::Table::Permission>.

=head1 METHODS

=head2 new

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

=head2 size

Returns the size of the table, specified at C<new>.

=head2 block_width

=head2 block_height

Return the width/height of internal blocks of the table,
specified at C<new>, respectively.

=head1 SEE ALSO

=over 4

=item L<Games::Sudoku::Component>

=item L<Games::Sudoku::Component::Table>

=item L<Games::Sudoku::Component::Table::Cell>

=item L<Games::Sudoku::Component::Table::Permission>

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
