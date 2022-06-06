# Copyright 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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


# period(period(...period(m)))
# p^(w+1)[m]=p^w[m]  at w=Fibonacci frequency, for w>=1
# A001178 Fibonacci frequency of n.
#


package Math::NumSeq::PisanoPeriodSteps;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 75;

use Math::NumSeq;
use Math::NumSeq::Base::IterateIth;
@ISA = ('Math::NumSeq::Base::IterateIth',
        'Math::NumSeq');
*_is_infinite = \&Math::NumSeq::_is_infinite;

use Math::NumSeq::Base::Cache
  'cache_hash';

use Math::NumSeq::NumAronson 8; # new in v.8
*_round_down_pow = \&Math::NumSeq::NumAronson::_round_down_pow;

use Math::NumSeq::PisanoPeriod;

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('...');
use constant i_start => 1;
use constant characteristic_smaller => 1;
use constant characteristic_integer => 1;
use constant values_min => 0;

use constant parameter_info_array =>
  [ { name    => 'values_type',
      display => Math::NumSeq::__('Values Type'),
      type    => 'enum',
      default => 'freq',
      choices => ['freq',
                  'log'],
      choices_display => [Math::NumSeq::__('Freq'),
                          Math::NumSeq::__('Log')],
      description => Math::NumSeq::__('The "frequency" count of steps, or the "logarithm" power in the final repeating period.'),
    },
  ];

sub description {
  my ($self) = @_;
  if (ref $self && $self->{'values_type'} eq 'log') {
    return Math::NumSeq::__('Leonardo logarithm, the "l" exponent in the final period 24*5^(l-1) on reaching an unchanging PisanoPeriod.');
  } else {
    return Math::NumSeq::__('Fibonacci frequency, how many applications of the PisanoPeriod to reach an unchanging value.')
  }
}

sub characteristic_count {
  my ($self) = @_;
  return ($self->{'values_type'} eq 'freq');
}

#------------------------------------------------------------------------------

my %oeis_anum = (freq => 'A001178',
                 log  => 'A001179',
                 # OEIS-Catalogue: A001178
                 # OEIS-Catalogue: A001179 values_type=log
                );
sub oeis_anum {
  my ($self) = @_;
  ### oeis_anum(): $self
  return $oeis_anum{$self->{'values_type'}};
}


#------------------------------------------------------------------------------

sub ith {
  my ($self, $i) = @_;
  ### PisanoPeriodSteps ith(): $i

  if (_is_infinite($i)) {
    return $i;
  }
  if ($i <= 1) {
    if ($i < 1) {
      return undef;
    }
    return 0;
  }

  my $key = "PisanoPeriodSteps:" . $self->{'values_type'};

  my $value = cache_hash()->{$key.$i};
  if (! defined $value) {
    ### calculate ...

    my $count = -1; # default undef for outside range
    my $log = -1;

    my @pending = ($i);
    if (defined ($i = $self->Math::NumSeq::PisanoPeriod::ith($i))) {
      for (;;) {
        ### at: "i=$i"

        my $p = $self->Math::NumSeq::PisanoPeriod::ith($i);
        if (! defined $p) {
          ### outside range of PisanoPeriod ...
          last;
        }
        if ($p == $i) {
          ### same: "i=$i p=$p"
          $count = 0;

          # $i is the final period, turn it into the logarithm
          $i /= 24;
          ($i, $log) = _round_down_pow ($i, 5);
          $log++;

          last;
        }
        ### not same: "i=$i p=$p"

        if (defined ($count = cache_hash()->{"PisanoPeriodSteps:freq:".$i})) {
          $log = cache_hash()->{"PisanoPeriodSteps:log:".$i};
          ### found cache: "i=$i count=$count log=$log"
          last;
        }
        push @pending, $i;
        $i = $p;
      }

      ### @pending
      foreach (reverse @pending) {
        if ($count >= 0) { $count++; }
        ### store: "$_ count $count"
        cache_hash()->{"PisanoPeriodSteps:freq:".$_} = $count;
        cache_hash()->{"PisanoPeriodSteps:log:".$_}  = $log;
      }
      $value = ($self->{'values_type'} eq 'freq' ? $count : $log);
    }
  }
  ### return: $value
  return ($value >= 0 ? $value : undef);
}

1;
__END__

# sub ith {
#   my ($self, $i) = @_;
#   ### PisanoPeriodSteps ith(): $i
#
#   if (_is_infinite($i)) {
#     return $i;
#   }
#
#   $i = $self->Math::NumSeq::PisanoPeriod::ith($i);
#   if (! defined $i) {
#     return undef;
#   }
#   my $count = 1;
#
#   for (;;) {
#     my $p = $self->Math::NumSeq::PisanoPeriod::ith($i);
#     if (! defined $p) {
#       return undef;
#     }
#     if ($p == $i) {
#       return $count;
#     }
#     $i = $p;
#     $count++;
#   }
# }

=for stopwords Ryde Math-NumSeq ie

=head1 NAME

Math::NumSeq::PisanoPeriodSteps -- Fibonacci frequency and Leonardo logarithm

=head1 SYNOPSIS

 use Math::NumSeq::PisanoPeriodSteps;
 my $seq = Math::NumSeq::PisanoPeriodSteps->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is the number of times the C<PisanoPeriod> must be applied before
reaching an unchanging value.

    0, 4, 3, 2, 3, 1, 2, 2, 1, 2, 3, 1, 3, 2, 3, 1, 2, 1, 2, ...
    starting i=1

X<Fulton, D.>X<Morris, W.L.>As per Fulton and Morris

=over

"On arithmetical functions related to the Fibonacci numbers",
Acta Arithmetica, volume 16, 1969, pages 105-110.
L<http://matwbn.icm.edu.pl/ksiazki/aa/aa16/aa1621.pdf>

=back

repeatedly applying the PisanoPeriod eventually reaches an m which is
unchanging, ie. for which PisanoPeriod(m)==m.  For example i=5 goes

    PisanoPeriod(5)=20
    PisanoPeriod(20)=60
    PisanoPeriod(60)=60
    PisanoPeriod(120)=120
    so value=3 applications until to reach unchanging 120

=head2 Leonardo Logarithm

The unchanging period reached is always of the form

    m = 24 * 5^(l-1)

The "l" exponent is the Leonardo logarithm.  Option C<values_type =E<gt>
"log"> returns that as the sequence values.

    0, 1, 1, 1, 2, 1, 1, 1, 1, 2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, ...
    starting i=1

For example the i=5 above ends at m=120=24*5^1 so l-1=1 is l=2 for the
sequence value.

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::PisanoPeriodSteps-E<gt>new ()>

=item C<$seq = Math::NumSeq::PisanoPeriodSteps-E<gt>new (values_type =E<gt> $str)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the count or logarithm of C<$i>.

=cut

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::Fibonacci>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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
