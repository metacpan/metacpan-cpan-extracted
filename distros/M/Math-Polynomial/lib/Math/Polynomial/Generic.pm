# Copyright (c) 2009-2017 by Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Polynomial::Generic;

use strict;
use warnings;
use Carp qw(carp croak);

our $VERSION = '1.014';

sub import {
    croak(__PACKAGE__ . " is no longer available");
}

1;

__END__
=head1 NAME

Math::Polynomial::Generic - history of a discontinued module

=head1 REMOVAL NOTICE

Math::Polynomial::Generic was an extension of Math::Polynomial that did
not make it into a permanent release.

It had been declared experimental and its interface as not to be taken
for granted.  The intention was to give users more expressive flexibility
through a kind of polynomial object that was not bound to a particular
coefficient space.

This experiment turned out as a failure.  Coefficient spaces need to be
specified at one point, and delaying this part of proper initialization
did more harm than good in terms of clarity.

Therefore, Math::Polynomial::Generic was removed from the Math-Polynomial
distribution after a two-stage deprecation period.

Technically, before its actual removal it was replaced by an empty module
in order to neutralize incompatible code in older versions.

=head2 MIGRATION

Old code still using this module can easily be fixed.

Instead of the symbol C<X>, a variable C<$X> that is initialized as
C<Math::Polynomial-E<gt>new($zero, $one)> with appropriate coefficient
values C<$zero> and C<$one> can be used.

C<C($coeff)> can be replaced by C<Math::Polynomial-E<gt>new($coeff)>
or it can be defined locally as a small wrapper for the same.

=head1 SEE ALSO

  Math::Polynomial

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp@cozap.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2017 by Martin Becker.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 DISCLAIMER OF WARRANTY

This module is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
