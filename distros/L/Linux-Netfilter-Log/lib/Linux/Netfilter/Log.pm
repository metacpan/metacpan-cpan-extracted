=head1 NAME

Linux::Netfilter::Log - Read packets logged using the B<NFLOG> mechanism

=head1 SYNOPSIS

  use Linux::Netfilter::Log qw(:constants);
  use Socket qw(PF_INET);
  
  my $log = Linux::Netfilter::Log->open();
  
  eval { $log->unbind_pf(PF_INET) };
  $log->bind_pf(PF_INET);
  
  my $group = $log->bind_group(0);
  
  $group->callback_register(sub
  {
	  my ($packet) = @_;
	  
	  ...
  });
  
  while(1)
  {
	  $log->recv_and_process_one() or warn "Buffer filled!";
  }

=head1 DESCRIPTION

This module provides a wrapper around B<libnetfilter_log>, allowing a Perl
program to process packets logged using the B<NFLOG> iptables target.

=head1 CONSTANTS

The C<libnetfilter_log> constants may be imported from this module individually
or using the C<:constants> import tag.

=cut

use strict;
use warnings;

package Linux::Netfilter::Log;

use Exporter qw(import);

use Linux::Netfilter::Log::Constants;
use Linux::Netfilter::Log::Group;
use Linux::Netfilter::Log::Packet;

our $VERSION = "1.0";

require XSLoader;
XSLoader::load("Linux::Netfilter::Log", $VERSION);

# Our @EXPORT_OK gets initialised by the ::Constants module.
our @EXPORT_OK;
our %EXPORT_TAGS = (
	constants => [ @EXPORT_OK ],
);

=head1 CLASS METHODS

=head2 open()

Constructor. Sets up an nflog handle and underlying netlink socket.

=head1 INSTANCE METHODS

=head2 bind_pf(protocol_family)

Binds the given nflog handle to process packets belonging to the given protocol
family (ie. PF_INET, PF_INET6, etc).

=head2 unbind_pf(protocol_family)

Unbinds the given nflog handle from processing packets belonging to the given
protocol family.

=head2 bind_group($group)

Creates a new L<Linux::Netfilter::Log::Group> object bound to the chosen group
number. Throws on failure.

=head2 fileno()

Returns the file descriptor of the underlying netlink socket, for polling with
C<select> or similar.

=head2 recv_and_process_one()

Reads one Netlink message from the socket and processes it, invoking callbacks
registered with
L<Group-E<gt>callback_register()|Linux::Netfilter::Log::Group/callback_register($callback)>.

A single message may contain multiple packets, if the callback throws an
exception, any which have not yet been processesed will be lost.

Returns true on success, false if C<recv()> failed with B<ENOBUFS> (indicating
the buffer filled up and some messages have been lost). Any other C<recv()>
errors will trigger an exception.

=head1 BUGS

The size of the buffer used to read netlink messages is currently fixed at 64k.

This is probably bigger than most people need, but if you intend to copy large
packet payloads from the kernel B<AND> queue multiple packets at a time, it may
not be big enough (C<recv_and_process_one()> will emit warnings upon possible
truncation).

I will change this to be dynamically sized automatically in the future if I
come up with an efficient way to do it (suggestions welcome).

=head1 SEE ALSO

L<Linux::Netfilter::Log::Group>

=head1 AUTHOR

Daniel Collins E<lt>daniel.collins@smoothwall.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 L<Smoothwall Ltd.|http://www.smoothwall.com/>

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
