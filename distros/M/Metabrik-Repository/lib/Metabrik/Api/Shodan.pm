#
# $Id: Shodan.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# api::shodan Brik
#
package Metabrik::Api::Shodan;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

# API: https://developer.shodan.io/api

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable rest) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         output_mode => [ qw(json|xml) ],
         apikey => [ qw(apikey) ],
         uri => [ qw(shodan_uri) ],
      },
      attributes_default => {
         output_mode => 'json',
         ssl_verify => 0,
         uri => 'https://api.shodan.io',
      },
      commands => {
         myip => [ qw(apikey|OPTIONAL) ],
         api_info => [ qw(apikey|OPTIONAL) ],
         host_ip => [ qw(ip_address apikey|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Network::Address' => [ ],
         'Metabrik::String::Json' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
   };
}

sub myip {
   my $self = shift;

   my $apikey = $self->apikey;
   $self->brik_help_run_undef_arg('myip', $apikey) or return;

   my $uri = $self->uri;

   my $resp = $self->get($uri.'/tools/myip?key='.$apikey) or return;
   my $content = $resp->{content};

   $content =~ s/"?//g;

   return $content;
}

sub api_info {
   my $self = shift;
   my ($apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('api_info', $apikey) or return;

   my $uri = $self->uri;

   my $resp = $self->get($uri.'/api-info?key='.$apikey) or return;
   my $content = $resp->{content};

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decoded = $sj->decode($content) or return;

   return $decoded;
}

sub host_ip {
   my $self = shift;
   my ($ip, $apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('host_ip', $ip) or return;
   $self->brik_help_run_undef_arg('host_ip', $apikey) or return;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if (! $na->is_ip($ip)) {
      return $self->log->error("host_ip: invalid format for IP [$ip]");
   }

   my $uri = $self->uri;

   my $resp = $self->get($uri.'/shodan/host/'.$ip.'?key='.$apikey) or return;
   my $content = $resp->{content};

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   my $decoded = $sj->decode($content) or return;

   return $decoded;
}

1;

__END__

=head1 NAME

Metabrik::Api::Shodan - api::shodan Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
