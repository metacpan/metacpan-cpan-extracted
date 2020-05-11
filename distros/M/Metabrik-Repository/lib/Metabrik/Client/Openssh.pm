#
# $Id$
#
# client::openssh Brik
#
package Metabrik::Client::Openssh;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable ssh) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         hostname => [ qw(hostname) ],
         port => [ qw(integer) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         pid => [ qw(master_pid) ],
         slave_pids => [ qw(slave_pids) ],
         forward_agent => [ qw(0|1) ],
         ssh => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => 'localhost',
         port => 22,
         forward_agent => 1,
         slave_pids => {},
      },
      commands => {
         connect => [ qw(hostname|OPTIONAL port|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         is_connected => [ ],
         disconnect => [ ],
         open_tunnel => [ qw(hostname port) ],
         close_tunnel => [ qw(hostname port) ],
      },
      require_modules => {
         'Net::OpenSSH' => [ ],
         'Metabrik::System::Process' => [ ],
      },
   };
}

sub is_connected {
   my $self = shift;

   if (defined($self->ssh)) {
      return 1;
   }

   return 0;
}

sub connect {
   my $self = shift;
   my ($hostname, $port, $username, $password) = @_;

   if ($self->is_connected) {
      return $self->log->verbose("connect: already connected");
   }

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $username ||= $self->username;
   $password ||= $self->password;

   my %opts = (
      timeout => 5,
   );
   if (length($username)) {
      $opts{user} = $username;
   }
   if (length($password)) {
      $opts{password} = $password;
   }
   if ($port) {
      $opts{port} = $port;
   }
   if ($self->forward_agent) {
      $opts{forward_agent} = 1;
   }

   my $ssh = Net::OpenSSH->new($hostname, %opts);
   if ($ssh->error) {
      return $self->log->error("connect: cannot connect to [$hostname]:$port: ".$ssh->error);
   }

   $self->log->verbose("connect: connected to [$hostname]:$port");

   $self->pid($ssh->get_master_pid);

   return $self->ssh($ssh);
}

sub disconnect {
   my $self = shift;

   if (! $self->is_connected) {
      return $self->log->verbose("disconnect: not connected");
   }

   my $ssh = $self->ssh;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;

   my @pids = ( $self->pid, keys %{$self->slave_pids} );
   for (@pids) {
      $sp->kill($_);
   }
   $self->pid(undef);
   $self->slave_pids({});
   $self->ssh(undef);

   return 1;
}

sub open_tunnel {
   my $self = shift;
   my ($hostname, $port) = @_;

   if (! $self->is_connected) {
      return $self->log->verbose("open_tunnel: not connected");
   }
   $self->brik_help_run_undef_arg('open_tunnel', $hostname) or return;
   $self->brik_help_run_undef_arg('open_tunnel', $port) or return;

   my $ssh = $self->ssh;
   my $slave_pids = $self->slave_pids;

   my ($tunnel, $pid) = $ssh->open_tunnel({}, $hostname, $port);
   if ($ssh->error) {
      return $self->log->error("open_tunnel: failed for [$hostname]:$port: ".$ssh->error);
   }

   $tunnel->blocking(0);
   $tunnel->autoflush(1);

   $slave_pids->{$pid} = { uid => "$hostname:$port" };

   return $tunnel;
}

sub close_tunnel {
   my $self = shift;
   my ($hostname, $port) = @_;

   if (! $self->is_connected) {
      return $self->log->verbose("close_tunnel: not connected");
   }
   $self->brik_help_run_undef_arg('close_tunnel', $hostname) or return;
   $self->brik_help_run_undef_arg('close_tunnel', $port) or return;

   my $ssh = $self->ssh;
   my $slave_pids = $self->slave_pids;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;

   my $found = 0;
   for my $k (keys %$slave_pids) {
      if ($slave_pids->{$k}{uid} eq "$hostname:$port") {
         $sp->kill($k);
         delete $slave_pids->{$k};
         $found++;
         last;
      }
   }

   if (! $found) {
      $self->log->verbose("close_tunnel: tunnel [$hostname]:$port not connected");
   }

   return 1;
}

sub brik_fini {
   my $self = shift;

   my $ssh = $self->ssh;
   if (defined($ssh)) {
      $ssh->disconnect;
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Openssh - client::openssh Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
