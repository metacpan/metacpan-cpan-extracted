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


# http://infolab.stanford.edu/TR/CS-TR-72-269.html
# http://infolab.stanford.edu/TR/CS-TR-72-275.html

package Math::NumSeq::KlarnerRado;
use 5.004;
use strict;
use List::Util;

use vars '$VERSION', '@ISA';
$VERSION = 74;

use Math::NumSeq;
use Math::NumSeq::Base::IteratePred;
@ISA = ('Math::NumSeq::Base::IteratePred', 'Math::NumSeq');

# uncomment this to run the ### lines
#use Devel::Comments;

# use constant name => Math::NumSeq::__('Klarner-Rado');
use constant description => Math::NumSeq::__('Klarner-Rado sequence 1,2,4,5,8,9,etc being 1 and then if n in the sequence so are 2n, 3n+2 and 6n+3.');
use constant i_start => 1;

sub values_min {
  my ($self) = @_;
  return $self->{'start'};
}

use constant parameter_info_array =>
  [ { name    => 'start',
      type    => 'integer',
      default => 1,
      minimum => 1,
      width   => 3,
    },
  ];

# cf A005659   2n-2, 3n-3, starting 4
#    A005660   2n+2, 3n+3, starting 3
#    A005661   2n-2, 3n-3, starting 5
#    A005662   2n+2, 3n+3
#    A185661   2n+1, 3n+1, starting 1
#    A005658   2n+1, 3n+1, 6n+1, starting 1
#
my @oeis_anum;
$oeis_anum[1] = 'A005658';
sub oeis_anum {
  my ($self) = @_;
  return $oeis_anum[$self->{'start'}];
}

# sub rewind {
#   my ($self) = @_;
#   $self->{'i'} = $self->i_start;
# 
#   # $self->{'pending'} = { 1 => undef };
#   # $self->{'pref_ref'} = \'';
#   # $self->{'pstart'} = 0;
# }

# sub next {
#   my ($self) = @_;
#   ### KlarnerRado next(): "$self->{'i'}"
# 
#   # my $pstart = $self->{'pstart'};
#   # vec($$pref, 
#   # # my $pending = $self->{'pending'};
#   # return ($self->{'i'}++, $min);
# 
#   my $pending = $self->{'pending'};
#   my $min = List::Util::min (keys %$pending);
#   delete $pending->{$min};
#   @{$pending}{2*$min,3*$min+2,6*$min+3} = ();
#   return ($self->{'i'}++, $min);
# }

sub pred {
  my ($self, $value) = @_;
  ### KlarnerRado pred(): $value

  my $start = $self->{'start'};
  my @pending = ($value);
  for (;;) {
    ### @pending
    ### $value

    if ($value <= $start) {
      if ($value == $start) {
        return 1;
      }
      $value = pop @pending || return 0;

    } elsif ($value == 2 || $value == 4) {
      $value /= 2; # from 2k
    } elsif ($value == 5) {
      $value = 1; # from 3k+2

    } elsif ($value >= 6) {
      #         mod6
      # 2k   = 0,2, 4
      # 3k+2 =   2,   5
      # 6k+3 =     3
      #
      my $mod = ($value % 6);
      if ($mod == 0 || $mod == 4) {
        # 6k under 2n -> 3k is 0,3 mod 6
        # 6k+4 under 2n -> 3k+2 is 2,5 mod 6
        $value /= 2;

      } elsif ($mod == 2) {
        ### 6k+2 ...
        #  under 2n -> 3k+2 is 2,5 mod 6
        #  under 3n+2 -> 2k is 0,2,4 mod 6
        push @pending, ($value-2)/3;   # n <- 3n+2
        $value /= 2;                   # n <- 2n

      } elsif ($mod == 3) {
        # 6k+3 -> k
        $value -= 3;
        $value /= 6;

      } elsif ($mod == 5) {
        # 6k+5 under 3n+2 -> 2*k+1
        $value -= 2;
        $value /= 3;

      } else {
        # mod == 1
        $value = pop @pending || return 0;
      }
    } else {
      $value = pop @pending || return 0;
    }
  }
}

1;
__END__

=for stopwords Ryde Math-NumSeq Klarner-Rado

=head1 NAME

Math::NumSeq::KlarnerRado -- Klarner-Rado sequences

=head1 SYNOPSIS

 use Math::NumSeq::KlarnerRado;
 my $seq = Math::NumSeq::KlarnerRado->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

Start with 1, then for any k in the sequence then 2*k, 3*k+2 and 6*k+3 are
in the sequence too.  Thus 1,2,4,5,8,9,etc.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::KlarnerRado-E<gt>new ()>

=item C<$seq = Math::NumSeq::KlarnerRado-E<gt>new (start =E<gt> $n)>

Create and return a new sequence object.

The optional C<start> parameter can start the sequence from a value other
than 1, which changes the sequence and in general bigger values thin out the
sequence.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.

=back

=head1 FORMULAS

=head2 Predicate

Taking value mod 6 can say whether it's a descendant of one of the 2*k,
3*k+2, 6*k+3 forms, and thus give one or two reduced values to then check
for being in the sequence.

    value mod 6    descendant of       reduce to
         0           2k               value/2
         1           none             
         2           2k or 3k+2       value/2 and (value-2)/3
         3           6k+3             (value-3)/6
         4           2k               value/2
         5           3k+2             (value-2)/3

The reduction dividing out 2, 3 or 6 makes the test logarithmic, except when
2mod6 gives two reduced values to check.

=head1 SEE ALSO

L<Math::NumSeq>

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
