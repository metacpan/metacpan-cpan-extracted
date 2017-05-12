package Linux::Proc::Net::UDP;

use strict;
use warnings;

use Carp;
use Scalar::Util;

require Linux::Proc::Net::TCP::Base;
our @ISA = qw(Linux::Proc::Net::TCP::Base);

sub read {
    my $class = shift;
    $class->_read(_proto => 'udp', @_);
}

package Linux::Proc::Net::UDP::Entry;
our @ISA = qw(Linux::Proc::Net::TCP::Base::Entry);

sub st                        { shift->[ 5] }
sub drops                     { shift->[16] }
sub _more                     { shift->[17] }

1;

__END__

=head1 NAME

Linux::Proc::Net::UDP - Parser for Linux /proc/net/udp and /proc/net/udp6

=head1 SYNOPSIS

  use Linux::Proc::Net::UDP;
  my $table = Linux::Proc::Net::UDP->read;

  for my $entry (@$table) {
    printf("%s:%d (%d)\n",
           $entry->local_address, $entry->local_port,
           $entry->st );
  }

=head1 DESCRIPTION

This module can read and parse the information available from
/proc/net/udp in Linux systems.

=head1 API

=head2 The table object

=over

=item $table = Linux::Proc::Net::UDP->read

=item $table = Linux::Proc::Net::UDP->read(%opts)

reads C</proc/net/udp> and C</proc/net/udp6> and returns an object
representing a table of the connections.

Individual entries in the table can be accessed just dereferencing the
returned object. For instance:

  for my $entry (@$table) {
    # do something with $entry
  }

The table entries are of class C<Linux::Proc::Net::UDP::Entry>
described below.

This method accepts the following optional arguments:

=over 4

=item ip4 => 0

disables parsing of the file /proc/net/udp containing
information for open UDP ports on IPv4

=item ip6 => 0

disables parsing of the file /proc/net/udp6 containing
information for open UDP ports on IPv6

=item mnt => $procfs_mount_point

overrides the default mount point for the procfs at C</proc>.

=back

=back

=head2 The entry object

The entries in the table are of class
C<Linux::Proc::Net::UDP::Entry> and implement the following read only
accessors:

   sl local_address local_port rem_address rem_port st tx_queue
   rx_queue timer tm_when retrnsmt uid timeout inode reference_count
   memory_address drops ip4 ip6

=head1 AUTHOR

Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2012, 2014 by Qindel FormaciE<oacute>n y Servicios
S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
