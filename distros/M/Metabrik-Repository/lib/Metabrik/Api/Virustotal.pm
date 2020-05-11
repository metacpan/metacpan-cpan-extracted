#
# $Id$
#
# api::virustotal Brik
#
package Metabrik::Api::Virustotal;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable rest domain virtualhost) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         apikey => [ qw(apikey) ],
         output_mode => [ qw(json|xml) ],
      },
      attributes_default => {
         ssl_verify => 0,
         output_mode => 'json',
      },
      commands => {
         check_resource => [ qw(hash apikey|OPTIONAL) ],
         file_report => [ qw(hash apikey|OPTIONAL) ],
         ipv4_address_report => [ qw(ipv4_address apikey|OPTIONAL) ],
         domain_report => [ qw(domain apikey|OPTIONAL) ],
         subdomain_list => [ qw(domain) ],
         hosted_domains => [ qw(ipv4_address) ],
      },
      require_modules => {
         'Metabrik::String::Json' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
   };
}

sub check_resource {
   my $self = shift;
   my ($resource, $apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('check_resource', $resource) or return;
   $self->brik_help_run_undef_arg('check_resource', $apikey) or return;

   my $r = $self->post({ apikey => $apikey, resource => $resource },
      'https://www.virustotal.com/vtapi/v2/file/rescan')
         or return;

   my $content = $r->{content};
   my $code = $r->{code};

   $self->log->verbose("check_resource: returned code [$code]");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decode = $sj->decode($content) or return;

   return $decode;
}

sub file_report {
   my $self = shift;
   my ($resource, $apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('file_report', $resource) or return;
   $self->brik_help_run_undef_arg('file_report', $apikey) or return;

   my $r = $self->post({ apikey => $apikey, resource => $resource },
      'https://www.virustotal.com/vtapi/v2/file/report')
         or return;

   my $content = $r->{content};
   my $code = $r->{code};

   $self->log->verbose("file_report: returned code [$code]");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decode = $sj->decode($content) or return;

   return $decode;
}

sub ipv4_address_report {
   my $self = shift;
   my ($ipv4_address, $apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('ipv4_address_report', $ipv4_address) or return;
   $self->brik_help_run_undef_arg('ipv4_address_report', $apikey) or return;

   my $r = $self->get('https://www.virustotal.com/vtapi/v2/ip-address/report?apikey='
      .$apikey.'&ip='.$ipv4_address)
         or return;

   my $content = $r->{content};
   my $code = $r->{code};

   $self->log->verbose("ipv4_address_report: returned code [$code]");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decode = $sj->decode($content) or return;

   return $decode;
}

sub domain_report {
   my $self = shift;
   my ($domain, $apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('domain_report', $domain) or return;
   $self->brik_help_run_undef_arg('domain_report', $apikey) or return;

   my $r = $self->get('https://www.virustotal.com/vtapi/v2/domain/report?apikey='
      .$apikey.'&domain='.$domain)
         or return;

   my $content = $r->{content};
   my $code = $r->{code};

   $self->log->verbose("domain_report: returned code [$code]");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decode = $sj->decode($content) or return;

   return $decode;
}

sub subdomain_list {
   my $self = shift;
   my ($domain) = @_;

   $self->brik_help_run_undef_arg('subdomain_list', $domain) or return;

   my $r = $self->domain_report($domain) or return;

   if (exists($r->{subdomains}) && ref($r->{subdomains}) eq 'ARRAY') {
      return $r->{subdomains};
   }

   return [];
}

sub hosted_domains {
   my $self = shift;
   my ($ipv4_address) = @_;

   $self->brik_help_run_undef_arg('hosted_domains', $ipv4_address) or return;

   my $r = $self->ipv4_address_report($ipv4_address) or return;

   my @result = ();
   if (exists($r->{resolutions}) && ref($r->{resolutions}) eq 'ARRAY') {
      for (@{$r->{resolutions}}) {
         push @result, $_->{hostname};
      }
   }

   return \@result;
}

1;

__END__

=head1 NAME

Metabrik::Api::Virustotal - api::virustotal Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
