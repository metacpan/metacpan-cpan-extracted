package Math::Vector::Real::Random;

our $VERSION = '0.03';

package Math::Vector::Real;

use strict;
use warnings;
use Carp;

use Math::Random ();

use constant _PI => 3.14159265358979323846264338327950288419716939937510;

sub random_in_box {
    if (ref $_[0]) {
        my $box = shift;
        return bless [map Math::Random::random_uniform(1, 0, $_), @$box], ref $box;
    }
    else {
        my ($class, $dim, $size) = @_;
        $size = 1 unless defined $size;
        return bless [Math::Random::random_uniform($dim, 0, $size)], $class;
    }
}

sub random_in_sphere {
    my ($class, $dim, $size) = @_;
    $size ||= 1;
    my $n = $class->random_versor($dim);
    my $f = $size * (Math::Random::random_uniform(1, 0, 1) ** (1/$dim));
    $_ *= $f for @$n;
    $n;
}

sub random_versor {
    my ($class, $dim, $scale) = @_;
    my @n;
    $scale = 1 unless defined $scale;
    if ($dim >= 3) {
        @n = Math::Random::random_normal $dim, 0, 1;
        my $d = 0;
        $d += $_ * $_ for @n;
        unless ($d) {
            $n[0] = $scale;
        }
        else {
            $d = $scale/sqrt($d);
            $_ *= $d for @n;
        }
    }
    elsif ($dim >= 2) {
        my $ang = Math::Random::random_uniform(1, -(_PI), _PI);
        @n = ($scale * sin $ang, $scale * cos $ang);
    }
    elsif ($dim >= 1) {
        @n = (rand >= 0.5 ? $scale : -$scale);
    }
    bless \@n, $class;
}

sub random_normal {
    my ($class, $dim, $sd) = @_;
    $sd ||= 1;
    bless [Math::Random::random_normal $dim, 0, $sd], $class;
}

1;

=head1 NAME

Math::Vector::Real::Random - Generate random real vectors

=head1 SYNOPSIS

  use Math::Vector::Real qw(V);
  use Math::Vector::Real::Random;

  my $v = Math::Vector::Real->random_normal(7);
  my $v2 = $c->random_normal;

=head1 DESCRIPTION

This module extends the L<Math::Vector::Real> package adding some
methods for random generation of vectors.

=head2 Methods

The extra methods are:

=over 4

=item Math::Vector::Real->random_in_box($dim, $size)

=item $v->random_in_box

When called as a class method, returns a random vector of dimension
C<$dim> contained inside the hypercube of the given size.

When called as an instance method, returns a random vector contained
in the box defined by the given vector instance.

=item Math::Vector::Real->random_in_sphere($dim, $radio)

Returns random vector inside the hyper-sphere of the given dimension
and radio.

=item Math::Vector::Real->random_versor($dim)

Returns a randon vector of norm 1.0.

=item Math::Vector::Real->random_normal($dim, $sd)

Returns a random vector in the space of the given dimension, where
each component follows a normal distribution with standard deviation
C<$sd> (defaults to 1.0).

=back

=head1 SEE ALSO

L<Math::Vector::Real>, L<Math::Random>.

=head1 AUTHORS

Salvador Fandino, E<lt>salva@E<gt>, David Serrano.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2013 by Salvador FandiE<ntilde>o

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
