package LCS::BV;

use 5.010001;
use strict;
use warnings;
our $VERSION = '0.14';
#use utf8;

our $width = int 0.999+log(~0)/log(2);

use integer;
no warnings 'portable'; # for 0xffffffffffffffff

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

# H. Hyyroe. A Note on Bit-Parallel Alignment Computation. In
# M. Simanek and J. Holub, editors, Stringology, pages 79-87. Department
# of Computer Science and Engineering, Faculty of Electrical
# Engineering, Czech Technical University, 2004.

sub LLCS {
  my ($self,$a,$b) = @_;

  #use integer;
  #no warnings 'portable'; # for 0xffffffffffffffff

  # TODO: maybe faster, if we have fewer expensive iterations
  #if (@$a < @$b) {
  #  my $temp = $a;
  #  $a = $b;
  #  $b = $temp;
  #}

  my ($amin, $amax, $bmin, $bmax) = (0, $#$a, 0, $#$b);

  while ($amin <= $amax and $bmin <= $bmax and $a->[$amin] eq $b->[$bmin]) {
    $amin++;
    $bmin++;
  }
  while ($amin <= $amax and $bmin <= $bmax and $a->[$amax] eq $b->[$bmax]) {
    $amax--;
    $bmax--;
  }

  #my %positions;

  if ($amax < $width ) {
    my %positions;
    #$positions{$a->[$_]}  |= 1 << ($_ % $width) for $amin..$amax;
    for ($amin..$amax) { $positions{$a->[$_]} |= 1 << ($_ % $width); }

    my $v = ~0;
    my ($p,$u);

    for ($bmin..$bmax) {
      $p = $positions{$b->[$_]} // 0;
      $u = $v & $p;
      $v = ($v + $u) | ($v - $u);
    }
    return $amin + _count_bits(~$v) + $#$a - $amax;
  }
  else {
    my %positions;
    #$positions{$a->[$_]}->[$_ / $width] |= 1 << ($_ % $width) for $amin..$amax;
    for ($amin..$amax) { $positions{$a->[$_]}->[$_ / $width] |= 1 << ($_ % $width); }

    my $S;
    my @Vs = ();      # $Vs->[$k] = bits;

    my ($p, $u, $carry);

    my $kmax = ($amax+1) / $width;
    $kmax++ if (($amax+1) % $width);

    for (my $k=0; $k < $kmax; $k++ ) { $Vs[$k] = ~0; }

    for my $j ($bmin..$bmax) {
      $carry = 0;
      for (my $k=0; $k < $kmax; $k++ ) {
        $S = $Vs[$k];
        $p = $positions{$b->[$j]}->[$k] // 0;
        $u = $S & $p;             # [Hyy04]
        $Vs[$k] = ($S + $u + $carry) | ($S - $u);
        $carry = (($S & $u) | (($S | $u) & ~($S + $u + $carry))) >> ($width-1) & 1;
      }
    }

    my $bitcount = 0;

    for my $k ( @Vs ) {
      $bitcount += _count_bits(~$k);
    }
    return $amin + $bitcount + $#$a - $amax;
  }
}

sub LLCS_prepared {
  my ($self,$positions,$b) = @_;

  #if ( ref($a) eq 'HASH' )    # $a contains $positions

  my ($bmin, $bmax) = (0, $#$b);
  my ($amin, $amax) = (0, $self->{'length_a'} - 1);

  if ($amax < $width ) {

    my $v = ~0;
    my ($p,$u);

    for ($bmin..$bmax) {
      $p = $positions->{$b->[$_]} // 0;
      $u = $v & $p;
      $v = ($v + $u) | ($v - $u);
    }
    return _count_bits(~$v);
  }
  else {

    my $S;
    my @Vs = ();      # $Vs->[$k] = bits;

    my ($p, $u, $carry);

    my $kmax = ($amax+1) / $width;
    $kmax++ if (($amax+1) % $width);

    for (my $k=0; $k < $kmax; $k++ ) { $Vs[$k] = ~0; }

    for my $j ($bmin..$bmax) {
      $carry = 0;
      for (my $k=0; $k < $kmax; $k++ ) {
        $S = $Vs[$k];
        $p = $positions->{$b->[$j]}->[$k] // 0;
        $u = $S & $p;             # [Hyy04]
        $Vs[$k] = ($S + $u + $carry) | ($S - $u);
        $carry = (($S & $u) | (($S | $u) & ~($S + $u + $carry))) >> ($width-1) & 1;
      }
    }

    my $bitcount = 0;

    for my $k ( @Vs ) {
      $bitcount += _count_bits(~$k);
    }
    return $bitcount;
  }
}


sub LCS {
  my ($self, $a, $b) = @_;

  #use integer;
  #no warnings 'portable'; # for 0xffffffffffffffff

  my ($amin, $amax, $bmin, $bmax) = (0, $#$a, 0, $#$b);

  while ($amin <= $amax and $bmin <= $bmax and $a->[$amin] eq $b->[$bmin]) {
    $amin++;
    $bmin++;
  }
  while ($amin <= $amax and $bmin <= $bmax and $a->[$amax] eq $b->[$bmax]) {
    $amax--;
    $bmax--;
  }

  my %positions;
  my @lcs;

  if ($amax < $width ) {
    $positions{$a->[$_]} |= 1 << ($_ % $width) for $amin..$amax;

    my $S = ~0;
    my @Vs = (~0);

    my ($y,$u);

    # outer loop
    for my $j ($bmin..$bmax) {
      $y = $positions{$b->[$j]} // 0;
      $u = $S & $y;               # [Hyy04]
      $S = ($S + $u) | ($S - $u); # [Hyy04]
      $Vs[$j] = $S;
    }

    # recover alignment
    my $i = $amax;
    my $j = $bmax;

    while ($i >= $amin && $j >= $bmin) {
      if ($Vs[$j] & (1<<$i)) {
        $i--;
      }
      else {
        unless (
           $j && ~$Vs[$j-1] & (1<<$i)
        ) {
           unshift @lcs, [$i,$j];
           $i--;
        }
        $j--;
      }
    }
  }
  else {
    $positions{$a->[$_]}->[$_ / $width] |= 1 << ($_ % $width) for $amin..$amax;

    my $S;
    my @Vs = ([~0]);
    my ($y,$u,$carry);

    my $kmax = ($amax+1) / $width;
    $kmax++ if (($amax+1) % $width);

    # outer loop
    for my $j ($bmin..$bmax) {
      for (my $k=0; $k < $kmax; $k++ ) { $Vs[$j]->[$k] = ~0; }
      $carry = 0;

      for (my $k=0; $k < $kmax; $k++ ) {
        $S = ($j > $bmin) ? $Vs[$j-1]->[$k] : ~0;
        $y = $positions{$b->[$j]}->[$k] // 0;
        $u = $S & $y;             # [Hyy04]

        $Vs[$j]->[$k] = ($S + $u + $carry) | ($S - $u);

        $carry = (($S & $u) | (($S | $u) & ~($S + $u + $carry))) >> ($width-1) & 1;
      }
    }

    # recover alignment
    my $i = $amax;
    my $j = $bmax;

    while ($i >= $amin && $j >= $bmin) {
      my $k = $i / $width;
      if ($Vs[$j]->[$k] & (1<<($i % $width))) {
        $i--;
      }
      else {
        unless (
           $j && ~$Vs[$j-1]->[$k] & (1<<($i % $width))
        ) {
           unshift @lcs, [$i,$j];
           $i--;
        }
        $j--;
      }
    }
  }

  return [
    map([$_ => $_], 0 .. ($bmin-1)), ## no critic qw(BuiltinFunctions::RequireBlockMap)
    @lcs,
    map([++$amax => $_], ($bmax+1) .. $#$b) ## no critic qw(BuiltinFunctions::RequireBlockMap)
  ];
}

sub prepare {
  my ($self, $a) = @_;

  $self->{'length_a'} = @{$a};

  my $positions;

  if ($#$a < $width ) {
    $positions->{$a->[$_]} |= 1 << ($_ % $width) for 0..$#$a;
  }
  else {
    $positions->{$a->[$_]}->[$_ / $width] |= 1 << ($_ % $width) for 0..$#$a;
  }
  return $positions;
}

sub _count_bits {
  my $v = shift;

  #use integer;
  #no warnings 'portable'; # for 0xffffffffffffffff

  if ($width == 64) {
    $v = $v - (($v >> 1) & 0x5555555555555555);
    $v = ($v & 0x3333333333333333) + (($v >> 2) & 0x3333333333333333);
    # (bytesof($v) -1) * bitsofbyte = (8-1)*8 = 56 ----------------------vv
    $v = (($v + ($v >> 4) & 0x0f0f0f0f0f0f0f0f) * 0x0101010101010101) >> 56;
    return $v;
  }
  else {
    #$v = $v - (($v >> 1) & 0x55555555);
    #$v = ($v & 0x33333333) + (($v >> 2) & 0x33333333);
    ## (bytesof($v) -1) * bitsofbyte = (4-1)*8 = 24 ------vv
    #$v = (($v + ($v >> 4) & 0x0f0f0f0f) * 0x01010101) >> 24

    my $c; # count
    for ($c = 0; $v; $c++) {
      $v &= $v - 1; # clear the least significant bit set
    }
    return $c;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LCS::BV - Bit Vector (BV) implementation of the
                 Longest Common Subsequence (LCS) Algorithm

=begin html

<a href="https://travis-ci.org/wollmers/LCS-BV"><img src="https://travis-ci.org/wollmers/LCS-BV.png" alt="LCS-BV"></a>
<a href='https://coveralls.io/r/wollmers/LCS-BV?branch=master'><img src='https://coveralls.io/repos/wollmers/LCS-BV/badge.png?branch=master' alt='Coverage Status' /></a>
<a href='http://cpants.cpanauthors.org/dist/LCS-BV'><img src='http://cpants.cpanauthors.org/dist/LCS-BV.png' alt='Kwalitee Score' /></a>
<a href="http://badge.fury.io/pl/LCS-BV"><img src="https://badge.fury.io/pl/LCS-BV.svg" alt="CPAN version" height="18"></a>

=end html

=head1 SYNOPSIS

  use LCS::BV;

  $object = LCS::BV->new;
  @lcs    = $object->LCS(\@a,\@b);

  $llcs   = $object->LLCS(\@a,\@b);

  $positions = $object->prepare(\@a);
  $llcs      = $object->LLCS_prepared($positions,\@b);


=head1 ABSTRACT

LCS::BV implements Algorithm::Diff using bit vectors and
is faster in most cases, especially on strings with a length shorter
than the used wordsize of the hardware (32 or 64 bits).

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the LCS computation. Use one of these per concurrent
LCS() call.

=back

=head2 METHODS

=over 4

=item LLCS(\@a,\@b)

Return the length of a Longest Common Subsequence, taking two arrayrefs as method
arguments. It returns an integer.

=item LCS(\@a,\@b)

Finds a Longest Common Subsequence, taking two arrayrefs as method
arguments. It returns an array reference of corresponding
indices, which are represented by 2-element array refs.

=item prepare(\@a)

For comparison of the same sequence @a many times against different sequences @b
it can be faster to prepare @a. It returns a hashref of positions.
This works only on object mode.

=item LLCS_prepared($positions,\@b)

Return the length of a Longest Common Subsequence, with one side prepared.
It returns an integer. It is two times faster than LLCS().

=back

=head2 EXPORT

None by design.

=head1 STABILITY

Until release of version 1.00 the included methods, names of methods and their
interfaces are subject to change.

Beginning with version 1.00 the specification will be stable, i.e. not changed between
major versions.

=head1 REFERENCES

H. Hyyroe. A Note on Bit-Parallel Alignment Computation.
In M. Simanek and J. Holub, editors, Stringology, pages 79-87. Department
of Computer Science and Engineering, Faculty of Electrical
Engineering, Czech Technical University, 2004.

=head1 SPEED COMPARISON

    Intel Core i7-4770HQ Processor
    Intel® SSE4.1, Intel® SSE4.2, Intel® AVX2
    4 Cores, 8 Threads
    2.20 - 3.40 GHz
    6 MB Cache
    16 GB DDR3 RAM

LCS-BV/xt$ perl 50_diff_bench.t

LCS: Algorithm::Diff, Algorithm::Diff::XS, LCS, LCS::BV

LCS: [Chrerrplzon] [Choerephon]

                Rate      LCS:LCS    AD:LCSidx AD:XS:LCSidx   LCS:BV:LCS
LCS:LCS       9225/s           --         -72%         -87%         -88%
AD:LCSidx    33185/s         260%           --         -53%         -58%
AD:XS:LCSidx 70447/s         664%         112%           --         -12%
LCS:BV:LCS   79644/s         763%         140%          13%           --

LCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]

               Rate      LCS:LCS    AD:LCSidx   LCS:BV:LCS AD:XS:LCSidx
LCS:LCS      49.5/s           --         -37%         -96%         -99%
AD:LCSidx    79.0/s          60%           --         -94%         -98%
LCS:BV:LCS   1255/s        2434%        1488%           --         -69%
AD:XS:LCSidx 4073/s        8124%        5052%         224%           --

LLCS: [Chrerrplzon] [Choerephon]

                     Rate    LCS:LLCS AD:LCS_length AD:XS:LCS_length LCS:BV:LLCS
LCS:LLCS          11270/s          --          -70%             -70%        -92%
AD:LCS_length     37594/s        234%            --              -1%        -75%
AD:XS:LCS_length  38059/s        238%            1%               --        -74%
LCS:BV:LLCS      148945/s       1222%          296%             291%          --

LLCS: [qw/a b d/ x 50], [qw/b a d c/ x 50]

                   Rate     LCS:LLCS AD:LCS_length AD:XS:LCS_length  LCS:BV:LLCS
LCS:LLCS         50.0/s           --          -37%             -37%         -98%
AD:LCS_length    79.2/s          58%            --              -1%         -97%
AD:XS:LCS_length 79.8/s          60%            1%               --         -97%
LCS:BV:LLCS      2357/s        4614%         2874%            2853%           --

=head1 SOURCE REPOSITORY

L<http://github.com/wollmers/LCS-BV>

=head1 SEE ALSO

Algorithm::Diff
LCS
LCS::Tiny

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT AND LICENSE

=encoding UTF-8

Copyright 2014-2020 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
