# Copyright 2012, 2015 Kevin Ryde

# This file is part of Math-NumSeq-Alpha.
#
# Math-NumSeq-Alpha is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq-Alpha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq-Alpha.  If not, see <http://www.gnu.org/licenses/>.



# Should values in cycles be all 0 ?





package Math::NumSeq::AlphabeticalLengthSteps;
use 5.004;
use strict;
use List::Util 'min';

use vars '$VERSION', '@ISA';
$VERSION = 3;
use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::AlphabeticalLength;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant description => Math::NumSeq::__('Steps of alphabetical length until reaching a cycle.');
use constant default_i_start => 1;
use constant characteristic_count => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;

*parameter_info_array
  = \&Math::NumSeq::AlphabeticalLength::parameter_info_array;

sub values_min {
  my ($self) = @_;
  ### oeis_anum: $self
  if (defined (my $values_min = $self->{'values_min'})) {
    return $values_min;
  }
  my $i_start = $self->i_start;
  return ($self->{'values_min'}
          = min (map {$self->ith($_)}
                 $i_start .. $i_start + 20));
}

#------------------------------------------------------------------------------
# A133418 single step towards 4

my %oeis_anum = (A005589 => 'A016037', # en cardinals
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum{$self->{'lenseq'}->oeis_anum || ''};
}

# forty two = 8
# eight = 5
# five = 4
# four = 4

# forty three = 10
# ten = 3
# three = 5
# five = 4
# four = 4
#
# forty three = 11 ... is 5 steps

# forty four = 9
# nine = 4
# four = 4

# fifty seven = 11
# eleven = 6
# size = 3
# three = 5
# five = 4
# four = 4   is 5 steps
#
# fifty seven = 10 ... is 4 steps


#------------------------------------------------------------------------------

sub new {
  ### AlphabeticalLengthSteps new(): @_
  my $self = shift->SUPER::new(@_);
  $self->{'lenseq'} = Math::NumSeq::AlphabeticalLength->new(@_);
  return $self;
}

sub ith {
  my ($self, $i) = @_;
  ### AlphabeticalLengthSteps ith(): $i

  if (_is_infinite($i)) {
    return undef;
  }

  my $count = 0;
  my %seen;
  for (;;) {
    $seen{$i} = undef;
    $i = $self->{'lenseq'}->ith($i);
    if (! defined $i) {
      return undef;
    }
    ### to: $i
    last if exists $seen{$i};
    $count++;
  }

  return $count;
}

1;
__END__

# =head2 Lang
# 
# The default is English, or the C<lang> option can select anything known to
# L<Lingua::Any::Numbers>.  For example French,
# 
#     lang => 'fr'
#     5, 4, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 5, 4, 4, 5, 5, ...
# 
# The first cycle is at i=3="trois" has 5 letters, 5="cinq" has 4 letters,
# 4="quatre" has 6 letters, 6="six" has 3 letters.


=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::AlphabeticalLengthSteps -- iterations of length in characters

=head1 SYNOPSIS

 use Math::NumSeq::AlphabeticalLengthSteps;
 my $seq = Math::NumSeq::AlphabeticalLengthSteps->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is a count of how many times iterating
S<i -E<gt> AlphabeticalLength(i)> until reaching a cycle.

    i     = 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 
    value = 3, 3, 2, 0, 1, 3, 2, 2, 1, 3, 4, 4, 3, 3, 3, ...

For example i=6="six" is 3 letters, then 3="three" is 5 letters, 5="five" is
4 letters, and 4="four" is its own length.  This took 3 steps to reach the
cycle at 4-E<gt>4.  At i=4 the value is 0 for no steps to reach a cycle
"four"=4.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::AlphabeticalLengthSteps-E<gt>new ()>

=item C<$seq = Math::NumSeq::AlphabeticalLengthSteps-E<gt>new (lang =E<gt> $str)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the number times to apply AlphabeticalLength until reaching a cycle.

=cut

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::AlphabeticalLength>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2015 Kevin Ryde

Math-NumSeq-Alpha is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Math-NumSeq-Alpha is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Math-NumSeq-Alpha.  If not, see L<http://www.gnu.org/licenses/>.

=cut
