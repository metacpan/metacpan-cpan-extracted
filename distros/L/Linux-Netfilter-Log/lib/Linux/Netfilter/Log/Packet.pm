=head1 NAME

Linux::Netfilter::Log::Packet - A logged packet

=head1 DESCRIPTION

This object represents a packet logged using B<NFLOG>, all accessor methods
return undef if the field isn't set.

=cut

use strict;
use warnings;

package Linux::Netfilter::Log::Packet;

# This module only has accessor methods - it gets constructed by Group.xs within
# the proxy callback.

=head1 INSTANCE METHODS

=head2 hw_type()

Returns the link layer type, such as C<ARPHRD_ETHER> - see F<linux/if_arp.h>.

=cut

sub hw_type { (shift)->{hw_type} }

=head2 hw_header()

Returns the link layer header.

=cut

sub hw_header { (shift)->{hw_header} }

=head2 hw_protocol()

Returns the link layer protocol number (if applicable), e.g. the EtherType
field on Ethernet links.

=cut

sub hw_protocol { (shift)->{hw_protocol} }

=head2 hw_addr()

Retrieves the hardware address associated with the given packet. For ethernet
packets, the hardware address returned (if any) will be the MAC address of the
packet source host. The destination MAC address is not known until after
POSTROUTING and a successful ARP request, so cannot currently be retrieved.

=cut

sub hw_addr { (shift)->{hw_addr} }

=head2 payload()

Returns the payload of the packet, which may be missing or truncated depending
on the mode set using L<set_mode|Linux::Netfilter::Log::Group/set_mode($mode, $range)>.

The payload consists of the "Layer 3" (e.g. IP) headers and everything "up"
from there (TCP, etc).

=cut

sub payload { (shift)->{payload} }

=head2 netfilter_hook()

Returns the hook number of the hook (e.g. C<NF_INET_FORWARD>) that B<NFLOG> was
invoked from.

(See C<nf_inet_hooks> in F<linux/netfilter.h>).

=cut

sub netfilter_hook { (shift)->{hook} }

=head2 mark()

Returns the 32-bit "mark" set on the packet.

=cut

sub mark { (shift)->{mark} }

=head2 timestamp()

Returns the timestamp of the packet, as a floating point UNIX timestamp.

=cut

sub timestamp
{
	my ($self) = @_;

	my $tv_sec  = $self->{"timestamp.sec"};
	my $tv_usec = $self->{"timestamp.usec"};

	return unless(defined $tv_sec);

	return $tv_sec + ($tv_usec / 1_000_000);
}

# TODO: Implement indev/etc variants that lookup the interface name?

=head2 indev()

Returns the "ifindex" of the interface the packet arrived on.

=cut

sub indev { (shift)->{indev} }

=head2 physindev()

Returns the "ifindex" of the bridge port the packet arrived on, if the packet
was received on a bridge.

=cut

sub physindev { (shift)->{physindev} }

=head2 outdev()

Returns the "ifindex" of the interface the packet is to be transmitted from.

=cut

sub outdev { (shift)->{outdev} }

=head2 physoutdev()

Returns the "ifindex" of the bridge port the packet is to be transmitted on, if
the packet is to be transmitted from a bridge.

=cut

sub physoutdev { (shift)->{physoutdev} }

=head2 prefix()

Returns the "prefix" string specified as an option to the iptables B<NFLOG>
target.

=cut

sub prefix { (shift)->{prefix} }

=head2 uid()

Returns the UID of the local process sending the packet (if applicable).

=cut

sub uid { (shift)->{uid} }

=head2 gid()

Returns the GID of the local process sending the packet (if applicable).

=cut

sub gid { (shift)->{gid} }

=head2 seq()

Returns the "local" sequence number.

The local sequence number is an incrementing counter on B<THIS NFLOG HANDLE>
that increases each time a packet is received for a group which has local
sequence numbering enabled.

This must be enabled using
L<Group-E<gt>set_flags()|Linux::Netfilter::Log::Group/set_flags($flags)>.

=cut

sub seq { (shift)->{seq} }

=head2 seq_global()

Returns the "global" sequence number.

The global sequence number is an incrementing counter that increases each time
any B<NFLOG> rule is triggered.

This must be enabled using
L<Group-E<gt>set_flags()|Linux::Netfilter::Log::Group/set_flags($flags)>.

=cut

sub seq_global { (shift)->{seq_global} }

=head1 SEE ALSO

L<Linux::Netfilter::Log>, L<Linux::Netfilter::Log::Group>

=cut

1;
