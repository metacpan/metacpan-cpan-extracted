#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Feature::Compat::Class 0.01;

use v5.14;
use warnings;
use feature ();

use constant HAVE_FEATURE_CLASS => defined $feature::feature{class};

=head1 NAME

C<Feature::Compat::Class> - make C<class> syntax available

=head1 SYNOPSIS

   use Feature::Compat::Class;

   class Point {
      field $x;
      field $y;

      ADJUST {
         $x = $y = 0;
      }

      method move_to ($new_x, $new_y) {
         $x = $new_x;
         $y = $new_y;
      }

      method describe {
         say "A point at ($x, $y)";
      }
   }

=head1 DESCRIPTION

This module provides the new C<class> keyword and related others (C<method>,
C<field> and C<ADJUST>) in a forward-compatible way.

There is a branch of Perl development source code which provides this syntax,
under the C<class> named feature. If all goes well, this will become available
in a stable release in due course. On such perls that contain the feature,
this module simple enables it.

On older versions of perl before such syntax is availble in core, it is
currently provided instead using the L<Object::Pad> module, imported with a
special set of options to configure it to only recognise the same syntax as
the core perl feature, thus ensuring any code using it will still continue to
function on that newer perl.

=head2 Perl Branch with C<feature 'class'>

At time of writing, the C<use feature 'class'> syntax is not part of mainline
perl source but is available in a branch. That branch currently resides at
L<https://github.com/leonerd/perl5/tree/feature-class/>. It is intended this
will be migrated to the main C<perl> repository ahead of actually being merged
once development has progressed further.

This module is a work-in-progress, because the underlying C<feature-class>
branch is too. Many of the limitations and inabilities listed below are a
result of the early-access nature of this branch, and are expected to be
lifted as work progresses towards a more featureful and complete
implementation.

=cut

sub import
{
   if( HAVE_FEATURE_CLASS ) {
      feature->import(qw( class ));
      require warnings;
      warnings->unimport(qw( experimental::class ));
   }
   else {
      require Object::Pad;
      Object::Pad->VERSION( '0.66' );
      Object::Pad->import(qw( class method field ADJUST ),
         ':config(always_strict no_class_attrs no_field_attrs)',
      );
   }
}

=head1 KEYWORDS

The keywords provided by this module offer a subset of the abilities of those
provided by C<Object::Pad>, restricted to specifically only what is commonly
supported by the core syntax as well. In general, the reader should first
consult the documentation for the corresponding C<Object::Pad> keyword, but
the following notes may be of interest:

=head2 class

   class NAME { ... }
   class NAME VERSION { ... }

   class NAME; ...
   class NAME VERSION; ...

See also L<Object::Pad/class>.

Attributes are not supported. In particular, there is no ability to declare
a superclass with C<:isa> nor any roles with C<:does>. The legacy subkeywords
for these are equally not supported.

The C<:repr> attribute is also not supported; the default representation type
will always be selected.

The C<:strict(params)> attribute is not available, but all constructed classes
will behave as if the attribute had been declared. Every generated constructor
will check its parameters for key names left unhandled by C<ADJUST> blocks,
and throw an exception if any remain.

=head2 method

   method NAME { ... }
   method NAME;

See also L<Object::Pad/method>.

Attributes are not supported, other than the usual ones provided by perl
itself. Of these, only C<:lvalue> is particularly useful.

Lexical methods are not supported.

=head2 field

   field $NAME;
   field @NAME;
   field %NAME;

See also L<Object::Pad/field>.

Attributes are not supported. In particular, rather than using the
accessor-generator attributes you will have to create accessor methods
yourself; such as

   field $var;
   method var { return $var; }
   method set_var ($new_var) { $var = $new_var; }

Field initialiser blocks are also not supported. Instead, you will have to use
an C<ADJUST> block to initialise a field:

   field $five;
   ADJUST { $five = 5; }

=head2 ADJUST

   ADJUST { ... }

See also L<Object::Pad/ADJUST>.

=head2 Other Keywords

The following other keywords provided by C<Object::Pad> are not supported here
at all:

   role

   BUILD, ADJUSTPARAMS

   has

   requires

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
