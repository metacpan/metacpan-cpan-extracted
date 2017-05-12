package Math::Vector::Real::Neighbors;

our $VERSION = '0.02';

use strict;
use warnings;

use Math::Vector::Real::kdTree;
use Sort::Key::Radix qw(nkeysort_inplace);

sub neighbors_slow {
    my $class = shift;
    my ($bottom, $top) = Math::Vector::Real->box(@_);
    my $box = $top - $bottom;
    my $v = [map $_ - $bottom, @_];
    my $ixs = [0..$#_];
    my $dist2 = [($box->abs2 * 10) x @_];
    my $neighbors = [(undef) x @_];
    _neighbors($v, $ixs, $dist2, $neighbors, $box, 0);
    return @$neighbors;
}

sub neighbors_bruteforce {
    my $class = shift;
    my ($bottom, $top) = Math::Vector::Real->box(@_);
    my $box = $top - $bottom;
    my $v = [map $_ - $bottom, @_];
    my $ixs = [0..$#_];
    my $dist2 = [($box->abs2 * 10) x @_];
    my $neighbors = [(undef) x @_];
    _neighbors_bruteforce($v, $ixs, $dist2, $neighbors, $box, 0);
    return @$neighbors;
}

sub neighbors_kdtree {
    shift;
    my $tree = Math::Vector::Real::kdTree->new(@_);
    map scalar($tree->find_nearest_neighbor_internal($_)), 0..$#_
}

sub neighbors_kdtree2 {
    shift;
    ( Math::Vector::Real::kdTree
      -> new(@_)
      -> find_nearest_neighbor_all_internal );
}

*neighbors = \&neighbors_kdtree2;

sub _neighbors_bruteforce {
    my ($v, $ixs, $dist2, $neighbors) = @_;
    my $ixix = 0;
    for my $i (@$ixs) {
        $ixix++;
        my $v0 = $v->[$i];
        for my $j (@$ixs[$ixix..$#$ixs]) {
            my $d2 = $v0->dist2($v->[$j]);
            if ($dist2->[$i] > $d2) {
                $dist2->[$i] = $d2;
                $neighbors->[$i] = $j;
            }
            if ($dist2->[$j] > $d2) {
                $dist2->[$j] = $d2;
                $neighbors->[$j] = $i;
            }
        }
    }
}

sub _neighbors {
    if (@{$_[1]} < 6) {
        _neighbors_bruteforce(@_);
    }
    else {
        my ($v, $ixs, $dist2, $neighbors, $box) = @_;
        my $dim = $box->max_component_index;
        nkeysort_inplace { $v->[$_][$dim] } @$ixs;

        my $bfirst = @$ixs >> 1;
        my $alast = $bfirst - 1;

        my $abox = $box->clone;
        $abox->[$dim] = $v->[$ixs->[$alast]][$dim] - $v->[$ixs->[0]][$dim];
        my $bbox = $box->clone;
        $bbox->[$dim] = $v->[$ixs->[$#$ixs]][$dim] - $v->[$ixs->[$bfirst]][$dim];

        _neighbors($v, [@$ixs[0..$alast]], $dist2, $neighbors, $abox);
        _neighbors($v, [@$ixs[$bfirst..$#$ixs]], $dist2, $neighbors, $bbox);

        for my $i (@$ixs[0..$alast]) {
            my $vi = $v->[$i];
            my $mind2 = $dist2->[$i];
            for my $j (@$ixs[$bfirst..$#$ixs]) {
                my $vj = $v->[$j];
                my $dc = $vj->[$dim] - $vi->[$dim];
                last unless ($mind2 > $dc * $dc);
                my $d2 = $vi->dist2($vj);
                if ($d2 < $mind2) {
                    $mind2 = $dist2->[$i] = $d2;
                    $neighbors->[$i] = $j;
                }
            }
        }

        for my $i (@$ixs[$bfirst..$#$ixs]) {
            my $vi = $v->[$i];
            my $mind2 = $dist2->[$i];
            for my $j (reverse @$ixs[0..$alast]) {
                my $vj = $v->[$j];
                my $dc = $vj->[$dim] - $vi->[$dim];
                last unless ($mind2 > $dc * $dc);
                my $d2 = $vi->dist2($vj);
                if ($d2 < $mind2) {
                    $mind2 = $dist2->[$i] = $d2;
                    $neighbors->[$i] = $j;
                }
            }
        }

        # my @dist2_cp = @$dist2;
        # my @neighbors_cp = @$neighbors;
        # _neighbors_bruteforce($v, $ixs, $dist2, $neighbors, $abox);
        # use 5.010;
        # say "ixs         : @$ixs";
        # say "neighbors_cp: @neighbors_cp[@$ixs]";
        # say "neighbors   : @$neighbors[@$ixs]";
    }
}

sub neighbors_bubble {
    my $class = shift;
    my @v = @_;
    my $n = sqrt(@v);
    my (@c, @r, @p); # bubbles centers, radius and points
}

sub _neighbors_bubble {}

1;
__END__

=head1 NAME

Math::Vector::Real::Neighbors - find nearest neighbor for a set of points

=head1 SYNOPSIS

  use Math::Vector::Real
  use Math::Vector::Real::Neighbors;
  use Math::Vector::Real::Random;

  my @v = map Math::Vector::Real->random_normal(2), 0..1000;

  my @nearest_ixs = Math::Vector::Real::Neighbors->neighbors(@v);

=head1 DESCRIPTION

This module is able to find for every point in a given set its nearest
neighbour from the same set.

B<Note: currently the C<neighbors> method is just a thin wrapper for
the neighbor look-up algorithm provided in
L<Math::Vector::Real::kdTree> which is a couple of orders of magnitude
faster than the old one formerly used here.

=head2 API

Two methods are currently available:

=over 4

=item @ixs = Math::Vector::Real::Neighbors->neighbors(@p)

Given a set of points returns the indexes on the set for the nearest
neighbor for every point.

=item @ixs = Math::Vector::Real::Neighbors->neighbors_bruteforce(@p)

Does the same using a brute force algorithm. This method is mostly for
testing purposes.

=back

=head1 SEE ALSO

L<Math::Vector::Real>.

The wikipedia entry for Nearest Neighbor Search L<http://en.wikipedia.org/wiki/Nearest_neighbor_search>.

L<http://cloud.github.com/downloads/salva/p5-Math-Vector-Real-Neighbors/nearest_neighbors.png>

=begin html

<image src="http://cloud.github.com/downloads/salva/p5-Math-Vector-Real-Neighbors/nearest_neighbors.png" alt="some nearest neighbor graphical representation" width="1000" heigh="1000"></image>

=end html

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2014 by Salvador FandiE<ntilde>o
E<lt>sfandino@yahoo.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
