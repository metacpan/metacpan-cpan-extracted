# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::TAPI_9;

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

Math::Logic::Ternary::TAPI_9 - ternary arbitrary precision integer format

=head1 VERSION

This documentation refers to version 0.004 of Math::Logic::Ternary::TAPI_9.

=head1 SYNOPSIS

  use Math::Logic::Ternary::TAPI_9;

  $i1 = Math::Logic::Ternary::TAPI_9->new(@trits);

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

TAPI_9 numbers are coded as sequences of 9-trit words (nonets) of
variable length.  The first nonet is interpreted as a balanced ternary
integer number.  If not negative, it denotes the size of the actual number
in nonets (not including itself).  Thus zero has the smallest possible
representation of a single 9-trit zero.  If negative, its absolute value
denotes the size of the following size value in nonets.  In practice,
only two negative values are common unless huge numbers are involved:
Minus two means the size is given as another 18-trit balanced ternary
integer, and minus one means another single size nonet is following.
If that integer is also negative, the actual size follows in yet another
group of nonets, and so on.  Thus leading minus one nonets can be used
for padding.

Examples (trits written in least to most significant order):

              0 = nnnnnnnnn
              1 = tnnnnnnnn, tnnnnnnnn
              2 = tnnnnnnnn, ftnnnnnnn
              3 = tnnnnnnnn, ntnnnnnnn
           9841 = tnnnnnnnn, ttttttttt
           9842 = ftnnnnnnn, fffffffff tnnnnnnnn
           9843 = ftnnnnnnn, nffffffff tnnnnnnnn
      193710244 = ftnnnnnnn, ttttttttt ttttttttt
      193710245 = ntnnnnnnn, fffffffff fffffffff tnnnnnnnn
      193710246 = ntnnnnnnn, nffffffff fffffffff tnnnnnnnn
  3812798742493 = ntnnnnnnn, ttttttttt ttttttttt ttttttttt
  3812798742494 = ttnnnnnnn, fffffffff fffffffff fffffffff tnnnnnnnn
  3812798742495 = ttnnnnnnn, nffffffff fffffffff fffffffff tnnnnnnnn

The largest number representable with a single size nonet takes 88578
trits, all true, and is equal to C<(3 ** 88569 - 1) / 2>, which is a
42258-digit number.  The largest number representable with a minus 2
prefix followed by two size nonets takes 1743392223 trits and is equal
to C<(3 ** 1743392196 - 1) / 2>, which is an 831809472-digit number.  The
largest number with a minus 3 prefix followed by three size nonets takes
34315188682473 trits (34 Teratrits) and is about C<10 ** 16372505880106>.

=head2 Exports

Nothing is exported into the caller's namespace.

=head1 DEPENDENCIES

This module depends on Math::BigInt and Math::Logic::Ternary::Word.
Installing Math::BigInt::GMP or Math::BigInt::Pari should make it faster.

=head1 BUGS AND LIMITATIONS

As of version 0.004, this module is not fully implemented.
The documentation is intended as a preview of its eventual content.

However, the definition of the TAPI_9 number format, as given here,
should be taken as authoritative, and can be used as a reference.

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

