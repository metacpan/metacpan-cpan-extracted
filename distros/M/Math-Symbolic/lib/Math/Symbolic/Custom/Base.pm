
=encoding utf8

=head1 NAME

Math::Symbolic::Custom::Base - Base class for tree tests and transformations

=head1 SYNOPSIS

  # Extending the Math::Symbolic::Custom class:
  package Math::Symbolic::Custom::MyTransformations;
  use Math::Symbolic::Custom::Base;
  BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}
  
  our $Aggregate_Export = [qw/apply_transformation1 .../];
  sub apply_transformation1 {
     # ...
  }

=head1 DESCRIPTION

This is a base class for your extensions to the Math::Symbolic::Custom
class.

To extend the class, just use the following template for your custom class:

  package Math::Symbolic::Custom::MyTransformations;

  use Math::Symbolic::Custom::Base;
  BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}
  
  our $Aggregate_Export = [...]; # exported subroutines listed here.
  
  # Now implement the subroutines.
  # Exported subroutine names must start with 'apply_', 'mod_',
  # 'is_', 'test_', 'contains_', or 'to_'
  
  # ...
  
  1;

=head2 EXPORT

Uses a custom exporter implementation to export certain routines from the
invoking namespace to the Math::Symbolic::Custom namespace.
But... Nevermind.

=head1 SUBROUTINES

=cut

package Math::Symbolic::Custom::Base;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.612';
our $AUTOLOAD;

=head2 aggregate_import

aggregate_import() is the only public subroutine defined by
Math::Symbolic::Custom::Base and should only be called in BEGIN blocks like
the one shown in the SYNOPSIS above.

=cut

sub aggregate_import {
    my $class = shift;
    no strict 'refs';
    my $subs = ${"${class}::Aggregate_Export"};
    foreach my $sub (@$subs) {
        *{"Math::Symbolic::Custom::$sub"} = \&{"$class\:\:$sub"};
    }
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

L<Math::Symbolic>

=cut
