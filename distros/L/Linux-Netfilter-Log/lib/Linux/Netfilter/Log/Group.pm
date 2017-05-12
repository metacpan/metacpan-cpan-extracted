=head1 NAME

Linux::Netfilter::Log::Group - Recieve packets for a particular C<NFLOG> group

=head1 DESCRIPTION

This object represents an B<NFLOG> group to which we are bound and receiving
packets from.

=cut

use strict;
use warnings;

package Linux::Netfilter::Log::Group;

require XSLoader;
XSLoader::load("Linux::Netfilter::Log::Group");

=head1 INSTANCE METHODS

=head2 callback_register($callback)

Sets the callback subroutine used to process packets logged in this group.

  $group->callback_register(sub
  {
	  my ($packet) = @_;
	  
	  ...
  });

The C<$packet> is a L<Linux::Netfilter::Log::Packet> reference.

=head2 set_mode($mode, $range)

Sets the amount of data to be copied to userspace for each packet logged to the
given group.

=over

=item C<NFULNL_COPY_NONE>

Do not copy any data.

=item C<NFULNL_COPY_META>

Copy only packet metadata.

=item C<NFULNL_COPY_PACKET>

Copy entire packet. Packets larger than C<$range> will be truncated.

=back

=head2 set_nlbufsiz($size)

This method sets the size (in bytes) of the buffer that is used to stack log
messages in nflog.

=head2 set_qthresh($qthresh)

This method determines the maximum number of log entries to queue in the kernel
until it is pushed to userspace. This can be overridden by the B<NFLOG>
B<iptables> target.

=head2 set_timeout($timeout)

This method determines the maximum time (in I<centiseconds>) that a logged
packet will be queued in the kernel before being pushed to userspace.

=head2 set_flags($flags)

Set the nflog flags for this group. Takes a bitwise OR'd set of the following:

=over

=item C<NFULNL_CFG_F_SEQ>

This enables local nflog sequence numbering (see
L<Packet-E<gt>seq()|Linux::Netfilter::Log::Packet/seq()>).

=item C<NFULNL_CFG_F_SEQ_GLOBAL>

This enables global nflog sequence numbering (see
L<Packet-E<gt>seq_global()|Linux::Netfilter::Log::Packet/seq_global()>).

=back

=head1 SEE ALSO

L<Linux::Netfilter::Log>, L<Linux::Netfilter::Log::Packet>

=cut

1;
