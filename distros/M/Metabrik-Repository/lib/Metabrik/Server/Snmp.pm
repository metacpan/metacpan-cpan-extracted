#
# $Id: Snmp.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# server::snmp Brik
#
package Metabrik::Server::Snmp;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable agent) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         community => [ qw(community_string) ],
         _snmp => [ qw(INTERNAL) ],
         _snmpd_pid => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => 'localhost',
         port => 161,
         community => 'public',
      },
      commands => {
         install => [ ], # Inherited
         start => [ qw(listen_hostname|OPTIONAL listen_port|OPTIONAL datadir|OPTIONAL) ],
         stop => [ ],
      },
      require_modules => {
         'NetSNMP::agent' => [ ],
         'NetSNMP::ASN' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::Shell::Command' => [ ],
         'Metabrik::Worker::Fork' => [ ],
      },
      require_binaries => {
         'snmpd' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libsnmp-dev snmpd) ],
         debian => [ qw(libsnmp-dev snmpd) ],
      },
   };
}

sub _create_snmpd_conf {
   my $self = shift;

   my $hostname = $self->hostname;
   my $port = $self->port;
   my $community = $self->community;

   my $conf = <<EOF;
agentAddress  udp:$hostname:$port
#agentAddress udp:161,udp6:[::1]:161

# SNMP v1, v2c
#rocommunity public  default    -V systemonly
rocommunity $community
#rocommunity secret  10.0.0.0/16
#rwcommunity private default

#   Full read-only access for SNMPv3
rouser   authOnlyUser
#rwuser   authPrivUser   priv

sysLocation   Metabrik
sysContact    GomoR <gomor\@metabrik.org>

# Run as an AgentX master agent
#master   agentx
EOF

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->overwrite(1);
   $ft->append(0);

   $ft->write($conf, $self->datadir.'/snmpd.conf')
      or return $self->log->error("_create_snmpd_conf: write failed");

   return 1;
}

sub _start_snmpd {
   my $self = shift;

   my $snmpd_conf = $self->datadir.'/snmpd.conf';

   my $sc = Metabrik::Shell::Command->new_from_brik_init($self) or return;
   my $wf = Metabrik::Worker::Fork->new_from_brik_init($self) or return;

   defined(my $pid = $wf->start) or return $self->log->error("_start_snmpd: start failed");

   # Son
   if (! $pid) {
      my $cmd = "snmpd -f -C -c $snmpd_conf 2>&1";
      $sc->system($cmd) or return $self->log->error("_start_snmpd: system failed");
      exit(0);
   }

   # Father
   $self->_snmpd_pid($pid);

   return 1;
}

sub start {
   my $self = shift;
   my ($hostname, $port, $root) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $root ||= $self->datadir;

   if ($port < 1024 && $< != 0) {
      return $self->log->error("start: need root privileges to bind port [$port]");
   }

   # Create snmpd.conf file
   $self->_create_snmpd_conf or return;

   # Start snmpd
   $self->_start_snmpd or return;

   #sub do_one { return int(rand(10)) };
   #sub do_two { return "two" };

   #my $root_oid = '1.3.6.1.4.1.8072.9999.9999.123';

   #my %handlers = (
      #'1' => { handler => \&do_one, type => &NetSNMP::ASN::ASN_GAUGE },
      #'2' => { handler => \&do_two },     # default type ASN_OCTET_STR
   #);

   #my $agent = SNMP::Agent->new(
      #'brik_snmp_agent',
      #$root_oid,
      #\%handlers,
   #);

   #return $self->_snmp($agent)->run;
   return 1;
}

sub stop {
   my $self = shift;

   #if (defined($self->_snmp)) {
      #$self->_snmp->shutdown;
      #$self->_snmp(undef);
   #}

   if (defined($self->_snmpd_pid)) {
      kill('INT', $self->_snmpd_pid);
      $self->_snmpd_pid(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Server::Snmp - server::snmp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
