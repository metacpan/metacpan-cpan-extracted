#
# $Id$
#
# client::whois Brik
#
package Metabrik::Client::Whois;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         use_normalization => [ qw(0|1) ],
      },
      attributes_default => {
         use_normalization => 1,
      },
      commands => {
         from_ip => [ qw(ip_address) ],
         from_domain => [ qw(domain) ],
         is_available_domain => [ qw(domain) ],
         parse_raw_ip_whois => [ qw($lines_list) ],
         normalize_raw_ip_whois => [ qw($chunks $lines_list) ],
         is_ip_from_owner => [ qw(ip_address owner) ],
      },
      require_modules => {
         'Metabrik::Network::Address' => [ ],
         'Metabrik::Network::Whois' => [ ],
         'Metabrik::String::Parse' => [ ],
      },
   };
}

sub parse_raw_ip_whois {
   my $self = shift;
   my ($lines) = @_;

   $self->brik_help_run_undef_arg('parse_raw_ip_whois', $lines) or return;

   my $sp = Metabrik::String::Parse->new_from_brik_init($self) or return;
   my $chunks = $sp->split_by_blank_line($lines) or return;

   my @abuse = ();
   my @chunks = ();
   for my $this (@$chunks) {
      my $new = {};
      for (@$this) {
         # Some whois prefix every line by 'network:'
         s/^\s*network\s*:\s*//;

         # If an abuse email adress can be found, we gather it.
         if (/abuse/i && /\@/) {
            my ($new) = $_ =~ /([A-Za-z0-9\._-]+\@[A-Za-z0-9\._-]+)/;
            if (defined($new)) {
               defined($new) ? ($new =~ s/['"]//g) : ();
               push @abuse, $new;
            }
         }

         if (/^\s*%error 230 No objects found/i) {
            $new->{match} = 0;
         }
         elsif (/^\s*%error 350 Invalid Query Syntax/i) {
            $new->{has_error} = 1;
         }
         elsif (/^\s*%error 501 Service Not Available: exceeded max client sessions/i) {
            $new->{has_error} = 1;
         }
         elsif (/^\s*%ok\s*$/) {
            $new->{has_error} = 1;
         }

         next if (/^\s*%/);  # Skip comments
         next if (/^\s*#/);  # Skip comments

         # We default to split by the first encountered : char
         if (/^\s*([^:]+?)\s*:\s*(.*)\s*$/) {
            if (defined($1) && defined($2)) {
               my $k = lc($1);
               my $v = $2;
               $k =~ s{[ /-]}{_}g;
               if (exists($new->{$k})) {
                  $new->{$k} .= "\n$v";
               }
               else {
                  $new->{$k} = $v;
               }
            }
         }
         # We try to guess an inetnum. Example:
         # Akamai Technologies, Inc. AKAMAI (NET-104-64-0-0-1) 104.64.0.0 - 104.127.255.255
         elsif (/^\s*([^\(]+)\(([^\)]+)\)\s*(\S+\s*-\s*\S+)$/) {
            my $description = $1;
            my $netname = $2;
            my $inetnum = $3;
            $new->{description} = $description;
            $new->{netname} = $netname;
            $new->{inetnum} = $inetnum;
         }
         # Nothing known. Exemple:
         # No match found for aaa
         elsif (/^\s*No match found for /i) {
            $new->{match} = 0;
         }
      }

      # If we found some email address along with 'abuse' string, we add this email address
      if (@abuse > 0) {
         $new->{abuse} = join("\n", @abuse);
      }

      if (keys %$new > 0 && ! exists($new->{match})) {
         $new->{match} = 1;
      }

      if (keys %$new > 0) {
         push @chunks, $new;
      }
   }

   return \@chunks;
}

sub _ip_lookup {
   my $self = shift;
   my ($this, $key, $normalize, $result) = @_;

   return $self->_domain_lookup($this, $key, $normalize, $result);
}

sub normalize_raw_ip_whois {
   my $self = shift;
   my ($chunks, $lines) = @_;

   $self->brik_help_run_undef_arg('normalize_raw_ip_whois', $chunks) or return;
   $self->brik_help_run_undef_arg('normalize_raw_ip_whois', $lines) or return;

   my $r = { raw => $lines };
   #my $r = {};

   my $n_chunks = @$chunks;
   if (@$chunks <= 0) {
      return $self->log->error("normalize_raw_ip_whois: nothing to normalize");
   }

   # We search for the first chunk with an inetnum.
   my $general;
   for (@$chunks) {
      if (exists($_->{inetnum}) || exists($_->{netrange}) || exists($_->{network}) || exists($_->{ip_network})) {
         $general = $_;
         last;
      }
   }
   if (! defined($general)) {
      use Data::Dumper;
      print Dumper($chunks)."\n";
      return $self->log->error("normalize_raw_ip_whois: no inetnum found in this record");
   }

   # inetnum,netrange,network,ip_network
   $self->_ip_lookup($general, 'inetnum', 'inetnum', $r);
   $self->_ip_lookup($general, 'netrange', 'inetnum', $r);
   $self->_ip_lookup($general, 'network', 'inetnum', $r);
   $self->_ip_lookup($general, 'ip_network', 'inetnum', $r);
   # cidr,
   $self->_ip_lookup($general, 'cidr', 'cidr', $r);
   # nethandle,
   $self->_ip_lookup($general, 'nethandle', 'nethandle', $r);
   # created,
   $self->_ip_lookup($general, 'created', 'date_created', $r);
   # updated,last_modified,
   $self->_ip_lookup($general, 'updated', 'date_updated', $r);
   $self->_ip_lookup($general, 'last_modified', 'date_updated', $r);
   # originas,origin,
   $self->_ip_lookup($general, 'originas', 'originas', $r);
   $self->_ip_lookup($general, 'origin', 'originas', $r);
   # netname,ownerid,
   $self->_ip_lookup($general, 'netname', 'netname', $r);
   $self->_ip_lookup($general, 'ownerid', 'netname', $r);
   # descr,
   $self->_ip_lookup($general, 'descr', 'description', $r);
   # parent,
   $self->_ip_lookup($general, 'parent', 'netparent', $r);
   # nettype,
   $self->_ip_lookup($general, 'nettype', 'nettype', $r);
   # organization,org,owner,org_name,
   $self->_ip_lookup($general, 'organization', 'organization', $r);
   $self->_ip_lookup($general, 'org', 'organization', $r);
   $self->_ip_lookup($general, 'owner', 'organization', $r);
   $self->_ip_lookup($general, 'org_name', 'organization', $r);
   # regdate,
   $self->_ip_lookup($general, 'regdate', 'date_registered', $r);
   # ref,
   $self->_ip_lookup($general, 'ref', 'ref', $r);
   # country,
   $self->_ip_lookup($general, 'country', 'country', $r);
   # source,
   $self->_ip_lookup($general, 'source', 'source', $r);
   # status,
   $self->_ip_lookup($general, 'status', 'status', $r);
   # abuse,abuse_c,
   $self->_ip_lookup($general, 'abuse', 'abuse', $r);
   $self->_ip_lookup($general, 'abuse_c', 'abuse', $r);
   # nserver,
   $self->_ip_lookup($general, 'nserver', 'nserver', $r);
   # phone,
   $self->_ip_lookup($general, 'phone', 'phone', $r);
   # responsible,
   $self->_ip_lookup($general, 'responsible', 'responsible', $r);
   # address,
   $self->_ip_lookup($general, 'address', 'address', $r);
   # city,
   $self->_ip_lookup($general, 'city', 'city', $r);
   # sponsoring_org,
   $self->_ip_lookup($general, 'sponsoring_org', 'sponsoring_org', $r);
   # route,inetnum-up,
   $self->_ip_lookup($general, 'route', 'route', $r);
   $self->_ip_lookup($general, 'inetnum_up', 'route', $r);

   # We search for a chunk with AS information (usually the last chunk)
   my $asinfo;
   for (reverse @$chunks) {
      if (exists($_->{origin}) && exists($_->{route})) {
         $asinfo = $_;
         last;
      }
   }

   $self->_ip_lookup($asinfo, 'route', 'route', $r);
   $self->_ip_lookup($asinfo, 'origin', 'originas', $r);

   my @fields = qw(
      inetnum
      cidr
      nethandle
      date_created
      date_updated
      originas
      netname
      description
      netparent
      nettype
      organization
      date_registered
      ref
      country
      source
      status
      abuse
      nserver
      phone
      responsible
      address
      city
      sponsoring_org
      route
   );

   # Put default values for missing fields
   for (@fields) {
      $r->{$_} ||= 'undef';
   }

   # Dedups lines
   for (keys %$r) {
      next if $_ eq 'raw';
      if (my @toks = split(/\n/, $r->{$_})) {
         my %uniq = map { $_ => 1 } @toks;
         $r->{$_} = join("\n", sort { $a cmp $b } keys %uniq);  # With a sort
      }
   }

   return $r;
}

sub from_ip {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('ip', $ip) or return;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if (! $na->is_ip($ip)) {
      return $self->log->error("ip: not a valid IP address [$ip]");
   }

   my $nw = Metabrik::Network::Whois->new_from_brik_init($self) or return;
   my $lines = $nw->target($ip) or return;

   my $r = {};
   if ($self->use_normalization) {
      my $chunks = $self->parse_raw_ip_whois($lines) or return;
      $r = $self->normalize_raw_ip_whois($chunks, $lines) or return;
   }

   $r->{date_queried} = localtime();
   $r->{whois_server} = $nw->last_server;
   $r->{raw} = $lines;

   return $r;
}

sub _domain_lookup {
   my $self = shift;
   my ($this, $key, $normalize, $result) = @_;

   if (exists($this->{$key})) {
      exists($result->{$normalize})
         ? ($result->{$normalize} .= "\n".$this->{$key})
         : ($result->{$normalize} = $this->{$key});
   }

   return $this;
}

sub from_domain {
   my $self = shift;
   my ($domain) = @_;

   $self->brik_help_run_undef_arg('domain', $domain) or return;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if ($na->is_ip($domain)) {
      return $self->log->error("domain: domain [$domain] must not be an IP address");
   }

   my $nw = Metabrik::Network::Whois->new_from_brik_init($self) or return;
   my $lines = $nw->target($domain) or return;

   my $r = { raw => $lines };
   $r->{date_queried} = localtime();
   $r->{whois_server} = $nw->last_server;

   if ($self->use_normalization) {
      my $chunks = $self->parse_raw_ip_whois($lines);

      # 4 categories: general, registrant, admin, tech
      for (@$chunks) {
         # Registrar,Sponsoring Registrar,
         $self->_domain_lookup($_, 'registrar', 'registrar', $r);
         $self->_domain_lookup($_, 'sponsoring_registrar', 'registrar', $r);

         # Whois Server,
         $self->_domain_lookup($_, 'whois_server', 'whois_server', $r);

         # Domain Name,Dominio,domain,
         $self->_domain_lookup($_, 'domain_name', 'domain_name', $r);
         $self->_domain_lookup($_, 'dominio', 'domain_name', $r);
         $self->_domain_lookup($_, 'domain', 'domain_name', $r);

         # Creation Date,Fecha de registro,created,
         $self->_domain_lookup($_, 'creation_date', 'creation_date', $r);
         $self->_domain_lookup($_, 'fecha_de_registro', 'creation_date', $r);
         $self->_domain_lookup($_, 'created', 'creation_date', $r);

         # Updated Date,last-update,
         $self->_domain_lookup($_, 'updated_date', 'updated_date', $r);
         $self->_domain_lookup($_, 'last_update', 'updated_date', $r);

         # Registrar Registration Expiration Date,Expiration Date,Registry Expiry Date,Fecha de vencimiento,Expiry Date,
         $self->_domain_lookup($_, 'registrar_registration_expiration_date', 'expiration_date', $r);
         $self->_domain_lookup($_, 'expiration_date', 'expiration_date', $r);
         $self->_domain_lookup($_, 'registry_expiry_date', 'expiration_date', $r);
         $self->_domain_lookup($_, 'fecha_de_vencimiento', 'expiration_date', $r);
         $self->_domain_lookup($_, 'expiry_date', 'expiration_date', $r);

         # Registrar URL,Referral URL,
         $self->_domain_lookup($_, 'registrar_url', 'registrar_url', $r);
         $self->_domain_lookup($_, 'referral_url', 'registrar_url', $r);

         # DNSSEC,
         $self->_domain_lookup($_, 'dnssec', 'dnssec', $r);

         # Domain Status,Status,
         $self->_domain_lookup($_, 'domain_status', 'domain_status', $r);
         $self->_domain_lookup($_, 'status', 'domain_status', $r);

         # Name Server,nserver,
         $self->_domain_lookup($_, 'name_server', 'name_server', $r);
         $self->_domain_lookup($_, 'nserver', 'name_server', $r);

         # Registrant Name,
         $self->_domain_lookup($_, 'registrant_name', 'registrant_name', $r);

         # Registrant Organization,Organizacion,
         $self->_domain_lookup($_, 'registrant_organization', 'registrant_organization', $r);
         $self->_domain_lookup($_, 'organizacion', 'registrar', $r);

         # Registrant Street,
         $self->_domain_lookup($_, 'registrant_street', 'registrant_street', $r);

         # Registrant City,Ciudad,
         $self->_domain_lookup($_, 'registrant_city', 'registrant_city', $r);
         $self->_domain_lookup($_, 'ciudad', 'registrant_city', $r);

         # Registrant Postal Code,
         $self->_domain_lookup($_, 'registrant_postal_code', 'registrant_postal_code', $r);

         # Registrant State/Province,
         $self->_domain_lookup($_, 'registrant_state_province', 'registrant_state_province', $r);

         # Registrant Country,Pais,
         $self->_domain_lookup($_, 'registrant_country', 'registrant_country', $r);
         $self->_domain_lookup($_, 'pais', 'registrant_country', $r);

         # Registrant Email,
         $self->_domain_lookup($_, 'registrant_email', 'registrant_email', $r);
      }

      # Dedups lines
      for (keys %$r) {
         next if $_ eq 'raw';
         if (my @toks = split(/\n/, $r->{$_})) {
            my %uniq = map { $_ => 1 } @toks;
            $r->{$_} = join("\n", sort { $a cmp $b } keys %uniq);  # With a sort
         }
      }

      # If there is more than the raw key, domain exists
      if (keys %$r > 1) {
         $r->{domain_exists} = 1;
      }
      else {
         $r->{domain_exists} = 0;
      }
   }

   return $r;
}

sub is_available_domain {
   my $self = shift;
   my ($domain) = shift;

   $self->brik_help_run_undef_arg('is_available_domain', $domain) or return;

   my $info = $self->domain($domain) or return;

   return $info->{domain_exists};
}

sub is_ip_from_owner {
   my $self = shift;
   my ($ip, $owner) = @_;

   $self->brik_help_run_undef_arg('is_ip_from_owner', $ip) or return;
   $self->brik_help_run_undef_arg('is_ip_from_owner', $owner) or return;

   my $r = $self->ip($ip) or return;
   if ((exists($r->{description}) && $r->{description} =~ m{$owner}i)
   ||  (exists($r->{organization}) && $r->{organization} =~ m{$owner}i)) {
      return 1;
   }

   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Client::Whois - client::whois Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
