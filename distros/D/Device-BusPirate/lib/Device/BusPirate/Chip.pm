#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Device::BusPirate::Chip;

use strict;
use warnings;

our $VERSION = '0.14';

=head1 NAME

C<Device::BusPirate::Chip> - base class for chip-specific adapters

=head1 DEPRECATION

B<Note>: this package and its entire module name heirarchy are now deprecated
in favour of the L<Device::Chip> interface instead. Any existing chip
implementations should be rewritten. They can continue to target the
I<Bus Pirate> by using L<Device::Chip::Adapter::BusPirate>, but will therefore
gain the ability to use any other implementation of L<Device::Chip::Adapter>.

=head1 DESCRIPTION

This base class is provided for implementations of chip-specific adapters, to
provide specific code to interact with particular kinds of chip or other
hardware attached to the Bus Pirate.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $chip = Device::BusPirate::Chip->new( $bp, %opts )

Constructs a new instance of the chip adapter. The first argument is the
L<Device::BusPirate> object itself. The remaining arguments are not otherwise
inspected by the base class; they are free for use by the specific subclasses.

=cut

sub new
{
   my $class = shift;
   my ( $bp ) = @_;

   return bless {
      bp => $bp,
   }, $class;
}

=head1 METHODS

=cut

=head2 pirate

   $pirate = $chip->pirate

Returns the L<Device::BusPirate> instance.

=cut

sub pirate
{
   my $self = shift;
   return $self->{bp};
}

=head2 mode

   $mode = $chip->mode

Returns the C<Device::BusPirate::Mode> instance being used to communicate with
this chip. Normally this method would be used directly by the implementation
subclass, rather than the end-user code calling it.

=cut

sub mode
{
   my $self = shift;
   return $self->{mode};
}

=head2 mount

   $chip = $chip->mount( $mode )->get

Called by the C<mount_chip> method on the C<Device::BusPirate> object, this
method is intended for implementation subclasses to perform any initial
configuration of the C<$mode> instance that they require; such as details of
communication speed or settings.

=cut

sub mount
{
   my $self = shift;
   ( $self->{mode} ) = @_;
   Future->done( $self );
}

=head1 MODE PASSTHROUGH METHODS

The following methods are passed through to the C<mode> instance

 power
 pullup
 aux

=cut

foreach my $method (qw( power pullup aux )) {
   no strict 'refs';
   *$method = sub { shift->mode->$method( @_ ) };
}

=head1 IMPLEMENTATION METHODS

The following methods must be provided by specific implementations of this
base class:

=head2 CHIP

   $chipname = Device::BusPirate::Chip->CHIP

Returns the name for this chip; the name that must be passed to the
C<mount_chip> method on C<Device::BusPirate> in order to request this
particular implementation. For ease of use, this name should match the name
given by the hardware manufacturer to identify the chip. It does not need to
be a valid Perl symbol; it may contain characters not normally allowed in
symbol names.

=head2 MODE

   $modename = $chip->MODE

Called after construction, this method should return a mode name that will be
used to communicate with the chip. Normally this would be a constant, hence
its capitalised name, but it is invoked on the instance, after construction,
in case of chips with multiple possible access methods (e.g. dual SPI or I2C
devices), allowing the method chance to inspect the constructor options to
make this choice.

=cut

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
