#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2022-2025 -- leonerd@leonerd.org.uk

use v5.28;  # delete %hash{@slice}
use warnings;
use Object::Pad 0.807 ':experimental(adjust_params)';

package Device::Serial::SLuRM 0.09;
class Device::Serial::SLuRM;

use Carp;

use Syntax::Keyword::Match;

use Future::AsyncAwait;
use Future::IO;
use Future::Selector 0.02; # ->run_until_ready

use Time::HiRes qw( gettimeofday tv_interval );

use constant DEBUG => $ENV{SLURM_DEBUG} // 0;

require Device::Serial::SLuRM::Protocol;
no warnings 'once';
our $METRICS = $Device::Serial::SLuRM::Protocol::METRICS;

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

   use v5.36;
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

Optionally, this module supports being the controller for a multi-drop
("MSLµRM") bus. See the L<Device::Serial::MSLuRM> subclass.

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

=item request_success_attempts

A distribution that tracks how many attempts it took to get a response to each
request.

=item request_duration

A timer that tracks how long it took to get a response to each request.

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
before sending it again. 

A default value will be calculated if not specified. This is based on the
serial link baud rate. At the default 115.2k baud it will be 50msec (0.05);
the delay will be scaled appropriately for other baud rates, to maintain a
timeout of the time it would take to send 576 bytes.

Applications that transfer large amounts of data over slow links, or for which
responding to a command may take a long time, should increase this value.

=head2 retransmit_count

   retransmit_count => NUM

Optional number of additional attempts to try sending REQUEST packets before
giving up entirely. A default of 2 will apply if not specified (thus each
C<request> method will make up to 3 attempts).

=cut

use constant is_multidrop => 0;

use Object::Pad ':experimental(inherit_field)';
field $_protocol :inheritable; # TODO
ADJUST :params ( %params )
{
   $_protocol = Device::Serial::SLuRM::Protocol->new(
      multidrop => __CLASS__->is_multidrop,
      delete %params{qw( fh dev baud )},
   );
}

field $_retransmit_delay :param = undef;
field $_retransmit_count :param //= 2;

ADJUST
{
   if( !defined $_retransmit_delay ) {
      # At 115200baud (being 11520 bytes/sec presuming 1 start, no parity,
      # 1 stop) we should get 0.05 sec delay; this is the time taken to
      # transmit 576 bytes.
      $_retransmit_delay = 576 / $_protocol->bps;
   }
}

field $_on_notify;
field $_on_request;

class Device::Serial::SLuRM::_NodeState {
   field $did_reset :mutator;

   field $seqno_tx  :mutator = 0;
   field $seqno_rx  :mutator = 0;

   field @_pending_slots; # [$seqno] = { payload, response_f }

   method pending_slot ( $seqno ) { return $_pending_slots[ $seqno ] }
   method set_pending_slot ( $seqno, $data ) { $_pending_slots[ $seqno ] = $data; }
   method clear_pending_slot ( $seqno ) { undef $_pending_slots[ $seqno ]; }
}

field @_nodestate; # keyed per peer node ID

field $_rx_nodestate; # a second set of pending slots for received REQUESTs

=head1 METHODS

=cut

=head2 recv_packet

   ( $pktctrl, $payload ) = await $slurm->recv_packet;

Waits for and returns the next packet to be received from the serial port.

=cut

field $_next_resetack_f;

async method recv_packet ()
{
   my ( $pktctrl, undef, $payload ) = await $_protocol->recv;
   return ( $pktctrl, $payload );
}

field $_run_f;

async method _run
{
   while(1) {
      my ( $pktctrl, $addr, $payload ) = await $_protocol->recv
         or return; # EOF

      redo if $addr & 0x80; # controller reflection

      my $node_id = $addr;

      my $seqno = $pktctrl & 0x0F;
      $pktctrl &= 0xF0;

      my $nodestate = $_nodestate[ $node_id ] //= Device::Serial::SLuRM::_NodeState->new;

      if( $pktctrl == SLURM_PKTCTRL_META ) {
         match( $seqno : == ) {
            case( SLURM_PKTCTRL_META_RESET ),
            case( SLURM_PKTCTRL_META_RESETACK ) {
               ( $nodestate->seqno_rx ) = unpack "C", $payload;

               if( $seqno == SLURM_PKTCTRL_META_RESET ) {
                  await $self->send_packet( SLURM_PKTCTRL_META_RESETACK, pack "C", $nodestate->seqno_tx );
               }
               else {
                  $_next_resetack_f->done if $_next_resetack_f;
               }
            }
            default {
               warn sprintf "No idea what to do with pktctrl(meta) = %02X\n", $seqno;
            }
         }

         next;
      }

      my $is_dup;
      if( !( $pktctrl & 0x80 ) ) {
         if( defined $nodestate->seqno_rx ) {
            my $seqdiff = $seqno - $nodestate->seqno_rx;
            $seqdiff += 16 if $seqdiff < 0;
            $is_dup = !$seqdiff || $seqdiff > 8; # suppress duplicates / backsteps
         }

         $nodestate->seqno_rx = $seqno;
      }

      match( $pktctrl : == ) {
         case( SLURM_PKTCTRL_NOTIFY ) {
            next if $is_dup;

            printf STDERR "SLuRM rx-NOTIFY(%d): %v02X\n", $seqno, $payload
               if DEBUG;

            $_on_notify ? $_on_notify->( ( __CLASS__->is_multidrop ? ( $node_id ) : () ), $payload )
                        : warn "Received NOTIFY packet with no handler\n";
         }

         case( SLURM_PKTCTRL_REQUEST ) {
            printf STDERR "SLuRM rx-REQUEST(%d): %v02X\n", $seqno, $payload
               if DEBUG;

            $_rx_nodestate //= Device::Serial::SLuRM::_NodeState->new;
            if( my $slot = $_rx_nodestate->pending_slot( $seqno ) ) {
               await $self->_send_response( $node_id, $seqno, $slot->{payload} )
                  if defined $slot->{payload};
            }
            else {
               next if $is_dup;

               # TODO: If multidrop we need to ignore requests except for us

               $_rx_nodestate->set_pending_slot( $seqno,
                  {
                     # no payload yet
                     start_time => [ gettimeofday ],
                  }
               );

               if( $_on_request ) {
                  $_on_request->( $seqno, $payload );
               }
               else {
                  warn "Received REQUEST packet with no handler\n";
               }
            }
         }

         case( SLURM_PKTCTRL_RESPONSE ),
         case( SLURM_PKTCTRL_ERR ) {
            my $slot = $nodestate->pending_slot( $seqno );
            unless( $slot ) {
               warn "Received reply to unsent request seqno=$seqno\n";
               next;
            }

            $METRICS and
               $METRICS->report_timer( request_duration => tv_interval $slot->{start_time} );

            # Send the first ACK before completing the future
            printf STDERR "SLuRM tx-ACK(%d)\n", $seqno
               if DEBUG;

            await $_protocol->send( SLURM_PKTCTRL_ACK | $seqno, $node_id | 0x80, "" );

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

            $nodestate->clear_pending_slot( $seqno );

            # Second ACK
            await $_protocol->interpacket_delay;
            await $_protocol->send( SLURM_PKTCTRL_ACK | $seqno, $node_id | 0x80, "" );
         }

         case( SLURM_PKTCTRL_ACK ) {
            $_rx_nodestate or next;
            my $slot = $_rx_nodestate->pending_slot( $seqno ) or next;

            $_rx_nodestate->clear_pending_slot( $seqno );
         }

         default {
            warn sprintf "Received unrecognised packet type=%02X\n", $pktctrl;
         }
      }
   }
}

field $_selector;
method _selector
{
   return $_selector if $_selector;

   $_selector = Future::Selector->new;
   $_selector->add(
      data => "runloop",
      f    => $_run_f = $self->_run
         ->set_label( "Device::Serial::SLuRM runloop" )
         ->on_fail( sub { die "Device::Serial::SLuRM runloop failed: $_[0]" } ),
   );

   return $_selector;
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

async method _autoreset
{
   my $nodestate = $_nodestate[0] //= Device::Serial::SLuRM::_NodeState->new;

   $nodestate->did_reset or
      await $self->_reset( 0 );
}

async method run ( %args )
{
   $_on_notify = $args{on_notify}; # TODO: save old, restore on exit?

   my $s = $self->_selector;
   my $f = $_run_f;

   # Ugh this is a terrible way to do this
   if( my $handle_request = $args{handle_request} ) {
      # Currently undocumented pending an idea of how to do a receiver subclass
      $_on_request = sub {
         my ( $seqno, $payload ) = @_;

         my $ret_f = $handle_request->( $payload )
            ->then(
               sub { # on_done
                  my ( $response ) = @_;
                  # TODO: insert my own node ID
                  # TODO: Consider reporting a metric?
                  return $self->_send_response( 0, $seqno, $response );
               },
               sub { # on_fail
                  # TODO: Consider reporting a metric?
                  warn "TODO: handle_request failed, we should send ERR somehow";
               },
            );

         $s->add( f => $ret_f, data => undef );
      };
   }

   await $self->_autoreset;

   await $s->run_until_ready( $f );
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
   undef $_selector;
}

=head2 send_packet

   await $slurm->send_packet( $pktctrl, $payload );

Sends a packet to the serial port.

=cut

async method send_packet ( $pktctrl, $payload ) { await $_protocol->send( $pktctrl, undef, $payload ); }

=head2 reset

   $slurm->reset;

Resets the transmitter sequence number and sends a META-RESET packet.

It is not normally required to explicitly call this, as the first call to
L</run>, L</send_notify> or L</request> will do it if required.

=cut

method reset () { $self->_reset( 0 ); }

async method _reset ( $node_id )
{
   my $s = $self->_selector;

   my $nodestate = $_nodestate[ $node_id ] //= Device::Serial::SLuRM::_NodeState->new;

   $nodestate->seqno_tx = 0;

   # Need to create this before sending because of unit testing
   $_next_resetack_f = $_run_f->new;

   await $_protocol->send_twice( SLURM_PKTCTRL_META_RESET, $node_id | 0x80, pack "C", $nodestate->seqno_tx );
   $nodestate->did_reset = 1;

   # TODO: These might collide, do we need a Queue?
   await $s->run_until_ready( Future->wait_any(
      $_next_resetack_f,
      Future::IO->sleep( $_retransmit_delay * 3 ),
   ) );
   die "Timed out waiting for reset\n"
      unless $_next_resetack_f->is_done;
   undef $_next_resetack_f;
}

=head2 send_notify

   await $slurm->send_notify( $payload );

Sends a NOTIFY packet.

Will automatically L</reset> first if required.

=cut

method send_notify ( $payload ) { $self->_send_notify( 0, $payload ); }

async method _send_notify ( $node_id, $payload )
{
   my $nodestate = $_nodestate[ $node_id ] //= Device::Serial::SLuRM::_NodeState->new;

   $nodestate->did_reset or
      await $self->_reset( $node_id );

   ( $nodestate->seqno_tx += 1 ) &= 0x0F;
   my $seqno = $nodestate->seqno_tx;

   printf STDERR "SLuRM tx-NOTIFY(%d): %v02X\n", $seqno, $payload
      if DEBUG;

   my $pktctrl = SLURM_PKTCTRL_NOTIFY | $seqno;

   await $_protocol->send_twice( $pktctrl, $node_id | 0x80, $payload );
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

method request ( $payload ) { $self->_request( 0, $payload ); }

async method _request ( $node_id, $payload )
{
   my $s = $self->_selector;

   my $nodestate = $_nodestate[ $node_id ] //= Device::Serial::SLuRM::_NodeState->new;

   $nodestate->did_reset or
      await $self->_reset( $node_id );

   ( $nodestate->seqno_tx += 1 ) &= 0x0F;
   my $seqno = $nodestate->seqno_tx;

   printf STDERR "SLuRM tx-REQUEST(%d): %v02X\n", $seqno, $payload
      if DEBUG;

   $nodestate->pending_slot( $seqno ) and croak "TODO: Request seqno collision - pick a new one?";

   my $pktctrl = SLURM_PKTCTRL_REQUEST | $seqno;

   await $_protocol->send( $pktctrl, $node_id | 0x80, $payload );

   $nodestate->set_pending_slot( $seqno,
      {
         payload          => $payload,
         response_f       => my $f = $_run_f->new,
         retransmit_count => $_retransmit_count,
         start_time       => [ gettimeofday ],
      }
   );

   $self->_set_retransmit( $node_id, $seqno );

   return await $f;
}

async method _send_response ( $node_id, $seqno, $payload )
{
   printf STDERR "SLuRM tx-RESPONSE(%d): %v02X\n", $seqno, $payload
      if DEBUG;

   my $pktctrl = SLURM_PKTCTRL_RESPONSE | $seqno;

   my $slot = ( $_rx_nodestate // die "ARGH cannot _send_response without a valid _rx_nodestate" )
      ->pending_slot( $seqno );

   $slot->{payload} = $payload;

   await $_protocol->send( $pktctrl, $node_id, $payload );
}

method _set_retransmit ( $node_id, $seqno )
{
   my $nodestate = $_nodestate[ $node_id ] //= Device::Serial::SLuRM::_NodeState->new;

   my $slot = $nodestate->pending_slot( $seqno ) or die "ARG expected $seqno request";

   $slot->{retransmit_f} = Future::IO->sleep( $_retransmit_delay )
      ->on_done( sub {
         if( $slot->{retransmit_count}-- ) {
            printf STDERR "SLuRM retransmit REQUEST(%d)\n", $seqno
               if DEBUG;

            my $pktctrl = SLURM_PKTCTRL_REQUEST | $seqno;
            $slot->{retransmit_f} = $_protocol->send( $pktctrl, $node_id, $slot->{payload} )
               ->on_fail( sub {
                  warn "Retransmit failed: @_";
                  $slot->{response_f}->fail( @_ );
               } )
               ->on_done( sub {
                  $self->_set_retransmit( $node_id, $seqno );
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

            $nodestate->clear_pending_slot( $seqno );
         }
      });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
