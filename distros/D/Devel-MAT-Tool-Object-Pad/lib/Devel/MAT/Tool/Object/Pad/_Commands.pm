#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

use v5.14;
use warnings;

package # hide
   Devel::MAT::Tool::Object::Pad::classes;
use base qw( Devel::MAT::Tool );

use constant CMD => "classes";
use constant CMD_DESC => "Display a list of the Object::Pad classes";

use List::UtilsBy qw( sort_by );

sub run
{
   my $self = shift;

   my $df = $self->df;

   my $OPtool = $self->pmat->load_tool( "Object::Pad" );

   my @classes = sort_by { $_->objectpad_name } values %{ $OPtool->classes_by_name };

   Devel::MAT::Tool::more->paginate( sub {
      my ( $count ) = @_;
      while( $count and @classes ) {
         my $class = shift @classes;

         Devel::MAT::Cmd->printf( "%s %s at %s\n",
            Devel::MAT::Cmd->format_note( $class->objectpad_type ? "role" : "class" ),
            Devel::MAT::Cmd->format_symbol( $class->objectpad_name ),
            Devel::MAT::Cmd->format_sv( $class ),
         );
      }

      return !!@classes;
   } );
}

package # hide
   Devel::MAT::Tool::Object::Pad::fields;
use base qw( Devel::MAT::Tool );

use constant CMD => "fields";
use constant CMD_DESC => "Display the fields of an Object::Pad instance";

use constant CMD_ARGS_SV => 1;

sub run
{
   my $self = shift;
   my ( $sv ) = @_;

   if( $sv->type eq "REF" ) {
      $sv = $sv->rv;
   }

   my $package = $sv->blessed or
      die "SV is not a blessed object instance\n";

   my $class = $package->objectpad_class or
      die $package->stashname . " is not an Object::Pad class\n";

   my $fieldav = $self->df->sv_at( $sv->{objectpad_fields_at} ) or
      die "SV has no Object::Pad fields AV";

   Devel::MAT::Cmd->printf( "The field AV %s\n",
      Devel::MAT::Cmd->format_sv( $fieldav ) );

   my @rows;
   $self->_walk_fields_for_class( $class, undef, $fieldav, \@rows );

   Devel::MAT::Cmd->print_table( \@rows,
      headings => [ "Ix", "Field", "Value" ],
   );
}

sub _walk_fields_for_class
{
   my $self = shift;
   my ( $classmeta, $nameprefix, $fieldav, $rows, $offset ) = @_;
   $offset //= 0;

   my $is_class = $classmeta->objectpad_type == 0;

   if( $is_class and my $superclass = $classmeta->objectpad_superclass ) {
      $self->_walk_fields_for_class( $superclass, $superclass->objectpad_name, $fieldav, $rows );
   }

   foreach my $fieldmeta ( $classmeta->objectpad_direct_fields ) {
      my $name    = $fieldmeta->objectpad_name;
      my $fieldix = $fieldmeta->objectpad_fieldix + $offset;

      my $value = $fieldav->elem( $fieldix );

      # non-scalar fields are stored as REFs
      if( $name !~ m/^\$/ ) {
         # TODO: Complain if this isn't a REF
         $value = $value->rv;
      }

      push @$rows, [
         $fieldix,
         Devel::MAT::Cmd->format_note( join( "/", grep { defined } $nameprefix, $name ), 1 ),
         Devel::MAT::Cmd->format_sv_with_value( $value ),
      ];
   }

   if( $is_class ) {
      foreach my $embedding ( $classmeta->objectpad_direct_roles ) {
         my $rolemeta = $embedding->objectpad_role;

         $self->_walk_fields_for_class( $rolemeta, $rolemeta->objectpad_name, $fieldav, $rows, $embedding->objectpad_offset );
      }
   }
}

0x55AA;
