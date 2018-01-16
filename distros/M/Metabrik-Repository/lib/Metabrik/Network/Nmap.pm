#
# $Id: Nmap.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# network::nmap Brik
#
package Metabrik::Network::Nmap;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable security scan vulnerability vuln port portscan synscan syn udpscan scanner nmap) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         targets => [ qw(nmap_targets) ],
         ports => [ qw(nmap_ports) ],
         args => [ qw(nmap_args) ],
         rate => [ qw(integer_packet_per_seconds) ],
         max_retries => [ qw(integer) ],
         service_scan => [ qw(0|1) ],
         save_output => [ qw(0|1) ],
      },
      attributes_default => {
         targets => '127.0.0.1',
         ports => '--top-ports 1000',
         args => '-n -Pn',
         rate => 10_000,
         max_retries => 3,
         service_scan => 0,
         save_output => 0,
      },
      commands => {
         install => [ ], # Inherited
         tcp_syn => [ ],
         tcp_connect => [ ],
         udp => [ ],
      },
      require_binaries => {
         'sudo' => [ ],
         'nmap' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(nmap) ],
         debian => [ qw(nmap) ],
      },
   };
}

sub _nmap_parse {
   my $self = shift;
   my ($cmd, $result) = @_;

   my $parsed = {};

   push @{$parsed->{raw}}, $cmd;

   my $host = 'undef';
   my $ip = 'undef';
   for (split(/\n/, $result)) {
      push @{$parsed->{raw}}, $_;
      if (/^Nmap scan report for (\S+)\s*\(?(\S*?)\)?$/) {
         if (defined($2) && length($2)) { # We have both hostname and IP address
            $host = $1;
            $ip = $2;
         }
         else { # We have only IP address
            $ip = $1;
         }
      }
      # With service scan enabled
      # 22/tcp   open  ssh     (protocol 2.0)
      # 3690/tcp open  svn?
      elsif (/^(\d+)\/tcp\s+(\S+)\s+(\S+)\s*(.*)$/) {
         my $port = $1;
         my $state = $2;
         my $service = $3;
         my $tail = $4;
         $parsed->{$ip}->{$port} = { state => $state, service => $service, port => $port, host => $host, ip => $ip };
         $parsed->{$ip}->{$state}->{$port} = { state => $state, service => $service, port => $port, host => $host, ip => $ip };
         if (defined($tail)) {
            $parsed->{$ip}->{$port}->{tail} = $tail;
            $parsed->{$ip}->{$state}->{$port}->{tail} = $tail;
         }
      }
   }

   return $parsed;
}

sub tcp_syn {
   my $self = shift;

   my $args = $self->args;
   my $targets = $self->targets;
   my $ports = $self->ports;
   my $max_retries = $self->max_retries;
   my $rate = $self->rate;
   my $service_scan = $self->service_scan;
   my $save_output = $self->save_output;

   my $datadir = $self->datadir;

   my $cmd = "sudo nmap -v -sS --max-retries $max_retries --min-rate $rate --max-rate $rate $args";
   if ($service_scan) {
      $cmd .= " -sV";
   }
   if ($save_output) {
      $cmd .= " -oA $datadir/nmap_output";
   }
   $cmd .= " $ports $targets";

   my $result = `$cmd`;

   my $parsed = $self->_nmap_parse($cmd, $result);

   return $parsed;
}

# nmap -sT -sV --top-port 500 -Pn -n -v -oA nmap_output_topXXX
# nmap -sT --max-retries 3 --min-rate 10000 --max-rate 10000 -n -Pn -sV -oA nmap_output --top-ports 100 127.0.0.1
sub tcp_connect {
   my $self = shift;

   my $args = $self->args;
   my $targets = $self->targets;
   my $ports = $self->ports;
   my $max_retries = $self->max_retries;
   my $rate = $self->rate;
   my $service_scan = $self->service_scan;
   my $save_output = $self->save_output;

   my $datadir = $self->datadir;
 
   my $cmd = "sudo nmap -v -sT --max-retries $max_retries --min-rate $rate --max-rate $rate $args";
   if ($service_scan) {
      $cmd .= " -sV";
   }
   if ($save_output) {
      $cmd .= " -oA $datadir/nmap_output";
   }
   $cmd .= " $ports $targets";

   my $result = `$cmd`; 

   my $parsed = $self->_nmap_parse($cmd, $result);

   return $parsed;
}

sub udp {
   my $self = shift;

   my $args = $self->args;
   my $targets = $self->targets;
   my $ports = $self->ports;
   my $max_retries = $self->max_retries;
   my $rate = $self->rate;
   my $service_scan = $self->service_scan;
   my $save_output = $self->save_output;

   my $datadir = $self->datadir;

   my $cmd = "sudo nmap -v -sU --max-retries $max_retries --min-rate $rate --max-rate $rate $args";
   if ($service_scan) {
      $cmd .= " -sV";
   }
   if ($save_output) {
      $cmd .= " -oA $datadir/nmap_output";
   }
   $cmd .= " $ports $targets";

   my $result = `$cmd`;

   my $parsed = $self->_nmap_parse($cmd, $result);

   return $parsed;
}

1;

__END__

=head1 NAME

Metabrik::Network::Nmap - network::nmap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
