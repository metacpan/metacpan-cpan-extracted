
=encoding utf8

=head1 NAME

Math::Symbolic::Custom - Aggregate class for tree tests and transformations

=head1 SYNOPSIS

  # Extending the class:
  package Math::Symbolic::Custom::MyTransformations;
  use Math::Symbolic::Custom::Base;
  BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}
  
  our $Aggregate_Export = [qw/apply_transformation1 .../];
  sub apply_transformation1 {
     # ...
  }
  # ...
  
  # Using the custom class:
  use Math::Symbolic;
  use Math::Symbolic::Custom::MyTransformations;

  # later...
  $tree->apply_transformation1();
  $tree->mod_transformation2();
  die unless $tree->is_type1();
  die unless $tree->test_condition1();
  die if $tree->contains_something1();
  print $tree->to_latex();

=head1 DESCRIPTION

This is an aggregate class for all custom modification, transformation,
testing and output extensions for Math::Symbolic trees.
Some default transformations and tests are implemented in the
Math::Symbolic::Custom::DefaultMods and
Math::Symbolic::Custom::DefaultTests packages, default output
routines in Math::Symbolic::Custom::DefaultDumpers which are automatically
loaded by the Math::Symbolic::Custom class.

Math::Symbolic::Custom imports all constants from
Math::Symbolic::ExportConstants

=head2 EXPORT

None by default.

=cut

package Math::Symbolic::Custom;

use 5.006;
use strict;
use warnings;

use Carp;

use Math::Symbolic::ExportConstants qw/:all/;

our $VERSION = '0.612';
our $AUTOLOAD;

use Math::Symbolic::Custom::DefaultTests;
use Math::Symbolic::Custom::DefaultMods;
use Math::Symbolic::Custom::DefaultDumpers;

1;
__END__

=head1 EXTENDING THE MODULE

In order to extend the functionality of Math::Symbolic, you have to go
through the following steps: (also see the synopsis in this document.)

=over 4

=item

Choose an appropriate namespace in the Math::Symbolic::Custom::*
hierarchy or if you desparately wish, somewhere else.

=item

Create a new module (probably using "h2xs -AX MODULENAME") and put the
following lines of code in it:

  # To make sure we're cooperating with Math::Symbolic's idea of
  # method delegation.
  use Math::Symbolic::Custom::Base;
  BEGIN {*import = \&Math::Symbolic::Custom::Base::aggregate_import}
  
  our $Aggregate_Export = [
    # Put the list of method names to be exported.
  /];

=item

Think well about the naming of your exported methods. Answer the following
questions:

Does the name start with 'is_', 'test_', 'mod_', 'apply_', 'contains_',
or 'to_'?
If not, find a suitable name that does.

Does the name clash with any of the methods exported by
Math::Symbolic::Custom::DefaultTests, Math::Symbolic::Custom::DefaultMods,
or Math::Symbolic::Custom::DefaultDumpers?
If so, please consider choosing a different name.

Does the name map to the idea behind the method prefix ('is_', ...)?
Only methods starting with one of the prefixes listed above can be
delegated. Any others will never be called. The idea behind delegating
methods with several prefixes is to provide for a reasonable
choice for naming methods. 'is_' and 'contains_' are meant to be
used for accurate tests like "is_constant". 'test_' is meant for
all tests that either make use of heuristics or can't be fitted into
either 'is_' or 'contains_'. The prefixes 'mod_' and 'apply_' are
meant for use with methods that modify the Math::Symbolic tree.
Finally, the prefix 'to_' is meant to be used with conversion and output
methods like 'to_latex' or 'to_string'. (Though as of version 0.122,
to_string is implemented in the core Math::Symbolic modules.)

=item

Make sure you document exactly what your methods do. Do they modify the
Math::Symbolic tree in-place or do they clone using the new() constructor
and return a copy? Make sure you mention the behaviour in the docs.

=item

Consider packaging your extensions as a CPAN distribution to
help others in their development with Math::Symbolic. If you
think the extensions are generic enough to be a worthwhile
addition to the core distribution, try sending your extensions
to the Math::Symbolic developers mailing list instead.

=item

Load your extension module after loading the Math::Symbolic module.

=item

Start using your custom enhancements as methods to the Math::Symbolic
trees (any term types).

=item

Send bug reports and feedback to the Math::Symbolic support mailing list.

=back

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

L<Math::Symbolic::Custom::Base>
L<Math::Symbolic::Custom::DefaultTests>
L<Math::Symbolic::Custom::DefaultMods>
L<Math::Symbolic::Custom::DefaultDumpers>

L<Math::Symbolic>

=cut

