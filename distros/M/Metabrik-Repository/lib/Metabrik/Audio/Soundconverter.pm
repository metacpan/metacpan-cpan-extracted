#
# $Id: Soundconverter.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# audio::soundconverter Brik
#
package Metabrik::Audio::Soundconverter;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         format => [ qw(flac|mp3|ogg|wav) ],
      },
      attributes_default => {
         format => 'wav',
      },
      commands => {
         convert => [ qw(file) ],
      },
      require_binaries => {
         soundconverter => [ ],
      },
      need_packages => {
         ubuntu => [ qw(soundconverter) ],
         debian => [ qw(soundconverter) ],
         kali => [ qw(soundconverter) ],
      },
   };
}

sub convert {
   my $self = shift;
   my ($file, $format) = @_;

   $format ||= $self->format;
   $self->brik_help_run_undef_arg('convert', $file) or return;

   $format = lc($format);
   if ($format ne 'ogg' && $format ne 'wav' && $format ne 'mp3' && $format ne 'flac') {
      return $self->log->error("convert: invalid value for format [$format]");
   }

   $self->log->info("convert: to format [$format]");

   my %h = (
      ogg => 'audio/x-vorbis',
      flac => 'audio/x-flac',
      wav => 'audio/x-wav',
      mp3 => 'audio/mpeg',
   );
   my $ext = $format;
   my $mime = $h{$format};

   my $cmd = "soundconverter -b -m $mime -s .$ext $file";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Audio::Soundconverter - audio::soundconverter Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
