#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use utf8;

use Object::Pad 0.800;

package Device::Chip::PMS5003 0.01;
class Device::Chip::PMS5003
   :isa( Device::Chip );

use Device::Chip::Sensor 0.23 -declare;

use Future::AsyncAwait;

use constant PROTOCOL => "UART";

=head1 NAME

C<Device::Chip::PMS5003> - chip driver for F<PMS5003>

=head1 SYNOPSIS

   use Device::Chip::PMS5003;
   use Future::AsyncAwait;

   my $chip = Device::Chip::PMS5003->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   $chip->start;

   my $readings = await $chip->read_all;

   printf "Particulate matter readings are %d / %d / %d\n",
      @{$readings->{concentration}}{qw( pm1 pm2_5 pm10 )};

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<PLANTOWER> F<PMS5003> particle concentration sensor attached to a computer
via a UART adapter. (Though if the communication protocol is the same, it is
likely also useful for a variety of other related sensors too).

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

method UART_options
{
   return
      baudrate => 9600;
}

async method _loop
{
   my $buf = "";
   while(1) {
      # A complete notification is 32bytes long
      $buf .= await $self->protocol->read( 32 - length $buf );

      # A notification begins "\x42\x4D"
      $buf =~ s{.*(?=\x42\x4D)}{}s or next;

      # A notification should be header, length, data
      my ( $sof, $len ) = unpack( "a2 s>", $buf );
      # Buffer length should be 28
      $len == 28 or goto next_packet;
      4 + length $buf >= $len or next;

      my @data = unpack( "s>*", substr $buf, 4, 28 );
      my $got_checksum = pop @data;

      my $want_checksum = 0;
      $want_checksum += ord for split m//, substr $buf, 0, 30;

      if( $got_checksum != $want_checksum ) {
         # Checksum failed
         goto next_packet;
      }

      substr( $buf, 0, 32 ) = "";

      $self->on_data( @data );

      next;

next_packet:
      # It's possible the header we found was not a real header but in fact
      # spurious data in the middle of packet.
      substr( $buf, 0, 2 ) = "";

      # Trim down to the next plausible start
      $buf =~ s{^.*\x42\x4D}{}s or $buf = "";
      next;
   }
}

field $_reading_count = 0;
field $_latest_reading;
field $_next_reading_f;

method on_data ( @data )
{
   # From observation, the chip outputs a reading every second but only
   # updates its values every 3. We'll therefore ignore the next two
   if( !$_reading_count ) {
      $_latest_reading = {
         concentration => {
            pm1   => $data[0],
            pm2_5 => $data[1],
            pm10  => $data[2],
         },
         atmos => {
            pm1   => $data[3],
            pm2_5 => $data[4],
            pm10  => $data[5],
         },
         particles => {
            pm0_3 => $data[6],
            pm0_5 => $data[7],
            pm1   => $data[8],
            pm2_5 => $data[9],
            pm5   => $data[10],
            pm10  => $data[11],
         }
      };

      my $f = $_next_reading_f; undef $_next_reading_f;
      $f->done if $f;
   }

   $_reading_count++;
   $_reading_count = 0 if $_reading_count > 2;
}

=head2 start

   $chip->start;

Begins the UART reading loop. This must be called before you can use
L</read_all>.

=cut

field $_run_f;
method start
{
   $_run_f = $self->_loop
      ->on_fail( sub { warn "TODO: run loop stalled: ", @_ } );
}

async method initialize_sensors
{
   $self->start;
}

=head2 read_all

   $readings = await $chip->read_all;

Waits for the next report packet from the sensor, then returns the readings
contained in it. This is in the form of a two-level hash:

   concentration => HASH # containing pm1, pm2_5, pm10

   atmost => HASH        # containing pm1, pm2_5, pm10

   particles => HASH     # containing pm0_3, pm0_5, pm1, pm2_5, pm5, pm10

=cut

async method read_all
{
   $_run_f or
      die "Must call ->start before you can ->read_all";

   my $f = $_next_reading_f //= $_run_f->new;

   await $f;

   return $_latest_reading;
}

# TODO: Ideally this should be one parametric sensor, not three separate ones
declare_sensor pm1 =>
   method => async method { return ( await $self->read_all )->{concentration}{pm1} },
   units  => "µg/m³",
   precision => 0;

declare_sensor pm2_5 =>
   method => async method { return ( await $self->read_all )->{concentration}{pm2_5} },
   units  => "µg/m³",
   precision => 0;

declare_sensor pm10 =>
   method => async method { return ( await $self->read_all )->{concentration}{pm10} },
   units  => "µg/m³",
   precision => 0;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
