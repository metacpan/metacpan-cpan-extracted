# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2019, 2020 Kevin Ryde

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


#    A053615 - 0toNto0
#    A004738 - 1toNto0
# cf A165162 - Nto1,N-1to1 cf A057058 making fracs A165200
#    A010751 - runs incr then decr, up=1,down=2,up=3,down=4
#    A055087 - runs 0toNtwice  each 0 .. N, 0 .. N,
#    A055086 - n repeat floor(n/2)+1 times, DiagonalsOctant X+Y
#    A082375 - k to 0 by 2s
#    A122196 - count down by 2s
#    A111650 - 2n repeated n times
#    A000194 - n repeated 2n times
#    A111651 - n repeated 3n times
#    A111652 - 3n repeated n times
#    A121997 - 1toN repeated N times
#    A079944 - 2^n 0s then 2^n, is second highest bit of n
#    A004525 - 1 even then 3 odd, OFFSET=0
#    A007001 - 1toN repeating 1toN
#
#    A049581 diagonals absdiff, abs(x-y) not plain runs
#    A061579 descending NtoPrev, permutation of the integers
#    A076478 0 to 2^k-1, each written out in k many bits
#    A000267 1,2,3,3,4,4,5,5,5,6,6,6, twice repeat each run length
#    A122196 down by 2s
#
# to nearest pronic
# pronic(i) = i*(i+1);
# pronic_to_i_floor(n) = floor((sqrt(4*n + 1) - 1)/2);
# is_pronic(n) = n==pronic(pronic_to_i_floor(n));
# next_pronic(n) = if(is_pronic(n),n, pronic(1+pronic_to_i_floor(n)));
# prev_pronic(n) = pronic(pronic_to_i_floor(n));
# to_pronic(n) = min(next_pronic(n) - n, n - prev_pronic(n));
# to_pronic_signed(n) = my(pos=next_pronic(n)-n, neg=prev_pronic(n)-n); if(pos>-neg,neg,pos);
# vector(40,n,to_pronic(n))
# vector(40,n,to_pronic_signed(n))
# to_oddeven(n) = n=to_pronic_signed(n); if(n<=0, -2*n, 2*n-1);
# vector(40,n,to_oddeven(n))
# vector(40,n,n + to_oddeven(n))
# vector(40,n,n + to_pronic_signed(n))

package Math::NumSeq::Runs;
use 5.004;
use strict;
use Carp;

use vars '$VERSION','@ISA';
$VERSION = 75;

use Math::NumSeq 21; # v.21 for oeis_anum field
@ISA = ('Math::NumSeq');

# uncomment this to run the ### lines
#use Smart::Comments;


# use constant name => Math::NumSeq::__('Runs of Integers');
use constant description => Math::NumSeq::__('Runs of integers of various kinds.');
use constant characteristic_smaller => 1;
use constant characteristic_increasing => 0;
use constant characteristic_integer => 1;
use constant default_i_start => 0;


use constant parameter_info_array =>
  [
   {
    name    => 'runs_type',
    display => Math::NumSeq::__('Runs Type'),
    type    => 'enum',
    default => '0toN',
    choices => ['0toN',
                '0to2N',
                '1toN',
                '1to2N',
                '1toFib',
                '0toNinc',
                'Nto0',
                'Nto1',
                'Nrep',
                'N+1rep',
                '2rep',
                '3rep',
               ],
    choices_display => [Math::NumSeq::__('0toN'),
                        Math::NumSeq::__('0to2N'),
                        Math::NumSeq::__('1toN'),
                        Math::NumSeq::__('1to2N'),
                        Math::NumSeq::__('1toFib'),
                        Math::NumSeq::__('0toNinc'),
                        Math::NumSeq::__('Nto0'),
                        Math::NumSeq::__('Nto1'),
                        Math::NumSeq::__('Nrep'),
                        Math::NumSeq::__('N+1rep'),
                        Math::NumSeq::__('2rep'),
                        Math::NumSeq::__('3rep'),
                       ],
    # description => Math::NumSeq::__(''),
   },
  ];

my %runs_type_data
  = ('0toN' => { i_start    => 0,
                 value      => -1, # initial
                 values_min => 0,
                 vstart     => 0,
                 vstart_inc => 0,
                 value_inc  => 1,
                 c          => 1, # initial
                 count      => 0,
                 count_inc  => 1,
                 oeis_anum  => 'A002262',
                 # OEIS-Catalogue: A002262 runs_type=0toN
               },

     '1toN' => { i_start    => 1,
                 value      => 0, # initial
                 values_min => 1,
                 vstart     => 1,
                 vstart_inc => 0,
                 value_inc  => 1,
                 c          => 1, # initial
                 count      => 0,
                 count_inc  => 1,
                 oeis_anum  => 'A002260',  # 1 to N, is 0toN + 1
                 # OEIS-Catalogue: A002260 runs_type=1toN
               },
     '0to2N' => { i_start    => 0,
                  value      => -1, # initial
                  values_min => 0,
                  vstart     => 0,
                  vstart_inc => 0,
                  value_inc  => 1,
                  c          => 1, # initial
                  count      => 0,
                  count_inc  => 2,
                  oeis_anum  => 'A053186',
                  # OEIS-Catalogue: A053186 runs_type=0to2N
                },
     '1to2N' => { i_start    => 1,
                  value      => 0, # initial
                  values_min => 1,
                  vstart     => 1,
                  vstart_inc => 0,
                  value_inc  => 1,
                  c          => 2, # initial
                  count      => 1,
                  count_inc  => 2,
                  oeis_anum  => 'A074294',
                  # OEIS-Catalogue: A074294 runs_type=1to2N
                },
     '1to2N+1' => { i_start    => 1,
                    value      => 0, # initial
                    values_min => 1,
                    vstart     => 1,
                    vstart_inc => 0,
                    value_inc  => 1,
                    c          => 1, # initial
                    count      => 0,
                    count_inc  => 2,
                    oeis_anum  => 'A071797', # "fractal" of odds
                    # OEIS-Catalogue: A071797 runs_type=1to2N+1
                  },
     '1toFib' => { i_start    => 1,
                   value      => 0, # initial
                   values_min => 1,
                   vstart     => 1,
                   vstart_inc => 0,
                   value_inc  => 1,
                   c          => 1, # initial
                   count      => 0,
                   count_inc_func => sub {
                     my ($self) = @_;
                     (my $ret, $self->{'f0'}, $self->{'f1'})
                       = ($self->{'f0'},
                          $self->{'f1'},
                          $self->{'f0'}+$self->{'f1'});
                     return $ret-1;
                   },
                   f0 => 1,
                   f1 => 2,
                   oeis_anum  => 'A194029',  # 1 to Fibonacci(N)
                   # OEIS-Catalogue: A194029 runs_type=1toFib
                 },
     'Nto0' => { i_start    => 0,
                 value      => 1, # initial
                 values_min => 0,
                 vstart     => 0,
                 vstart_inc => 1,
                 value_inc  => -1,
                 c          => 1, # initial
                 count      => 0,
                 count_inc  => 1,
                 oeis_anum  => 'A025581',
                 # OEIS-Catalogue: A025581 runs_type=Nto0
               },
     'Nto1' => { i_start    => 1,
                 value      => 2, # initial
                 values_min => 1,
                 vstart     => 1,
                 vstart_inc => 1,
                 value_inc  => -1,
                 c          => 1, # initial
                 count      => 0,
                 count_inc  => 1,
                 oeis_anum  => 'A004736',
                 # OEIS-Catalogue: A004736 runs_type=Nto1
               },
     'Nrep' => { i_start    => 1,
                 value      => 1,
                 values_min => 1,
                 value_inc  => 0,
                 vstart     => 1,
                 vstart_inc => 1,
                 c          => 1, # initial
                 count      => 0,
                 count_inc  => 1,
                 oeis_anum  => 'A002024', # N appears N times
                 # OEIS-Catalogue: A002024 runs_type=Nrep
               },
     'N+1rep' => { i_start    => 0,
                   value      => 0,
                   values_min => 0,
                   value_inc  => 0,
                   vstart     => 0,
                   vstart_inc => 1,
                   c          => 1, # initial
                   count      => 0,
                   count_inc  => 1,
                   oeis_anum  => 'A003056', # N appears N+1 times
                   # OEIS-Catalogue: A003056 runs_type=N+1rep
                 },
     '0toNinc' => { i_start    => 0,
                    value      => -1,
                    values_min => 0,
                    value_inc  => 1,
                    vstart     => 0,
                    vstart_inc => 1,
                    c          => 1, # initial
                    count      => 0,
                    count_inc  => 1,
                    oeis_anum  => 'A051162',
                    # OEIS-Catalogue: A051162 runs_type=0toNinc
                  },
    );
# {
#   my @a = keys %runs_type_data;
#   ### assert: scalar(@{parameter_info_array()->[0]->{'choices'}}) == scalar(@a)
# }

my @rep_oeis_anum
  = ([ undef, # 0rep, nothing

       'A001477',  # 1rep, integers 0 upwards
       # OEIS-Other: A001477 runs_type=1rep

       'A004526', # 2rep, N appears 2 times, starting from 0
       # OEIS-Catalogue: A004526 runs_type=2rep

       'A002264', # 3rep, N appears 3 times
       # OEIS-Catalogue: A002264 runs_type=3rep

       'A002265', # 4rep
       # OEIS-Catalogue: A002265 runs_type=4rep

       'A002266', # 5rep
       # OEIS-Catalogue: A002266 runs_type=5rep

       'A152467', # 6rep
       # OEIS-Catalogue: A152467 runs_type=6rep

       # no, A132270 has OFFSET=1 (with 7 initial 0s)
       # 'A132270', # 7rep
       # # OEIS-Catalogue: A132270 runs_type=7rep

       # no, A132292 has OFFSET=1 (with 8 initial 0s)
       # 'A132292', # 8rep
       # # OEIS-Catalogue: A132292 runs_type=8rep

     ],

     # starting i=1
     [ undef, # 0rep, nothing

       'A000027',  # 1rep, integers 1 upwards
       # OEIS-Other: A000027 runs_type=1rep i_start=1

       # Not quite, A008619 starts OFFSET=0 value=1,1,2,2,
       # 'A008619', # 2rep, N appears 2 times, starting from 0
       # # OEIS-Catalogue: A008619 runs_type=2rep i_start=1
     ] );

sub rewind {
  my ($self) = @_;
  $self->{'runs_type'} ||= '0toN';

  my $data;
  if ($self->{'runs_type'} =~ /^(\d+)rep/) {
    my $rep = $1;
    my $i_start = ($self->{'i_start'} || 0);
    $data = { i_start    => $i_start,
              value      => $i_start,
              values_min => $i_start,
              value_inc  => 0,
              vstart     => $i_start,
              vstart_inc => 1,
              c          => $rep,   # initial
              count      => $rep-1,
              count_inc  => 0,
              oeis_anum  => ($i_start >= 0
                             ? $rep_oeis_anum[$i_start][$rep]
                             : undef),
            };
  } else {
    $data = $runs_type_data{$self->{'runs_type'}}
      || croak "Unrecognised runs_type: ", $self->{'runs_type'};
  }
  %$self = (%$self, %$data);
  $self->{'i'} = $self->i_start;
}

sub next {
  my ($self) = @_;
  my $i = $self->{'i'}++;
  if (--$self->{'c'} >= 0) {
    return ($i,
            ($self->{'value'} += $self->{'value_inc'}));
  } else {
    if (my $func = $self->{'count_inc_func'}) {
      $self->{'c'} = &$func($self);
    } else {
      $self->{'c'} = ($self->{'count'} += $self->{'count_inc'});
    }
    return ($i,
            ($self->{'value'} = ($self->{'vstart'} += $self->{'vstart_inc'})));
  }
}

sub ith {
  my ($self, $i) = @_;
  ### Runs ith(): $i

  my $i_start = $self->{'i_start'};
  if ($i < $i_start) {
    return undef;
  }

  if ($self->{'runs_type'} eq 'Nto0' || $self->{'runs_type'} eq 'Nto1') {
    # d-(i-(d-1)*d/2)
    #   = d-i+(d-1)*d/2
    #   = d*(1+(d-1)/2) - i
    #   = d*((d+1)/2) - i
    #   = (d+1)d/2 - i

    $i -= $self->{'i_start'};
    my $d = int((sqrt(8*$i+1) + 1) / 2);
    ### $d
    ### base: ($d-1)*$d/2
    ### rem: $i - ($d-1)*$d/2
    return -$i + ($d+1)*$d/2 - 1 + $self->{'values_min'};

  } elsif ($self->{'runs_type'} eq 'Nrep'
           || $self->{'runs_type'} eq 'N+1rep') {
    $i -= $self->{'i_start'};
    return int((sqrt(8*$i+1) - 1) / 2) + $self->{'values_min'};

  } elsif ($self->{'runs_type'} eq '0toNinc') {
    # i-(d-1)d/2 + d
    #   = i-((d-1)d/2 - d)
    #   = i-(d-3)d/2
    my $d = int((sqrt(8*$i+1) + 1) / 2);
    return $i - ($d-3)*$d/2 - 1;

  } elsif ($self->{'runs_type'} =~ /^(\d+)rep/) {
    my $rep = $1;
    ### $rep
    if ($rep < 1) {
      return undef;
    }
    return int($i/$rep);

  } elsif ($self->{'runs_type'} eq '1to2N') {
    # runs beginning i=1,3,7,13,21,31    (Math::NumSeq::Pronic + 1)
    # N = (d^2 - d + 1)
    #   = ($d**2 - $d + 1)
    #   = (($d - 1)*$d + 1)
    # d = 1/2 + sqrt(1 * $n + -3/4)
    #   = (1 + sqrt(4*$n - 3)) / 2

    my $d = int( (sqrt(4*$i-3) + 1) / 2);

    ### $d
    ### base: ($d-1)*$d/2
    ### rem: $i - ($d-1)*$d/2

    return $i - ($d-1)*$d;

  } elsif ($self->{'runs_type'} eq '0to2N'
           || $self->{'runs_type'} eq '1to2N+1') {
    ### 1to2N+1 ...
    # values 1, 1,2,3, 1,2,3,4,5
    # run beginning i=1,2,5,10,17,26
    # N = (d^2 - 2 d + 2), starting d=1
    # d = 1 + sqrt(1 * $n + -1)
    #   = 1 + sqrt($n-1)

    $i -= $self->{'i_start'};
    my $d = int(sqrt($i)) + 1;

    ### $d
    ### base: ($d-2)*$d
    ### rem: $i - ($d-2)*$d

    return $i - ($d-2)*$d + $self->{'vstart'}-1;

  } elsif ($self->{'runs_type'} eq '1toFib') {
    my $f0 = ($i*0) + 1;  # inherit bignum 1
    my $f1 = $f0 + 1;     # inherit bignum 2
    while ($f1 <= $i) {
      ($f0,$f1) = ($f1,$f0+$f1);
    }
    return $i - $f0 + 1;

  } else { # 0toN, 1toN
    $i -= $i_start;
    my $d = int((sqrt(8*$i+1) + 1) / 2);

    ### $d
    ### base: ($d-1)*$d/2
    ### rem: $i - ($d-1)*$d/2

    return $i - ($d-1)*$d/2 + $self->{'vstart'};
  }
}

sub pred {
  my ($self, $value) = @_;
  ### Runs pred(): $value

  unless ($value == int($value)) {
    return 0;
  }
  if (defined $self->{'values_min'}) {
    return ($value >= $self->{'values_min'});
  } else {
    return ($value <= $self->{'values_max'});
  }
}

1;
__END__

=for stopwords Ryde 0toN 1toN ie pronic 1toFib Math-NumSeq

=head1 NAME

Math::NumSeq::Runs -- runs of consecutive integers

=head1 SYNOPSIS

 use Math::NumSeq::Runs;
 my $seq = Math::NumSeq::Runs->new;
 my ($i, $value) = $seq->next;

=head1 DESCRIPTION

This is various kinds of runs of integers.  The C<runs_type> parameter (a
string) can be

    "0toN"      0, 0,1, 0,1,2, 0,1,2,3, etc runs 0..N
    "1toN"      1, 1,2, 1,2,3, 1,2,3,4, etc runs 1..N
    "1to2N"     1,2, 1,2,3,4, 1,2,3,4,5,6 etc runs 1..2N
    "1to2N+1"   1, 1,2,3, 1,2,3,4,5, etc runs 1..2N+1
    "1toFib"    1, 1, 1,2, 1,2,3,  1,2,3,4,5 etc runs 1..Fibonacci
    "Nto0"      0, 1,0, 2,1,0, 3,2,1,0, etc runs N..0
    "Nto1"      1, 2,1, 3,2,1, 4,3,2,1, etc runs N..1
    "0toNinc"   0, 1,2, 2,3,4, 3,4,5,6, etc runs 0..N increasing
    "Nrep"      1, 2,2, 3,3,3, 4,4,4,4, etc N repetitions of N
    "N+1rep"    0, 1,1, 2,2,2, 3,3,3,3, etc N+1 repetitions of N
    "2rep"      0,0, 1,1, 2,2, etc two repetitions of each N
    "3rep"      0,0,0, 1,1,1, 2,2,2, etc three repetitions of N

"0toN" and "1toN" differ only the latter being +1.  They're related to the
triangular numbers (L<Math::NumSeq::Triangular>) in that each run starts at
index i=Triangular+1, ie. i=1,2,4,7,11,etc.

"1to2N" is related to the pronic numbers (L<Math::NumSeq::Pronic>) in that
each run starts at index i=Pronic+1, ie. i=1,3,7,13,etc.

"1toFib" not only runs up to each Fibonacci number
(L<Math::NumSeq::Fibonacci>), but the runs start at i=Fibonacci too,
ie. i=1,2,3,5,8,13,etc.  This arises because the cumulative total of
Fibonacci numbers has F[1]+F[2]+...+F[k]+1 = F[k+2].

=head1 FUNCTIONS

See L<Math::NumSeq/FUNCTIONS> for behaviour common to all sequence classes.

=over 4

=item C<$seq = Math::NumSeq::Runs-E<gt>new (runs_type =E<gt> $str)>

Create and return a new sequence object.

=back

=head2 Random Access

=over

=item C<$value = $seq-E<gt>ith($i)>

Return the C<$i>'th value from the sequence.

=item C<$bool = $seq-E<gt>pred($value)>

Return true if C<$value> occurs in the sequence.  This is merely all integer
C<$value E<gt>= 0> or C<E<gt>= 1> according to the start of the
C<runs_type>.

=back

=head1 SEE ALSO

L<Math::NumSeq>,
L<Math::NumSeq::AllDigits>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/math-numseq/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2019, 2020 Kevin Ryde

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
