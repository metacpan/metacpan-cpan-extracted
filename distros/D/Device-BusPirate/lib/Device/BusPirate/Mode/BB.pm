#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2021 -- leonerd@leonerd.org.uk

use v5.14;
use Object::Pad 0.45;

package Device::BusPirate::Mode::BB 0.23;
class Device::BusPirate::Mode::BB isa Device::BusPirate::Mode;

use Carp;

use Future::AsyncAwait;

use constant MODE => "BB";

use constant {
   MASK_CS   => 0x01,
   MASK_MISO => 0x02,
   MASK_CLK  => 0x04,
   MASK_MOSI => 0x08,
   MASK_AUX  => 0x10,

   CONF_PULLUP => 0x20,
   CONF_POWER  => 0x40,
};

# Convenience hash
my %PIN_MASK = map { $_ => __PACKAGE__->${\"MASK_\U$_"} } qw( cs miso clk mosi aux );

=head1 NAME

C<Device::BusPirate::Mode::BB> - use C<Device::BusPirate> in bit-banging mode

=head1 SYNOPSIS

   use Device::BusPirate;

   my $pirate = Device::BusPirate->new;
   my $bb = $pirate->enter_mode( "BB" )->get;

   my $count = 0;
   while(1) {
      $bb->write(
         miso => $count == 0,
         cs   => $count == 1,
         mosi => $count == 2,
         clk  => $count == 3,
         aux  => $count == 4,
      )->then( sub { $pirate->sleep( 0.5 ) })
       ->get;

     $count++;
     $count = 0 if $count >= 5;
   }

=head1 DESCRIPTION

This object is returned by a L<Device::BusPirate> instance when switching it
into C<BB> mode. It provides methods to configure the hardware, and interact
with the five basic IO lines in bit-banging mode.

=cut

=head1 METHODS

=cut

has $_dir_mask;
has $_out_mask;

async method start
{
   $_dir_mask = 0x1f; # all inputs

   $_out_mask = 0; # all off

   return $self;
}

=head2 configure

   $bb->configure( %args )->get

Change configuration options. The following options exist; all of which are
simple true/false booleans.

=over 4

=item open_drain

If enabled, a "high" output pin will be set as an input; i.e. hi-Z. When
disabled (default), a "high" output pin will be driven by 3.3V. A "low" output
will be driven to GND in either case.

=back

=cut

has $_open_drain;

async method configure ( %args )
{
   defined $args{open_drain} and $_open_drain = $args{open_drain};
}

=head2 write

   $bb->write( %pins )->get

Sets the state of multiple output pins at the same time.

=cut

async method _writeread ( $want_read, $pins_write, $pins_read )
{
   my $out = $_out_mask;
   my $dir = $_dir_mask;

   foreach my $pin ( keys %$pins_write ) {
      my $mask = $PIN_MASK{$pin} or
         croak "Unrecognised BB pin name $pin";
      my $val = $pins_write->{$pin};

      if( $val and !$_open_drain ) {
         $dir &= ~$mask;
         $out |=  $mask;
      }
      elsif( $val ) {
         $dir |=  $mask;
      }
      else {
         $dir &= ~$mask;
         $out &= ~$mask;
      }
   }

   foreach my $pin ( @$pins_read ) {
      my $mask = $PIN_MASK{$pin} or
         croak "Unrecognised BB pin name $pin";

      $dir |= $mask;
   }

   my $len = 0;
   if( $dir != $_dir_mask ) {
      $self->pirate->write( chr( 0x40 | $dir ) );
      $len++;

      $_dir_mask = $dir;
   }

   if( $want_read or $out != $_out_mask ) {
      $self->pirate->write( chr( 0x80 | $out ) );
      $len++;

      $_out_mask = $out;
   }

   return unless $len;

   my $buf = await $self->pirate->read( $len );

   return if !$want_read;

   $buf = ord $buf;

   my $pins;
   foreach my $pin ( keys %PIN_MASK ) {
      my $mask = $PIN_MASK{$pin};
      next unless $_dir_mask & $mask;
      $pins->{$pin} = !!( $buf & $mask );
   }

   return $pins;
}

method write ( %pins )
{
   $self->_writeread( 0, \%pins, [] );
}

async method _input1 ( $mask )
{
   $_dir_mask |= $mask;

   $self->pirate->write( chr( 0x40 | $_dir_mask ) );
   return ord( await $self->pirate->read( 1 ) ) & $mask;
}

=head2 read

   $pins = $bbio->read( @pins )->get

Sets given list of pins (which may be empty) to be inputs, and returns a HASH
containing the current state of all the pins currently configured as inputs.
More efficient than calling multiple C<read_*> methods when more than one pin
is being read at the same time.

=cut

method read ( @pins )
{
   $self->_writeread( 1, {}, \@pins );
}

=head2 writeread

   $in_pins = $bbio->writeread( %out_pins )->get

Combines the effects of C<write> and C<read> in a single operation; sets the
output state of any pins in C<%out_pins> then returns the input state of the
pins currently set as inputs.

=cut

method writeread ( %pins )
{
   $self->_writeread( 1, \%pins, [] );
}

=head2 power

   $bb->power( $power )->get

Enable or disable the C<VREG> 5V and 3.3V power outputs.

=cut

async method power ( $on )
{
   $on ? ( $_out_mask |=  CONF_POWER )
       : ( $_out_mask &= ~CONF_POWER );
   $self->pirate->write( chr( 0x80 | $_out_mask ) );
   await $self->pirate->read( 1 );
   return;
}

=head2 pullup

   $bb->pullup( $pullup )->get

Enable or disable the IO pin pullup resistors from C<Vpu>. These are connected
to the C<MISO>, C<CLK>, C<MOSI> and C<CS> pins.

=cut

async method pullup ( $on )
{
   $on ? ( $_out_mask |=  CONF_PULLUP )
       : ( $_out_mask &= ~CONF_PULLUP );
   $self->pirate->write( chr( 0x80 | $_out_mask ) );
   await $self->pirate->read( 1 );
   return;
}

=head1 PER-PIN METHODS

For each named pin, the following methods are defined. The pin names are

   cs miso sck mosi aux

=head2 I<PIN>

   $bbio->PIN( $state )->get

Sets the output state of the given pin.

=head2 read_I<PIN>

   $state = $bbio->read_PIN->get

Sets the pin to input direction and reads its current state.

=cut

BEGIN {
   my $metaclass = Object::Pad::MOP::Class->for_caller;

   foreach my $pin (qw( cs miso clk mosi aux )) {
      my $mask = __PACKAGE__->${\"MASK_\U$pin"};

      $metaclass->add_method(
         $pin => method ( $on ) { $self->_writeread( 0, { $pin => $on }, [] ) }
      );

      $metaclass->add_method(
         "read_$pin" => method { $self->_input1( $mask ) }
      );
   }
}

=head1 TODO

=over 4

=item *

Some method of setting multiple pins into read mode at once, so that a single
C<read> method hits them all.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
