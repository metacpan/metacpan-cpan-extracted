#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011-2014 -- leonerd@leonerd.org.uk

package Method::Utils;

use strict;
use warnings;

our $VERSION = '0.03';

use Exporter 'import';

our @EXPORT_OK = qw(
   maybe
   possibly

   inwardly
   outwardly
);

require mro;

=head1 NAME

C<Method::Utils> - functional-style utilities for method calls

=cut

=head1 SYNOPSIS

 use Method::Utils qw( maybe possibly inwardly );

 $obj->${maybe "do_thing"}(@args);
 # equivalent to
 #   $obj->do_thing(@args) if defined $obj;

 $obj->${possibly "do_another"}(@args);
 # equivalent to
 #   $obj->do_another(@args) if $obj->can( "do_another" );

 $obj->${inwardly "do_all_these"}();
 # invokes the method on every subclass in 'mro' order

=cut

=head1 FUNCTIONS

All of the following functions are intended to be used as method call
modifiers. That is, they return a C<SCALAR> reference to a C<CODE> reference
which allows them to be used in the following syntax

 $ball->${possibly "bounce"}( "10 metres" );

Since the returned double-reference can be dereferenced by C<${ }> to obtain
the C<CODE> reference directly, it can be used to create new methods. For
example:

 *bounce_if_you_can = ${possibly "bounce"};

This is especially useful for creating methods in base classes which
distribute across all the classes in a class heirarchy; for example

 *DESTROY = ${inwardly "COLLAPSE"};

=cut

=head2 maybe $method

Invokes the named method on the object or class, if one is provided, and
return what it returned. If invoked on C<undef>, returns C<undef> in scalar
context or the empty list in list context.

C<$method> here may also be a double-ref to a C<CODE>, such as returned by
the remaining utility functions given below. In this case, it will be
dereferenced automatically, allowing you to conveniently perform

  $obj->${maybe possibly 'method'}( @args )

=cut

sub maybe
{
   my $mth = shift;
   $mth = $$mth if ref $mth eq "REF" and ref $$mth eq "CODE";
   \sub {
      my $self = shift;
      defined $self or return;
      $self->$mth( @_ );
   };
}

=head2 possibly $method

Invokes the named method on the object or class and return what it returned,
if it exists. If the method does not exist, returns C<undef> in scalar context
or the empty list in list context.

=cut

sub possibly
{
   my $mth = shift;
   \sub {
      my $self = shift;
      return unless $self->can( $mth );
      $self->$mth( @_ );
   };
}

=head2 inwardly $method

=head2 outwardly $method

Invokes the named method on the object or class for I<every> class that
provides such a method in the C<@ISA> heirarchy, not just the first one that
is found. C<inwardly> searches all the classes in L<mro> order, finding the
class itself first and then its superclasses. C<outwardly> runs in reverse,
starting its search at the base-most superclass, searching upward before
finally ending at the class itself.

=cut

sub inwardly
{
   my $mth = shift;
   \sub {
      my $self = shift;
      foreach my $class ( @{ mro::get_linear_isa( ref $self || $self ) } ) {
         no strict 'refs';
         defined &{$class."::$mth"} or next;
         &{$class."::$mth"}( $self, @_ );
      }
   }
}

sub outwardly
{
   my $mth = shift;
   \sub {
      my $self = shift;
      foreach my $class ( reverse @{ mro::get_linear_isa( ref $self || $self ) } ) {
         no strict 'refs';
         defined &{$class."::$mth"} or next;
         &{$class."::$mth"}( $self, @_ );
      }
   }
}

=head1 TODO

=over 4

=item *

Consider C<hopefully $method>, which would C<eval{}>-wrap the call, returning
C<undef>/empty if it failed.

=item *

Consider better ways to combine more of these. E.g. C<hopefully inwardly>
would C<eval{}>-wrap each subclass call. C<inwardly> without C<possibly> would
fail if no class provides the method.

=back

=cut

=head1 SEE ALSO

=over 4

=item *

L<http://shadow.cat/blog/matt-s-trout/madness-with-methods/> - Madness With Methods

=back

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
