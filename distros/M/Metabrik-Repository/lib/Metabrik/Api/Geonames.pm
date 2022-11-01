#
# $Id$
#
# api::geonames Brik
#
package Metabrik::Api::Geonames;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         username => [ qw(username) ],
      },
      attributes_default => {
      },
      commands => {
         find_nearby_place_name => [ qw(lat long) ],
         find_nearby => [ qw(lat long) ],
      },
      require_modules => {
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
      },
   };
}

#
# API doc:
#
# http://www.geonames.org/export/web-services.html
#

sub brik_init {
   my $self = shift;

   # Do your init here, return 0 on error.

   return $self->SUPER::brik_init;
}

#
# curl 'http://api.geonames.org/findNearbyPlaceNameJSON?formatted=true&lat=52.22991544468422&lng=21.011717319488525&username=demo'
#
sub find_nearby_place_name {
   my $self = shift;
   my ($lat, $long) = @_;

   my $username = $self->username;
   $self->brik_help_set_undef_arg('username', $username) or return;

   $self->brik_help_run_undef_arg('find_nearby_place_name', $lat)
      or return;
   $self->brik_help_run_undef_arg('find_nearby_place_name', $long)
      or return;

   if ($lat !~ m{^\d+\.\d+$}) {
      return $self->log->error("find_nearby_place_name: lat format error");
   }
   if ($long !~ m{^\d+\.\d+$}) {
      return $self->log->error("find_nearby_place_name: long format error");
   }

   my $url = 'http://api.geonames.org/findNearbyPlaceNameJSON?'.
      #'radius=10&style=full&lang=en&formatted=true&lat='.$lat.'&lng='.$long.'&username='.$username;
      'cities=cities1000&style=full&formatted=true&lat='.$lat.'&lng='.$long.'&username='.$username;

   my $get = $self->get($url) or return;

   return $self->content;
}

sub find_nearby {
   my $self = shift;
   my ($lat, $long) = @_;

   my $username = $self->username;
   $self->brik_help_set_undef_arg('username', $username) or return;

   $self->brik_help_run_undef_arg('find_nearby', $lat)
      or return;
   $self->brik_help_run_undef_arg('find_nearby', $long)
      or return;

   if ($lat !~ m{^\d+\.\d+$}) {
      return $self->log->error("find_nearby: lat format error");
   }
   if ($long !~ m{^\d+\.\d+$}) {
      return $self->log->error("find_nearby: long format error");
   }

   my $url = 'http://api.geonames.org/findNearbyJSON?'.
      'style=full&formatted=true&lat='.$lat.'&lng='.$long.'&username='.$username;

   my $get = $self->get($url) or return;

   return $self->content;
}

1;

__END__

=head1 NAME

Metabrik::Api::Geonames - api::geonames Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
