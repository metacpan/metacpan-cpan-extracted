# Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

package Math::NumSeq::UlamSequence;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 74;
use Math::NumSeq;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Ulam Sequence');
use constant description => Math::NumSeq::__('Ulam sequence, 1,2,3,4,6,8,11,etc starting 1,2 then each member being uniquely representable as the sum of two earlier values.');
use constant characteristic_increasing => 1;
use constant i_start => 1;
use constant values_min => 1;

use constant parameter_info_array =>
  [
   { name    => 'start_values',
     display => Math::NumSeq::__('Start Values'),
     type    => 'string',
     width   => 5,
     default => '1,2',
     choices => ['1,2', '1,3', '1,4', '1,5',
                 '2,3', '2,4', '2,5'],
     description => Math::NumSeq::__('Starting values for the sequence.'),
   },
  ];

my %oeis_anum = ('1,2' => 'A002858',
                 '1,3' => 'A002859',
                 '1,4' => 'A003666',
                 '1,5' => 'A003667',
                 '2,3' => 'A001857',
                 '2,4' => 'A048951',
                 '2,5' => 'A007300',

                 # OEIS-Catalogue: A002858 start_values=1,2
                 # OEIS-Catalogue: A002859 start_values=1,3
                 # OEIS-Catalogue: A003666 start_values=1,4
                 # OEIS-Catalogue: A003667 start_values=1,5
                 # OEIS-Catalogue: A001857 start_values=2,3
                 # OEIS-Catalogue: A048951 start_values=2,4
                 # OEIS-Catalogue: A007300 start_values=2,5
                );
sub oeis_anum {
  my ($self) = @_;
  (my $key = $self->{'start_values'}) =~ tr/ \t//d;
  return $oeis_anum{$key};
}

# each 2-bit vec() value is
#    0 not a sum
#    1 sum one
#    2 sum two or more
#    3 (unused)

my @transform = (0, 0, 1, -1);

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'upto'} = 0;
  $self->{'string'} = '';

  ### start_values: $self->{'start_values'}
  my $max = -1;
  foreach my $value (split /(?:\s|,)+/, $self->{'start_values'}) {
    ### $value
    vec($self->{'string'}, $value, 2) = 1;
    if ($value > $max) { $max = $value; }
  }
  $self->{'max'} = $max;
}

# 0 => 1
# 1 => 2
# 2 => 2
my @incr = (1,2,2);

sub next {
  my ($self) = @_;

  my $upto = $self->{'upto'};
  my $sref = \$self->{'string'};

  for (;;) {
    $upto++;
    my $entry = vec($$sref, $upto,2);
    ### $upto
    ### $entry
    if ($entry == 1) {
      my $max;
      foreach my $i (1 .. $upto-1) {
        if (vec($$sref, $i,2) == 1) {
          vec($$sref, $i+$upto,2) = $incr[vec($$sref, $i+$upto,2)];
          $max = $i+$upto;
        }
      }
      if ($max) {
        $self->{'max'} = $max;
      }
      return ($self->{'i'}++, ($self->{'upto'} = $upto));

    } elsif ($upto > $self->{'max'}) {
      return;
    }
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq ie Ulam

=head1 NAME

Math::NumSeq::UlamSequence -- integers uniquely the sum of two previous terms

=head1 SYNOPSIS

 use Math::NumSeq::UlamSequence;
 my $seq = Math::NumSeq::UlamSequence->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

Ulam sequences are integers which are the sum of two previous terms in just
one way.  The default starting values are 1,2,

    1, 2, 3, 4, 6, 8, 11, 13, 16, 18, 26, ...

For example 11 is in the sequence because it's the sum of two previous terms
3+8, and no other such sum.  Whereas 12 is not in the sequence because
there's two sums 4+8 and 1+11.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::UlamSequence-E<gt>new ()>

=item C<$seq = Math::NumSeq::UlamSequence-E<gt>new (start_values =E<gt> '2,5')>

Create and return a new sequence object.

=back

=head1 SEE ALSO

L<Math::NumSeq>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
