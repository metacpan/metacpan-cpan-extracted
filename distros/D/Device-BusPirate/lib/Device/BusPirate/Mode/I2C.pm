#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2019 -- leonerd@leonerd.org.uk

package Device::BusPirate::Mode::I2C;

use strict;
use warnings;
use base qw( Device::BusPirate::Mode );

our $VERSION = '0.20';

use Carp;

use Future::AsyncAwait;

use constant MODE => "I2C";

use constant PIRATE_DEBUG => $ENV{PIRATE_DEBUG} // 0;

=head1 NAME

C<Device::BusPirate::Mode::I2C> - use C<Device::BusPirate> in I2C mode

=head1 SYNOPSIS

   use Device::BusPirate;

   my $pirate = Device::BusPirate->new;
   my $i2c = $pirate->enter_mode( "I2C" )->get;

   my $addr = 0x20;

   my $count = 0;
   while(1) {
      $i2c->send( $addr, chr $count )->get;
      my $in = ord $i2c->recv( $addr, 1 )->get;
      printf "Read %02x\n", $in;

      $count++; $count %= 255;
   }

=head1 DESCRIPTION

This object is returned by a L<Device::BusPirate> instance when switching it
into C<I2C> mode. It provides methods to configure the hardware, and interact
with one or more I2C-attached chips.

=cut

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

# Not to be confused with start_bit
async sub start
{
   my $self = shift;

   await $self->_start_mode_and_await( "\x02", "I2C" );

   ( $self->{version} ) = await $self->pirate->read( 1, "I2C start" );

   print STDERR "PIRATE I2C STARTED\n" if PIRATE_DEBUG;
   return $self;
}

=head2 configure

   $i2c->configure( %args )->get

Change configuration options. The following options exist:

=over 4

=item speed

A string giving the clock speed to use for I2C. Must be one of the values:

   5k 50k 100k 400k

=back

=cut

my %SPEEDS = (
   '5k'   => 0,
   '50k'  => 1,
   '100k' => 2,
   '400k' => 3,
);

async sub configure
{
   my $self = shift;
   my %args = @_;

   my $bytes = "";

   if( defined $args{speed} ) {
      defined( my $speed = $SPEEDS{$args{speed}} ) or
         croak "Unrecognised speed '$args{speed}'";

      $bytes .= chr( 0x60 | $speed );
   }

   $self->pirate->write( $bytes );

   my $response = await $self->pirate->read( length $bytes, "I2C configure" );
   $response eq "\x01" x length $bytes or
      die "Expected ACK response to I2C configure";

   return;
}

=head2 start_bit

   $i2c->start_bit->get

Sends an I2C START bit transition

=cut

sub start_bit
{
   my $self = shift;

   print STDERR "PIRATE I2C START-BIT\n" if PIRATE_DEBUG;

   $self->pirate->write_expect_ack( "\x02", "I2C start_bit" );
}

=head2 stop_bit

   $i2c->stop_bit->get

Sends an I2C STOP bit transition

=cut

sub stop_bit
{
   my $self = shift;

   print STDERR "PIRATE I2C STOP-BIT\n" if PIRATE_DEBUG;

   $self->pirate->write_expect_ack( "\x03", "I2C stop_bit" );
}

=head2 write

   $i2c->write( $bytes )->get

Sends the given bytes over the I2C wire. This method does I<not> send a
preceding start or a following stop; you must do that yourself, or see the
C<send> and C<recv> methods.

=cut

async sub write
{
   my $self = shift;
   my ( $bytes ) = @_;

   printf STDERR "PIRATE I2C WRITE %v02X\n", $bytes if PIRATE_DEBUG;
   my @chunks = $bytes =~ m/(.{1,16})/gs;

   foreach my $bytes ( @chunks ) {
      my $len_1 = length( $bytes ) - 1;

      my $buf = await $self->pirate->write_expect_acked_data(
         chr( 0x10 | $len_1 ) . $bytes, length $bytes, "I2C bulk transfer"
      );

      $buf =~ m/^\x00*/;
      $+[0] == length $bytes or
         die "Received NACK after $+[0] bytes";
   }
}

=head2 read

   $bytes = $i2c->read( $length )->get

Receives the given number of bytes over the I2C wire, sending an ACK bit after
each one but the final, to which is sent a NACK.

=cut

async sub read
{
   my $self = shift;
   my ( $length ) = @_;

   my $ret = "";

   print STDERR "PIRATE I2C READING $length\n" if PIRATE_DEBUG;

   foreach my $ack ( (1)x($length-1), (0) ) {
      $self->pirate->write( "\x04" );

      $ret .= await $self->pirate->read( 1, "I2C read data" );

      await $self->pirate->write_expect_ack( $ack ? "\x06" : "\x07", "I2C read send ACK" );
   }

   printf STDERR "PIRATE I2C READ %v02X\n", $ret if PIRATE_DEBUG;
   return $ret;
}

# TODO: Turn this into an `async sub` without ->then chaining; though currently the
#   ->followed_by makes that trickier
sub _i2c_txn
{
   my $self = shift;
   my ( $code ) = @_;

   $self->pirate->enter_mutex( sub {
      $self->start_bit
         ->then( $code )
         ->followed_by( sub {
            my $f = shift;
            $self->stop_bit->then( sub { $f } );
         });
   });
}

=head2 send

   $i2c->send( $address, $bytes )->get

A convenient wrapper around C<start_bit>, C<write> and C<stop_bit>. This
method sends a START bit, then an initial byte to address the slave in WRITE
mode, then the remaining bytes, followed finally by a STOP bit. This is
performed atomically by using the C<enter_mutex> method.

C<$address> should be an integer, in the range 0 to 0x7f.

=cut

sub send
{
   my $self = shift;
   my ( $address, $bytes ) = @_;

   $address >= 0 and $address < 0x80 or
      croak "Invalid I2C slave address";

   $self->_i2c_txn( sub {
      $self->write( chr( $address << 1 | 0 ) . $bytes );
   });
}

=head2 recv

   $bytes = $i2c->recv( $address, $length )->get

A convenient wrapper around C<start_bit>, C<write>, C<read> and C<stop_bit>.
This method sends a START bit, then an initial byte to address the slave in
READ mode, then reads the given number of bytes, followed finally by a STOP
bit. This is performed atomically by using the C<enter_mutex> method.

C<$address> should be an integer, in the range 0 to 0x7f.

=cut

sub recv
{
   my $self = shift;
   my ( $address, $length ) = @_;

   $address >= 0 and $address < 0x80 or
      croak "Invalid I2C slave address";

   $self->_i2c_txn( async sub {
      await $self->write( chr( $address << 1 | 1 ) );
      await $self->read( $length );
   });
}

=head2 send_then_recv

   $bytes_in = $ic->send_then_recv( $address, $bytes_out, $read_len )->get

A convenient wrapper around C<start_bit>, C<write>, C<read> and C<stop_bit>.
This method combines a C<send> and C<recv> operation, with a repeated START
condition inbetween (not a STOP). It is useful when reading values from I2C
slaves that implement numbered registers; sending the register number as a
write, before requesting the read.

C<$address> should be an integer, in the range 0 to 0x7f.

=cut

sub send_then_recv
{
   my $self = shift;
   my ( $address, $bytes_out, $read_len ) = @_;

   $address >= 0 and $address < 0x80 or
      croak "Invalid I2C slave address";

   $self->_i2c_txn( async sub {
      await $self->write( chr( $address << 1 | 0 ) . $bytes_out );
      await $self->start_bit; # repeated START
      await $self->write( chr( $address << 1 | 1 ) );
      await $self->read( $read_len );
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
