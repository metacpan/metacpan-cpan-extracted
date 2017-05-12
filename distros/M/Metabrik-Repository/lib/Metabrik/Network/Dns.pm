#
# $Id: Dns.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# network::dns Brik
#
package Metabrik::Network::Dns;
use strict;
use warnings;

use base qw(Metabrik);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable ns nameserver) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         nameserver => [ qw(ip_address|$ip_address_list) ],
         port => [ qw(port) ],
         use_recursion => [ qw(0|1) ],
         try => [ qw(try_number) ],
         rtimeout => [ qw(timeout) ],
         type => [ qw(query_type) ],
         resolver => [ qw(INTERNAL) ],
         use_persistence => [ qw(0|1) ],
         src_ip_address => [ qw(ip_address) ],
         src_port => [ qw(port) ],
      },
      attributes_default => {
         use_recursion => 0,
         port => 53,
         try => 3,
         rtimeout => 2,
         type => 'A',
         use_persistence => 0,
      },
      commands => {
         create_resolver => [ qw(nameserver|OPTIONAL port|OPTIONAL) ],
         reset_resolver => [ ],
         lookup => [ qw(hostname|ip_address type|OPTIONAL nameserver|OPTIONAL port|OPTIONAL) ],
         background_lookup => [ qw(hostname|ip_address type|OPTIONAL nameserver|OPTIONAL port|OPTIONAL) ],
         background_read => [ qw(handle) ],
         version_bind => [ qw(hostname|ip_address) ],
      },
      require_modules => {
         'Net::DNS::Resolver' => [ ],
      },
   };
}

sub create_resolver {
   my $self = shift;
   my ($nameserver, $port, $timeout) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port;
   $timeout ||= $self->rtimeout;
   $self->brik_help_run_undef_arg('create_resolver', $nameserver) or return;
   my $ref = $self->brik_help_run_invalid_arg('create_resolver', $nameserver, 'ARRAY', 'SCALAR')
      or return;

   my $try = $self->try;
   my $persist = $self->use_persistence;
   my $src_ip_address = $self->src_ip_address;
   my $src_port = $self->src_port;

   my %args = (
      recurse => $self->use_recursion,
      searchlist => [],
      debug => $self->debug ? 1 : 0,
      tcp_timeout => $timeout,
      udp_timeout => $timeout,
      port => $port,
      persistent_udp => $persist,
      persistent_tcp => $persist,
      retrans => $timeout,
      retry => $try,
   );

   if (defined($src_ip_address)) {
      $args{srcaddr} = $src_ip_address;
   }
   if (defined($src_port)) {
      $args{srcport} = $src_port;
   }

   if ($ref eq 'ARRAY') {
      $self->log->verbose("create_resolver: using nameserver [".join('|', @$nameserver)."]");
      $args{nameservers} = $nameserver;
   }
   else {
      $self->log->verbose("create_resolver: using nameserver [$nameserver]");
      $args{nameservers} = [ $nameserver ];
   }

   my $resolver = Net::DNS::Resolver->new(%args);
   if (! defined($resolver)) {
      return $self->log->error("create_resolver: Net::DNS::Resolver new failed");
   }

   $self->resolver($resolver);

   return 1;
}

sub reset_resolver {
   my $self = shift;

   $self->resolver(undef);

   return 1;
}

sub lookup {
   my $self = shift;
   my ($host, $type, $nameserver, $port) = @_;

   $type ||= $self->type;
   $nameserver ||= $self->nameserver;
   $port ||= $self->port;
   $self->brik_help_run_undef_arg('lookup', $host) or return;
   $self->brik_help_run_undef_arg('lookup', $nameserver) or return;

   my $resolver = $self->resolver;
   if (! defined($resolver)) {
      $self->create_resolver($nameserver, $port) or return;
      $resolver = $self->resolver;
   }

   $self->debug && $self->log->debug("lookup: host [$host] for type [$type]");

   my $packet = $resolver->send($host, $type);
   if (! defined($packet)) {
      return $self->log->error("lookup: query failed [".$resolver->errorstring."]");
   }

   $self->debug && $self->log->debug("lookup: ".$packet->string);

   my @res = ();
   my @answers = $packet->answer;
   for my $rr (@answers) {
      $self->debug && $self->log->debug("lookup: ".$rr->string);

      my $h = {
         type => $rr->type,
         ttl => $rr->ttl,
         name => $rr->name,
         string => $rr->string,
         raw => $rr,
      };
      if ($rr->can('address')) {
         $h->{address} = $rr->address;
      }
      if ($rr->can('cname')) {
         $h->{cname} = $rr->cname;
      }
      if ($rr->can('exchange')) {
         $h->{exchange} = $rr->exchange;
      }
      if ($rr->can('nsdname')) {
         $h->{nsdname} = $rr->nsdname;
      }
      if ($rr->can('ptrdname')) {
         $h->{ptrdname} = $rr->ptrdname;
      }
      if ($rr->can('rdatastr')) {
         $h->{rdatastr} = $rr->rdatastr;
      }
      if ($rr->can('dummy')) {
         $h->{dummy} = $rr->dummy;
      }
      if ($rr->can('target')) {
         $h->{target} = $rr->target;
      }

      push @res, $h;
   }

   return \@res;
}

sub background_lookup {
   my $self = shift;
   my ($host, $type, $nameserver, $port) = @_;

   $type ||= $self->type;
   $nameserver ||= $self->nameserver;
   $port ||= $self->port;
   $self->brik_help_run_undef_arg('background_lookup', $host) or return;
   $self->brik_help_run_undef_arg('background_lookup', $nameserver) or return;

   my $resolver = $self->resolver;
   if (! defined($resolver)) {
      $self->create_resolver($nameserver, $port) or return;
      $resolver = $self->resolver;
   }

   $self->debug && $self->log->debug("background_lookup: host [$host] for type [$type]");

   my $handle = $resolver->bgsend($host, $type);
   if (! defined($handle)) {
      return $self->log->error("background_lookup: query failed [".$resolver->errorstring."]");
   }

   return $handle;
}

sub background_read {
   my $self = shift;
   my ($handle) = @_;

   my $resolver = $self->resolver;
   $self->brik_help_run_undef_arg('background_lookup', $resolver) or return;
   $self->brik_help_run_undef_arg('background_read', $handle) or return;
   $self->brik_help_run_invalid_arg('background_read', $handle, 'IO::Socket::IP') or return;

   # Answer not ready
   if (! $resolver->bgisready($handle)) {
      return 0;
   }

   my $packet = $resolver->bgread($handle);
   if (! defined($packet)) {
      return [];  # No error checking possible, undef means no response or timeout.
   }

   $self->debug && $self->log->debug("background_read: ".$packet->string);

   my @res = ();
   my @answers = $packet->answer;
   for my $rr (@answers) {
      $self->debug && $self->log->debug("background_read: ".$rr->string);

      my $h = {
         type => $rr->type,
         ttl => $rr->ttl,
         name => $rr->name,
         string => $rr->string,
         raw => $rr,
      };
      if ($rr->can('address')) {
         $h->{address} = $rr->address;
      }
      if ($rr->can('cname')) {
         $h->{cname} = $rr->cname;
      }
      if ($rr->can('exchange')) {
         $h->{exchange} = $rr->exchange;
      }
      if ($rr->can('nsdname')) {
         $h->{nsdname} = $rr->nsdname;
      }
      if ($rr->can('ptrdname')) {
         $h->{ptrdname} = $rr->ptrdname;
      }
      if ($rr->can('rdatastr')) {
         $h->{rdatastr} = $rr->rdatastr;
      }
      if ($rr->can('dummy')) {
         $h->{dummy} = $rr->dummy;
      }
      if ($rr->can('target')) {
         $h->{target} = $rr->target;
      }

      push @res, $h;
   }

   return \@res;
}

sub version_bind {
   my $self = shift;
   my ($nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('version_bind', $nameserver) or return;

   my $timeout = $self->rtimeout;

   my $resolver = Net::DNS::Resolver->new(
      nameservers => [ $nameserver, ],
      recurse => $self->use_recursion,
      searchlist => [],
      tcp_timeout => $timeout,
      udp_timeout => $timeout,
      port => $port,
      debug => $self->debug ? 1 : 0,
   ); 
   if (! defined($resolver)) {
      return $self->log->error("version_bind: Net::DNS::Resolver new failed");
   }

   my $version = 0;
   my $res = $resolver->send('version.bind', 'TXT', 'CH');
   if (defined($res) && exists($res->{answer})) {
      my $rr = $res->{answer}->[0];
      if (defined($rr) && exists($rr->{rdata})) {
         $version = unpack('H*', $rr->{rdata});
      }
   }

   $self->log->verbose("version_bind: version [$version]");

   return $version;
}

1;

__END__

=head1 NAME

Metabrik::Network::Dns - network::dns Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
