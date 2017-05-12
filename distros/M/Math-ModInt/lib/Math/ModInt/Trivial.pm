# Copyright (c) 2009-2015 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: Trivial.pm 60 2015-05-18 08:47:12Z demetri $

package Math::ModInt::Trivial;

use 5.006;
use strict;
use warnings;

# ----- object definition -----

# Math::ModInt::Trivial=ARRAY(...)

# .......... index ..........   # .......... value ..........
use constant NFIELDS   => 0;

# ----- class data -----

BEGIN {
    require Math::ModInt;
    our @ISA     = qw(Math::ModInt);
    our $VERSION = '0.011';
}

my $singleton = bless [];

# ----- overridden methods -----

sub _NEG { $singleton }
sub _ADD { $singleton }
sub _SUB { $singleton }
sub _MUL { $singleton }
sub _DIV { $singleton }
sub _POW { $singleton }
sub _INV { $singleton }
sub _NEW { $singleton }
sub _NEW2 { $_[1], $singleton }

sub modulus { 1 }
sub residue { 0 }
sub signed_residue { 0 }

1;

__END__

=head1 NAME

Math::ModInt::Trivial - integer arithmetic modulo one

=head1 VERSION

This documentation refers to version 0.011 of Math::ModInt::Trivial.

=head1 SYNOPSIS

  use Math::ModInt qw(mod);

  $a = mod(0, 1);                                 # 0 [mod 1]
  $b = $a->new(0);                                # 0 [mod 1]
  $c = $a + $b;                                   # 0 [mod 1]
  $d = $a**2 - $b/$a;                             # 0 [mod 1]

  print $d->residue, " [mod ", $b->modulus, "]";  # prints 0 [mod 1]
  print "$d\n";                                   # prints mod(0, 1)

  $bool = $c == $d;                               # true

=head1 DESCRIPTION

Math::ModInt::Trivial is an implementation of Math::ModInt for
modulus one.  Like all Math::ModInt implementations, it is loaded
behind the scenes when there is demand for it, without applications
needing to worry about it.

The residue class modulo one is the only ring where division by
zero is defined, because the single element is its own multiplicative
inverse.  While operating on a one-element space may seem rather
pointless, modular arithmetic would be incomplete without it, as
it is a valid quotient ring of the ring of integers.

=head1 SEE ALSO

=over 4

=item *

L<Math::ModInt>

=item *

The subject "trivial ring" on Wikipedia.
L<http://en.wikipedia.org/wiki/Trivial_ring>

=back

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp@cozap.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2015 by Martin Becker.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
