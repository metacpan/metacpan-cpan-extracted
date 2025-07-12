#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023-2025 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800 ':experimental(adjust_params)';

package Device::Serial::SLuRM::Protocol 0.09;
class Device::Serial::SLuRM::Protocol;

use Carp;

use Future::AsyncAwait;
use Future::Buffer 0.03;
use Future::IO;

use Digest::CRC qw( crc8 );

use constant DEBUG => $ENV{SLURM_DEBUG} // 0;

=encoding UTF-8

=head1 NAME

C<Device::Serial::SLuRM::Protocol> - implements the lower-level packet format of the SLµRM protocol

=head1 DESCRIPTION

This class provides the inner logic used by L<Device::Serial::SLuRM> and
L<Device::Serial::MSLuRM>.

=cut

use constant {
   SLURM_PKTCTRL_META   => 0x00,
      SLURM_PKTCTRL_META_RESET    => 0x01,
      SLURM_PKTCTRL_META_RESETACK => 0x02,

   SLURM_PKTCTRL_NOTIFY => 0x10,

   SLURM_PKTCTRL_REQUEST => 0x30,

   SLURM_PKTCTRL_RESPONSE => 0xB0,
   SLURM_PKTCTRL_ACK      => 0xC0,
   SLURM_PKTCTRL_ERR      => 0xE0,
};

# Metrics support is entirely optional
our $METRICS;
eval {
   require Metrics::Any and Metrics::Any->VERSION( '0.05' ) and
      Metrics::Any->import( '$METRICS', name_prefix => [ 'slurm' ] );
};

my %PKTTYPE_NAME;

if( defined $METRICS ) {
   $METRICS->make_counter( discards =>
      description => "Number of received packets discarded due to CRC check",
   );

   $METRICS->make_counter( packets =>
      description => "Number of packets sent and received, by type",
      labels => [qw( dir type )],
   );

   $METRICS->make_distribution( request_success_attempts =>
      description => "How many requests eventually succeeded after a given number of transmissions",
      units => "",
      buckets => [ 1 .. 3 ],
   );

   $METRICS->make_timer( request_duration =>
      description => "How long it took to get a response to each request",
      buckets => [ 0.001, 0.002, 0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5 ],
   );

   $METRICS->make_counter( retransmits =>
      description => "Number of retransmits of packets",
   );

   $METRICS->make_counter( serial_bytes =>
      description => "Total number of bytes sent and received on the serial link",
      labels => [qw( dir )],
   );

   $METRICS->make_counter( timeouts =>
      description => "Number of transactions that were abandoned due to eventual timeout",
   );

   %PKTTYPE_NAME = map { __PACKAGE__->can( "SLURM_PKTCTRL_$_" )->() => $_ }
      qw( META NOTIFY REQUEST RESPONSE ERR ACK );

   # Keep prometheus increase() happy by initialising all the counters to zero
   $METRICS->inc_counter_by( discards => 0 );
   foreach my $dir (qw( rx tx )) {
      $METRICS->inc_counter_by( packets => 0, [ dir => $dir, type => $_ ] ) for values %PKTTYPE_NAME;
      $METRICS->inc_counter_by( serial_bytes => 0, [ dir => $dir ] );
   }
   $METRICS->inc_counter_by( retransmits => 0 );
   $METRICS->inc_counter_by( timeouts => 0 );
}

field $_fh :param = undef;

field $_multidrop :param = 0;

# To calculate baud-independent timeout values we need a rough estimate of the
# time to send each byte
field $_bps :reader;

ADJUST :params (
   :$dev    = undef,
   :$baud //= 115200,
) {
   if( defined $_fh ) {
      # fine
      $_bps = $baud / 10;
   }
   elsif( defined $dev ) {
      require IO::Termios;

      $_fh = IO::Termios->open( $dev, "$baud,8,n,1" ) or
         croak "Cannot open device $dev - $!";

      $_fh->cfmakeraw;

      $_bps = $_fh->getobaud / 10;
   }
   else {
      croak "Require either a 'dev' or 'fh' parameter";
   }
}

field $_recv_buffer;

async method recv
{
   $_recv_buffer //= Future::Buffer->new(
      fill => sub {
         my $f = Future::IO->sysread( $_fh, 8192 );
         $f->on_done( sub { $METRICS->inc_counter_by( serial_bytes => length $_[0], [ dir => "rx" ] ) } )
            if $METRICS;
         $f->on_done( sub { printf STDERR "SLuRM DEV READ: %v02X\n", $_[0] } )
            if DEBUG > 2;
         $f;
      },
   );

   my $headerlen = 3 + !!$_multidrop;

   PACKET: {
      await $_recv_buffer->read_until( qr/\x55/ );

      defined( my $pkt = await $_recv_buffer->read_exactly( $headerlen ) )
         or return; # EOF

      my ( $pktctrl, $addr, $len );
      $_multidrop ? ( ( $pktctrl, $addr, $len ) = unpack "C C C", $pkt )
                  : ( ( $addr, $pktctrl, $len ) = ( 0, unpack "C C", $pkt ) );

      if( crc8( $pkt ) != 0 ) {
         # Header checksum failed
         $METRICS and
            $METRICS->inc_counter( discards => );

         $pkt =~ m/\x55/ and
            $_recv_buffer->unread( substr $pkt, $-[0] );
         redo PACKET;
      }

      $pkt .= await $_recv_buffer->read_exactly( $len + 1 );

      if( crc8( $pkt ) != 0 ) {
         # Body checksum failed
         $METRICS and
            $METRICS->inc_counter( discards => );

         $pkt =~ m/\x55/ and
            $_recv_buffer->unread( substr $pkt, $-[0] );
         redo PACKET;
      }

      my $payload = substr( $pkt, $headerlen, $len );

      printf STDERR "SLuRM <-RX%s {%02X/%v02X}\n",
         ( $_multidrop ? sprintf "(%d)", $addr : "" ), $pktctrl, $payload
            if DEBUG > 1;

      $METRICS and
         $METRICS->inc_counter( packets => [ dir => "rx", type => $PKTTYPE_NAME{ $pktctrl & 0xF0 } // "UNKNOWN" ] );

      return $pktctrl, $addr, $payload;
   }
}

async method send ( $pktctrl, $addr, $payload )
{
   printf STDERR "SLuRM TX%s-> {%02X/%v02X}\n",
      ( $_multidrop ? sprintf "(%d)", $addr & 0x7F : "" ), $pktctrl, $payload
         if DEBUG > 1;

   my $bytes = $_multidrop
      ? pack( "C C C", $pktctrl, $addr // die( "ADDR must be defined for multidrop" ), length $payload )
      : pack( "C C", $pktctrl, length $payload );
   $bytes .= pack( "C", crc8( $bytes ) );

   $bytes .= $payload;
   $bytes .= pack( "C", crc8( $bytes ) );

   $METRICS and
      $METRICS->inc_counter( packets => [ dir => "tx", type => $PKTTYPE_NAME{ $pktctrl & 0xF0 } // "UNKNOWN" ] );
   $METRICS and
      $METRICS->inc_counter_by( serial_bytes => 1 + length $bytes, [ dir => "tx" ] );

   printf STDERR "SLuRM DEV WRITE: %v02X\n", "\x55" . $bytes
      if DEBUG > 2;

   return await Future::IO->syswrite_exactly( $_fh, "\x55" . $bytes );
}

async method interpacket_delay ()
{
   # wait 20-ish byte times as a gap between packets
   await Future::IO->sleep( 20 / $_bps );
}

async method send_twice ( $pktctrl, $node_id, $payload )
{
   await $self->send( $pktctrl, $node_id, $payload );

   await $self->interpacket_delay;

   await $self->send( $pktctrl, $node_id, $payload );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
