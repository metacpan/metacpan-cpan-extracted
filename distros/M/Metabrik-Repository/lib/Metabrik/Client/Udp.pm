#
# $Id$
#
# client::udp Brik
#
package Metabrik::Client::Udp;
use strict;
use warnings;

use base qw(Metabrik::Client::Tcp);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable socket netcat) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         host => [ qw(host) ],
         port => [ qw(port) ],
         eof => [ qw(0|1) ],
         size => [ qw(size) ],
         rtimeout => [ qw(read_timeout) ],
         use_ipv6 => [ qw(0|1) ],
         use_broadcast => [ qw(0|1) ],
      },
      attributes_default => {
         protocol => 'udp',
         use_broadcast => 0,
      },
      commands => {
         connect => [ qw(host|OPTIONAL port|OPTIONAL) ],
         read => [ ],
         read_size => [ qw(size) ],
         write => [ qw($data) ],
         disconnect => [ ],
         is_connected => [ ],
         chomp => [ qw($data) ],
      },
   };
}

sub connect {
   my $self = shift;
   my ($host, $port) = @_;

   $host ||= $self->host;
   $port ||= $self->port;
   $self->brik_help_run_undef_arg('connect', $host) or return;
   $self->brik_help_run_undef_arg('connect', $port) or return;

   my $mod = $self->use_ipv6 ? 'IO::Socket::INET6' : 'IO::Socket::INET';

   my %args = (
      PeerHost => $host,
      PeerPort => $port,
      Proto => $self->protocol,
      Timeout => $self->rtimeout,
      ReuseAddr => 1,
   );
   if ($self->use_broadcast) {
      $args{Broadcast} = 1;
   }
   my $socket = $mod->new(%args);
   if (! defined($socket)) {
      return $self->log->error("connect: failed connecting to target [$host:$port]: $!");
   }

   $socket->blocking(0);
   $socket->autoflush(1);

   my $select = IO::Select->new or return $self->log->error("connect: IO::Select failed: $!");
   $select->add($socket);

   $self->_socket($socket);
   $self->_select($select);

   $self->log->verbose("connect: successfully connected to [$host:$port]");

   my $conn = {
      ip => $socket->peerhost,
      port => $socket->peerport,
      my_ip => $socket->sockhost,
      my_port => $socket->sockport,
   };

   return $conn;
}

sub write {
   my $self = shift;
   my ($data, $host, $port) = @_;

   if (! $self->is_connected) {
      return $self->log->error("write: not connected");
   }

   $self->brik_help_run_undef_arg('write', $data) or return;

   my $socket = $self->_socket;

   eval {
      print $socket $data;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("write: syswrite failed with error [$@]");
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Udp - client::udp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
