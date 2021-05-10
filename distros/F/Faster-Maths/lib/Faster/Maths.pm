#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Faster::Maths 0.02;

use v5.14;
use warnings;

require XSLoader;
XSLoader::load( __PACKAGE__, our $VERSION );

=head1 NAME

C<Faster::Maths> - make mathematically-intense programs faster

=head1 SYNOPSIS

   use Faster::Maths;

   # and that's it :)

=head1 DESCRIPTION

This module installs an optimizer into the perl compiler that looks for
sequences of maths operations that it can make faster.

When this module is lexically in scope, mathematical expressions composed of
the four basic operators (C<+>, C<->, C<*>, C</>) operating on lexical
variables and constants will be compiled into a form that is more efficient at
runtime.

=cut

sub import
{
   $^H{"Faster::Maths/faster"}++;
}

sub unimport
{
   delete $^H{"Faster::Maths/faster"};
}

=head2 BUGS

=over 2

=item *

Does not currently respect operator overloading. All values will get converted
into NVs individually, and composed using regular NV maths.

We should recognise the presence of overloading magic on variables and fall
back to slower-but-correct operation in that case; also potentially ignore any
OP_CONSTs with magical values.

L<https://rt.cpan.org/Ticket/Display.html?id=136453>

=item *

Does not currently retain full integer precision on integer values larger than
platform float (NV) size. All values will get converted to NVs immediately,
thus losing the lower bits of precision if the value is too large.

L<https://rt.cpan.org/Ticket/Display.html?id=136454>

=back

=head1 TODO

=over 2

=item *

Recognise more potential arguments - padrange and package variables at least.

=item *

Recognise more operators - C<%>, unary C<-> and C<sqrt>, possibly other unary
operators like C<sin>.

=item *

Store IV/UV constants as values directly in the UNOP_AUX structure avoiding
the need for SV lookup on them.

=item *

Back-compatibility to perls older than 5.22.0 by providing an UNOP_AUX
implementation.

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
