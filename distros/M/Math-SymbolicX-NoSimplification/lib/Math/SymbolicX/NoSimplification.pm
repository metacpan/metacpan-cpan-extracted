package Math::SymbolicX::NoSimplification;

use 5.006;
use strict;
use warnings;

# We don't need exports
use Math::Symbolic qw();

# But we might export ourselves
require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	dont_simplify
	do_simplify
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '1.01';

# This is what we do instead of simplifying: Cloning
sub _Minimum_Simplification_Sub  {
	# Minimum simplification method clones.
	return $_[0]->new();
};

# This is where we save the simplification routines for
# later reinstallation using 'do_simplify()'
sub _Simplification_Sub_Cache {}
{
	# no warnings since we're redefining the simplify routine.
	# It is sufficient to redefine the one in ::Operator since that
	# is the only one that does anything but cloning.
	no warnings;
	*_Simplification_Sub_Cache = \&Math::Symbolic::Operator::simplify;
}

# A call to this will replace the simplify() routine in M::S::Operator with
# one that just clones (see above)
sub dont_simplify {
	no warnings;
	*Math::Symbolic::Operator::simplify =
		\&Math::SymbolicX::NoSimplification::_Minimum_Simplification_Sub;
}

# A call to this routine will undo all the damage dont_simplify() may have
# done by restoring the simplification routine in M::S::Operator from the
# backup in this module's &Simplification_Sub_Cache.
sub do_simplify {
	no warnings;
	*Math::Symbolic::Operator::simplify = \&Math::SymbolicX::NoSimplification::_Simplification_Sub_Cache;
}

# By default, if you load this module, we don't simplify.
dont_simplify();

1;
__END__

=head1 NAME

Math::SymbolicX::NoSimplification - Turn off Math::Symbolic simplification

=head1 SYNOPSIS

  use Math::SymbolicX::NoSimplification qw(:all);
  # ... code that uses Math::Symbolic ...
  # Won't use the builtin simplification routines.
  # ...
  do_simplify();
  # ... code that uses Math::Symbolic ...
  # Will use the builtin simplification routines.
  # ...
  dont_simplify();
  # ... you get the idea ...

=head1 DESCRIPTION

This module offers facilities to turn off the builtin Math::Symbolic
simplification routines and replace them with routines that just clone
the objects. You may want to do this in cases where the simplification
routines fail to simplify the Math::Symbolic trees and waste a lot of
CPU time. (For example, calculating the first order Taylor polynomial of
a moderately complex test function was sped up by 100% on my machine.)

A word of caution, however: If you turn off the simplification routines,
some procedures may produce very, very large trees. One such procedure
would be the consecutive application of many derivatives to a product
without intermediate simplification. This would yield exponential
growth of nodes. (And may, in fact, still do if you keep the simplification
heuristics turned on because most expressions cannot be simplified
significantly.)

=head2 USAGE

Just load the module to turn off simplification. To turn it back on, you
can call C<Math::SymbolicX::NoSimplification->do_simplify()> and to
turn it off again, you may call
C<Math::SymbolicX::NoSimplification->do_simplify()>. Since the module's name
is quite long, you may choose to import C<do_simplify()> and/or
C<dont_simplify()> into your namespace using standard C<Exporter> semantics.
See below.

=head2 CLASS METHODS

=over 2

=item do_simplify

Turn simplification back on.

=item dont_simplify

Turn simplification off.

=back

=head2 EXPORT

None by default, but you may choose to import either the routines
C<do_simplify()> and/or C<dont_simplify()> or both by using the
C<:all> exporter group. See also: L<Exporter>


=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN.

L<Math::Symbolic>,

=cut
