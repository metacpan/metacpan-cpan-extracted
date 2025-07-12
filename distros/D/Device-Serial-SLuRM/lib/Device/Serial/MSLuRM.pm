#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.807;

package Device::Serial::MSLuRM 0.09;
class Device::Serial::MSLuRM;

use Object::Pad ':experimental(inherit_field)';
inherit Device::Serial::SLuRM
   qw( $_protocol );

use Carp;

use Future::AsyncAwait;

=encoding UTF-8

=head1 NAME

C<Device::Serial::MSLuRM> - communicate Multi-drop SLµRM over a serial port

=head1 SYNOPSIS

   use v5.36;
   use Device::Serial::MSLuRM;

   my $slurm = Device::Serial::MSLuRM->new(
      dev  => "/dev/ttyUSB0",
      baud => 19200,
   );

   $slurm->run(
      on_notify => sub ($node_id, $payload) {
         printf "NOTIFY(%d): %v02X\n", $node_id, $payload;
      }
   )->await;

=head1 DESCRIPTION

This variant of L<Device::Serial::SLuRM> allows communication with a
collection of nodes using Multi-drop SLµRM over a serial port, such as over
an RS-485 bus.

The endpoint running with this module takes the role of the bus controller.
Currently this module does not support being a non-controller node.

=cut

use constant is_multidrop => 1;

=head1 METHODS

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

   $on_notify->( $node_id, $payload )

Optional. Invoked on receipt of a NOTIFY packet.

=back

Note that unlike in the single-peer case, a multi-drop controller cannot
C<reset> all the nodes before starting this, as it does not know the full set
of nodes that need resetting.

=cut

async method _autoreset () {}

=head2 recv_packet

   ( $pktctrl, $addr, $payload ) = await $slurm->recv_packet;

Waits for and returns the next packet to be received from the serial port.
Note that in a multi-drop scenario this packet may well be a reflection of one
sent by the controller, depending on how the serial port adapter works.

=cut

method recv_packet () { $_protocol->recv; }

=head2 send_packet

   await $slurm->send_packet( $pktctrl, $addr, $payload );

Sends a packet to the serial port.

=cut

method send_packet ( $pktctrl, $addr, $payload ) { $self->_send( $pktctrl, $addr, $payload ); }

=head2 send_notify

   await $slurm->send_notify( $node_id, $payload );

Sends a NOTIFY packet.

Will automatically L</reset> first if required.

=cut

method send_notify ( $node_id, $payload ) { $self->_send_notify( $node_id, $payload ); }

=head2 request

   $data_in = await $slurm->request( $node_id, $data_out );

Sends a REQUEST packet to the node, and waits for a response to it.

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

method request ( $node_id, $payload ) { $self->_request( $node_id, $payload ); }

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
