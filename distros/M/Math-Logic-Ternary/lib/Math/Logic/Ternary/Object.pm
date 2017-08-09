# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Object;

use 5.008;
use strict;
use warnings;
use Role::Basic;

our $VERSION  = '0.004';

requires qw(
    Trit Trits Rtrits Sign
    as_int as_int_u as_int_v as_string
    is_equal res_mod3
);

1;

__END__
=head1 NAME

Math::Logic::Ternary::Object - role providing trit introspection

=head1 VERSION

This documentation refers to version 0.004 of Math::Logic::Ternary::Object.

=head1 SYNOPSIS

  package Foo;

  use Role::Basic qw(with);
  with qw(Math::Logic::Ternary::Object);

  sub Trit      { ... }
  sub Trits     { ... }
  sub Rtrits    { ... }
  sub Sign      { ... }
  sub as_int    { ... }
  sub as_int_u  { ... }
  sub as_int_v  { ... }
  sub as_string { ... }
  sub is_equal  { ... }
  sub res_mod3  { ... }

=head1 DESCRIPTION

The role I<Math::Logic::Ternary::Object> defines a common interface for
trit container objects to retrieve individual trits, numerical values
and a string representation.

Classes consuming the role I<Math::Logic::Ternary::Object> have to
implement these methods:

=over 4

=item Trit

Take an integer index, return a single trit, as if the object was an
array of trits.  Return I<nil> if the index exceeds the container size.

=item Trits

In list context, return all trits in the container, from least to most
significant, including "leading" (most significant) zeroes.  In scalar
context, return the size of the container in trits.

=item Rtrits

In list context, return all trits in the container, from least to most
significant, without "leading" (most significant) zeroes.  In scalar
context, return the number of trits in the container not counting
leading zeroes.

=item Sign

Return the sign trit of the balanced ternary integer number the object
represents.  This is equivalent to the most significant non-zero trit
if that exists or zero (I<nil>) otherwise.

=item as_int

Return the balanced ternary integer number the object represents.

=item as_int_u

Return the unsigned base 3 integer number the object represents.

=item as_int_v

Return the base(-3) integer number the object represents.

=item as_string

Return a string representation of the object.

For containers, this may be a C<@> sigil, followed by a sequence of
C<n> | C<t> | C<f> characters for all trits in the container including
leading zeroes, from most to least significant trit.

For single trits, this may be a C<$> sigil followed by the name of
the trit.

=item is_equal

Take another object, return a boolean value whether both objects contain
the same sequence of trits (ignoring most significant zeroes, so that
containers of different size may compare as equal).

=item res_mod3

Return the least significant trit as an unsigned integer (0, 1, or 2).

=back

=head2 Exports

None.

=head1 SEE ALSO

=over 4

=item *

L<Math::Logic::Ternary>

=item *

L<Math::Logic::Ternary::Trit>

=item *

L<Math::Logic::Ternary::Word>

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
