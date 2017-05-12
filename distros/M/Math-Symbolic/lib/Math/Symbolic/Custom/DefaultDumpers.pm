
=encoding utf8

=head1 NAME

Math::Symbolic::Custom::DefaultDumpers - Default Math::Symbolic output routines

=head1 SYNOPSIS

  use Math::Symbolic qw/parse_from_string/;
  $term = parse_from_string(...);
  my ($sub, $leftover_trees) = $term->to_sub();

=head1 DESCRIPTION

This is a class of default output routines for Math::Symbolic trees. Likewise,
Math::Symbolic::Custom::DefaultTests defines default tree testing
routines and Math::Symbolic::Custom::DefaultMods has default tree modification
methods.
For details on how the custom method delegation model works, please have
a look at the Math::Symbolic::Custom and Math::Symbolic::Custom::Base
classes.

=head2 EXPORT

Please see the docs for Math::Symbolic::Custom::Base for details, but
you should not try to use the standard Exporter semantics with this
class.

=head1 SUBROUTINES

=cut

package Math::Symbolic::Custom::DefaultDumpers;

use 5.006;
use strict;
use warnings;
no warnings 'recursion';

our $VERSION = '0.612';

use Math::Symbolic::Custom::Base;
BEGIN { *import = \&Math::Symbolic::Custom::Base::aggregate_import }

use Math::Symbolic::ExportConstants qw/:all/;

use Carp;

# Class Data: Special variable required by Math::Symbolic::Custom
# importing/exporting functionality.
# All subroutines that are to be exported to the Math::Symbolic::Custom
# namespace should be listed here.

our $Aggregate_Export = [
    qw/
      to_code
      to_sub
      /
];

=head2 to_string

The to_string method is currently implemented in the module core namespaces
and will be moved to Math::Symbolic::DefaultDumpers in a future release.

Takes one optional argument indicating whether the Math::Symbolic tree should
be transformed to a string using 'postfix' notation or using 'infix' notation.
Default is infix which is also more likely to be reparseable by the
Math::Symbolic parser.

=head2 to_code

This method is a wrapper around the compile_to_code class method in the
Math::Symbolic::Compiler module. Takes key/value pairs of variables and
integers as argument. The integers should starting at 0 and they determine
the order of the variables/parameters to the compiled code.

Returns the compiled code and a reference to an array of possible leftover
tree elements that could not be compiled.

Please refer to the Math::Symbolic::Compiler man page for details.

=cut

sub to_code {
    my $self = shift;
    my $args = [@_];    # \@_ would be evil. @_ is not a real Perl array
    return Math::Symbolic::Compiler->compile_to_code( $self, $args );
}

=head2 to_sub

This method is a wrapper around the compile_to_sub class method in the
Math::Symbolic::Compiler module. Takes key/value pairs of variables and
integers as argument. The integers should starting at 0 and they determine
the order of the variables/parameters to the compiled code.

Returns the compiled sub and a reference to an array of possible leftover
tree elements that could not be compiled.

Please refer to the Math::Symbolic::Compiler man page for details.

=cut

sub to_sub {
    my $self = shift;
    my $args = [@_];    # \@_ would be evil. @_ is not a real Perl array
    return Math::Symbolic::Compiler->compile_to_sub( $self, $args );
}

1;
__END__

=head1 AUTHOR

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

List of contributors:

  Steffen Müller, symbolic-module at steffen-mueller dot net
  Stray Toaster, mwk at users dot sourceforge dot net
  Oliver Ebenhöh

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN. The module development takes place on
Sourceforge at http://sourceforge.net/projects/math-symbolic/

L<Math::Symbolic::Custom>
L<Math::Symbolic::Custom::DefaultMods>
L<Math::Symbolic::Custom::DefaultTests>
L<Math::Symbolic>

=cut
