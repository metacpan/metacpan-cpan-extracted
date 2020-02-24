# Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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

# http://dimacs.rutgers.edu/TechnicalReports/abstracts/1993/93-84.html


package Math::NumSeq::Kolakoski;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Devel::Comments;

# use constant name => Math::NumSeq::__('Kolakoski Sequence');
use constant description => Math::NumSeq::__('Kolakoski sequence 1,2,2,1,1,2,1,etc its own run lengths.');
use constant characteristic_increasing => 0;
use constant characteristic_integer => 1;
use constant values_min => 1;
use constant values_max => 2;
use constant i_start => 1;

# cf A000002 - starting 1,2,2,1,1,
#    A006928 - starting 1,2,1,1,...
#    A064353 - 1,3 sequence
#    A054353 - partial sums
#    A078880 - starting from 2
#    A054353 - partial sums, step 1 or 2, is kol(n)!=kol(n+1) the 2 gaps ...
#    A074286 - partial sums minus n (variously repeating values)
#    A054349 - successive generations as big decimals
#    A042942 - something substitutional
#    A013949 substitute
#    A156077 digits ...
#    A078929 A(n+k) = A(n)
#    A081592 - runs of n many 1 or 2
#
#    A156253 kol supp
#    A064353 kol 1/3
#    A001083 A00002 lengths after iterating 1,2,3,5,7,10,15
#    A006928 lengths ...
#    A042942 1,2,1,1 lengths after iterating 1,2,4,6,9,14,22
#    A079729 1,2,3 starting 1,2,2
#    A079730 1,2,3,4 starting 1,2,2
#
#    A074290 - diff from n mod 2
#    A074291 - positions of n odd having 1 or n even having 2
#
#    A025142,A025143 - invert 1,2 so opposite run length
#
#    A171899 van eck transform of A000002
#
use constant oeis_anum => 'A000002';

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  $self->{'digits'} = [1];
  $self->{'counts'} = [2];
}

sub next {
  my ($self) = @_;
  ### Kolakoski next(): "$self->{'i'}"

  my $counts = $self->{'counts'};
  my $digits = $self->{'digits'};
  my $pos = -1;
  my $digit;
  for (;;) {
    if (++$pos > $#$counts) {
      ### all zeros to pos: $pos
      if ($pos == 1 && $digits->[0] == 1) {
        ### special case i=2,i=3 digit 2 ...
        $counts->[0] = 2;
        return ($self->{'i'}++, ($digits->[0] = 2));
      }
      ### extend for get i=3 leave i=4 state ...
      push @$counts, 1;
      push @$digits, ($digit = 2);
      last;
    }
    if (--$counts->[$pos]) {
      ### non-zero count at: "pos=$pos digit=$digits->[$pos], remaining count=$counts->[$pos]"
      $digit = $digits->[$pos];
      last;
    }
  }

  while (--$pos >= 0) {
    $counts->[$pos] = $digit;
    $digit = ($digits->[$pos] ^= 3);
  }
  return ($self->{'i'}++, $digit);

}

1;
__END__

  # my $pending = $self->{'pending'};
  # # unless (@$pending) {
  # #   push @$pending, ($self->{'digit'}) x $self->{'digit'};
  # #   # ($self->{'digit'} ^= 3);
  # # }
  # my $ret = shift @$pending;
  # ### $ret
  # ### append: ($self->{'digit'} ^ 3)
  # 
  # push @$pending, (($self->{'digit'} ^= 3) x $ret);
  # 
  # # A025142
  # # push @$pending, (($self->{'digit'}) x $ret);
  # # $self->{'digit'} ^= 3;
  # 
  # ### now pending: @$pending
  # return ($self->{'i'}++, $ret);


=for stopwords Ryde Math-NumSeq

=head1 NAME

Math::NumSeq::Kolakoski -- sequence of 1s and 2s its own run lengths

=head1 SYNOPSIS

 use Math::NumSeq::Kolakoski;
 my $seq = Math::NumSeq::Kolakoski->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

A sequence 1,2,2,1,1,2,1,etc, each run length being given successively by
the sequence itself.

Starting from 1,2, at i=2 the values is 2, so there should be a run of two
2s.  Then at i=3 value 2 means two 1s.  Then at i=4 value 1 means a run of
one 2.  The value alternates between 1 and 2 and the sequence values
themselves determine the run length to give that value, either 1 or 2.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Kolakoski-E<gt>new ()>

Create and return a new sequence object.

=back

=head1 FORMULAS

There's no need to keep the entire sequence, nor even the portion between
where i is up to and the values past that which those up to i induce.
Instead the value at i is determined by the earlier value, which is
determined a yet earlier value, etc.  At each level only a value and pending
count need to be kept.  The levels required end up being about log base 1.6
of the position i.

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::GolombSequence>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2011, 2012, 2013, 2014, 2016, 2019 Kevin Ryde

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
