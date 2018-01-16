#
# $Id: Ssh2tcp.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# proxy::ssh2tcp Brik
#
package Metabrik::Proxy::Ssh2tcp;
use strict;
use warnings;

use base qw(Metabrik::System::Process);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable ssh tcp socket netcat) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         username => [ qw(username) ],
         ssh_hostname_port => [ qw(ssh_hostname_port) ],
         remote_hostname_port => [ qw(remote_hostname_port) ],
         st => [ qw(INTERNAL) ],
         so => [ qw(INTERNAL) ],
      },
      attributes_default => {
         username => 'root',
         hostname => '127.0.0.1',
         port => 8888,
      },
      commands => {
         start => [ qw(ssh_hostname_port|OPTIONAL remote_hostname_port|OPTIONAL) ],
         tunnel_loop => [ qw(remote_hostname_port) ],
         background_tunnel_loop => [ qw(remote_hostname_port) ],
         is_started => [ ],
         stop => [ ],
      },
      require_modules => {
         'Metabrik::Client::Openssh' => [ ],
         'Metabrik::Server::Tcp' => [ ],
      },
   };
}

sub _handle_sigint {
   my $self = shift;

   my $restore = $SIG{INT};

   $SIG{INT} = sub {
      $self->log->debug("brik_init: INT caught");
      $SIG{INT} = $restore;
      $self->stop;
      return 1;
   };

   return 1;
}

sub brik_init {
   my $self = shift;

   $self->_handle_sigint;

   return $self->SUPER::brik_init(@_);
}

sub is_started {
   my $self = shift;

   if (defined($self->st)) {
      return 1;
   }

   return 0;
}

sub background_tunnel_loop {
   my $self = shift;
   my $args = \@_;

   return $self->start(sub { $self->start(@$args) && $self->tunnel_loop(@$args) });
}

sub start {
   my $self = shift;
   my ($ssh_hostname_port, $remote_hostname_port, $username) = @_;

   my $hostname = $self->hostname;
   my $port = $self->port;
   $ssh_hostname_port ||= $self->ssh_hostname_port;
   $remote_hostname_port ||= $self->remote_hostname_port;
   $username ||= $self->username;
   $self->brik_help_run_undef_arg('start', $ssh_hostname_port) or return;
   my $ref = $self->brik_help_run_invalid_arg('start', $ssh_hostname_port, 'ARRAY', 'SCALAR')
      or return;
   $self->brik_help_run_undef_arg('start', $remote_hostname_port) or return;
   if ($remote_hostname_port !~ /^[^:]+:\d+$/) {
      return $self->log->error("start: invalid format for remote_hostname_port [$remote_hostname_port], must be hostname:port");
   }

   my $so;
   # Only one hop
   if ($ref eq 'SCALAR') {
      if ($ssh_hostname_port !~ /^[^:]+:\d+$/) {
         return $self->log->error("start: invalid format for ssh_hostname_port [$ssh_hostname_port], must be hostname:port");
      }

      my ($ssh_hostname, $ssh_port) = split(':', $ssh_hostname_port);

      $so = Metabrik::Client::Openssh->new_from_brik_init($self) or return;
      $so->username($username);
      $so->connect($ssh_hostname, $ssh_port) or return;

      $self->log->verbose("start: connected to SSH [$ssh_hostname]:$ssh_port");
   }
   # Multiple hops :)
   elsif ($ref eq 'ARRAY') {
      my @ok = ();
      for my $this (@$ssh_hostname_port) {
         if ($this !~ /^[^:]+:\d+$/) {
            $self->log->verbose("start: invalid format for this [$this], must be hostname:port");
            next;
         }
         push @ok, $this;
      }

      if (@ok < 2) {
         return $self->log->error("start: cannot chain with only one proxy");
      }

      # Build hop chain
      my $path = [];
      my $hop = 1;
      my $lport = $port+1;
      my $target = $remote_hostname_port;
      while (1) {
         if ($hop == 1) {
            my $this = shift @ok;
            my $next = shift @ok;
            last unless defined $next;
            push @$path, {
               from => $this,
               to => $next,
               host => 'localhost',
               port => $lport++,
            };
         }
         else {
            my $next = shift @ok;
            last unless defined $next;
            push @$path, {
               from => $path->[-1]->{host}.':'.$path->[-1]->{port},
               to => $next,
               host => 'localhost',
               port => $lport++,
            };
         }
         $hop++;
      }

      push @$path, {
          from => $path->[-1]->{host}.':'.$path->[-1]->{port},
          to => $remote_hostname_port,
          host => 'localhost',
          port => $port,
      };

      use Data::Dumper;
      print Dumper($path)."\n";
      #return 1;

      $hop = 1;
      for my $this (@$path) {
         $self->hostname($this->{host});
         $self->port($this->{port});
         $self->log->verbose("background_start: ".
            "from: ".$this->{from}." to: ".$this->{to}. " listen: ".$this->{port}
         );

         #$self->start($this->{from}, $this->{to}) or return;
         $self->background_tunnel_loop($this->{from}, $this->{to}) or return;

         $self->log->verbose("start: connected to SSH hop [$hop] [".$this->{to}."]");

         # XXX: do better
         sleep(5);  # Wait for tunnel to be established

         $hop++;
      }

      return 1;
   }

   my $st = Metabrik::Server::Tcp->new_from_brik_init($self) or return;
   $st->hostname($self->hostname);
   $st->port($self->port);

   my $server = $st->start or return;
   $self->st($st);
   $self->so($so);

   $self->tunnel_loop($remote_hostname_port) or return;

   return 1;
}

sub tunnel_loop {
   my $self = shift;
   my ($remote_hostname_port) = @_;

   if (! $self->is_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   $self->brik_help_run_undef_arg('tunnel_loop', $remote_hostname_port) or return;
   if ($remote_hostname_port !~ /^[^:]+:\d+$/) {
      return $self->log->error("start: invalid format for remote_hostname_port [$remote_hostname_port], must be hostname:port");
   }

   my ($remote_hostname, $remote_port) = split(':', $remote_hostname_port);

   my $st = $self->st;
   my $server = $st->socket;
   my $select = $st->select;
   my $clients = $st->clients;

   my $so = $self->so;

   while (1) {
      last if ! $self->is_started;  # Used to stop the process on SIGINT

      if (my $ready = $st->wait_readable) {
         for my $sock (@$ready) {
            my ($id, $this_client, $this_tunnel) = $self->_get_tunnel_from_sock($clients, $sock);
            if ($sock == $server) {
               $self->log->verbose("start: server socket ready");
               my $client = $st->accept;

               $self->log->verbose("start: new connection from [".
                  $client->{ipv4}."]:".$client->{port});

               my $tunnel = $so->open_tunnel($remote_hostname, $remote_port) or return;
               $select->add($tunnel);
               $client->{tunnel} = $tunnel;

               $self->log->verbose("start: tunnel opened to [$remote_hostname]:$remote_port");
            }
            else {
               if ($sock == $this_client) { # Client sent something
                  my $buf = $st->read($this_client);
                  if (! defined($buf)) {
                     $self->log->verbose("start: client disconnected");
                     $select->remove($this_client);
                  }
                  else {
                     $self->log->verbose("start: read from client [".length($buf)."]");
                     $self->log->verbose("start: write to tunnel [".length($buf)."]");
                     $this_tunnel->syswrite($buf);
                  }
               }
               elsif ($sock == $this_tunnel) {
                  my $buf = $st->read($this_tunnel);
                  if (! defined($buf)) {
                     # If tunnel is disconnected, we can wipe the full connecting client state.
                     # And only at that time.
                     $self->log->verbose("start: tunnel disconnected");
                     $select->remove($this_tunnel);
                     close($this_tunnel);
                     $st->client_disconnected($id);
                  }
                  else {
                     $self->log->verbose("start: read from tunnel [".length($buf)."]");
                     $self->log->verbose("start: write to client [".length($buf)."]");
                     $this_client->syswrite($buf);
                  }
               }
            }
         }
      }
   }

   return 1;
}

sub stop {
   my $self = shift;

   if (! $self->is_started) {
      return $self->log->verbose("stop: not started");
   }

   my $st = $self->st;

   # server::tcp know nothing about tunnels, we have to clean by ourselves
   my $clients = $st->clients;
   for my $this (keys %$clients) {
      if (exists($clients->{$this}{tunnel})) {
         close($clients->{$this}{tunnel});
         $self->log->verbose("stop: tunnel for client [$this] closed");
      }
   }

   $st->stop;

   $self->_handle_sigint;  # Reharm the signal

   $self->st(undef);

   return 1;
}

sub _get_tunnel_from_sock {
   my $self = shift;
   my ($clients, $sock) = @_;

   my $client;
   my $this_client;
   my $this_tunnel;
   for my $k (keys %$clients) {
      if ($sock == $clients->{$k}{socket} || $sock == $clients->{$k}{tunnel}) {
         $client = $k;
         $this_client = $clients->{$k}{socket};
         $this_tunnel = $clients->{$k}{tunnel};
         last;
      }
   }

   return ( $client, $this_client, $this_tunnel );
}

1;

__END__

=head1 NAME

Metabrik::Proxy::Ssh2tcp - proxy::ssh2tcp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
