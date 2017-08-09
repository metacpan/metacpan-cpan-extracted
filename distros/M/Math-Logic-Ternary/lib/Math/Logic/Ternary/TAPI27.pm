# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::TAPI27;

use strict;
use warnings;
use Carp qw(croak);
use Math::BigInt try => 'GMP,Pari';

our $VERSION     = '0.004';

sub new {
    my ($class, @trits) = @_;
    croak "$class: class not yet fully implemented";
    return bless [map { $_->Trits } @trits], $class;
}

1;
__END__

=head1 NAME

Math::Logic::Ternary::TAPI27 - ternary arbitrary precision integer format

=head1 VERSION

This documentation refers to version 0.004 of Math::Logic::Ternary::TAPI27.

=head1 SYNOPSIS

  use Math::Logic::Ternary::TAPI27;

  $i1 = Math::Logic::Ternary::TAPI27->new(@trits);

  $i2 = $i1->Ineg;
  $i3 = $i1->Iadd($i2);
  $i3 = $i1->Isub($i2);
  $i3 = $i1->Imul($i2);
  $i3 = $i1->Idiv($i2);
  $i3 = $i1->Imod($i2);
  ($q, $r) = $i1->Idivmod($i2);
  $i3 = $i1->Ipow($i2);
  $i2 = $i1->Iabs;

  $trit = $i1->Icmp($i2);
  $trit = $i1->Iasc($i2);

  @nonets = $i1->Words(9);
  $bigint = $i1->as_int;

=head1 DESCRIPTION

This module defines an arbitrary precision ternary integer format and
emulates some basic operations on numbers of this format.

=head2 Number Format

TAPI27 numbers are coded as sequences of variable length of 27-trit words.
The first word is interpreted as a balanced ternary integer number.
It must not be negative.  It denotes the size of the actual number in
words (not including itself).  It is followed by the given number of
27-trit words ordered from least to most significant word.  Thus zero
has the smallest possible representation of a single 27-trit zero.

The largest representable number takes 3_812798_742494 words
(102_945566_047338 trits) and is equal to
C<(3 ** 102_945566_047311 - 1) / 2>, which is close to
C<2 ** 163_164861_800500> or C<4.014 * 10 ** 49_117517_640318>.

Examples (words written in most significant trit left, balanced base
27 notation):

                          -3 = ________a, ________X
                          -2 = ________a, ________Y
                          -1 = ________a, ________Z
                           0 = _________
                           1 = ________a, ________a
                           2 = ________a, ________b
                           3 = ________a, ________c
               3812798742493 = ________a, mmmmmmmmm
               3812798742494 = ________b, NNNNNNNNN, ________a
               3812798742495 = ________b, NNNNNNNNO, ________a
  29074868501520029845195084 = ________b, mmmmmmmmm, mmmmmmmmm
  29074868501520029845195085 = ________c, NNNNNNNNN, NNNNNNNNN, ________a
  29074868501520029845195086 = ________c, NNNNNNNNO, NNNNNNNNN, ________a

Note that the trits within a TAPI27 number are in the same order as in
a very large word but need only 27-trit alignment.

=head2 Class Methods

=over 4

=item new

C<Math::Logic::Ternary::TAPI27-E<gt>new(@trits)> creates a new
TAPI27 coded number from a sequence of raw trits in lowest to highest
significance order that are interpreted as a large balanced ternary
integer (without size prefix).

=back

=head2 Exports

Nothing is exported into the caller's namespace.

=head1 DEPENDENCIES

This module depends on Math::BigInt and Math::Logic::Ternary::Word.
Installing Math::BigInt::GMP or Math::BigInt::Pari should make it faster.

=head1 BUGS AND LIMITATIONS

As of version 0.004, this module is not fully implemented.
The documentation is intended as a preview of its eventual content.

However, the definition of the TAPI27 number format, as given here,
should be taken as authoritative, and can be used as a reference.

Note that there is actually a size limit for TAPI27 numbers a little
above 100 Teratrits.
Architectures built for higher precision than that should use TAPI27a
as a replacement, which is upward compatible and unlimited.

Note also that TAPI27/TAPI27a numbers on one hand and TAPI_9 numbers
on the other hand are not intended to be interoperable, beyond simple
type conversions.

=head1 SEE ALSO

=over 4

=item *

L<Math::Logic::Ternary>

=item *

L<Math::Logic::Ternary::Word>

=item *

L<Math::BigInt>

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

