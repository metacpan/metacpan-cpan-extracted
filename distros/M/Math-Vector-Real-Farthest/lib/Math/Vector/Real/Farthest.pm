package Math::Vector::Real::Farthest;

our $VERSION = '0.02';

use strict;
use warnings;

use Math::Vector::Real;
use Sort::Key::Top qw(nslotpartref);
use Math::nSphere qw(nsphere_volumen);
use Carp;

our $optimization_core = 1;
our $optimization_convex_hull = 0;
our $threshold_brute_force = 16;
our $O = 0;

use constant _c0 => 0;
use constant _c1 => 1;
use constant _n  => 2;
use constant _vs => 3;
use constant _s0 => 4;
use constant _s1 => 5;

sub _find_brute_force {
    my $best_d2 = 0;
    my @best_vs = ($_[0], $_[0]);

    for my $i (0..$#_) {
        for my $j ($i + 1..$#_) {
            my $vi = $_[$i];
            my $vj = $_[$j];
            my $d2 = Math::Vector::Real::dist2($vi, $vj);
            if ($d2 > $best_d2) {
                $best_d2 = $d2;
                @best_vs = ($vi, $vj);
            }
        }
    }

    wantarray ? ($best_d2, map V(@$_), @best_vs) : $best_d2;
}

sub _find_1d {
    my $max = $_[0][0];
    my $min = $max;
    shift if @_ & 1;
    while (@_) {
        my $a = shift->[0];
        my $b = shift->[0];
        if ($a > $b) {
            $max = $a if $a > $max;
            $min = $b if $b < $min;
        }
        else {
            $max = $b if $b > $max;
            $min = $a if $a < $min;
        }
    }
    my $d = $max - $min;
    my $d2 = $d * $d;
    wantarray ? ($d2, V($min), V($max)) : $d2;
}


my $skr_loaded;
sub _find_2d_convex_hull {

    $skr_loaded++ or require Sort::Key::Radix;
    my @p = &Sort::Key::Radix::nkeysort(sub { $_->[0] }, @_);

    # use GD;
    # my $size = 1024;
    # my $im = new GD::Image($size, $size);
    # my $white = $im->colorAllocate(255,255,255);
    # my $black = $im->colorAllocate(0,0,0);
    # my $blue = $im->colorAllocate(0,0,255);
    # my $red = $im->colorAllocate(255,0,0);
    # my $green = $im->colorAllocate(0,255,0);
    # my $gray = $im->colorAllocate(200, 200, 200);
    # my $yellow = $im->colorAllocate(255, 255, 0);
    # $im->rectangle(0, 0, $size, $size, $white);
    # $im->filledEllipse($_->[0] * $size, $_->[1] * $size, 2, 2, $black) for @p;

    my (@u, @l);
    my $i = 0;
    while ($i < @p) {
        my $iu = my $il = $i;
        my ($x, $yu) = @{$p[$i]};
        my $yl = $yu;
        # search for upper and lower Y for the current X
        while (++$i < @p and $p[$i][0] == $x) {
            my $y = $p[$i][1];
            if ($y < $yl) {
                $il = $i;
                $yl = $y;
            }
            elsif ($y > $yu) {
                $iu = $i;
                $yu = $y;
            }
        }
        while (@l >= 2) {
            my ($ox, $oy) = @{$l[-2]};
            last if ($l[-1][1] - $oy) * ($x - $ox) < ($yl - $oy) * ($l[-1][0] - $ox);
            pop @l;
        }
        push @l, $p[$il];
        while (@u >= 2) {
            my ($ox, $oy) = @{$u[-2]};
            last if ($u[-1][1] - $oy) * ($x - $ox) > ($yu - $oy) * ($u[-1][0] - $ox);
            pop @u;
        }
        push @u, $p[$iu];
    }

    # $im->filledEllipse($_->[0] * $size, $_->[1] * $size, 12, 12, $blue) for @u;
    # $im->filledEllipse($_->[0] * $size, $_->[1] * $size, 12, 12, $green) for @l;

    my $u = $l[-1];
    my $l = $u[0];
    my $d = V(0,  1);
    pop @u if $u->[1] == $u[-1][1];
    shift @l if $l->[1] == $l[0][1];
    my $best_d2 = 0;
    my @best_vs = ($u, $u);
    while (1) {
        # print "u: $u, l: $l\n";
        # $im->line(map($_ * $size, @$u, @$l), $yellow);
        my $d2 = Math::Vector::Real::dist2($u, $l);
        if ($d2 > $best_d2) {
            $best_d2 = $d2;
            @best_vs = ($u, $l);
        }

        if (not @u) {
            last unless @l;
            $l = shift @l;
        }
        elsif(not @l) {
            $u = pop @u;
        }
        else {
            my $du = Math::Vector::Real::versor($u[-1] - $u);
            my $dl = Math::Vector::Real::versor($l - $l[0]);
            if ($du * $d > $dl * $d) {
                $u = pop @u;
                $d = $du;
            }
            else {
                $l = shift @l;
                $d = $dl;
            }
        }
    }


    #my ($alt_d2, @alt_vs) = _find_brute_force(@_);
    #if ($alt_d2 != $best_d2) {
    #$im->filledEllipse($_->[0] * $size, $_->[1] * $size, 8, 8, $gray) for @best_vs;
    #$im->filledEllipse($_->[0] * $size, $_->[1] * $size, 4, 4, $red) for @alt_vs;
    #open my $fh, '>', "frame.png";
    #print $fh $im->png;
    #exit -1;
    #}
    wantarray ? ($best_d2, map V(@$_), @best_vs) : $best_d2;
}

sub find {
    shift;

    return unless @_;
    my $dim = @{$_[0]};

    my @vs;
    if (@_ <= 10) {
        if (@_ <= 2) {
            # shortcut for sets of 1 and 2 elements
            my @best_vs = @_[0, -1];
            my $best_d2 = Math::Vector::Real::dist2(@best_vs);
            return (wantarray ? ($best_d2, map V(@$_), @best_vs) : $best_d2);
        }
        $dim > 1 and goto &_find_brute_force;
    }

    if ($dim <= 2) {
        # use specialized algorithm for 1D
        $dim == 1 and goto &_find_1d;

        # use specialized algorithm for 2D
        goto &_find_2d_convex_hull if $optimization_convex_hull;
    }

    my ($best_d2, @best_vs);
    ### $O++;
    my ($c0, $c1) = Math::Vector::Real->box(@_);
    my $diag = $c1 - $c0;
    my $max_comp = $diag->max_component;
    $best_d2 = $max_comp * $max_comp;
    if ($best_d2) {

        my $vs0;

        if ($optimization_core) {
            # There is a place in the center of the box which is
            # guaranteed to not contain any of the target vectors.  We
            # calculate its aproximate hyper-volumen and if it is at least
            # 10% of that of the box we filter out the points within. This
            # heuristic works well when the vectors are evenly
            # distributed.

            # Benchmarks show that this optimization can provide a
            # huge gain in some cases while non impacting performance
            # on the rest.

            my $nellipsoid_volumen = nsphere_volumen(scalar(@$diag));
            my $ncube_volumen = 1;
            my $half = 0.5 * $diag;
            my $t2 = $half->abs2 - $best_d2;
            for my $ix (0..$#$half) {
                my $y = $half->[$ix];
                my $y2 = $y * $y;
                if ($t2 + 3 * $y2 > 0) {
                    if ($y2 > $t2) {
                        $y = sqrt($y2 - $t2) - $y;
                    }
                    else {
                        $y = 0;
                    }
                }
                $nellipsoid_volumen *= $y;
                $ncube_volumen *= $diag->[$ix];
            }

            # we don't want to discard points that are at a distance
            # exactly equal to the bigest box side, so we apply a small
            # correction factor here:
            $best_d2 *= 0.99999;

            if ($nellipsoid_volumen > $ncube_volumen * 0.1) {
                # we aim at discarding at least 10% of the points
                my $zero = 0.5 * ($c0 + $c1);
                my $corner = $c0 - $zero;
                $vs0 = [grep { Math::Vector::Real::dist2($corner, ($_ - $zero)->first_orthant_reflection) > $best_d2 } @_];
            }
            else {
                $vs0 = \@_;
            }
        }
        else {
            $best_d2 *= 0.99999;
            $vs0 = \@_;
        }

        my @d2 = $diag->abs2;
        my @a = [$c0, $c1, scalar(@$vs0), $vs0];
        my @b = undef;

        while (@d2) {
            my $d2 = pop @d2;
            $d2 > $best_d2 or last;
            ### $O++;
            my $a = pop @a;
            my $b = pop @b;
            ($a, $b) = ($b, $a) if $b and $a->[_n] < $b->[_n];
            if (my $avs = $a->[_vs]) {
                if ($a->[_n] <= $threshold_brute_force) {
                    if ($b) {
                        # brute force
                        ### $O += @$avs * $b->[_n];
                        for my $v0 (@{$b->[_vs]}) {
                            for my $v1 (@$avs) {
                                my $d2 = Math::Vector::Real::dist2($v0, $v1);
                                if ($best_d2 < $d2) {
                                    $best_d2 = $d2;
                                    @best_vs = ($v0, $v1);
                                }
                            }
                        }
                    }
                    else {
                        ### $O += ((@$avs - 1) * @$avs) >> 1;
                        for my $i (1..$#$avs) {
                            my $v0 = $avs->[$i];
                            for my $v1 (@$avs[0 .. $i - 1]) {
                                my $d2 = Math::Vector::Real::dist2($v0, $v1);
                                if ($best_d2 < $d2) {
                                    $best_d2 = $d2;
                                    @best_vs = ($v0, $v1);
                                }
                            }
                        }
                    }
                    next;
                }

                # else part it in two...
                ### $O += @$avs;
                my $ix = ($a->[_c0] - $a->[_c1])->max_component_index;
                my ($avs0, $avs1) = nslotpartref $ix => @$avs / 2 => @$avs;
                $a->[_s0] = [Math::Vector::Real->box(@$avs0), scalar(@$avs0), $avs0];
                $a->[_s1] = [Math::Vector::Real->box(@$avs1), scalar(@$avs1), $avs1];
                undef $a->[_vs];

                # and fall-through...
            }

            my ($a0, $a1) = @{$a}[_s0, _s1];
            # If $b is defined we generate the combinations ($a0-$b,
            # $a1-$b), otherwise it means we want to compare a with
            # itself and so we generate the trio of pairs ($a0-$a1,
            # $a0-$a0, $a1-$a1).
            my (@na, @nb, @nd2);
            if ($b) {
                @na = ($a0, $a1);
                @nb = ($b, $b);
                @nd2 = (Math::Vector::Real->max_dist2_between_boxes(@{$a0}[_c0, _c1], @{$b}[_c0, _c1]),
                        Math::Vector::Real->max_dist2_between_boxes(@{$a1}[_c0, _c1], @{$b}[_c0, _c1]));
            }
            else {
                @na = ($a0, $a0, $a1);
                @nb = ($a1);
                @nd2 = (Math::Vector::Real->max_dist2_between_boxes(@{$a0}[_c0, _c1], @{$a1}[_c0, _c1]),
                        Math::Vector::Real::dist2(@{$a0}[_c0, _c1]),
                        Math::Vector::Real::dist2(@{$a1}[_c0, _c1]));
            }

            while (@na) {
                my $a = shift @na;
                my $b = shift @nb;
                my $d2 = shift @nd2;

                if ($d2 > $best_d2) {
                    my $p;
                    for ($p = @d2; $p > 0; $p--) {
                        ### $O++;
                        last if $d2[$p - 1] <= $d2;
                    }
                    splice @d2, $p, 0, $d2;
                    splice @a, $p, 0, $a;
                    splice @b, $p, 0, $b;
                }
            }
        }
    }
    else {
        @best_vs = ($_[0], $_[0]);
    }
    wantarray ? ($best_d2, map V(@$_), @best_vs) : $best_d2;
}

sub find_brute_force {
    shift;
    goto &_find_brute_force;
}

sub find_2d_convex_hull {
    shift;

    return unless @_;
    my $dim = @{$_[0]};
    $dim == 2 or croak "find_2d_convex_hull called with vectors of dimension $dim";

    goto &_find_2d_convex_hull;
}

1;
__END__

=head1 NAME

Math::Vector::Real::Farthest - Find the two more distant vectors from a set

=head1 SYNOPSIS

  use Math::Vector::Real::Farthest;
  my ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find(@vs);

=head1 DESCRIPTION

This module implements several algorithms for finding the maximum
distance between any two vectors from a given set (AKA the set
diameter) and some two vectors that are that far away.

=head2 METHODS

The methods available are as follows:

=over 4

=item ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find(@vs)

Returns the square of the maximum distance between any two vectors on
the given set (AKA the set diameter squared) and some two vectors
which are actually that far away.

The algorithm used in this method is quite similar to the one
described in L<"A Practical Approach for Computing the Diameter of a
Point-Set", SOCG_2001, Sariel
Har-Peled|http://sarielhp.org/p/00/diam.html>. The main difference
being that, when dividing the subset in some tree node along the
largest side of the wrapping box, instead of doing it at the middle
point it does it at the median.

The global C<$Math::Vector::Real::Farthes::threshold_brute_force>
defines the subset size at which the algorithm switches to the
brute-force algorithm (which is more efficient for small data sizes).

=item ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find_brute_force(@vs)

This is an alternative implementation of C<find> that uses the brute
force algorithm.

The C<find> method already switches automatically to the brute force
algorithm when the number of vectors is low.

This method is provided just for testing purposes. Though, note that
the vectors returned by C<find> and C<find_brute_force> for the same
given set may be different.

=item ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find_2d_convex_hull

In order to calculate the diameter of a set of bidimensional vectors,
an algorithm commonly recommended on the literature is to calculate
the convex hull of the set and then to use the rotating-calipers
method to find the two more distant vectors from it. This method
implements that algorithm.

Benchmarks show that the generic algorithm used by C<find> is usually
much faster.

See also the Wikipedia entries for L<convex
hull|http://en.wikipedia.org/wiki/Convex_hull> and L<rotating
calipers|http://en.wikipedia.org/wiki/Rotating_calipers>.

In order to use this method the extra module L<Sort::Key::Radix> must
be also installed.

=back

If this module is not fast enough for you, tell me. Maybe in a happy
day I could write a C/XS version.

=head1 SEE ALSO

L<Math::Vector::Real>.

I have found two papers describing efficient algorithms for solving
the set diameter problem. One is L<"A Practical Approach for Computing
the Diameter of a Point-Set", SOCG_2001, Sariel
Har-Peled|http://sarielhp.org/p/00/diam.html>; the other L<"Computing
the Diameter of a Point Set", INRIA 2001, Malandain, GrE<eacute>goire
and Boissonnat,
Jean-Daniel|http://www-sop.inria.fr/members/Gregoire.Malandain/diameter/>
(the links to the paper are dead, but Google is able to find the
file, look for C<dgci-2002.ps.gz>).

Note that the source code for Math::Vector::Real::Farthest is not
based on the code provided with those papers.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Salvador FandiE<ntilde>o
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
