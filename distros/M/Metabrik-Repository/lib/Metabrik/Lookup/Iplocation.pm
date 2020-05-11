#
# $Id$
#
# lookup::iplocation Brik
#
package Metabrik::Lookup::Iplocation;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable location ipv4 ipv6 ip geo geolocation) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         _na => [ qw(INTERNAL) ],
      },
      commands => {
         update => [ ],
         from_ip => [ qw(ip_address) ],
         from_ipv4 => [ qw(ipv4_address) ],
         from_ipv6 => [ qw(ipv6_address) ],
         subnet4 => [ qw(ipv4_address) ],
         organization_name => [ qw(ip_address) ],
         range_from_ipv4 => [ qw(ipv4_address) ],
         networks_from_ipv4 => [ qw(ipv4_address) ],
      },
      require_modules => {
         'Geo::IP' => [ ],
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Compress' => [ ],
         'Metabrik::Network::Address' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libgeoip-dev) ],
         debian => [ qw(libgeoip-dev) ],
         kali => [ qw(libgeoip-dev) ],
         freebsd => [ qw(net/GeoIP) ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $init = $self->SUPER::brik_init or return;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   $self->_na($na);

   return 1;
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;

   my $dl_path = 'http://geolite.maxmind.com/download/geoip/database/';

   my %mirror = (
      'GeoIP.dat.gz' => 'GeoLiteCountry/GeoIP.dat.gz',
      'GeoIPv6.dat.gz' => 'GeoIPv6.dat.gz',
      'GeoLiteCity.dat.gz' => 'GeoLiteCity.dat.gz',
      'GeoLiteCityv6.dat.gz' => 'GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz',
      'GeoIPASNum.dat.gz' => 'asnum/GeoIPASNum.dat.gz',
      'GeoIPASNumv6.dat.gz' => 'asnum/GeoIPASNumv6.dat.gz',
   );

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->user_agent("Metabrik-MaxMind-geolite-mirror/1.01");
   $cw->datadir($datadir);

   my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
   $fc->datadir($datadir);

   my @updated = ();
   for my $f (keys %mirror) {
      my $files = $cw->mirror($dl_path.$mirror{$f}, $f) or next;
      for my $file (@$files) {
         (my $outfile = $file) =~ s/\.gz$//;
         $self->log->verbose("update: uncompressing to [$outfile]");
         $fc->uncompress($file, $outfile) or next;
         push @updated, $outfile;
      }
   }

   return \@updated;
}

sub from_ipv4 {
   my $self = shift;
   my ($ipv4) = @_;

   $self->brik_help_run_undef_arg('from_ipv4', $ipv4) or return;

   my $na = $self->_na;

   my $gi = Geo::IP->open($self->datadir.'/GeoLiteCity.dat', Geo::IP::GEOIP_STANDARD())
      or return $self->log->error("from_ipv4: unable to open GeoLiteCity.dat");

   my $gi_asn = Geo::IP->open($self->datadir.'/GeoIPASNum.dat', Geo::IP::GEOIP_STANDARD())
      or return $self->log->error("from_ipv4: unable to open GeoIPASNum.dat");

   my $record;
   eval {
      $record = $gi->record_by_addr($ipv4);
   };
   if ($@ || ! defined($record)) {
      chomp($@);
      return $self->log->error("from_ipv4: unable to find info for IPv4 [$ipv4]");
   }

   my $h = {};
   $h->{country_code} = $record->country_code;
   $h->{country_code3} = $record->country_code3;
   $h->{country_name} = $record->country_name;
   $h->{region} = $record->region;
   $h->{region_name} = $record->region_name;
   $h->{city} = $record->city;
   $h->{postal_code} = $record->postal_code;
   $h->{latitude} = $record->latitude;
   $h->{longitude} = $record->longitude;
   $h->{time_zone} = $record->time_zone;
   $h->{area_code} = $record->area_code;
   $h->{continent_code} = $record->continent_code;
   $h->{metro_code} = $record->metro_code;

   my $asn = '';
   my $organization = '';
   my $asn_organization = $gi_asn->name_by_addr($ipv4);
   if ($asn_organization) {
      ($asn, $organization) = $asn_organization =~ m{^(\S+)(?:\s+(.*))?$};
      $asn ||= $asn_organization;  # Not able to parse, we put it raw.
   }
   $asn ||= 'undef';
   $organization ||= 'undef';

   my ($from, $to) = $gi->range_by_ip($ipv4);
   if (! defined($from) || ! defined($to)) {
      return $self->log->error("from_ipv4: unable to find range for IPv4 [$ipv4]");
   }

   my $network = $na->range_to_cidr($from, $to) or return;
   my $network_list = join('|', @$network);

   # Add other info and return
   $h->{asn} = $asn;
   $h->{organization} = $organization;
   $h->{first_ip} = $from;
   $h->{last_ip} = $to;
   $h->{networks} = $network_list;

   # If not defined, we set to 0, as this should be a number.
   $h->{dma_code} ||= 0;
   $h->{area_code} ||= 0;
   $h->{metro_code} ||= 0;

   # Set as undef if nothing found
   for my $k (keys %$h) {
      if (! defined($h->{$k}) || ! length($h->{$k})) {
         $h->{$k} = 'undef';
      }
   }

   return $h;
}

sub from_ipv6 {
   my $self = shift;
   my ($ipv6) = @_;

   $self->brik_help_run_undef_arg('from_ipv6', $ipv6) or return;

   my $na = $self->_na;

   my $gi = Geo::IP->open($self->datadir.'/GeoLiteCityv6.dat', Geo::IP::GEOIP_STANDARD())
      or return $self->log->error("from_ipv6: unable to open GeoLiteCityv6.dat");

   my $gi_asn = Geo::IP->open($self->datadir.'/GeoIPASNumv6.dat',
      Geo::IP::GEOIP_STANDARD())
         or return $self->log->error("from_ipv6: unable to open GeoIPASNumv6.dat");

   my $record;
   eval {
      $record = $gi->record_by_addr_v6($ipv6);
   };
   if ($@ || ! defined($record)) {
      chomp($@);
      return $self->log->error("from_ipv6: unable to find info for IPv6 [$ipv6]");
   }

   my $h = {};
   $h->{country_code} = $record->country_code;
   $h->{country_code3} = $record->country_code3;
   $h->{country_name} = $record->country_name;
   $h->{region} = $record->region;
   $h->{region_name} = $record->region_name;
   $h->{city} = $record->city;
   $h->{postal_code} = $record->postal_code;
   $h->{latitude} = $record->latitude;
   $h->{longitude} = $record->longitude;
   $h->{time_zone} = $record->time_zone;
   $h->{area_code} = $record->area_code;
   $h->{continent_code} = $record->continent_code;
   $h->{metro_code} = $record->metro_code;

   my $asn = '';
   my $organization = '';
   my $asn_organization = $gi_asn->name_by_addr_v6($ipv6);
   if ($asn_organization) {
      ($asn, $organization) = $asn_organization =~ m{^(\S+)(?:\s+(.*))?$};
      $asn ||= $asn_organization;  # Not able to parse, we put it raw.
   }
   $asn ||= 'undef';
   $organization ||= 'undef';

   #my ($from, $to) = $gi->range_by_ip($ipv6);
   #if (! defined($from) || ! defined($to)) {
      #return $self->log->error("from_ipv6: unable to find range for IPv6 [$ipv6]");
   #}

   #my $network = $na->range_to_cidr($from, $to) or return;
   my $network = [ 'undef' ]; # Not avail in IPv6 for now.
   my $network_list = join('|', @$network);
   $h->{first_ip} = 'undef';
   $h->{last_ip} = 'undef';

   # Add other info and return
   $h->{asn} = $asn;
   $h->{organization} = $organization;
   $h->{networks} = $network_list;

   # If not defined, we set to 0, as this should be a number.
   $h->{dma_code} ||= 0;
   $h->{area_code} ||= 0;
   $h->{metro_code} ||= 0;

   # Set as undef if nothing found
   for my $k (keys %$h) {
      if (! defined($h->{$k}) || ! length($h->{$k})) {
         $h->{$k} = 'undef';
      }
   }

   return $h;
}

sub from_ip {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('from_ip', $ip) or return;

   my $na = $self->_na;
   if ($na->is_ipv4($ip)) {
      return $self->from_ipv4($ip);
   }
   elsif ($na->is_ipv6($ip)) {
      return $self->from_ipv6($ip);
   }

   $self->log->info("from_ip: IP [$ip] is not a valid IP address");

   return 0;
}

sub subnet4 {
   my $self = shift;
   my ($ipv4_address) = @_;

   $self->brik_help_run_undef_arg('subnet4', $ipv4_address) or return;

   my $gi = Geo::IP->open($self->datadir.'/GeoLiteCity.dat', Geo::IP::GEOIP_STANDARD())
      or return $self->log->error("subnet4: unable to open GeoLiteCity.dat");

   my ($from, $to) = $gi->range_by_ip($ipv4_address);

   return [ $from, $to ];
}

sub organization_name {
   my $self = shift;
   my ($ip_address) = @_;

   $self->brik_help_run_undef_arg('organization_name', $ip_address) or return;
  
   my $gi = Geo::IP->open($self->datadir.'/GeoLiteCity.dat', Geo::IP::GEOIP_STANDARD())
      or return $self->log->error("organization_name: unable to open GeoLiteCity.dat");

   my $record = $gi->name_by_addr($ip_address);

   return $record;
}

sub range_from_ipv4 {
   my $self = shift;
   my ($ipv4) = @_;

   $self->brik_help_run_undef_arg('range_from_ipv4', $ipv4) or return;

   my $gi = Geo::IP->open($self->datadir.'/GeoLiteCity.dat', Geo::IP::GEOIP_STANDARD())
      or return $self->log->error("range_from_ipv4: unable to open GeoLiteCity.dat");

   my ($from, $to) = $gi->range_by_ip($ipv4);

   return [ $from, $to ];
}

sub networks_from_ipv4 {
   my $self = shift;
   my ($ipv4) = @_;

   $self->brik_help_run_undef_arg('networks_from_ipv4', $ipv4) or return;

   my $range = $self->range_from_ipv4($ipv4) or return;

   my $na = $self->_na;

   return $na->range_to_cidr($range->[0], $range->[1]);
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Iplocation - lookup::iplocation Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
