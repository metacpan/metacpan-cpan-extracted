package LCS::Tiny;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.11';
#use utf8;

sub new {
  my $class = shift;
  # uncoverable condition false
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, ref $class || $class;
}

# Implemented according to

# J. W. Hunt and T. G. Szymanski.
# A fast algorithm for computing longest common subsequences.
# Commun. ACM, 20(5):350-353, 1977.

sub LCS {
  my ($self, $a, $b) = @_;

  my ($amin, $amax, $bmin, $bmax) = (0, $#$a, 0, $#$b);

  while ($amin <= $amax and $bmin <= $bmax and $a->[$amin] eq $b->[$bmin]) {
    $amin++;
    $bmin++;
  }
  while ($amin <= $amax and $bmin <= $bmax and $a->[$amax] eq $b->[$bmax]) {
    $amax--;
    $bmax--;
  }

  my $bMatches;
  unshift @{ $bMatches->{$b->[$_]} },$_ for $bmin..$bmax;

  my $matchVector = [];
  my $thresh = [];
  my $links  = [];

  my ( $i, $ai, $j, $k );
  for ( $i = $amin ; $i <= $amax ; $i++ ) {
    $ai = $a->[$i];
    if ( exists( $bMatches->{$ai} ) ) {
      for $j ( @{ $bMatches->{$ai} } ) {
        if ( !@$thresh || $j > $thresh->[-1] ) {
          $k = $#$thresh+1;
          $thresh->[$k] = $j;
        }
        #elsif ( $k and $thresh->[$k] > $j and $thresh->[ $k - 1 ] < $j ) {
        #  $thresh->[$k] = $j;
        #}
        else {
          # binary search for insertion point
          $k = 0;
          my $index;
          my $found;
          my $high = $#$thresh;
          while ( $k <= $high ) {
            use integer;
            $index = ( $high + $k ) / 2;
            #$index = int(( $high + $k ) / 2);  # without 'use integer'
            $found = $thresh->[$index];

            if ( $j == $found ) { $k = undef; last; }
            elsif ( $j > $found ) { $k = $index + 1; }
            else { $high = $index - 1; }
          }
          # now insertion point is in $k.
          $thresh->[$k] = $j if (defined $k);    # overwrite next larger
        }
        if (defined $k) {
          $links->[$k] = [ ( $k ? $links->[ $k - 1 ] : undef ), $i, $j ];
        }
      }
    }
  }
  if (@$thresh) {
    for ( my $link = $links->[$#$thresh] ; $link ; $link = $link->[0] ) {
      unshift @$matchVector,[$link->[1],$link->[2]];
    }
  }
  return [ map([$_ => $_], 0 .. ($bmin-1)),
        @$matchVector,
            map([++$amax => $_], ($bmax+1) .. $#$b) ];
}

1;

__END__

=head1 NAME

LCS::Tiny - Tiny implementation of the
                 Longest Common Subsequence (LCS) Algorithm

=head1 SYNOPSIS

  use LCS::Tiny;

  $alg = LCS::Tiny->new;
  $lcs = $alg->LCS(\@a,\@b);

=head1 ABSTRACT

LCS::Tiny is a heavily tuned version based on Algorithm::Diff

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
arguments. It returns a list of corresponding
indices, which are represented by 2-element array refs.

=back

=head2 EXPORT

None by design.

=head1 SEE ALSO

Algorithm::Diff

=head1 REFERENCES

James W. Hunt and Thomas G. Szymanski. A fast algorithm for computing longest common
subsequences. Communications of the ACM, 20(5):350-353, 1977.

Hunt, J.W. and McIlroy, M.D. An Algorithm for Differential File Comparison.
Computing Science Technical Report 41, Bell Laboratories (1975).

=head1 AUTHOR

Helmut Wollmersdorfer E<lt>helmut.wollmersdorfer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014-2015 by Helmut Wollmersdorfer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
