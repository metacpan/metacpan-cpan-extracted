# Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

package Math::NumSeq::Multiples;
use 5.004;
use strict;
use POSIX 'ceil';

use vars '$VERSION', '@ISA';
$VERSION = 72;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Devel::Comments;


# use constant name => Math::NumSeq::__('Multiples of a given K');
use constant description => Math::NumSeq::__('The multiples K, 2*K, 3*K, 4*K, etc of a given number.');
use constant default_i_start => 0;

sub values_min {
  my ($self) = @_;
  if ((my $multiples = $self->{'multiples'}) >= 0) {
    return $multiples * $self->i_start;
  } else {
    return undef;
  }
}
sub values_max {
  my ($self) = @_;
  if ((my $multiples = $self->{'multiples'}) <= 0) {
    return $multiples * $self->i_start;
  } else {
    return undef;
  }
}
sub characteristic_non_decreasing {
  my ($self) = @_;
  return ($self->{'multiples'} >= 0);
}
sub characteristic_increasing {
  my ($self) = @_;
  return ($self->{'multiples'} > 0);
}
sub characteristic_integer {
  my ($self) = @_;
  return (int($self->{'multiples'}) == $self->{'multiples'});
}

use constant parameter_info_array =>
  [ { name => 'multiples',
      type => 'float',
      width => 10,
      decimals => 4,
      page_increment => 10,
      step_increment => 1,
      minimum => 0,
      default => 29,
      description => Math::NumSeq::__('Display multiples of this number.  For example 6 means show 6,12,18,24,30,etc.'),
    },
  ];

#------------------------------------------------------------------------------

# cf A017173 9n+1
my %oeis_anum =
  (0 => { 0 => 'A000004',  # 0,  all zeros
          # OEIS-Catalogue: A000004 multiples=0

          1  => 'A001477',  # 1,  integers 0,1,2,...
          2  => 'A005843',  # 2 even 0,2,4,...
          # OEIS-Other: A001477 multiples=1
          # OEIS-Other: A005843 multiples=2

          3  => 'A008585',  # 3 starting from i=0
          4  => 'A008586',  # 4 starting from i=0
          5  => 'A008587',  # 5 starting from i=0
          6  => 'A008588',  # 6 starting from i=0
          7  => 'A008589',  # 7 starting from i=0
          8  => 'A008590',  # 8 starting from i=0
          9  => 'A008591',  # 9 starting from i=0
          10 => 'A008592',  # 10 starting from i=0
          # OEIS-Catalogue: A008585 multiples=3
          # OEIS-Catalogue: A008586 multiples=4
          # OEIS-Catalogue: A008587 multiples=5
          # OEIS-Catalogue: A008588 multiples=6
          # OEIS-Catalogue: A008589 multiples=7
          # OEIS-Catalogue: A008590 multiples=8
          # OEIS-Catalogue: A008591 multiples=9
          # OEIS-Catalogue: A008592 multiples=10
        },
   1 => {
         3018 => 'A086746', # multiples of 3018, start OFFSET=1 value=3018
         # OEIS-Catalogue: A086746 multiples=3018 i_start=1
        },
  );
sub oeis_anum {
  my ($self) = @_;
  my $i_start = $self->i_start;
  if ($i_start < 0) { return undef; }
  return $oeis_anum{$i_start}->{$self->{'multiples'}};
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
}
sub seek_to_i {
  my ($self, $i) = @_;
  # if ($i >= $self->{'uv_i_limit'}) {
  #   $i = Math::NumSeq::_to_bigint($i);
  # }
  $self->{'i'} = $i;
}
sub seek_to_value {
  my ($self, $value) = @_;
  $self->{'i'} = $self->value_to_i_ceil($value);
}
sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  return ($i, $i * $self->{'multiples'});
}
sub ith {
  my ($self, $i) = @_;
  return $i * $self->{'multiples'};
}
sub pred {
  my ($self, $value) = @_;
  my $multiples = $self->{'multiples'};
  if ($multiples == 0) {
    return ($value == 0);
  }
  my $i = int($value / $multiples);
  return ($value == $i*$multiples);
}

use constant::defer _INFINITY => sub {
  require POSIX;
  return 2 * POSIX::DBL_MAX();
};

sub value_to_i_estimate {
  my ($self, $value) = @_;
  my $multiples = $self->{'multiples'};
  if ($multiples == 0) {
    return _INFINITY;
  }
  return int($value / $multiples);
}

use Math::NumSeq::All;
*_floor = \&Math::NumSeq::All::_floor;

sub value_to_i {
  my ($self, $value) = @_;
  my $i = $self->value_to_i_floor($value);
  if ($value == $self->ith($i)) {
    return $i;
  }
  return undef;
}
sub value_to_i_floor {
  my ($self, $value) = @_;
  return _floor($value/$self->{'multiples'});
}
sub value_to_i_ceil {
  my ($self, $value) = @_;
  if ($value < 0) { return 0; }
  my $i = $self->value_to_i_floor($value);
  if ($value > $self->ith($i)) {
    $i += 1;
  }
  return $i;
}


1;
__END__

=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::Multiples -- multiples of a given number

=head1 SYNOPSIS

 use Math::NumSeq::Multiples;
 my $seq = Math::NumSeq::Multiples->new (multiples => 123);
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

A simple sequence of multiples of a given number, for example multiples of 5
gives 0, 5, 10, 15, 20, etc.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Multiples-E<gt>new (multiples =E<gt> $num)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return C<$multiples * $i>.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> is an integer multiple of the given C<multiples>.

=item C<$i = $seq-E<gt>value_to_i_floor($value)>

Return floor(value/multiples).

=item C<$i = $seq-E<gt>value_to_i_estimate($value)>

Return an estimate of the i corresponding to C<$value>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Modulo>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014 Kevin Ryde

Math-NumSeq is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

=cut
