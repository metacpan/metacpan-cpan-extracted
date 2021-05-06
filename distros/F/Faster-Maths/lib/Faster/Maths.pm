#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

package Faster::Maths 0.01;

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

=head1 TODO

=over 2

=item *

Recognise more potential arguments - padrange and package variables at least.

=item *

Recognise more operators - C<%>, unary C<-> and C<sqrt>, possibly other unary
operators like C<sin>.

=item *

Recognise the presence of overloading magic on variables and fall back to
slower-but-correct operation in that case.

=item *

Split the runtime loop into IV/UV/NV cases, further optimise the accumulator
value in each case.

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
