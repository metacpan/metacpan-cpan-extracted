#
# $Id$
#
# server::tor Brik
#
package Metabrik::Server::Tor;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         tor_port => [ qw(port) ],
         tor_listen => [ qw(address) ],
         dns_port => [ qw(port) ],
         dns_listen => [ qw(address) ],
         virtual_network => [ qw(subnet) ],
         user => [ qw(user) ],
         conf => [ qw(file) ],
         pidfile => [ qw(file) ],
      },
      attributes_default => {
         tor_port => 9051,
         tor_listen => '127.0.0.1',
         dns_port => 9061,
         dns_listen => '127.0.0.1',
         virtual_network => '10.20.0.0/255.255.0.0',
         conf => 'torrc',
         pidfile => 'tor.pid',
      },
      commands => {
         install => [ ], # Inherited
         generate_conf => [ qw(file|OPTIONAL) ],
         start => [ qw(conf_file|OPTIONAL) ],
         stop => [ ],
         status => [ ],
         list_exit_nodes => [ ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::System::Process' => [ ],
      },
      require_binaries => {
         tor => [ ],
      },
      need_packages => {
         ubuntu => [ qw(tor) ],
         debian => [ qw(tor) ],
         kali => [ qw(tor) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         user => defined($self->global) && $self->global->username || 'username',
      },
   };
}

#
# Inspired by https://github.com/HeitorG/nipe/blob/master/nipe.pl
#
sub generate_conf {
   my $self = shift;
   my ($conf) = @_;

   $conf ||= $self->conf;
   my $datadir = $self->datadir;
   # If it does not start with a /, we put it in $datadir
   if ($conf !~ m{^/}) {
      $conf = $datadir.'/'.$conf;
   }

   $self->brik_help_run_undef_arg('generate_conf', $conf) or return;

   my $user = $self->user;
   my $pidfile = $self->pidfile;
   my $tor_port = $self->tor_port;
   my $tor_listen = $self->tor_listen;
   my $dns_port = $self->dns_port;
   my $dns_listen = $self->dns_listen;
   my $virtual_network = $self->virtual_network;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->remove($conf);

   my $data =<<EOF
DataDirectory $datadir
PidFile $datadir/$pidfile
RunAsDaemon 1
ClientOnly 1
User $user

ControlSocket $datadir/control
ControlSocketsGroupWritable 1

CookieAuthentication 1
CookieAuthFileGroupReadable 1
CookieAuthFile $datadir/control.authcookie

Log notice file $datadir/tor.log

TransPort $tor_port
TransListenAddress $tor_listen
DNSPort $dns_port
DNSListenAddress $dns_listen

VirtualAddrNetwork $virtual_network
AutomapHostsOnResolve 1
EOF
;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->write($data, $conf) or return;
   $ft->close;

   $sf->chmod($datadir, "0700") or return;

   return $conf;
}

sub start {
   my $self = shift;
   my ($conf) = @_;

   $conf ||= $self->conf;
   $self->brik_help_run_undef_arg('start', $conf) or return;

   my $datadir = $self->datadir;

   # If it does not start with a /, we put it in $datadir
   if ($conf !~ m{^/}) {
      $conf = $datadir.'/'.$conf;
   }

   my $cmd = "tor -f \"$conf\"";

   return $self->sudo_system($cmd);
}

sub stop {
   my $self = shift;

   my $datadir = $self->datadir;
   my $pidfile = $self->pidfile;

   if ($pidfile !~ m{^/}) {
      $pidfile = $datadir.'/'.$pidfile;
   }

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   $sp->kill_from_pidfile($pidfile) or return;

   return 1;
}

sub status {
   my $self = shift;

   my $datadir = $self->datadir;
   my $pidfile = $self->pidfile;

   if ($pidfile !~ m{^/}) {
      $pidfile = $datadir.'/'.$pidfile;
   }

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   return $sp->is_running_from_pidfile($pidfile);
}

#
# Alternatives URLs:
# https://www.dan.me.uk/torlist/
# https://check.torproject.org/exit-addresses
# https://www.dan.me.uk/torcheck?ip=2.100.184.78
# https://globe.torproject.org/
# https://atlas.torproject.org/
#
sub list_exit_nodes {
   my $self = shift;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $get = $cw->get('http://torstatus.blutmagie.de/ip_list_exit.php/Tor_ip_list_EXIT.csv')
      or return;

   my $content = $get->{content};
   my @ip_list = split(/\n/, $content);

   return \@ip_list;
}

1;

__END__

=head1 NAME

Metabrik::Server::Tor - server::tor Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
