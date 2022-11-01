#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;

use Object::Pad 0.70 ':experimental(adjust_params)';

package Electronics::PSU::DPSxxxx 0.03;
class Electronics::PSU::DPSxxxx;

use Carp;
use Future::AsyncAwait;
use Future::IO;

use Fcntl qw( O_NOCTTY O_NDELAY );
use IO::Termios;

# Protocol::Modbus exists but it doesn't do async, and it doesn't do proper
# frame detection of incoming data :(
# We'll just write this all ourselves; it's not hard

# See also
#   https://autoit.de/wcf/attachment/88980-dps3005-cnc-communication-protocol-v1-2-pdf/

=head1 NAME

C<Electronics::PSU::DPSxxxx> - control a F<DPS> power supply

=head1 SYNOPSIS

   use Future::AsyncAwait;

   use Electronics::PSU::DPSxxxx;

   my $psu = Electronics::PSU::DPSxxxx->new( dev => "/dev/ttyUSB0" );

   await $psu->set_voltage( 1.23  ); # volts
   await $psu->set_current( 0.200 ); # amps

   await $psu->set_output_state( 1 ); # turn it on!

=head1 DESCRIPTION

This module allows control of a F<RDTech> F<DPS>-series power supply, such as
the F<DPS3005>, when connected over a serial port.

=head2 Interface Design

The interface is currently an ad-hoc collection of whatever seems to work
here, but my hope is to find a more generic shareable interface that multiple
differenet modules can use, to provide interfaces to various kinds of
electronics test equipment.

The intention is that it should eventually be possible to write a script for
performing automated electronics testing or experimentation, and easily swap
out modules to suit the equipment available. Similar concepts apply in fields
like L<DBI>, or L<Device::Chip>, so there should be plenty of ideas to borrow.

=cut

has $_fh   :param = undef;
has $_addr :param = 1;

ADJUST :params (
   :$dev = undef,
) {
   unless( $_fh ) {
      $_fh = IO::Termios->open( $dev, "9600,8,n,1", O_NOCTTY, O_NDELAY ) or
         croak "Cannot open $dev - $!";

      $_fh->cfmakeraw;
      $_fh->setflag_clocal( 1 );
      $_fh->blocking( 1 );
      $_fh->autoflush;
   }
}

sub _calc_crc ( $data )
{
   # This is not the standard CRC16 algorithm
   # Stolen and adapted from
   #   https://ctlsys.com/support/how_to_compute_the_modbus_rtu_message_crc/
   my $crc = 0xFFFF;
   foreach my $d ( split //, $data ) {
      $crc ^= ord $d;
      foreach ( 1 .. 8 ) {
         if( $crc & 0x0001 ) {
            $crc >>= 1;
            $crc ^= 0xA001;
         }
         else {
            $crc >>= 1;
         }
      }
   }

   return $crc;
}

async method _send_command ( $func, $format, @args )
{
   my $request = pack "C C $format", $_addr, $func, @args;

   # CRC is appended in little-endian format
   $request .= pack "S<", _calc_crc( $request );

   await Future::IO->syswrite( $_fh, $request );
}

async method _recv_response ( $func, $len, $format )
{
   my $response = await Future::IO->sysread_exactly( $_fh, 2 + $len + 2 );

   my $got_crc = unpack "S<", substr( $response, -2, 2, "" );
   if( $got_crc != ( my $want_crc = _calc_crc( $response ) ) ) {
      # Just warn for now
      warn sprintf "Received PDU CRC %04X, expected %04X\n", $got_crc, $want_crc;
   }

   my ( $got_addr, $got_func, $payload ) = unpack "C C a*", $response;
   $got_addr == $_addr or croak "Received response from unexpected addr";
   $got_func == $func  or croak "Received response for unexpected function";

   return unpack $format, $payload;
}

use constant {
   FUNC_READ_HOLDING_REGISTER => 0x03,
   FUNC_WRITE_SINGLE_REGISTER => 0x06,
};

async method _read_holding_registers ( $reg, $count = 1 )
{
   await $self->_send_command( FUNC_READ_HOLDING_REGISTER, "S> S>", $reg, $count );

   my ( $nbytes, @regs ) =
      await $self->_recv_response( FUNC_READ_HOLDING_REGISTER, 1 + 2*$count, "C (S>)*" );

   return @regs;
}

async method _write_single_register ( $reg, $value )
{
   await $self->_send_command( FUNC_WRITE_SINGLE_REGISTER, "S> S>", $reg, $value );

   # ignore result
   await $self->_recv_response( FUNC_WRITE_SINGLE_REGISTER, 2 + 2, "S> S>" );

   return;
}

=head1 METHODS

=cut

use constant {
   REG_USET    => 0x00, # centivolts
   REG_ISET    => 0x01, # miliamps
   REG_UOUT    => 0x02, # centivolts (RO)
   REG_IOUT    => 0x03, # miliiamps (RO)
   REG_POWER   => 0x04, # (RO)
   REG_UIN     => 0x05, # centivolts (RO)
   REG_LOCK    => 0x06, # 0=off 1=on
   REG_PROTECT => 0x07, # 0=ok, 1=OVP 2=OCP 3=OPP
   REG_CVCC    => 0x08, # 0=CV 1=CC
   REG_ONOFF   => 0x09, # 0=off 1=on
   REG_B_LED   => 0x0A,
   REG_MODEL   => 0x0B, # (RO)
   REG_VERSION => 0x0C, # (RO)
};

=head2 set_voltage

   await $psu->set_voltage( $volts );

Sets the output voltage, in volts.

=cut

async method set_voltage ( $voltage )
{
   await $self->_write_single_register( REG_USET, $voltage * 100 );
}

=head2 set_current

   await $psu->set_current( $amps );

Sets the output current, in amps.

=cut

async method set_current ( $current )
{
   await $self->_write_single_register( REG_ISET, $current * 1000 );
}

my %READINGS;

# Build up all the reading methods
BEGIN {
   use Object::Pad qw( :experimental(mop) );

   my $metaclass = Object::Pad::MOP::Class->for_caller;

   %READINGS = ( # register, scale
      output_voltage => [ REG_UOUT,    sub { $_ /  100 } ],
      output_current => [ REG_IOUT,    sub { $_ / 1000 } ],
      input_voltage  => [ REG_UIN,     sub { $_ /  100 } ],
      output_protect => [ REG_PROTECT, sub { (qw( ok OVP OCP OPP ))[$_]} ],
      output_mode    => [ REG_CVCC,    sub { (qw( CV CC ))[$_] } ],
   );

   foreach my $name ( keys %READINGS ) {
      $metaclass->add_method(
         "read_$name" => async method { return await $self->read_multiple( $name ) }
      );
   }
}

=head2 read_output_voltage

   $volts = await $psu->read_output_voltage;

Returns the measured voltage at the output terminals, in volts.

=head2 read_output_current

   $amps = await $psu->read_output_current;

Returns the measured current at the output terminals, in amps.

=head2 read_input_voltage

   $volts = await $psu->read_input_voltage;

Returns the input voltage to the PSU module, in volts.

=head2 read_output_protect

   $protect = await $psu->read_output_protect;

Returns the output protection state as a string, either C<"ok"> if protection
has not been triggered, or one of C<"OVP">, C<"OCP"> or C<"OPP"> if any of the
protection mechanisms have been triggered.

=head2 read_output_mode

   $mode = await $psu->read_output_mode;

Returns the output mode, as a string either C<"CV"> for constant-voltage or
C<"CC"> for constant-current.

=cut

=head2 read_multiple

   @readings = await $psu->read_multiple( @names )

Returns multiple measurements in a single query. This is faster than
performing several individual read requests. C<@names> should be a list of
string names, taken from the C<read_...> method names. For example:

   my ( $volts, $amps ) =
      await $psu->read_multiple(qw( output_voltage output_current ));

Results are returned in the same order as the requested names.

=cut

async method read_multiple ( @names )
{
   my ( $minreg, $maxreg );

   my @regs = map {
      my $m = $READINGS{$_} or croak "Measurement '$_' is not recognised";
      my $reg = $m->[0];
      $minreg = $reg if !defined $minreg or $reg < $minreg;
      $maxreg = $reg if !defined $maxreg or $reg > $maxreg;
   } @names;

   my @values = await $self->_read_holding_registers( $minreg, $maxreg-$minreg+1 );

   return map {
      my $m = $READINGS{$_};
      $m->[1]->( local $_ = $values[$m->[0] - $minreg] );
   } @names;
}

=head2 set_output_state

   await $psu->set_output_state( $on );

Switches output on / off.

=cut

async method set_output_state ( $on )
{
   await $self->_write_single_register( REG_ONOFF, !!$on );
}

=head2 read_model

   $model = await $psu->read_model;

Returns the model number (e.g. 3005 for F<DPS3005>).

=cut

async method read_model
{
   return await $self->_read_holding_registers( REG_MODEL );
}

=head2 read_version

   $version = await $psu->read_version;

Returns firmware version as an integer.

=cut

async method read_version
{
   return await $self->_read_holding_registers( REG_VERSION );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
