#
# $Id: Tcp.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# server::tcp Brik
#
package Metabrik::Server::Tcp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable socket netcat) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         listen => [ qw(listen) ],
         use_ipv4 => [ qw(0|1) ],
         use_ipv6 => [ qw(0|1) ],
         socket => [ qw(server_socket) ],
         select => [ qw(select) ],
         clients => [ qw(connected_clients) ],
      },
      attributes_default => {
         hostname => 'localhost',
         port => 8888,
         listen => 10,
         use_ipv4 => 1,
         use_ipv6 => 0,
         clients => {},
      },
      commands => {
         start => [ qw(listen_hostname|OPTIONAL listen_port|OPTIONAL) ],
         stop => [ ],
         is_started => [ ],
         wait_readable => [ ],
         get_clients_count => [ ],
         get_last_client => [ ],
         get_last_client_id => [ ],
         accept => [ ],
      },
      require_modules => {
         'IO::Socket' => [ ],
         'IO::Select' => [ ],
         'IO::Socket::INET' => [ ],
      },
   };
}

sub start {
   my $self = shift;
   my ($hostname, $port, $root) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   if ($port !~ /^\d+$/) {
      return $self->log->error("start: port [$port] must be an integer");
   }

   my $use_ipv4 = $self->use_ipv4;
   my $use_ipv6 = $self->use_ipv6;
   my $domain = IO::Socket::AF_INET();  # XXX: TODO
   my $listen = $self->listen;

   my $socket = IO::Socket::INET->new(
      LocalHost => $hostname,
      LocalPort => $port,,
      Proto => 'tcp',
      ReuseAddr => 1,
      Listen => $listen,
      Domain => $domain,
   );
   if (! defined($socket)) {
      return $self->log->error("start: unable to create server: $!");
   }

   $socket->blocking(0);
   $socket->autoflush(1);

   my $select = IO::Select->new;
   $select->add($socket);

   $self->select($select);

   $self->log->info("start: starting server on [$hostname]:$port");

   return $self->socket($socket);
}

sub stop {
   my $self = shift;

   if (! $self->is_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $socket = $self->socket;
   my $select = $self->select;
   my $clients = $self->clients;

   for my $this (keys %$clients) {
      $select->remove($clients->{$this}{socket});
      close($clients->{$this}{socket});
      delete $clients->{$this};
   }

   $select->remove($socket);
   close($socket);

   $self->socket(undef);
   $self->select(undef);
   $self->clients({});

   return 1;
}

sub is_started {
   my $self = shift;

   my $socket = $self->socket;
   if (! defined($socket)) {
      return 0;
   }

   return 1;
}

sub wait_readable {
   my $self = shift;
   my ($timeout) = @_;

   if (! $self->is_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   $timeout ||= 0; # No timeout

   my $socket = $self->socket;
   my $select = $self->select;

   my @readable = $select->can_read;
   if (@readable > 0) {
      return \@readable;
   }

   return 0;  # Timeout occured
}

sub get_clients_count {
   my $self = shift;

   if (! $self->is_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $clients = $self->{clients};

   return keys %$clients;
}

sub get_last_client {
   my $self = shift;

   if (! $self->is_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $clients = $self->{clients};

   my $last = 0;
   for my $this (keys %$clients) {
      if ($this > $last) {
         $last = $this;
      }
   }

   return $clients->{$last};
}

sub get_last_client_id {
   my $self = shift;

   if (! $self->is_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $clients = $self->{clients};

   my $last = 0;
   for my $this (keys %$clients) {
      if ($this > $last) {
         $last = $this;
      }
   }

   return $last;
}

sub accept {
   my $self = shift;

   if (! $self->is_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $socket = $self->socket;
   my $select = $self->select;
   my $clients = $self->clients;

   my $client = $socket->accept;
   $client->blocking(0);
   $client->autoflush(1);

   $select->add($client);

   my $last = $self->get_last_client_id;

   my $new = {
      id => $last + 1,
      socket => $client,
      ipv4 => $client->peerhost,
      port => $client->peerport,
   };

   return $clients->{$last+1} = $new;
}

sub read {
   my $self = shift;
   my ($socket) = @_;

   if (! $self->is_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $buf = '';
   my $chunk = 512;
   my @ready = ();
   while (1) {
      my $n = $socket->sysread(my $tmp = '', $chunk);
      if (! defined($n)) {
         last;  # Should test for EWOULDBLOCK. If so, we can return. Otherwise, handle error.
      }
      if ($n == 0 && length($buf)) {  # EOF, but we send what we read
         return $buf;
      }
      if ($n == 0) {  # EOF, nothing read
         return;
      }
      $buf .= $tmp;
   }

   return $buf;
}

sub client_disconnected {
   my $self = shift;
   my ($id) = @_;

   if (! $self->is_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   $self->brik_help_run_undef_arg('client_disconnected', $id) or return;

   my $clients = $self->clients;
   my $select = $self->select;

   if (exists($clients->{$id})) {
      close($clients->{$id}{socket});
      $select->remove($clients->{$id}{socket});
      delete $clients->{$id};
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Server::Tcp - server::tcp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
