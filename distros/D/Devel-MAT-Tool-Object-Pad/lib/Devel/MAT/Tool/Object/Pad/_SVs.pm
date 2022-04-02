#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

use v5.14;
use warnings;

package Devel::MAT::Tool::Object::Pad::_SVs;

use Devel::MAT::SV;

use List::Util qw( first );

my $field_index_for = sub {
   my $self = shift;
   my ( $name ) = @_;

   my $fields = $self->structtype->fields;

   return first { $fields->[$_]->name eq $name } 0 .. $#$fields;
};

my $make_accessor = sub {
   my ( $name ) = @_;

   return sub {
      my $self = shift;
      state $idx = $self->$field_index_for( $name );
      return $self->field( $idx );
   };
};

my $make_sv_accessor = sub {
   my ( $name ) = @_;

   return sub {
      my $self = shift;
      state $idx = $self->$field_index_for( $name );
      return $self->df->sv_at( $self->field( $idx ) );
   };
};

my $make_sv_pv_accessor = sub {
   my ( $name ) = @_;

   return sub {
      my $self = shift;
      state $idx = $self->$field_index_for( $name );
      return $self->df->sv_at( $self->field( $idx ) )->pv;
   };
};

my $make_sv_elems_accessor = sub {
   my ( $name ) = @_;

   return sub {
      my $self = shift;
      state $idx = $self->$field_index_for( $name );
      return $self->df->sv_at( $self->field( $idx ) )->elems;
   };
};

package # hide
   Devel::MAT::Tool::Object::Pad::_ClassSV;
use base qw( Devel::MAT::SV::C_STRUCT );

*objectpad_name = $make_sv_pv_accessor->( "the name SV" );

*objectpad_type = $make_accessor->( "type" );

*objectpad_repr = $make_accessor->( "repr" );

*objectpad_superclass = $make_sv_accessor->( "the supermeta" );

*objectpad_direct_fields = $make_sv_elems_accessor->( "the direct fields AV" );

*objectpad_direct_roles = $make_sv_elems_accessor->( "the direct roles AV" );

sub objectpad_fieldnames_by_idx
{
   my $self = shift;
   return $self->{objectpad_fieldnames_by_idx} //= do {
      my @fieldnames;
      $self->_objectpad_fieldnames_for_class( \@fieldnames, $self );
      \@fieldnames;
   };
}

sub _objectpad_fieldnames_for_class
{
   my $self = shift;
   my ( $fieldnames, $classmeta, $nameprefix, $offset ) = @_;
   $offset //= 0;

   my $is_class = $classmeta->objectpad_type == 0;

   if( $is_class and my $superclass = $classmeta->objectpad_superclass ) {
      $self->_objectpad_fieldnames_for_class( $fieldnames, $superclass, $superclass->objectpad_name );
   }

   foreach my $fieldmeta ( $classmeta->objectpad_direct_fields ) {
      my $name    = $fieldmeta->objectpad_name;
      my $fieldix = $fieldmeta->objectpad_fieldix + $offset;

      my $fieldname = Devel::MAT::Cmd->format_note(
         join( "/", grep { defined } $nameprefix, $name ), 1
      );

      $fieldnames->[$fieldix] = "the $fieldname field";
   }

   if( $is_class ) {
      foreach my $embedding ( $classmeta->objectpad_direct_roles ) {
         my $rolemeta = $embedding->objectpad_role;

         $self->_objectpad_fieldnames_for_class( $fieldnames, $rolemeta, $rolemeta->objectpad_name, $embedding->objectpad_offset );
      }
   }
}

package # hide
   Devel::MAT::Tool::Object::Pad::_RoleSV;
use base qw( Devel::MAT::SV::C_STRUCT );

*objectpad_name = $make_sv_pv_accessor->( "the name SV" );

*objectpad_type = $make_accessor->( "type" );

*objectpad_repr = $make_accessor->( "repr" );

*objectpad_direct_fields = $make_sv_elems_accessor->( "the direct fields AV" );

package # hide
   Devel::MAT::Tool::Object::Pad::_FieldSV;
use base qw( Devel::MAT::SV::C_STRUCT );

*objectpad_name = $make_sv_pv_accessor->( "the name SV" );

*objectpad_class = $make_sv_accessor->( "the class" );

*objectpad_fieldix = $make_accessor->( "fieldix" );

package # hide
   Devel::MAT::Tool::Object::Pad::_MethodSV;
use base qw( Devel::MAT::SV::C_STRUCT );

*objectpad_name = $make_sv_pv_accessor->( "the name SV" );

*objectpad_class = $make_sv_accessor->( "the class" );

package # hide
   Devel::MAT::Tool::Object::Pad::_RoleEmbeddingSV;
use base qw( Devel::MAT::SV::C_STRUCT );

*objectpad_role = $make_sv_accessor->( "the role" );

*objectpad_class = $make_sv_accessor->( "the class" );

*objectpad_offset = $make_accessor->( "offset" );

package # hide
   Devel::MAT::Tool::Object::Pad::_FieldAV;
use base qw( Devel::MAT::SV::ARRAY );

# TODO: Devel::MAT ought to export these somehow
BEGIN {
   *STRENGTH_STRONG   = \&Devel::MAT::SV::STRENGTH_STRONG;
   *STRENGTH_INDIRECT = \&Devel::MAT::SV::STRENGTH_INDIRECT;
}

sub _outrefs
{
   my $self = shift;
   my ( $match, $no_desc ) = @_;

   my $instance = $self->df->sv_at( $self->{objectpad_instance_at} ) or
      return $self->Devel::MAT::SV::ARRAY::_outrefs( @_ );

   my $package = $instance->blessed or
      die "SV is not a blessed object instance\n";

   my $class = $package->objectpad_class or
      die $package->stashname . " is not an Object::Pad class\n";

   # Try to give outrefs per index a better name by using field names
   my $fieldnames_by_idx = $class->objectpad_fieldnames_by_idx;

   my @elems = $self->elems;
   my @outrefs;

   foreach my $idx ( 0 .. $#elems ) {
      my $value = $elems[$idx];

      my $name = $fieldnames_by_idx->[$idx] //
         ( "element " . Devel::MAT::Cmd->format_value( $idx, index => 1 ) );

      if( $match & STRENGTH_STRONG ) {
         push @outrefs, $no_desc ? ( strong => $value ) :
            Devel::MAT::SV::Reference( $name, strong => $value );
      }
      if( $match & STRENGTH_INDIRECT and $value->type eq "REF" and !$value->{magic} and my $rv = $value->rv ) {
         push @outrefs, $no_desc ? ( indirect => $rv ) :
            Devel::MAT::SV::Reference( $name . " via RV", indirect => $rv );
      }
   }

   return @outrefs;
}

0x55AA;
