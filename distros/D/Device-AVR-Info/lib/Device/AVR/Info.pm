#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014 -- leonerd@leonerd.org.uk

package Device::AVR::Info;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.01';

use Carp;

use XML::Smart;
use Struct::Dumb 'readonly_struct';

use Device::AVR::Info::Module;

=head1 NAME

C<Device::AVR::Info> - load data from F<Atmel> F<AVR Studio> device files

=head1 SYNOPSIS

 use Device::AVR::Info;

 my $avr = Device::AVR::Info->new_from_file( "devices/ATtiny84.xml" );

 printf "The signature of %s is %s\n",
    $avr->name, $avr->signature;

=head1 DESCRIPTION

This module loads an parses "part info" XML files as supplied with F<Atmel>'s
F<AVR Studio>, and provides convenient access to the data stored inside them.

=cut

=head1 CONSTRUCTORS

=cut

=head2 $avr = Device::AVR::Info->new_from_file( $filename )

Loads the device information from the given XML file.

=cut

sub new_from_file
{
   my $class = shift;
   my ( $filename ) = @_;

   my $root = XML::Smart->new( $filename );

   my $devices = $root->{"avr-tools-device-file"}{devices};
   @$devices == 1 or
      croak "Expected only one device, found " . scalar(@$devices);

   bless {
      _device => $devices->[0]{device},
      _modules => $root->{"avr-tools-device-file"}{modules}{module},
   }, $class;
}

sub _module_by_name
{
   my $self = shift;
   my ( $name ) = @_;

   foreach ( @{ $self->{_modules} } ) {
      return Device::AVR::Info::Module->_new( $_ ) if $_->{name} eq $name;
   }

   croak "No module named '$name' is defined";
}

=head1 ACCESSORS

=cut

=head2 $name = $avr->name

The device name (e.g. "ATtiny84")

=head2 $architecture = $avr->architecture

The device architecture (e.g. "AVR8")

=head2 $family = $avr->family

The device family (e.g. "tinyAVR")

=cut

sub name         { shift->{_device}{name} }
sub architecture { shift->{_device}{architecture} }
sub family       { shift->{_device}{family} }

=head2 @ifaces = $avr->interfaces

=head2 $iface = $avr->interface( $name )

Returns a list of interface instances, or a single one having the given name,
representing the programming interfaces supported by the device.

Each is a structure of the following fields.

 $iface->name
 $iface->type

=cut

readonly_struct Interface => [qw( type name )];

sub interfaces
{
   my $self = shift;
   return @{ $self->{interfaces} //= [ map {
      Interface( "$_->{type}", "$_->{name}" )
   } @{ $self->{_device}{interfaces}{interface} } ] };
}

sub interface
{
   my $self = shift;
   my ( $name ) = @_;
   $_->name eq $name and return $_ for $self->interfaces;
   return;
}

=head2 @memories = $avr->memories

=head2 $memory = $avr->memory( $name )

Returns a list of memory instances, or a single one having the given name,
representing the available memories on the device.

Each is a structure of the following fields.

 $memory->name
 $memory->id
 $memory->endianness
 $memory->start # in bytes
 $memory->size  # in bytes
 @segments = $memory->segments

The C<segments> field returns a list of structures of the following fields:

 $seg->start
 $seg->size
 $seg->name
 $seg->type
 $seg->can_read
 $seg->can_write
 $seg->can_exec
 $seg->pagesize

Note that all sizes are given in bytes; for memories of 16-bit word-size,
divide this by 2 to obtain the size in words.

=cut

{
   # Can't quite use Struct::Dumb because of list return inflation of 'segments'
   package
      Device::AVR::Info::_Memory;

   sub name       { shift->[0] }
   sub id         { shift->[1] }
   sub endianness { shift->[2] }
   sub start      { shift->[3] }
   sub size       { shift->[4] }
   sub segments   { @{ shift->[5] } }
}

readonly_struct MemorySegment => [qw( start size name type can_read can_write can_exec pagesize )];

sub memories
{
   my $self = shift;
   return @{ $self->{memories} //= [ map {
      my @segments = exists $_->{"memory-segment"} ? map {
         my $rw = $_->{rw};
         MemorySegment( hex "$_->{start}", hex "$_->{size}", "$_->{name}", "$_->{type}",
            scalar $rw =~ m/R/, scalar $rw =~ m/W/, !!"$_->{exec}", hex "$_->{pagesize}" );
      } @{ $_->{"memory-segment"} } : ();

      bless [ "$_->{name}", "$_->{id}", "$_->{endianness}",
         hex "$_->{start}", hex "$_->{size}", \@segments ], "Device::AVR::Info::_Memory";
   } @{ $self->{_device}{"address-spaces"}{"address-space"} } ] };
}

sub memory
{
   my $self = shift;
   my ( $name ) = @_;
   $_->name eq $name and return $_ for $self->memories;
   return;
}

sub _memory_by_id
{
   my $self = shift;
   my ( $id ) = @_;
   $_->id eq $id and return $_ for $self->memories;
   return;
}

=head2 @ints = $avr->interrupts

=head2 $int = $avr->interrupt( $name )

Returns a list of interrupt instances, or a single one having the given name,
representing the interrupt sources available on the device.

Each is a structure of the following fields.

 $int->name
 $int->index
 $int->caption

=cut

readonly_struct Interrupt => [qw( name index caption )];

sub interrupts
{
   my $self = shift;
   return @{ $self->{interrupts} //= [ map {
      Interrupt( "$_->{name}", "$_->{index}", "$_->{caption}" )
   } @{ $self->{_device}{interrupts}{interrupt} } ] };
}

sub interrupt
{
   my $self = shift;
   my ( $name ) = @_;
   $_->name eq $name and return $_ for $self->interrupts;
   return;
}

=head2 @periphs = $avr->peripherals

=head2 $periph = $avr->peripheral( $name )

Returns a list of peripheral instances, or a single one having the given name,
representing the peripherals or other miscellaneous information available on
the device.

Each is a structure of the following fields.

 $periph->name
 $periph->module     # instance of Device::AVR::Info::Module
 $periph->regname
 $periph->regspace   # instance of $memory

 @registers = $periph->registers
 # instances of $register from Device::AVR::Info::Module

=cut

{
   package
      Device::AVR::Info::_Peripheral;

   sub name      { shift->[0] }
   sub module    { shift->[1] }
   sub regname   { shift->[2] }
   sub regoffset { shift->[3] }
   sub regspace  { shift->[4] }

   sub registers {
      my $self = shift;
      $self->module->_registers_offset( $self->regname, $self->regoffset );
   }
}

sub peripherals
{
   my $self = shift;
   return @{ $self->{peripherals} //= [ map {
      my $module = $self->_module_by_name( "$_->{name}" );
      map {
         my $reggroup = $_->{"register-group"}[0];
         bless [ "$_->{name}", $module,
            "$reggroup->{'name-in-module'}", hex "$reggroup->{offset}",
            $self->_memory_by_id( $reggroup->{"address-space"} ) ], "Device::AVR::Info::_Peripheral";
      } @{ $_->{instance} };
   } @{ $self->{_device}{peripherals}{module} } ] };
}

sub peripheral
{
   my $self = shift;
   my ( $name ) = @_;

   $self->peripherals;

   $_->name eq $name and return $_ for @{ $self->{peripherals} };
   return;
}

=head2 @group_names = $avr->property_groups

Returns (in no particular order) the names of the defined property groups.

=head2 \%values = $avr->property_group( $group_name )

Returns a HASH reference of all the properties in the given property group.

=head2 $value = $avr->property( $group_name, $prop_name )

Returns a single value of a property in the given property group.

Any value given in the XML file in the form of a single hexadecimal numerical
constant is automatically converted into the appropriate integer. Strings of
multiple numbers (such as the HVSP and HVPP control stacks) are not converted.

=cut

sub property_groups
{
   my $self = shift;
   $self->{property_groups} //= { map {
      +( "$_->{name}", $_->{property} )
   } @{ $self->{_device}{"property-groups"}{"property-group"} } };
   return keys %{ $self->{property_groups} };
}

sub property_group
{
   my $self = shift;
   my ( $group ) = @_;

   $self->property_groups;
   my $properties = $self->{property_groups}{$group} or
      croak "No such property group '$group'";

   return $self->{properties}{$group} //= { map {
      my $value = $_->{value};
      $value = hex $value if $value =~ m/^0x[[:xdigit:]]+$/;

      +( "$_->{name}", "$value" )
   } @$properties };
}

sub property
{
   my $self = shift;
   my ( $group, $prop ) = @_;

   return $self->property_group( $group )->{$prop};
}

=head1 DERIVED METHODS

These methods wrap information provided by the basic accessors.

=cut

=head2 $sig = $avr->signature

Returns a 6-character hexadecimal string consisting of the three bytes of the
device signature.

=cut

sub signature
{
   my $self = shift;
   return sprintf "%02x%02x%02x",
      map { $self->property( SIGNATURES => "SIGNATURE$_" ) } 0 .. 2;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
