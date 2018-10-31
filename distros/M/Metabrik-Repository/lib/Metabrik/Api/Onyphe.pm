#
# $Id: Onyphe.pm,v 25ec7afdbe64 2018/10/30 15:24:17 gomor $
#
# api::onyphe Brik
#
package Metabrik::Api::Onyphe;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision: 25ec7afdbe64 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         apikey => [ qw(key) ],
         apiurl => [ qw(url) ],
         wait => [ qw(seconds) ],
      },
      attributes_default => {
         apiurl => 'https://www.onyphe.io/api',
         wait => 3,
      },
      commands => {
        api => [ qw(api ip apikey|OPTIONAL page|OPTIONAL) ],
        ip => [ qw(ip apikey|OPTIONAL) ],
        geoloc => [ qw(ip) ],
        pastries => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        inetnum => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        threatlist => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        synscan => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        datascan => [ qw(ip|string apikey|OPTIONAL page|OPTIONAL) ],
        onionscan => [ qw(ip|string apikey|OPTIONAL page|OPTIONAL) ],
        sniffer => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        ctl => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        reverse => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        forward => [ qw(ip apikey|OPTIONAL page|OPTIONAL) ],
        md5 => [ qw(sum apikey|OPTIONAL) ],
        search_datascan => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_inetnum => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_pastries => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_resolver => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_synscan => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_threatlist => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_onionscan => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_sniffer => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        search_ctl => [ qw(query apikey|OPTIONAL page|OPTIONAL) ],
        user => [ qw(apikey|OPTIONAL) ],
      },
   };
}

sub api {
   my $self = shift;
   my ($api, $arg, $apikey, $page) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('api', $api) or return;
   $self->brik_help_run_undef_arg('api', $arg) or return;
   my $ref = $self->brik_help_run_invalid_arg('api', $arg, 'SCALAR', 'ARRAY') or return;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;

   my $wait = $self->wait;

   $api =~ s{_}{/}g;

   my $apiurl = $self->apiurl;
   $apiurl =~ s{/*$}{};

   $self->log->verbose("api: using url[$apiurl]");

   my @r = ();
   if ($ref eq 'ARRAY') {
      for my $this (@$arg) {
         my $res = $self->api($api, $this, $apikey, $page) or next;
         push @r, @$res;
      }
   }
   else {
   RETRY:
      my $url = $apiurl.'/'.$api.'/'.$arg.'?k='.$apikey;
      if (defined($page)) {
         $url .= '&page='.$page;
      }

      my $res = $self->get($url);
      my $code = $self->code;
      if ($code == 429) {
         $self->log->verbose("api: request limit reached, waiting before retry");
         sleep($wait);
         goto RETRY;
      }
      elsif ($code == 200) {
         my $content = $self->content;
         if ($content->{status} eq 'nok') {
            my $message = $content->{message};
            return $self->log->error("api: got error with message [$message]");
         }
         else {
            $content->{arg} = $arg;  # Add the IP or other info,
                                     # in case an ARRAY was requested.
            push @r, $content;
         }
      }
      else {
         my $content = $self->get_last->content;
         $self->log->warning("api: skipping from error [$content] code [$code]");
      }
   }

   return \@r;
}

sub geoloc {
   my $self = shift;
   my ($ip) = @_;

   return $self->api('geoloc', $ip);
}

sub ip {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('ip', $ip, $apikey);
}

sub pastries {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('pastries', $ip, $apikey, $page);
}

sub inetnum {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('inetnum', $ip, $apikey, $page);
}

sub threatlist {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('threatlist', $ip, $apikey, $page);
}

sub synscan {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('synscan', $ip, $apikey, $page);
}

sub datascan {
   my $self = shift;
   my ($ip_or_string, $apikey, $page) = @_;

   return $self->api('datascan', $ip_or_string, $apikey, $page);
}

sub onionscan {
   my $self = shift;
   my ($onion, $apikey, $page) = @_;

   return $self->api('onionscan', $onion, $apikey, $page);
}

sub sniffer {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('sniffer', $ip, $apikey, $page);
}

sub ctl {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('ctl', $ip, $apikey, $page);
}

sub reverse {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('reverse', $ip, $apikey, $page);
}

sub forward {
   my $self = shift;
   my ($ip, $apikey, $page) = @_;

   return $self->api('forward', $ip, $apikey, $page);
}

sub md5 {
   my $self = shift;
   my ($sum, $apikey, $page) = @_;

   return $self->api('md5', $sum, $apikey, $page);
}

sub search_datascan {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_datascan', $query, $apikey, $page);
}

sub search_inetnum {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_inetnum', $query, $apikey, $page);
}

sub search_pastries {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_pastries', $query, $apikey, $page);
}

sub search_resolver {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_resolver', $query, $apikey, $page);
}

sub search_synscan {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_synscan', $query, $apikey, $page);
}

sub search_threatlist {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_threatlist', $query, $apikey, $page);
}

sub search_onionscan {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_onionscan', $query, $apikey, $page);
}

sub search_sniffer {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_sniffer', $query, $apikey, $page);
}

sub search_ctl {
   my $self = shift;
   my ($query, $apikey, $page) = @_;

   return $self->api('search_ctl', $query, $apikey, $page);
}

sub user {
   my $self = shift;
   my ($apikey) = @_;

   return $self->api('user', '', $apikey);
}

1;

__END__

=head1 NAME

Metabrik::Api::Onyphe - api::onyphe Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
