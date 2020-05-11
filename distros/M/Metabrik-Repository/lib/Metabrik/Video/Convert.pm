#
# $Id$
#
# video::convert Brik
#
package Metabrik::Video::Convert;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable avi jpg) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(directory) ],
         output_pattern => [ qw(file_pattern) ],
         keep_only_first => [ qw(0|1) ],
      },
      attributes_default => {
         output_pattern => 'image_%04d.jpg',
         keep_only_first => 0,
      },
      commands => {
         install => [ ], # Inherited
         to_jpg => [ qw(input) ],
      },
      require_modules => {
         'Metabrik::File::Find' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         'ffmpeg' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(ffmpeg) ],
         debian => [ qw(ffmpeg) ],
         kali => [ qw(ffmpeg) ],
      },
   };
}

sub to_jpg {
   my $self = shift;
   my ($input) = @_;

   my $datadir = $self->datadir;
   my $output_pattern = $self->output_pattern;
   my $keep_only_first = $self->keep_only_first;
   $self->brik_help_run_undef_arg('to_jpg', $input) or return;
   $self->brik_help_run_file_not_found('to_jpg', $input) or return;

   my $ff = Metabrik::File::Find->new_from_brik_init($self) or return;
   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;

   # This program is only provided for compatibility and will be removed in a future release.
   # Please use avconv instead.
   my $cmd = "ffmpeg -i $input $datadir/".$output_pattern;

   $self->execute($cmd) or return;

   (my $find = $output_pattern) =~ s/^(.*)%.*$/$1/;
   my $found = $ff->files($datadir, "$find.*") or return;

   if ($keep_only_first) {
      my $keep = shift @$found;
      $sf->remove($found);
      $found = $keep;
   }

   return $found;
}

1;

__END__

=head1 NAME

Metabrik::Video::Convert - video::convert Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
