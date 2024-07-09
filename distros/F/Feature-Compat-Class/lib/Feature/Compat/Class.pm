#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2024 -- leonerd@leonerd.org.uk

package Feature::Compat::Class 0.07;

use v5.14;
use warnings;
use feature ();

use constant HAVE_FEATURE_CLASS => $^V ge v5.40;

=head1 NAME

C<Feature::Compat::Class> - make C<class> syntax available

=head1 SYNOPSIS

   use Feature::Compat::Class;

   class Point {
      field $x :param :reader = 0;
      field $y :param :reader = 0;

      method move_to ($new_x, $new_y) {
         $x = $new_x;
         $y = $new_y;
      }

      method describe {
         say "A point at ($x, $y)";
      }
   }

   Point->new(x => 5, y => 10)->describe;

=head1 DESCRIPTION

This module provides the new C<class> keyword and related others (C<method>,
C<field> and C<ADJUST>) in a forward-compatible way.

Perl added such syntax at version 5.38.0, which is enabled by

   use feature 'class';

This syntax was further expanded in 5.40, adding the C<__CLASS__> keyword and
C<:reader> attribute on fields.

On that version of perl or later, this module simply enables the core feature
equivalent of using it directly. On such perls, this module will install with
no non-core dependencies, and requires no C compiler.

On older versions of perl before such syntax is availble in core, it is
currently provided instead using the L<Object::Pad> module, imported with a
special set of options to configure it to only recognise the same syntax as
the core perl feature, thus ensuring any code using it will still continue to
function on that newer perl.

This module is a work-in-progress, because the underlying C<feature 'class'>
is too. Many of the limitations and inabilities listed below are a result of
the early-access nature of this branch, and are expected to be lifted as work
progresses towards a more featureful and complete implementation.

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
      Object::Pad->VERSION( '0.806' );
      Object::Pad->import(qw( class method field ADJUST ),
         ':experimental(init_expr)',
         ':config(' .
            'always_strict only_class_attrs=isa only_field_attrs=param,reader ' .
            'no_field_block no_adjust_attrs no_implicit_pragmata' .
         ')',
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

There is no ability to declare any roles with C<:does>. The legacy subkeywords
for these are equally not supported.

The C<:repr> attribute is also not supported; the default representation type
will always be selected.

The C<:strict(params)> attribute is not available, but all constructed classes
will behave as if the attribute had been declared. Every generated constructor
will check its parameters for key names left unhandled by C<ADJUST> blocks,
and throw an exception if any remain.

The following class attributes are supported:

=head3 :isa

   :isa(CLASS)

   :isa(CLASS CLASSVER)

I<Since version 0.02.>

Declares a superclass that this class extends. At most one superclass is
supported.

If the package providing the superclass does not exist, an attempt is made to
load it by code equivalent to

   require CLASS ();

and thus it must either already exist, or be locatable via the usual C<@INC>
mechanisms.

An optional version check can also be supplied; it performs the equivalent of

   BaseClass->VERSION( $ver )

Note that C<class> blocks B<do not> implicitly enable the C<strict> and
C<warnings> pragmata; either when using the core feature or C<Object::Pad>.
This is to avoid surprises when eventually switching to purely using the core
perl feature, which will not do that. Remember however that a C<use VERSION>
of a version C<v5.36> or above will enable both these pragmata anyway, so that
will be sufficient.

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

   field $NAME = EXPR;

   field $NAME :ATTRS... = EXPR;

See also L<Object::Pad/field>.

Most field attributes are not supported. In particular, rather than using the
accessor-generator attributes you will have to create accessor methods
yourself; such as

   field $var;
   method var { return $var; }
   method set_var ($new_var) { $var = $new_var; }

I<Since version 0.04> fields of any type may take initialising expressions.
Initialiser blocks are not supported.

   field $five = 5;

I<Since version 0.07> field initialiser expressions can see earlier fields
that have already been declared, and use their values:

   field $fullname  :param;
   field $shortname :param = ( split m/ +/, $fullname )[0];

The following field attributes are supported:

=head3 :param

   field $var :param;

   field $var :param(name)

I<Since version 0.04.>

Declares that the constructor will take a named parameter to set the value for
this field in a new instance.

   field $var :param = EXPR;

Without a defaulting expression, the parameter is mandatory. When combined
with a defaulting expression, the parameter is optional and the default will
only apply if the named parameter was not passed to the constructor.

   field $var :param //= EXPR;
   field $var :param ||= EXPR;

With both the C<:param> attribute and a defaulting expression, the operator
can also be written as C<//=> or C<||=>. In this case, the defaulting
expression will be used even if the caller passed an undefined value (for
C<//=>) or a false value (for C<||=>). This simplifies many situations where
C<undef> would not be a valid value for a field parameter.

   class C {
      field $timeout :param //= 20;
   }

   C->new( timeout => $args{timeout} );
   # default applies if %args has no 'timeout' key, or if its value is undef

=head3 :reader, :reader(NAME)

I<Since version 0.07.>

Generates a reader method to return the current value of the field. If no name
is given, the name of the field is used. A single prefix character C<_> will
be removed if present.

   field $x :reader;

   # equivalent to
   field $x;  method x { return $x }

These are permitted on an field type, not just scalars. The reader method
behaves identically to how a lexical variable would behave in the same
context; namely returning a list of values from an array or key/value pairs
from a hash when in list context, or the number of items or keys when in
scalar context.

   field @items :reader;

   foreach my $item ( $obj->items ) { ... }   # iterates the list of items

   my $count = $obj->items;                   # yields count of items

=head2 ADJUST

   ADJUST { ... }

See also L<Object::Pad/ADJUST>.

Attributes are not supported; in particular the C<:params> attribute of
C<Object::Pad> v0.70.

=head2 __CLASS__

   my $classname = __CLASS__;

I<Since version 0.07.>

Only valid within the body (or signature) of a C<method>, an C<ADJUST> block,
or the initialising expression of a C<field>. Yields the class name of the
instance that the method, block or expression is invoked on.

This is similar to the core perl C<__PACKAGE__> constant, except that it cares
about the dynamic class of the actual instance, not the static class the code
belongs to. When invoked by a subclass instance that inherited code from its
superclass it yields the name of the class of the instance regardless of which
class defined the code.

For example,

   class BaseClass {
      ADJUST { say "Constructing an instance of " . __CLASS__; }
   }

   class DerivedClass :isa(BaseClass) { }

   my $obj = DerivedClass->new;

Will produce the following output

   Constructing an instance of DerivedClass

This is particularly useful in field initialisers for invoking (constant)
methods on the invoking class to provide default values for fields. This way a
subclass could provide a different value.

   class Timer {
      use constant DEFAULT_DURATION => 60;
      field $duration = __CLASS__->DEFAULT_DURATION;
   }

   class ThreeMinuteTimer :isa(Timer) {
      use constant DEFAULT_DURATION => 3 * 60;
   }

=head2 Other Keywords

The following other keywords provided by C<Object::Pad> are not supported here
at all:

   role

   BUILD, ADJUSTPARAMS

   has

   requires

=cut

=head1 COMPATIBILITY NOTES

This module may use either L<Object::Pad> or the perl core C<class> feature to
implement its syntax. While the two behave very similarly and both conform to
the description given above, the following differences should be noted.

=over 4

=item I<No known issues at this time>

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
