#
# $Id: Dns.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# server::dns Brik
#
package Metabrik::Server::Dns;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         a => [ qw(a_hash) ],
         aaaa => [ qw(aaaa_hash) ],
         cname => [ qw(cname_hash) ],
         mx => [ qw(mx_hash) ],
         ns => [ qw(ns_hash) ],
         soa => [ qw(soa_hash) ],
         recursive_mode => [ qw(0|1) ],
         cache_file => [ qw(cache_file) ],
         _dns => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => '127.0.0.1',
         port => 2053,
         recursive_mode => 1,
         cache_file => 'cache.db',
      },
      commands => {
         start => [ qw(listen_hostname|OPTIONAL listen_port|OPTIONAL) ],
      },
      require_modules => {
         'Net::DNS::Nameserver::Trivial' => [ ],
      },
   };
}

sub start {
   my $self = shift;
   my ($hostname, $port) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;

   my $zones = {
      '_' => {
         slaves => '8.8.4.4',
      },
   };

   my $a = $self->a;
   if (defined($a)) {
      $zones->{A} = $a;
   }

   my $aaaa = $self->aaaa;
   if (defined($aaaa)) {
      $zones->{AAAA} = $aaaa;
   }

   my $cname = $self->cname;
   if (defined($cname)) {
      $zones->{CNAME} = $cname;
   }

   my $mx = $self->mx;
   if (defined($mx)) {
      $zones->{MX} = $mx;
   }

   my $ns = $self->ns;
   if (defined($ns)) {
      $zones->{NS} = $ns;
   }

   my $soa = $self->soa;
   if (defined($soa)) {
      $zones->{SOA} = $soa;
   }

   my $params = {
      FLAGS => {
         ra => $self->recursive_mode,
      },
      RESOLVER => {
         tcp_timeout => 50,
         udp_timeout => 50,
      },
      CACHE => {
         size => '32m',              # size of cache
         expire => '1d',             # expire time of cache
         init => 1,                  # clear cache at startup
         unlink => 1,                # destroy cache on exit
         file => $self->datadir.'/'.$self->cache_file,  # cache
      },
      SERVER => {
         address => $hostname,
         port => $port,
         verbose => $self->debug,
         truncate => 1,           # truncate too big 
         timeout => 5,            # seconds
      },
      LOG => {
         file => '/dev/null',
         level => 'INFO'
      },
   };

   my $dns;
   eval {
      $dns = Net::DNS::Nameserver::Trivial->new($zones, $params);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("start: Net::DNS server failed: is port [$port] already listening?");
   }


   $self->log->verbose("start: listening on [$hostname:$port]");

   return $self->_dns($dns)->main_loop;
}

1;

__END__

=head1 NAME

Metabrik::Server::Dns - server::dns Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
