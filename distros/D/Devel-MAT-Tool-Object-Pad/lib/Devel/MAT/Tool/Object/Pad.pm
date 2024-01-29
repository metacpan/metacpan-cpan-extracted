#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

package Devel::MAT::Tool::Object::Pad 0.02;

use v5.14;
use warnings;
use base qw( Devel::MAT::Tool );

use Syntax::Keyword::Match;

use List::Util qw( first );

=encoding UTF-8

=head1 NAME

C<Devel::MAT::Tool::Object::Pad> - extend C<Devel::MAT> to analyse C<Object::Pad>-based programs

=head1 DESCRIPTION

This third-party C<Devel::MAT> tool adds commands and other support to help
with analysis of programs that use L<Object::Pad>. Once installed, it is
loaded automatically by the F<pmat> shell whenever a dumpfile that uses
C<Object::Pad> is loaded.

=head1 COMMANDS

=head2 classes

Prints a list of the C<Object::Pad> classes and roles.

   pmat> classes
   role ARole at C_STRUCT(Object::Pad/ClassMeta.role) at 0x55d7c17a1550
   class HashClass at C_STRUCT(Object::Pad/ClassMeta.class) at 0x55d7c1776b70
   ...

=head2 fields

Prints the values of all the fields of a given instance of an
C<Object::Pad>-based class.

   pmat> fields 0x55d7c173d4b8
   The field AV ARRAY(3)=NativeClass at 0x55d7c173d4b8
   Ix Field   Value
   0  $sfield SCALAR(UV) at 0x55d7c173d938 = 123
   ...

=head1 EXTENSIONS TO COMMANDS

=head2 outrefs, identify, ...

Outbound references from ARRAY SVs that are the backing fields of object
instances will print elements using field names, instead of plain indexes.

   pmat> outrefs 0x55d7c173d4b8
   s  the $sfield field  SCALAR(UV) at 0x55d7c173d938
   ...

   pmat> identify 0x55d7c17606d8
   REF() at 0x55d7c17606d8 is:
   └─the %hfield field of ARRAY(3)=NativeClass at 0x55d7c173d4b8, which is:
   ...

=cut

sub AUTOLOAD_TOOL
{
   shift;
   my ( $pmat ) = @_;

   return 1 if eval { $pmat->find_symbol( '%Object::Pad::' ) };
}

sub init_tool
{
   my $self = shift;

   require Devel::MAT::Tool::Object::Pad::_SVs;
   require Devel::MAT::Tool::Object::Pad::_Commands;

   my $df = $self->df;
   my $pmat = $self->pmat;

   $self->{classes_by_name} = \my %classes_by_name;

   $self->{vtbl_ptr} = $df->root_at( "the Object::Pad backing AV VTBL" );

   my $heap_total = scalar $df->heap;
   my $count;

   # Find all the classes
   $count = 0;
   foreach my $sv ( $df->heap ) {
      $count++;
      $self->report_progress( sprintf "Finding Object::Pad structures in %d of %d (%.2f%%)",
         $count, $heap_total, 100*$count / $heap_total ) if ($count % 10000) == 0;

      next unless $sv->type eq "C_STRUCT";

      match( $sv->structtype->name : eq ) {
         case( "Object::Pad/ClassMeta.class" ) {
            bless $sv, "Devel::MAT::Tool::Object::Pad::_ClassSV";

            $classes_by_name{ $sv->objectpad_name } = $sv;

            $pmat->find_symbol( "%" . $sv->objectpad_name . "::" )->{objectpad_class_at} = $sv->addr;
         }
         case( "Object::Pad/ClassMeta.role" ) {
            bless $sv, "Devel::MAT::Tool::Object::Pad::_RoleSV";

            $classes_by_name{ $sv->objectpad_name } = $sv;

            $pmat->find_symbol( "%" . $sv->objectpad_name . "::" )->{objectpad_class_at} = $sv->addr;
         }
         case( "Object::Pad/FieldMeta" ) {
            bless $sv, "Devel::MAT::Tool::Object::Pad::_FieldSV";
         }
         case( "Object::Pad/MethodMeta" ) {
            bless $sv, "Devel::MAT::Tool::Object::Pad::_MethodSV";
         }
         case( "Object::Pad/RoleEmbedding" ) {
            bless $sv, "Devel::MAT::Tool::Object::Pad::_RoleEmbeddingSV";
         }
      }
   }

   # Find all the instances of them
   $count = 0;
   foreach my $sv ( $df->heap ) {
      $count++;
      $self->report_progress( sprintf "Finding Object::Pad instances in %d of %d (%.2f%%)",
         $count, $heap_total, 100*$count / $heap_total ) if ($count % 10000) == 0;

      my $package = $sv->blessed or next;
      my $class = $classes_by_name{ $package->stashname } or next;

      my $fieldav;

      match( $class->objectpad_repr : == ) {
         case(0) {  # REPR_NATIVE
            $fieldav = $sv;
         }
         case(1) {  # REPR_HASH
            # TODO: Signal this as some sort of error condition
            next unless $sv->type eq "HASH";

            $fieldav = $sv->value( "Object::Pad/slots" )->rv;
         }
         case(2) {  # REPR_MAGIC
            my $fieldmagic = first { $_->type eq "~" and $_->vtbl == $self->{vtbl_ptr} } $sv->magic or
               next;

            $fieldav = $fieldmagic->obj;
         }
         default {
            warn "TODO: Find fields AV for repr=" . $class->objectpad_repr;
            next;
         }
      }

      $sv->{objectpad_fields_at} = $fieldav->addr;

      bless $fieldav, "Devel::MAT::Tool::Object::Pad::_FieldAV";
      $fieldav->{objectpad_instance_at} = $sv->addr;
   }
}

sub classes_by_name
{
   my $self = shift;
   return $self->{classes_by_name};
}

=head1 SV METHODS

This tool adds the following SV methods.

=cut

=head2 objectpad_class (STASH)

   $class = $stash->objectpad_class

If the stash is the package for an C<Object::Pad>-based class, returns the
C<C_STRUCT> containing information about the class itself. Otherwise, returns
C<undef>.

=cut

# Extension to STASHes
sub Devel::MAT::SV::STASH::objectpad_class
{
   my $self = shift;
   return undef unless my $class_at = $self->{objectpad_class_at};
   return $self->df->sv_at( $class_at );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
