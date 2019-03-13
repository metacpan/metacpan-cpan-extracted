#
# $Id: Syslogng.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# server::syslogng Brik
#
package Metabrik::Server::Syslogng;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable syslog log logging syslog-ng) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         output => [ qw(file) ],
         listen => [ qw(address) ],
         port => [ qw(port) ],
         conf_file => [ qw(file) ],
         to_remote => [ qw(host) ],
         to_port => [ qw(port) ],
         use_ssl => [ qw(0|1) ],
         ca_dir => [ qw(directory) ],
         key_file => [ qw(file) ],
         cert_file => [ qw(file) ],
         version => [ qw(version) ],
      },
      attributes_default => {
         listen => '127.0.0.1',
         port => 6300,
         output => 'local.log',
         use_ssl => 0,
         version => '3.5',
      },
      commands => {
         install => [ ],  # Inherited
         generate_conf => [ qw(conf_file|OPTIONAL) ],
         start => [ qw(conf_file|OPTIONAL) ],
         stop => [ qw(pidfile|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         'syslog-ng' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(syslog-ng) ],
         debian => [ qw(syslog-ng) ],
         kali => [ qw(syslog-ng) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;

   return {
      attributes_default => {
         conf_file => "$datadir/syslogng.conf",
      },
   };
}

#
# https://www.balabit.com/documents/syslog-ng-ose-3.5-guides/en/syslog-ng-ose-guide-admin/html-single/index.html
#

sub generate_conf {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file;

   my $datadir = $self->datadir;
   my $user = defined($self->global) && $self->global->username || 'username';
   my $hostname = defined($self->global) && $self->global->hostname || 'hostname';
   my $group = $user;
   my $listen = $self->listen;
   my $port = $self->port;
   my $output = $self->output;
   my $remote_host = $self->to_remote;
   my $remote_port = $self->to_port;
   my $use_ssl = $self->use_ssl;
   my $ca_dir = $self->ca_dir;
   my $key_file = $self->key_file;
   my $cert_file = $self->cert_file;
   my $version = $self->version;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   if ($sf->is_relative($output)) {
      $output = "$datadir/$output";
   }

   my $conf = '@version:'."$version\n";
   if (-f '/etc/syslog-ng/scl.conf') {
      $conf .= '@include "scl.conf"'."\n";
   }
   $conf .= "\n";

   $conf .=<<EOF
options {
   use-dns(no);
   use-fqdn(no);
   keep-hostname(yes);
   chain-hostnames(no);
   owner("$user");
   group("$group");
   perm(0644);
   stats-freq(120);

   # Performance optimizations
   # From: https://pzolee.blogs.balabit.com/2011/02/syslog-ng-performance-tuning/
   flush-lines(100);
   log-fifo-size(1000);
};

source s_internal {
   internal();
};

destination d_local_syslogng {
   file("$datadir/syslogng.log");
};

log { source(s_internal); destination(d_local_syslogng); };

source s_listen_udp {
   udp(ip($listen) port($port)
      host-override("$hostname")
      log-iw-size(100)
      log-fetch-limit(100)
   );
};

destination d_local_file {
   file("$output");
};

EOF
;

   if (defined($remote_host) && $use_ssl) {
      $conf .=<<EOF
destination d_remote_host {
   tcp("$remote_host" port($remote_port)
      tls(
         ca-dir("$ca_dir")
         key-file("$key_file")
         cert-file("$cert_file")
      )
   );
};

log { source(s_listen_udp); destination(d_remote_host); flags(flow-control); };
EOF
;
   }
   elsif (defined($remote_host)) {
      $conf .=<<EOF
destination d_remote_host { tcp("$remote_host" port($remote_port) ); };

log { source(s_listen_udp); destination(d_remote_host); flags(flow-control); };
EOF
;
   }
   else {
      $conf .=<<EOF
log { source(s_listen_udp); destination(d_local_file); };
EOF
;
   }

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);
   $ft->write($conf, $conf_file) or return;

   return $conf_file;
}

sub start {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file;
   $self->brik_help_run_undef_arg('start', $conf_file) or return;

   my $datadir = $self->datadir;
   $self->brik_help_run_file_not_found('start', $conf_file) or return;

   my $ctlfile = $datadir.'/syslogng.ctl';
   my $persistfile = $datadir.'/syslogng.persist';
   my $pidfile = $datadir.'/syslogng.pidfile';

   if (-f $pidfile) {
      return $self->log->error("start: syslogng already started with pidfile [$pidfile]");
   }

   my $cmd = "syslog-ng -f \"$conf_file\" -c \"$ctlfile\" -R \"$persistfile\" --pidfile \"$pidfile\"";
   $self->ignore_error(0);
   my $r = $self->system($cmd) or return;
   if ($r == 256) {
      return $self->log->error("start: unable to start syslogng: code [$r]");
   }
   elsif ($r > 0) {
      $self->log->warning("start: some errors found while starting syslogng: code [$r]");
   }

   return $pidfile;
}

sub stop {
   my $self = shift;
   my ($pidfile) = @_;

   if (! defined($pidfile)) {
      my $datadir = $self->datadir;
      $pidfile = $datadir.'/syslogng.pidfile';
   }
   if (! -f $pidfile) {
      return $self->log->error("start: syslogng NOT started with pidfile [$pidfile]");
   }

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   return $sp->kill_from_pidfile($pidfile);
}

1;

__END__

=head1 NAME

Metabrik::Server::Syslogng - server::syslogng Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
