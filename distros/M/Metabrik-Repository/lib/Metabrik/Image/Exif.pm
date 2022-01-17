#
# $Id$
#
# image::exif Brik
#
package Metabrik::Image::Exif;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes_default => {
         capture_mode => 1,
      },
      commands => {
         install => [ ], # Inherited
         get_metadata => [ qw(file) ],
         get_gps_coordinates => [ qw(file) ],
         get_field => [ qw(file field) ],
         get_manufacturer => [ qw(file) ],
         get_model => [ qw(file) ],
      },
      require_binaries => {
         'exif' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(exif) ],
         debian => [ qw(exif) ],
         kali => [ qw(exif) ],
      },
   };
}

sub get_metadata {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('get_metadata', $file) or return;
   $self->brik_help_run_file_not_found('get_metadata', $file) or return;

   my $cmd = "exif $file";
   my $lines = $self->execute($cmd) or return;

   my %fields = ();
   for my $line (@$lines) {
      my @toks = split(/\s*\|\s*/, $line);
      if (defined($toks[0]) && defined($toks[1])) {
         $fields{$toks[0]} = $toks[1];
      }
   }

   return \%fields;
}

sub get_gps_coordinates {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('get_gps_coordinates', $file) or return;
   $self->brik_help_run_file_not_found('get_gps_coordinates', $file) or return;

   my $fields = $self->get_metadata($file) or return;

   my $north_south = $fields->{"North or South Latit"};
   my $east_west = $fields->{"East or West Longitu"};
   my $latitude = $fields->{"Latitude"};
   my $longitude = $fields->{"Longitude"};

   if (defined($north_south) && defined($east_west)
   &&  defined($latitude) && defined($longitude)) {
      # Google Maps format: 47°36'16.146"N,7°24'52.48"E
      my @l = split(/\s*,\s*/, $latitude);
      my @L = split(/\s*,\s*/, $longitude);

      if (defined($l[0]) && defined($l[1]) && defined($l[2])
      &&  defined($L[0]) && defined($L[1]) && defined($L[2])) {
         my $lati = "$l[0]°$l[1]'$l[2]\"$north_south";
         my $long = "$L[0]°$L[1]'$L[2]\"$east_west";

         return [ $lati, $long ];
      }
   }

   return 'undef';
}

# No check for Args version (internal version)
sub _get_field {
   my $self = shift;
   my ($file, $field) = @_;

   my $fields = $self->get_metadata($file) or return;

   my $info = $fields->{$field};
   if (defined($info)) {
      return $info;
   }

   return 'undef';
}

# Check for Args vesion (user version)
sub get_field {
   my $self = shift;
   my ($file, $field) = @_;

   $self->brik_help_run_undef_arg('get_field', $file) or return;
   $self->brik_help_run_undef_arg('get_field', $field) or return;
   $self->brik_help_run_file_not_found('get_field', $file) or return;

   return $self->_get_field($file, $field);
}

sub get_manufacturer {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('get_manufacturer', $file) or return;
   $self->brik_help_run_file_not_found('get_manufacturer', $file) or return;

   return $self->_get_field($file, 'Manufacturer');
}

sub get_model {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('get_model', $file) or return;
   $self->brik_help_run_file_not_found('get_model', $file) or return;

   return $self->_get_field($file, 'Model');
}

1;

__END__

=head1 NAME

Metabrik::Image::Exif - image::exif Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
