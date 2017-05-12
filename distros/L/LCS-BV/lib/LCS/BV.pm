package LCS::BV;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.05';
#use utf8;

our $width = int 0.999+log(~0)/log(2);

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

# H. Hyyroe. A Note on Bit-Parallel Alignment Computation. In
# M. Simanek and J. Holub, editors, Stringology, pages 79-87. Department
# of Computer Science and Engineering, Faculty of Electrical
# Engineering, Czech Technical University, 2004.

sub LCS {
  my ($self, $a, $b) = @_;

  use integer;
  no warnings 'portable'; # for 0xffffffffffffffff

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
    my ($bj,$y,$u);

    # outer loop
    for my $j ($bmin..$bmax) {
      $bj = $b->[$j];
      unless (defined $positions->{$bj}) {
        $Vs->[$j] = $S;
        next;
      }
      $y = $positions->{$bj};
      $u = $S & $y;             # [Hyy04]
      $S = ($S + $u) | ($S - $u); # [Hyy04]
      $Vs->[$j] = $S;
    }

    # recover alignment
    #my @lcs;
    my $i = $amax;
    my $j = $bmax;

    while ($i >= $amin && $j >= $bmin) {
      if ($Vs->[$j] & (1<<$i)) {
        $i--;
      }
      else {
        unless ($j && ~$Vs->[$j-1] & (1<<$i)) {
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
    my ($bj,$y,$u,$carry);
    my $kmax = $amax / $width + 1;

    # outer loop
    for my $j ($bmin..$bmax) {
      $carry = 0;
      $bj = $b->[$j];

      for (my $k=0; $k < $kmax; $k++ ) {
        #$S = ($j && defined($Vs->[$j-1]->[$k])) ? $Vs->[$j-1]->[$k] : ~0;
        $S = ($j) ? $Vs->[$j-1]->[$k] : ~0;
        unless (defined $positions->{$bj}->[$k]) {
          $Vs->[$j]->[$k] = $S;
          next;
        }
        $y = $positions->{$bj}->[$k];
        $u = $S & $y;             # [Hyy04]
        #$S = ($S + $u + $carry) | ($S & ~$y);
        #$Vs->[$j]->[$k] = $S;
        $Vs->[$j]->[$k] = $S = ($S + $u + $carry) | ($S & ~$y);
        # carry = ((vv & u) | ((vv | u) & ~(vv + u + carry))) >> 63;
        $carry = (($S & $u) | (($S | $u) & ~($S + $u + $carry))) >> 63;
      }
    }

    # recover alignment
    #my @lcs;
    my $i = $amax;
    my $j = $bmax;

    while ($i >= $amin && $j >= $bmin) {
      my $k = $i / $width;
      if ($Vs->[$j]->[$k] & (1<<($i % $width))) {
        $i--;
      }
      else {
        unless ($j && ~$Vs->[$j-1]->[$k] & (1<<($i % $width))) {
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

Copyright 2014-2015 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
