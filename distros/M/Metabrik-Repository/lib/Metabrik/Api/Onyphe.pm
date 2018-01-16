#
# $Id: Onyphe.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# api::onyphe Brik
#
package Metabrik::Api::Onyphe;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
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
        api => [ qw(api ip apikey|OPTIONAL) ],
        ip => [ qw(ip apikey|OPTIONAL) ],
        pastries => [ qw(ip apikey|OPTIONAL) ],
        inetnum => [ qw(ip apikey|OPTIONAL) ],
        threatlist => [ qw(ip apikey|OPTIONAL) ],
        synscan => [ qw(ip apikey|OPTIONAL) ],
        datascan => [ qw(ip|string apikey|OPTIONAL) ],
        reverse => [ qw(ip apikey|OPTIONAL) ],
        forward => [ qw(ip apikey|OPTIONAL) ],
        md5 => [ qw(sum apikey|OPTIONAL) ],
        list_ports => [ qw(since apikey|OPTIONAL)],
        search => [ qw(query apikey|OPTIONAL) ],
      },
   };
}

sub api {
   my $self = shift;
   my ($api, $arg, $apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('api', $api) or return;
   $self->brik_help_run_undef_arg('api', $arg) or return;
   my $ref = $self->brik_help_run_invalid_arg('api', $arg, 'SCALAR', 'ARRAY') or return;
   $self->brik_help_set_undef_arg('apikey', $apikey) or return;

   my $wait = $self->wait;

   my $apiurl = $self->apiurl;
   $apiurl =~ s{/*$}{};

   $self->log->verbose("api: using url[$apiurl]");

   my @r = ();
   if ($ref eq 'ARRAY') {
      for my $this (@$arg) {
         my $res = $self->api($api, $this, $apikey) or next;
         push @r, @$res;
      }
   }
   else {
   RETRY:
      my $res = $self->get($apiurl.'/'.$api.'/'.$arg.'?k='.$apikey);
      my $code = $self->code;
      if ($code == 429) {
         $self->log->info("api: request limit reached, waiting before retry");
         sleep($wait);
         goto RETRY;
      }
      elsif ($code == 200) {
         my $content = $self->content;
         $content->{arg} = $arg;  # Add the IP or other info,
                                  # in case an ARRAY was requested.
         push @r, $content;
      }
      else {
         my $content = $self->get_last->content;
         $self->log->error("api: skipping from error [$content]");
      }
   }

   return \@r;
}

sub ip {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('ip', $ip, $apikey);
}

sub pastries {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('pastries', $ip, $apikey);
}

sub inetnum {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('inetnum', $ip, $apikey);
}

sub threatlist {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('threatlist', $ip, $apikey);
}

sub synscan {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('synscan', $ip, $apikey);
}

sub datascan {
   my $self = shift;
   my ($ip_or_string, $apikey) = @_;

   return $self->api('datascan', $ip_or_string, $apikey);
}

sub reverse {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('reverse', $ip, $apikey);
}

sub forward {
   my $self = shift;
   my ($ip, $apikey) = @_;

   return $self->api('forward', $ip, $apikey);
}

sub md5 {
   my $self = shift;
   my ($sum, $apikey) = @_;

   return $self->api('md5', $sum, $apikey);
}

sub list_ports {
   my $self = shift;
   my ($apikey) = @_;

   $apikey ||= $self->apikey;
   $self->brik_help_run_undef_arg('list_ports', $apikey) or return;

   my $wait = $self->wait;

   my $apiurl = $self->apiurl;
   $apiurl =~ s{/*$}{};

   my @r = ();

RETRY:
   my $res = $self->get($apiurl.'/list/ports/?k='.$apikey);
   my $code = $self->code;
   if ($code == 429) {
      $self->log->info("list_ports: request limit reached, waiting before retry");
      sleep($wait);
      goto RETRY;
   }
   elsif ($code == 200) {
      my $content = $self->content;
      push @r, $content;
   }

   return \@r;
}

sub search {
   my $self = shift;
   my ($query, $apikey) = @_;

   return $self->api('search', $query, $apikey);
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
