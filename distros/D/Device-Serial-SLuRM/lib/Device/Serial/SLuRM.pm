#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.73 ':experimental(init_expr adjust_params)';

package Device::Serial::SLuRM 0.04;
class Device::Serial::SLuRM;

use Carp;

use Syntax::Keyword::Match;

use Future::AsyncAwait;
use Future::Buffer 0.03;
use Future::IO;

use Digest::CRC qw( crc8 );
use Time::HiRes qw( gettimeofday tv_interval );

use constant DEBUG => $ENV{SLURM_DEBUG} // 0;

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

=encoding UTF-8

=head1 NAME

C<Device::Serial::SLuRM> - communicate the SLµRM protocol over a serial port

=head1 SYNOPSIS

   use v5;36;
   use Device::Serial::SLuRM;

   my $slurm = Device::Serial::SLuRM->new(
      dev  => "/dev/ttyUSB0",
      baud => 19200,
   );

   $slurm->run(
      on_notify => sub ($payload) {
         printf "NOTIFY: %v02X\n", $payload;
      }
   )->await;

=head1 DESCRIPTION

This module provides a L<Future::IO>-based interface for communicating with
a peer device on a serial port (or similar device handle) which talks the
SLµRM messaging protocol. It supports sending and receiving of NOTIFY
packets, and sending of REQUEST packets that receive a RESPONSE.

It currently does not support receiving REQUESTs, though this could be added
relatively easily.

=head2 SLµRM

SLµRM ("Serial Link Microcontroller Reliable Messaging") is a simple
bidirectional communication protocol for adding reliable message framing and
request/response semantics to byte-based data links (such as asynchronous
serial ports), which may themselves be somewhat unreliable. SLµRM can tolerate
bytes arriving corrupted or going missing altogether, or additional noise
bytes being received, while still maintaining a reliable bidirectional flow of
messages. There are two main kinds of message flows - NOTIFYs and REQUESTs. In
all cases, packet payloads can be of a variable length (including zero bytes),
and the protocol itself does not put semantic meaning on those bytes - they
are free for the application to use as required.

A NOTIFY message is a simple notification from one peer to the other, that
does not yield a response.

A REQUEST message carries typically some sort of command instruction, to which
the peer should respond with a RESPONSE or ERR packet. Replies to a REQUEST
message do not have to be sent sequentially.

The F<doc/> directory of this distribution contains more detailed protocol
documentation which may be useful for writing other implementations.

The F<contrib/> directory of this distribution contains a reference
implementation in C for 8-bit microcontrollers, such as AVR ATtiny and ATmega
chips.

=cut

=head2 Metrics

If L<Metrics::Any> is available, this module additionally provides metrics
under the namespace prefix of C<slurm>. The following metrics are provided:

=over 4

=item discards

An unlabelled counter tracking the number of times a received packet is
discarded due to failing CRC check.

=item packets

A counter, labelled by direction and packet type, tracking the number of
packets sent and received of each type.

=item retransmits

An unlabelled counter tracking the number of times a (REQUEST) packet had to
be retransmitted after the initial one timed out.

=item serial_bytes

A counter, labelled by direction, tracking the number of bytes sent and
received directly over the serial port. The rate of this can be used to
calculate overall serial link utilisation.

=item timeouts

An unlabelled counter tracking the number of times a request transaction was
abandoned entirely due to a timeout. This does I<not> count transactions that
eventually succeeded after intermediate timeouts and retransmissions.

=back

=cut

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
      description => "Number of SLµRM packets sent and received, by type",
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

=head1 PARAMETERS

=head2 dev

   dev => PATH

Path to the F</dev/...> device node representing the serial port used for this
communication. This will be opened via L<IO::Termios> and configured into the
appropriate mode and baud rate.

=head2 baud

   baud => NUM

Optional baud rate to set for communication when opening a device node.

SLµRM does not specify a particular rate, but a default value of 115.2k will
apply if left unspecified.

=head2 fh

   fh => IO

An IO handle directly to the the serial port device to be used for reading and
writing. It will be assumed to be set up correctly; no further setup will be
performed.

Either C<dev> or C<fh> are required.

=head2 retransmit_delay

   retransmit_delay => NUM

Optional delay in seconds to wait after a non-response of a REQUEST packet
before sending it again. A default of 50msec (0.05) will apply if not
specified.

Applications that transfer large amounts of data over slow links, or for which
responding to a command may take a long time, should increase this value.

=head2 retransmit_count

   retransmit_count => NUM

Optional number of additional attempts to try sending REQUEST packets before
giving up entirely. A default of 2 will apply if not specified (thus each
C<request> method will make up to 3 attempts).

=cut

field $_fh :param = undef;

ADJUST :params (
   :$dev    = undef,
   :$baud //= 115200,
) {
   if( defined $_fh ) {
      # fine
   }
   elsif( defined $dev ) {
      require IO::Termios;

      $_fh = IO::Termios->open( $dev, "$baud,8,n,1" ) or
         croak "Cannot open device $dev - $!";

      $_fh->cfmakeraw;
   }
   else {
      croak "Require either a 'dev' or 'fh' parameter";
   }
}

field $_retransmit_delay :param = 0.05;
field $_retransmit_count :param = 2;

field $_on_notify;

field $_did_reset;

field $_seqno_tx = 0 ;
field $_seqno_rx :reader(_seqno_rx); # :reader just for unit-test purposes

=head1 METHODS

=cut

=head2 recv_packet

   ( $pktctrl, $payload ) = await $slurm->recv_packet;

Waits for and returns the next packet to be received from the serial port.

=cut

field $_recv_buffer;

field $_next_resetack_f;

async method recv_packet
{
   $_recv_buffer //= Future::Buffer->new(
      fill => $METRICS
         ? sub {
            Future::IO->sysread( $_fh, 8192 )
               ->on_done( sub { $METRICS->inc_counter_by( serial_bytes => length $_[0], [ dir => "rx" ] ) } );
            }
         : sub { Future::IO->sysread( $_fh, 8192 ) },
   );

   PACKET: {
      await $_recv_buffer->read_until( qr/\x55/ );

      my ( $pktctrl, $len ) = unpack "C C", my $pkt = await $_recv_buffer->read_exactly( 3 );

      if( crc8( $pkt ) != 0 ) {
         # Header checksum failed
         $METRICS and
            $METRICS->inc_counter( discards => );

         $_recv_buffer->unread( $pkt ) if $pkt =~ m/\x55/;
         redo PACKET;
      }

      $pkt .= await $_recv_buffer->read_exactly( $len + 1 );

      if( crc8( $pkt ) != 0 ) {
         # Body checksum failed
         $METRICS and
            $METRICS->inc_counter( discards => );

         $_recv_buffer->unread( $pkt ) if $pkt =~ m/\x55/;
         redo PACKET;
      }

      my $payload = substr( $pkt, 3, $len );

      printf STDERR "SLuRM <-RX {%02X/%v02X}\n", $pktctrl, $payload
         if DEBUG > 1;

      $METRICS and
         $METRICS->inc_counter( packets => [ dir => "rx", type => $PKTTYPE_NAME{ $pktctrl & 0xF0 } // "UNKNOWN" ] );

      return $pktctrl, $payload;
   }
}

field @_pending_slots; # [$seqno] = { payload, response_f }
field $_run_f;

async method _run
{
   while(1) {
      my ( $pktctrl, $payload ) = await $self->recv_packet;
      my $seqno = $pktctrl & 0x0F;
      $pktctrl &= 0xF0;

      if( $pktctrl == SLURM_PKTCTRL_META ) {
         if( $seqno == SLURM_PKTCTRL_META_RESET or
               $seqno == SLURM_PKTCTRL_META_RESETACK ) {
            ( $_seqno_rx ) = unpack "C", $payload;

            if( $seqno == SLURM_PKTCTRL_META_RESET ) {
               await $self->send_packet( SLURM_PKTCTRL_META_RESETACK, pack "C", $_seqno_tx );
            }
            else {
               $_next_resetack_f->done if $_next_resetack_f;
            }
         }
         else {
            warn sprintf "No idea what to do with pktctrl(meta) = %02X\n", $seqno;
         }

         next;
      }

      my $is_dup;
      if( !( $pktctrl & 0x80 ) ) {
         if( defined $_seqno_rx ) {
            my $seqdiff = $seqno - $_seqno_rx;
            $seqdiff += 16 if $seqdiff < 0;
            $is_dup = !$seqdiff || $seqdiff > 8; # suppress duplicates / backsteps
         }

         $_seqno_rx = $seqno;
      }

      match( $pktctrl : == ) {
         case( SLURM_PKTCTRL_NOTIFY ) {
            next if $is_dup;

            printf STDERR "SLuRM rx-NOTIFY(%d): %v02X\n", $seqno, $payload
               if DEBUG;

            $_on_notify ? $_on_notify->( $payload )
                        : warn "Received NOTIFY packet with no handler\n";
         }

         case( SLURM_PKTCTRL_RESPONSE ),
         case( SLURM_PKTCTRL_ERR ) {
            my $slot = $_pending_slots[$seqno];
            unless( $slot ) {
               warn "Received reply to unsent request seqno=$seqno\n";
               next;
            }

            $METRICS and
               $METRICS->report_timer( request_duration => tv_interval $slot->{start_time} );

            if( $pktctrl == SLURM_PKTCTRL_RESPONSE ) {
               printf STDERR "SLuRM rx-RESPONSE(%d): %v02X\n", $seqno, $payload
                  if DEBUG;

               $slot->{response_f}->done( $payload );
            }
            else {
               printf STDERR "SLuRM rx-ERR(%d): %v02X\n", $seqno, $payload
                  if DEBUG;

               my $message = sprintf "Received ERR packet <%v02X%s>",
                  substr( $payload, 0, 3 ),
                  length $payload > 3 ? "..." : "";
               $slot->{response_f}->fail( $message, slurm => $payload );
            }
            $slot->{retransmit_f}->cancel;

            $METRICS and
               $METRICS->report_distribution( request_success_attempts => 1 + $_retransmit_count - $slot->{retransmit_count} );

            undef $_pending_slots[$seqno];

            printf STDERR "SLuRM tx-ACK(%d)\n", $seqno
               if DEBUG;

            await $self->send_packet_twice( SLURM_PKTCTRL_ACK | $seqno, "" );
         }
         default {
            die sprintf "TODO: Received unrecognised packet type=%02X\n", $pktctrl;
         }
      }
   }
}

# undocumented but useful for unit tests
method _start
{
   $_run_f //= $self->_run->on_fail( sub { die "Device::Serial::SLuRM runloop failed: $_[0]" } );

   return $_run_f;
}

=head2 run

   $run_f = $slurm->run( %args );

Starts the receiver run-loop, which can be used to wait for incoming NOTIFY
packets. This method returns a future, but the returned future will not
complete in normal circumstances. It will remain pending while the run-loop is
running. If an unrecoverable error happens (such as an IO error on the
underlying serial port device) then this future will fail.

Takes the following named arguments:

=over 4

=item on_notify => CODE

   $on_notify->( $payload )

Optional. Invoked on receipt of a NOTIFY packet.

=back

Will automatically L</reset> first if required.

=cut

async method run ( %args )
{
   $_on_notify = $args{on_notify}; # TODO: save old, restore on exit?

   $_did_reset or
      await $self->reset;

   await $self->_start
      ->on_cancel( sub { undef $_on_notify } );
}

=head2 stop

   $slurm->stop;

Stops the receiver run-loop, if running, causing its future to be cancelled.

It is not an error to call this method if the run loop is not running.

=cut

method stop
{
   return unless $_run_f;

   eval { $_run_f->cancel } or warn "Failed to ->cancel the runloop future - $@";
   undef $_run_f;
}

=head2 send_packet

   await $slurm->send_packet( $pktctrl, $payload );

Sends a packet to the serial port.

=cut

async method send_packet ( $pktctrl, $payload )
{
   printf STDERR "SLuRM TX-> {%02X/%v02X}\n", $pktctrl, $payload
      if DEBUG > 1;

   my $bytes = pack( "C C", $pktctrl, length $payload );
   $bytes .= pack( "C", crc8( $bytes ) );

   $bytes .= $payload;
   $bytes .= pack( "C", crc8( $bytes ) );

   $METRICS and
      $METRICS->inc_counter( packets => [ dir => "tx", type => $PKTTYPE_NAME{ $pktctrl & 0xF0 } // "UNKNOWN" ] );
   $METRICS and
      $METRICS->inc_counter_by( serial_bytes => 1 + length $bytes, [ dir => "tx" ] );

   return await Future::IO->syswrite_exactly( $_fh, "\x55" . $bytes );
}

async method send_packet_twice ( $pktctrl, $payload )
{
   await $self->send_packet( $pktctrl, $payload );
   # TODO: Send again after a short delay
   await $self->send_packet( $pktctrl, $payload );
}

=head2 reset

   $slurm->reset;

Resets the transmitter sequence number and sends a META-RESET packet.

It is not normally required to explicitly call this, as the first call to
L</run>, L</send_notify> or L</request> will do it if required.

=cut

async method reset
{
   $_seqno_tx = 0;

   await $self->send_packet_twice( SLURM_PKTCTRL_META_RESET, pack "C", $_seqno_tx );
   $_did_reset = 1;

   $self->_start;

   # TODO: These might collide, do we need a Queue?
   await $_next_resetack_f = $_run_f->new;
   undef $_next_resetack_f;
}

=head2 send_notify

   await $slurm->send_notify( $payload )

Sends a NOTIFY packet.

Will automatically L</reset> first if required.

=cut

async method send_notify ( $payload )
{
   $_did_reset or
      await $self->reset;

   ( $_seqno_tx += 1 ) &= 0x0F;
   my $pktctrl = SLURM_PKTCTRL_NOTIFY | $_seqno_tx;

   await $self->send_packet_twice( $pktctrl, $payload );
}

=head2 request

   $data_in = await $slurm->request( $data_out );

Sends a REQUEST packet, and waits for a response to it.

If the peer responds with an ERR packet, the returned future will fail with
an error message, the category of C<slurm>, and the payload body of the ERR
packet in the message details:

   $f->fail( $message, slurm => $payload );

If the peer does not respond at all and all retransmit attempts end in a
timeout, the returned future will fail the same way but with C<undef> as the
message details:

   $f->fail( $message, slurm => undef );

Will automatically L</reset> first if required.

=cut

async method request ( $payload )
{
   $_did_reset or
      await $self->reset;

   ( $_seqno_tx += 1 ) &= 0x0F;
   my $seqno = $_seqno_tx;

   printf STDERR "SLuRM tx-REQUEST(%d): %v02X\n", $seqno, $payload
      if DEBUG;

   $_pending_slots[$seqno] and croak "TODO: Request seqno collision - pick a new one?";

   my $pktctrl = SLURM_PKTCTRL_REQUEST | $seqno;

   await $self->send_packet( $pktctrl, $payload );

   $self->_start;

   $_pending_slots[$seqno] = {
      payload          => $payload,
      response_f       => my $f = $_run_f->new,
      retransmit_count => $_retransmit_count,
      start_time       => [ gettimeofday ],
   };

   $self->_set_retransmit( $seqno );

   return await $f;
}

method _set_retransmit ( $seqno )
{
   my $slot = $_pending_slots[$seqno] or die "ARG expected $seqno request";

   $slot->{retransmit_f} = Future::IO->sleep( $_retransmit_delay )
      ->on_done( sub {
         if( $slot->{retransmit_count}-- ) {
            printf STDERR "SLuRM retransmit REQUEST(%d)\n", $seqno
               if DEBUG;

            my $pktctrl = SLURM_PKTCTRL_REQUEST | $seqno;
            $slot->{retransmit_f} = $self->send_packet( $pktctrl, $slot->{payload} )
               ->on_fail( sub {
                  warn "Retransmit failed: @_";
                  $slot->{response_f}->fail( @_ );
               } )
               ->on_done( sub {
                  $self->_set_retransmit( $seqno );
               } );

            $METRICS and
               $METRICS->inc_counter( retransmits => );
         }
         else {
            printf STDERR "SLuRM timeout REQUEST(%d)\n", $seqno
               if DEBUG;

            my $message = sprintf "Request timed out after %d attempts\n", 1 + $_retransmit_count;
            $slot->{response_f}->fail( $message, slurm => undef );

            $METRICS and
               $METRICS->inc_counter( timeouts => );

            undef $_pending_slots[$seqno];
         }
      });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
