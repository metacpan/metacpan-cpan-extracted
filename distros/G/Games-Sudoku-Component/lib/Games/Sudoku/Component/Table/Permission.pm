package Games::Sudoku::Component::Table::Permission;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.01';

  use base qw/Games::Sudoku::Component::Base/;

  my $Verbose = 0;

  sub _initialize {
    my ($this, %options) = @_;

    $this->clear;
  }

  sub verbose { shift; $Verbose = shift; }

  sub clear {
    my $this = shift;

    my $size = $this->{size};
    my $flag = (2 ** $size) - 1;

    foreach my $ct (1..$size) {
      $this->{row}[$ct] = $flag;
      $this->{col}[$ct] = $flag;
      $this->{blk}[$ct] = $flag;
    }
  }

  sub allow {
    my ($this, $row, $col, $value) = @_;

    my $blk = $this->_block_id($row,$col);

    $this->{row}[$row] = $this->_on($this->{row}[$row], $value);
    $this->{col}[$col] = $this->_on($this->{col}[$col], $value);
    $this->{blk}[$blk] = $this->_on($this->{blk}[$blk], $value);
  }

  sub deny {
    my ($this, $row, $col, $value) = @_;

    my $blk = $this->_block_id($row,$col);

    $this->{row}[$row] = $this->_off($this->{row}[$row], $value);
    $this->{col}[$col] = $this->_off($this->{col}[$col], $value);
    $this->{blk}[$blk] = $this->_off($this->{blk}[$blk], $value);
  }

  sub allowed {
    my ($this, $row, $col) = @_;

    my @allowed = ();
    foreach my $ct (1..$this->{size}) {
      push @allowed, $ct if $this->is_allowed($row, $col, $ct);
    }
    @allowed;
  }

  sub is_allowed {
    my ($this, $row, $col, $value) = @_;

    my $blk = $this->_block_id($row, $col);

    return $this->result(
      result => 0,
      reason => "row $row has $value"
    ) unless $this->_flag($this->{row}[$row], $value);

    return $this->result(
      result => 0,
      reason => "col $col has $value"
    ) unless $this->_flag($this->{col}[$col], $value);

    return $this->result(
      result => 0,
      reason => "blk $blk has $value"
    )  unless $this->_flag($this->{blk}[$blk], $value);

    return $this->result(1);
  }

  sub result {
    my $this = shift;

    if ($Verbose) {
      require Games::Sudoku::Component::Result;
      my $result = Games::Sudoku::Component::Result->new(@_);
    }
    else {
      if (@_ == 1) {
        if (ref $_[0] eq 'HASH') {
          my %options = %{ $_[0] };
          return $options{result} || 0;
        }
        else {
          return $_[0];
        }
      }
      else {
        my %options = @_;
        return $options{result} || 0;
      }
    }
  }

  sub _flag {
    my ($this, $flag, $value) = @_;

    croak "Invalid value: $value" unless $this->_check($value);
    croak "Invalid flag: undef"   unless defined $flag;

    return (0 + $flag) & (2 ** ($value - 1));
  }

  sub _on {
    my ($this, $flag, $value) = @_;

    croak "Invalid value: $value" unless $this->_check($value);
    croak "Invalid flag: undef"   unless defined $flag;

    return (0 + $flag) | (2 ** ($value - 1));
  }

  sub _off {
    my ($this, $flag, $value) = @_;

    croak "Invalid value: $value" unless $this->_check($value);
    croak "Invalid flag: undef"   unless defined $flag;

    return (0 + $flag) & ~(2 ** ($value - 1));
  }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Table::Permission

=head1 SYNOPSIS

  use Games::Sudoku::Component::Table;
  use Games::Sudoku::Component::Table::Permission;

  my $table = Games::Sudoku::Component::Table->new(
    perm => Games::Sudoku::Component::Table::Permission->new
  );

=head1 DESCRIPTION

This module provides a permission table. Usually you don't have to
care about this.

=head1 METHODS

=head2 new (I<hash> or I<hashref>)

Creates an object. As for options, see the base class
L<Games::Sudoku::Component::Base>. Size related options
are required.

=head2 allow (I<row>, I<column>, I<value>)

Allows the value for the cell(row, column).

=head2 deny (I<row>, I<column>, I<value>)

Denies the value for the cell(row, column).
Actually the value will be held as a temporary one.

=head2 allowed

Returns an array of allowed values.

=head2 is_allowed (I<row>, I<column>, I<integer>)

Returns true if the value is allowed for the cell(row, column).

=head2 result

Mainly used internally. In the verbose mode, this returns a result
code and a reason/description of the code; otherwise only the code
will be returned.

=head2 clear

Clears all of the permission data.

=head2 verbose (I<bool>)

If set true, C<result> method will be verbose.

=head1 SEE ALSO

=over 4

=item L<Games::Sudoku::Component>,

=item L<Games::Sudoku::Component::Base>,

=item L<Games::Sudoku::Component::Table>,

=item L<Games::Sudoku::Component::Table::Cell>

=back

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
