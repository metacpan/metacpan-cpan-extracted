package LCS::BV;

use 5.010001;
use strict;
use warnings;
our $VERSION = '0.08';
#use utf8;

our $width = int 0.999+log(~0)/log(2);

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

  use integer;
  #no warnings 'portable'; # for 0xffffffffffffffff

  # TODO: maybe faster, if we have fewer expensive iterations
  #if (@$a < @$b) {
  #  my $temp = $a;
  #  $a = $b;
  #  $b = $temp;
  #}

  my ($amin, $amax, $bmin, $bmax) = (0, $#$a, 0, $#$b);

  #if (1) {
  while ($amin <= $amax and $bmin <= $bmax and $a->[$amin] eq $b->[$bmin]) {
    $amin++;
    $bmin++;
  }
  while ($amin <= $amax and $bmin <= $bmax and $a->[$amax] eq $b->[$bmax]) {
    $amax--;
    $bmax--;
  }
  #}

  my $positions;

  if (1 && $amax < $width ) {
    $positions->{$a->[$_]} |= 1 << ($_ % $width) for $amin..$amax;

    my $v = ~0;
    my ($p,$u);

    for ($bmin..$bmax) {
      $p = $positions->{$b->[$_]} // 0;
      $u = $v & $p;
      $v = ($v + $u) | ($v - $u);
    }
    return $amin + _count_bits(~$v) + scalar(@$a) - ($amax+1);
  }
  else {
    $positions->{$a->[$_]}->[$_ / $width] |= 1 << ($_ % $width) for $amin..$amax;

    my $S;
    my $Vs = [];      # $Vs->[$k] = bits;

    my ($p, $u, $carry);

    my $kmax = ($amax+1) / $width;
    $kmax++ if (($amax+1) % $width);

    for (my $k=0; $k < $kmax; $k++ ) { $Vs->[$k] = ~0; }

    for my $j ($bmin..$bmax) {
      $carry = 0;
      for (my $k=0; $k < $kmax; $k++ ) {
        #$S = (exists($Vs->[$k])) ? $Vs->[$k] : ~0;
        $S = $Vs->[$k];
        $p = $positions->{$b->[$j]}->[$k] // 0;
        $u = $S & $p;             # [Hyy04]
        $Vs->[$k] = ($S + $u + $carry) | ($S - $u);
        $carry = (($S & $u) | (($S | $u) & ~($S + $u + $carry))) >> ($width-1) & 1;
      }
    }

    my $bitcount = 0;

    if (@$Vs) {
      for my $k ( @{$Vs} ) {
        $bitcount += _count_bits(~$k);
      }
    }
    return $amin + $bitcount + scalar(@$a) - ($amax+1);
  }
}


sub LCS {
  my ($self, $a, $b) = @_;

  use integer;
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


  my $positions;
  my @lcs;

  if ($amax < $width ) {
    $positions->{$a->[$_]} |= 1 << ($_ % $width) for $amin..$amax;

    my $S = ~0;

    my $Vs = [];
    my ($y,$u);

    # outer loop
    for my $j ($bmin..$bmax) {
      $y = $positions->{$b->[$j]} // 0;
      $u = $S & $y;               # [Hyy04]
      $S = ($S + $u) | ($S - $u); # [Hyy04]
      $Vs->[$j] = $S;
    }

    # recover alignment
    my $i = $amax;
    my $j = $bmax;

    while ($i >= $amin && $j >= $bmin) {
      if ($Vs->[$j] & (1<<$i)) {
        $i--;
      }
      else {
        unless (
           $j
           && exists $Vs->[$j-1]
           && ~$Vs->[$j-1] & (1<<$i)
        ) {
           unshift @lcs, [$i,$j];
           $i--;
        }
        $j--;
      }
    }
  }
  else {
    $positions->{$a->[$_]}->[$_ / $width] |= 1 << ($_ % $width) for $amin..$amax;

    my $S;
    my $Vs = [];
    my ($y,$u,$carry);

    my $kmax = ($amax+1) / $width;
    $kmax++ if (($amax+1) % $width);

    # outer loop
    for my $j ($bmin..$bmax) {
      for (my $k=0; $k < $kmax; $k++ ) { $Vs->[$j]->[$k] = ~0; }
      $carry = 0;

      for (my $k=0; $k < $kmax; $k++ ) {
        $S = ($j > $bmin) ? $Vs->[$j-1]->[$k] : ~0;
        $y = $positions->{$b->[$j]}->[$k] // 0;
        $u = $S & $y;             # [Hyy04]

        $Vs->[$j]->[$k] = ($S + $u + $carry) | ($S - $u);

        $carry = (($S & $u) | (($S | $u) & ~($S + $u + $carry))) >> ($width-1) & 1;
      }
    }

    # recover alignment
    my $i = $amax;
    my $j = $bmax;

    while ($i >= $amin && $j >= $bmin) {
      my $k = $i / $width;
      if ($Vs->[$j]->[$k] & (1<<($i % $width))) {
        $i--;
      }
      else {
        unless (
           $j
           && exists $Vs->[$j-1]->[$k]
           && ~$Vs->[$j-1]->[$k] & (1<<($i % $width))
        ) {
           unshift @lcs, [$i,$j];
           $i--;
        }
        $j--;
      }
    }
  }

  return [
    map([$_ => $_], 0 .. ($bmin-1)),
    @lcs,
    map([++$amax => $_], ($bmax+1) .. $#$b)
  ];
}

sub _count_bits {
  my $v = shift;

  use integer;
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

  $alg = LCS::BV->new;
  @lcs = $alg->LCS(\@a,\@b);

=head1 ABSTRACT

LCS::BV implements Algorithm::Diff using bit vectors and
is faster in most cases, especially on strings with a length shorter
than the used wordsize of the hardware (32 or 64 bits).

=head1 DESCRIPTION

=head2 CONSTRUCTOR

=over 4

=item new()

Creates a new object which maintains internal storage areas
for the LCS computation.  Use one of these per concurrent
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

=back

=head2 EXPORT

None by design.

=head1 SEE ALSO

Algorithm::Diff

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=begin html

<a href='http://cpants.cpanauthors.org/author/wollmers'><img src='http://cpants.cpanauthors.org/author/wollmers.png' alt='Kwalitee Score' /></a>

=end html

=head1 COPYRIGHT AND LICENSE

Copyright 2014-2019 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
