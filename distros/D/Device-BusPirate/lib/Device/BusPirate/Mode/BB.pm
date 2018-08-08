#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2015 -- leonerd@leonerd.org.uk

package Device::BusPirate::Mode::BB;

use strict;
use warnings;
use base qw( Device::BusPirate::Mode );

our $VERSION = '0.16';

use Carp;

use Future;

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

sub start
{
   my $self = shift;

   $self->{dir_mask} = 0x1f; # all inputs

   $self->{out_mask} = 0; # all off

   Future->done( $self );
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

sub configure
{
   my $self = shift;
   my %args = @_;

   defined $args{$_} and $self->{$_} = $args{$_}
      for (qw( open_drain ));

   return Future->done
}

=head2 cs

=head2 miso

=head2 clk

=head2 mosi

=head2 aux

   $bb->cs( $state )->get

   $bb->miso( $state )->get

   $bb->clk( $state )->get

   $bb->mosi( $state )->get

   $bb->aux( $state )->get

Set an output pin to the given logical state. Uses the C<open_drain>
configuration setting to determine whether high should be hi-Z or 3.3V.

=cut

sub cs   { shift->_writeread( 0, { cs   => $_[0] }, [] ) }
sub miso { shift->_writeread( 0, { miso => $_[0] }, [] ) }
sub clk  { shift->_writeread( 0, { clk  => $_[0] }, [] ) }
sub mosi { shift->_writeread( 0, { mosi => $_[0] }, [] ) }
sub aux  { shift->_writeread( 0, { aux  => $_[0] }, [] ) }

=head2 write

   $bb->write( %pins )->get

Sets the state of multiple output pins at the same time.

=cut

sub _writeread
{
   my $self = shift;
   my ( $want_read, $pins_write, $pins_read ) = @_;

   my $out = $self->{out_mask};
   my $dir = $self->{dir_mask};

   foreach my $pin ( keys %$pins_write ) {
      my $mask = $PIN_MASK{$pin} or
         croak "Unrecognised BB pin name $pin";
      my $val = $pins_write->{$pin};

      if( $val and !$self->{open_drain} ) {
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
   if( $dir != $self->{dir_mask} ) {
      $self->pirate->write( chr( 0x40 | $dir ) );
      $len++;

      $self->{dir_mask} = $dir;
   }

   if( $want_read or $out != $self->{out_mask} ) {
      $self->pirate->write( chr( 0x80 | $out ) );
      $len++;

      $self->{out_mask} = $out;
   }

   return Future->done unless $len;

   my $f = $self->pirate->read( $len );

   return $f->then_done() if !$want_read;
   return $f->then( sub {
      my ( $buf ) = @_;
      $buf = ord $buf;

      my $pins;
      foreach my $pin ( keys %PIN_MASK ) {
         my $mask = $PIN_MASK{$pin};
         next unless $self->{dir_mask} & $mask;
         $pins->{$pin} = !!( $buf & $mask );
      }
      Future->done( $pins );
   });
}

sub write
{
   my $self = shift;
   $self->_writeread( 0, { @_ }, [] );
}

sub read_cs   { shift->_input1( MASK_CS,   @_ ) }
sub read_miso { shift->_input1( MASK_MISO, @_ ) }
sub read_clk  { shift->_input1( MASK_CLK,  @_ ) }
sub read_mosi { shift->_input1( MASK_MOSI, @_ ) }
sub read_aux  { shift->_input1( MASK_AUX,  @_ ) }

=head2 read_cs

=head2 read_miso

=head2 read_clk

=head2 read_mosi

=head2 read_aux

   $state = $bb->read_cs->get

   $state = $bb->read_miso->get

   $state = $bb->read_clk->get

   $state = $bb->read_mosi->get

   $state = $bb->read_aux->get

Set a pin to input direction and read its current state.

=cut

sub _input1
{
   my $self = shift;
   my ( $mask ) = @_;

   $self->_input( $mask )->then( sub {
      my ( $buf ) = @_;
      Future->done( ord( $buf ) & $mask );
   });
}

sub _input
{
   my $self = shift;
   my ( $mask ) = @_;

   $self->{dir_mask} |= $mask;
   $self->pirate->write( chr( 0x40 | $self->{dir_mask} ) );
   return $self->pirate->read( 1 );
}

=head2 read

   $pins = $bbio->read( @pins )->get

Sets given list of pins (which may be empty) to be inputs, and returns a HASH
containing the current state of all the pins currently configured as inputs.
More efficient than calling multiple C<read_*> methods when more than one pin
is being read at the same time.

=cut

sub read
{
   my $self = shift;
   $self->_writeread( 1, {}, [ @_ ] );
}

=head2 writeread

   $in_pins = $bbio->writeread( %out_pins )->get

Combines the effects of C<write> and C<read> in a single operation; sets the
output state of any pins in C<%out_pins> then returns the input state of the
pins currently set as inputs.

=cut

sub writeread
{
   my $self = shift;
   $self->_writeread( 1, { @_ }, [] );
}

=head2 power

   $bb->power( $power )->get

Enable or disable the C<VREG> 5V and 3.3V power outputs.

=cut

sub power
{
   my $self = shift;
   my ( $state ) = @_;

   $state ? ( $self->{out_mask} |=  CONF_POWER )
          : ( $self->{out_mask} &= ~CONF_POWER );
   $self->pirate->write( chr( 0x80 | $self->{out_mask} ) );
   $self->pirate->read( 1 )->then_done(); # ignore input
}

=head2 pullup

   $bb->pullup( $pullup )->get

Enable or disable the IO pin pullup resistors from C<Vpu>. These are connected
to the C<MISO>, C<CLK>, C<MOSI> and C<CS> pins.

=cut

sub pullup
{
   my $self = shift;
   my ( $state ) = @_;

   $state ? ( $self->{out_mask} |=  CONF_PULLUP )
          : ( $self->{out_mask} &= ~CONF_PULLUP );
   $self->pirate->write( chr( 0x80 | $self->{out_mask} ) );
   $self->pirate->read( 1 )->then_done(); # ignore input
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
