package Math::nSphere;

our $VERSION = '0.01';

use strict;
use warnings;
use Carp;

use Exporter qw(import);
our @EXPORT_OK = qw(nsphere_surface nsphere_volumen);

my $PI = 3.14159265358979323846264338327950288419716939937510;

my @S = ( 0 , 2 * $PI , 4 * $PI );
my @V = ( 0 ,       2 ,     $PI , 4 / 3 * $PI );

sub nsphere_surface {
    my ($n, $r) = @_;
    my $S = $S[$n];
    unless (defined $S) {
        $n = int $n;
        $n >= 0 or croak "index out of range";
        my $i = $n;
        $i -= 2 until defined $S[$i];
        $S = $S[$i];
        while ($i < $n) {
            $i += 2;
            $S[$i] = $S = 2 * $PI * $S / ($i - 1);
        }
    };
    return $S unless defined $r;
    $r ** $n * $S;
}

sub nsphere_volumen {
    my ($n, $r) = @_;
    my $V = $V[$n];
    unless (defined $V) {
        $n = int $n;
        $n >= 0 or croak "index out of range";
        my $i = $n;
        $i -= 2 until defined $V[$i];
        $V = $V[$i];
        while ($i < $n) {
            $i += 2;
            $V[$i] = $V = 2 * $PI * $V / $i;
        }
    };
    return $V unless defined $r;
    $r ** ($n + 1) * $V;
}

1;
__END__

=head1 NAME

Math::nSphere - calculate volumen and surface of n-spheres

=head1 SYNOPSIS

  use Math::nSphere qw(nsphere_surface nshepere_volumen);

  my $sur = nsphere_surface($dim - 1, $radius);
  my $vol = nsphere_volumen($dim - 1, $radius);

=head1 DESCRIPTION

This module provides functions to calculate the surface and the
volumen of n-spheres of any dimension.

Note that n + 1 equals the space dimension. For instace, a
circunference is a 1-sphere and a sphere is a 2-sphere.

=over 4

=item $sur = nsphere_surface($n, $r)

Returns the surface of the n-sphere of the given radius (1.0 by
default).

=item $vol = nsphere_volumen($n, $r)

Returns the volumen of the n-sphere of the given radius (1.0 by
default).

=back

=head1 SEE ALSO

n-sphere entry at the Wikipedia: L<http://en.wikipedia.org/wiki/N-sphere>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Salvador Fandino (sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
