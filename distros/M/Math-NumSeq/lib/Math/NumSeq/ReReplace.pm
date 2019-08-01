# Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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



# Benoit Cloitre followups
# http://sci.tech-archive.net/Archive/sci.math.research/2004-10/0224.html
# http://sci.tech-archive.net/Archive/sci.math.research/2004-11/0015.html
# http://sci.tech-archive.net/Archive/sci.math.research/2004-11/0021.html
#


package Math::NumSeq::ReReplace;
use 5.004;
use strict;

use vars '$VERSION','@ISA';
$VERSION = 73;

use Math::NumSeq 7; # v.7 for _is_infinite()
@ISA = ('Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

# uncomment this to run the ### lines
#use Smart::Comments;

# use constant name => Math::NumSeq::__('Repeated Replacement');
use constant description => Math::NumSeq::__('Sequence of repeated replacements.');
use constant values_min => 1;
sub values_max {
  my ($self) = @_;
  my $stage = $self->{'stage'};
  return ($stage < 0 ? undef : $stage+1);
}
use constant i_start => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;

use constant parameter_info_array =>
  [
   { name        => 'stage',
     share_key   => 'stage_neg1',
     type        => 'integer',
     default     => '-1',
     width       => 4,
     minimum     => -1,
     # description => Math::NumSeq::__('...'),
   },
  ];

#------------------------------------------------------------------------------
# 'A100002'
# 0  1  2  3  4  5  6  7  8  9
# 1, 2, 1, 2, 3, 3, 1, 2, 4, 4, 3, 4, 1, 2, 5, 5, 3, 5, 1, 2, 4, 5, 3, 4,
#             1  2        1  2

# cf A100287 - first occurrence of n
#    A101224
#
my @oeis_anum = ('A100002', # -1 all stages
                 # 0 all-ones, but A000012 has OFFSET=0
                 # 1 is 1,2 rep, but A040001 has OFFSET=0
                );
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'stage'}+1];
}

#------------------------------------------------------------------------------

sub rewind {
  my ($self) = @_;
  $self->{'i'} = $self->i_start;
  my $count = $self->{'count'} = [undef, [], []];
}
sub next {
  my ($self) = @_;
  ### ReReplace next(): $self->{'i'}

  my $stage = $self->{'stage'};
  if ($stage == 0) {
    return ($self->{'i'}++,
            1);
  }

  my $count = $self->{'count'};
  ### $count

  my $value = 1;
  for my $level (2 .. $#$count) {
    ### $level
    ### $value
    ### count: ($count->[$level]->[$value]||0) + 1

    if (++$count->[$level]->[$value] >= $level) {
      $count->[$level]->[$value] = 0;
      $value = $level;
    }
  }

  if ($value >= $#$count-1
      && ($stage < 0 || $value < $stage)) {
    push @$count, [ @{$count->[-1]} ];  # array copy
    ### extended to: $count
  }

  ### return: $value
  return ($self->{'i'}++,
          $value);
}

sub pred {
  my ($self, $value) = @_;
  ### Runs pred(): $value

  return ($value >= 1
          && $value == int($value));
}

1;
__END__

=for stopwords Ryde OEIS Madore N'th Math-NumSeq

=head1 NAME

Math::NumSeq::ReReplace -- sequence of repeated replacements

=head1 SYNOPSIS

 use Math::NumSeq::ReReplace;
 my $seq = Math::NumSeq::ReReplace->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

X<Madore, David>This is a sequence by David Madore formed by repeatedly
replacing every N'th occurrence of a term with N.

    1, 2, 1, 2, 3, 3, 1, 2, 4, 4, 3, 4, ...

As per

=over

David Madore, "have you seen this sequence?", sci.math.research, 24 Oct
2004,
L<http://sci.tech-archive.net/Archive/sci.math.research/2004-10/0218.html>

L<http://www.madore.org/~david/.misc/seq.png>

=back

=head2 Stages

The generating procedure begins with all 1s,

    stage 0: 1,1,1,1,1,1,1,1,1,1,1,1,...

Then every second 1 is changed to 2

    stage 1: 1,2,1,2,1,2,1,2,1,2,1,2,...

Then every third 1 is changed to 3, and every third 2 changed to 3 also,

    stage 2: 1,2,1,2,3,3,1,2,1,2,3,3,...

Then every fourth 1 becomes 4, every fourth 2 becomes 4, and every fourth 3
becomes 4.

    stage 3: 1,2,1,2,3,3,1,2,4,4,3,4,...

The replacement by N of every Nth is applied separately to the 1s, 2s, 3s
etc remaining at each stage.

The optional C<stage =E<gt> $n> parameter limits the replacements to a given
number of stages of the algorithm.  The default -1 means unlimited.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::ReReplace-E<gt>new ()>

=item C<$seq = Math::NumSeq::ReRound-E<gt>new (stages =E<gt> $integer)>

Create and return a new sequence object.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.  This merely means integer
C<$value E<gt>= 1>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::ReRound>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016 Kevin Ryde

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
