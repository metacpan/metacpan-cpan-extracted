#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Device::AVR::Info::Module;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.01';

use Carp;

use Struct::Dumb 'readonly_struct';

=head1 NAME

C<Device::AVR::Info::Module> - represent a single kind of peripheral module type from an F<AVR> chip

=head1 SYNOPSIS

Instances in this class are returned from L<Device::AVR::Info>:

 use Device::AVR::Info;

 my $avr = Device::AVR::Info->new_from_file( "devices/ATtiny84.xml" );

 my $fuses = $avr->peripheral( 'FUSE' );
 my $module = $fuses->module;

 printf "The FUSE module has %d registers\n",
    scalar $module->registers( 'FUSE' );

=cut

sub _new
{
   my $class = shift;
   my ( $module ) = @_;

   return bless {
      _module => $module,
   }, $class;
}

=head1 ACCESSORS

=cut

=head2 $name = $module->name

Returns the name of the module

=cut

sub name { shift->{_module}{name} }

=head2 @registers = $module->registers( $groupname )

Returns a list of register instances, representing the registers in the named
group.

Each is a structure of the following fields.

 $register->name
 $register->offset
 $register->size
 $register->caption
 $register->mask
 @fields = $register->bitfields

The C<bitfields> field returns a list of structures of the following fields:

 $field->name
 $field->caption
 $field->mask

=cut

{
   package
      Device::AVR::Info::Module::_Register;

   sub name      { shift->[0] }
   sub offset    { shift->[1] }
   sub size      { shift->[2] }
   sub caption   { shift->[3] }
   sub mask      { shift->[4] }
   sub bitfields { @{ shift->[5] } }

   package
      Device::AVR::Info::Module::_Bitfield;

   sub name    { shift->[0] }
   sub caption { shift->[1] }
   sub mask    { shift->[2] }
   sub values  { @{ shift->[3] } }
}

sub registers
{
   my $self = shift;
   my ( $name ) = @_;
   $self->_registers_offset( $name, 0 );
}

sub _registers_offset
{
   my $self = shift;
   my ( $name, $offset ) = @_;

   my $registers = $self->{_module}{"register-group"}( name => eq => $name )
      or croak "No register group named '$name'";

   map {
      my @fields = exists $_->{bitfield} ?
         map {
            my $mask = hex "$_->{mask}";
            my $values = exists $_->{values} ? $self->_value_group( $_->{values}, $mask ) : [];
            bless [ "$_->{name}", "$_->{caption}", $mask, $values ], "Device::AVR::Info::Module::_Bitfield";
         } @{ $_->{bitfield} } : ();

      bless [ "$_->{name}", $offset + hex "$_->{offset}", "$_->{size}",
         "$_->{caption}", hex "$_->{mask}", \@fields ], "Device::AVR::Info::Module::_Register";
   } @{ $registers->{register} };
}

readonly_struct Value => [qw( name caption value )];

sub _value_group
{
   my $self = shift;
   my ( $name, $mask ) = @_;

   my $values = $self->{_module}{"value-group"}( name => eq => $name )
      or croak "No value group named '$name'";

   [ map {
      my $value_in = hex "$_->{value}";

      # The bits in $value are "compressed", and have to be expanded out to
      # only the bit positions set in $mask.
      my $value_out = 0;
      my $in_bit = 0;
      my $out_bit = 0;
      while( $value_in ) {
         $out_bit++ until $out_bit > 16 or $mask & 1<<$out_bit;
         die "Ran out of mask bits before value bits" if $in_bit > 16;

         $value_out |= 1<<$out_bit if $value_in & 1<<$in_bit;
         $value_in &= ~( 1<<$in_bit );

         $in_bit++;
         $out_bit++;
      }

      Value( "$_->{name}", "$_->{caption}", $value_out )
   } @{ $values->{value} } ];
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
