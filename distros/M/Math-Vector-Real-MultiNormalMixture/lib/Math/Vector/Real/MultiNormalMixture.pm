package Math::Vector::Real::MultiNormalMixture;

our $VERSION = '0.02';

use 5.010;
use strict;
use warnings;
use Carp;

use Math::Vector::Real;

my $PI = 3.14159265358979323846264338327950288419716939937510;

sub new {
    my ($class, %opts) = @_;
    my $mu = delete $opts{mu} // croak "required argument 'mu' missing";
    @$mu >= 1 or die "'mu' must containt one point at least";
    my $dim = @{$mu->[0]};
    my $n = @$mu;
    my $alpha = delete $opts{alpha};
    my @alpha = (defined $alpha ? @$alpha : ((1/$n) x $n));
    my $sigma = delete $opts{sigma} // 1.0;
    my @sigma = (ref $sigma ? @$sigma : (($sigma) x $n));
    croak "bad array size" unless (@alpha == $n and @sigma == $n);
    my $c1 = (2 * $PI) ** (-0.5 * $dim);
    my @c = map $alpha[$_] * $c1 * ($sigma[$_] ** (-$dim)), (0..$#alpha);
    my @isigma2 = map 1.0/($_ * $_), @sigma;
    my $c2 = -sqrt(2.0 / $PI);
    my @second = map $c2/($_ * $_ * $_), @sigma;

    my $self = { mu => [map Math::Vector::Real::clone($_), @$mu],
                 alpha => \@alpha,
                 sigma => \@sigma,
                 isigma2 => \@isigma2,
                 c => \@c,
                 second => \@second,
                 dim => $dim,
               };
    bless $self, $class;
}

sub density {
    my ($self, $p) = @_;
    my $c = $self->{c};
    my $mu = $self->{mu};
    my $isigma2 = $self->{sigma};
    my $acu = 0;
    for (0..$#$mu) {
        $acu += $c->[$_] * exp(-$isigma2->[$_] * $mu->[$_]->dist2($p));
    }
    $acu;
}

sub density_portion {
    my $self = shift;
    my $p = shift;
        my $c = $self->{c};
    my $mu = $self->{mu};
    my $isigma2 = $self->{sigma};
    my $acu = 0;
    for (@_) {
        $acu += $c->[$_] * exp(-$isigma2->[$_] * $mu->[$_]->dist2($p));
    }
    $acu;
}

sub density_and_gradient {
    my ($self, $p) = @_;
    my $c = $self->{c};
    my $mu = $self->{mu};
    my $isigma2 = $self->{sigma};
    my $d = 0;
    my $g = $Math::Vector::Real->zero(scalar @{$mu->[0]});
    for (0..$#$mu) {
        my $mu_p = $p - $mu->[$_];
        my $isigma2 = $isigma2->[$_];
        my $Dd = $c->[$_] * exp(-$isigma2 * $mu_p->abs2);
        $d += $Dd;
        $g += -2 * $isigma2 * $mu_p * $Dd;
    }
    return ($d, $g);
}

sub max_density_estimation {
    my $self = shift;
    my $mu = $self->{mu};
    my $max = $self->density($mu->[0]);
    for my $ix (1..$#$mu) {
        my $d = $self->density($mu->[$ix]);
        # print "d: $d\n";
        $max = $d if $d > $max;
    }
    return $max;
}

1;
__END__

=head1 NAME

Math::Vector::Real::MultiNormalMixture - Multinormal Mixture distribution

=head1 SYNOPSIS

  use Math::Vector::Real::MultiNormalMixture;

  my $mnm = Math::Vector::Real::MultiNormalMixture->new(
       mu    => [[0.0, 0.0], [1.0, 0.0], [0.0, 1.5]],
       sigma => [ 1.0,        1.0,        2.0      ],
       alpha => [ 0.5,        0.25,       0.25     ]
  );

  my $d = $mnm->density([0.5, 0.2]);

=head1 DESCRIPTION

This module allows to calculate the density of a mixture of n
multivariate normal simetric distributions.

Given a multivariate normal simetric distributions in IR**k (IR := the
real numbers domain) such that its density function can be calculated
as...

  p($x) = (sqrt(2*pi)*$sigma)**(-$k) * exp(|$x-$mu|/$sigma)**2)

  where

    $x is a vector of dimension k,
    $mu is the median vector of the distribution,
    $d = |$x - $mu|, the distance between the median and x
    $sigma is the standard deviation,
    (the covariance matrix is restricted to $sigma*$Ik being $Ik
     the identity matrix of size k)

A multivariate normal distribution mixin is defined as a weighted mix
of a set of multivariate normal simetric distributions, such that its
density function is...

  pm(x) = sum ( $alpha[$i] * p[$i](x) )


=head2 API

The following methods are available:

=over 4

=item $mnm = Math::Vector::Real::MultiNormalMixture->new(%opts)

Creates a new Multivariate Normal Mixture distribution object.

The accepted arguments are as follow:

=over 4

=item mu => \@mu

An array of vectors (or array references) containing the mediams of
the single multinormal distributions.

=item alpha => \@alpha

An array of coeficients with the mixing weights. This argument is
optional.

=item sigma => \@sigma

An array with the sigma parameter for every one of the multinormal
distributions.

A single value can also be provided and all the multinormal
distributions will have it.

The default sigma value is 1.0.

=back

=item $mnm->density($x)

Returns the distribution density at the given point.


=item $mnm->density_portion($x, $i0, $i1, $i2, ...)

Returns the density portion associated to the multivariate normals with indexes
C<$i0>, C<$i1>, etc.

=item $dd = $mnm->density_and_gradient($x)

Returns density and the gradient of the density function at the given
point.

=item $d = $mnm->max_density_estimation

Returns the maximun value of the density in IR**k.

=back

=head1 SEE ALSO

Mixture distribution on the wikipedia:
L<http://en.wikipedia.org/wiki/Mixture_model>

Multivariate normal distribution on the wikipedia:
L<http://en.wikipedia.org/wiki/Multivariate_normal_distribution>.

L<Math::Vector::Real>

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Salvador Fandino

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
