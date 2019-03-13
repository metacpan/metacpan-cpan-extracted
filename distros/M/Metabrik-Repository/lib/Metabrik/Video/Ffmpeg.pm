#
# $Id: Ffmpeg.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# video::ffmpeg Brik
#
package Metabrik::Video::Ffmpeg;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable audio sound record micro) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         resolution => [ qw(resolution) ],
         use_micro => [ qw(0|1) ],
      },
      attributes_default => {
         resolution => '1024x768',
         use_micro => 0,
      },
      commands => {
         install => [ ],  # Inherited
         record_desktop => [ qw(output.mkv) ],
         convert_to_youtube => [ qw(input.mkv output.mp4) ],
      },
      require_binaries => {
         ffmpeg => [ ],
      },
      need_packages => {
         ubuntu => [ qw(ffmpeg) ],
         debian => [ qw(ffmpeg) ],
         kali => [ qw(ffmpeg) ],
      },
   };
}

sub record_desktop {
   my $self = shift;
   my ($output, $resolution) = @_;

   $resolution ||= $self->resolution;
   $self->brik_help_run_undef_arg('record_desktop', $output) or return;

   # Give 1 second to switch window if needed.
   my $cmd = 'sleep 1 && ffmpeg';
   if ($self->use_micro) {
      $cmd .= " -f alsa -i pulse -f x11grab -r 25 -s $resolution -i :0.0 ".
         "-acodec pcm_s16le -vcodec libx264 -preset ultrafast -crf 0 -threads 0";
   }
   else {
      $cmd .= " -f x11grab -r 25 -s $resolution -i :0.0 -vcodec libx264 ".
         "-preset ultrafast -crf 0 -threads 0";
   }

   $cmd .= " \"$output\"";

   return $self->execute($cmd);
}

sub convert_to_youtube {
   my $self = shift;
   my ($input, $output) = @_;

   $self->brik_help_run_undef_arg('convert_to_youtube', $input) or return;
   $self->brik_help_run_undef_arg('convert_to_youtube', $output) or return;

   my $cmd = "ffmpeg -i \"$input\" -codec:v libx264 -crf 21 -bf 2 -flags +cgop ".
      "-pix_fmt yuv420p -codec:a aac -strict -2 -b:a 384k -r:a 48000 -movflags faststart ".
      "\"$output\"";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Video::Ffmpeg - video::ffmpeg Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
