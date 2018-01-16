#
# $Id: Convert.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# image::convert Brik
#
package Metabrik::Image::Convert;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         output => [ qw(file) ],
         delay => [ qw(microseconds) ],
      },
      attributes_default => {
         delay => 50,
      },
      commands => {
         install => [ ], # Inherited
         to_animated_gif => [ qw($files output|OPTIONAL delay|OPTIONAL) ],
      },
      require_binaries => {
         'convert' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(imagemagick) ],
         debian => [ qw(imagemagick) ],
      },
   };
}

sub to_animated_gif {
   my $self = shift;
   my ($files, $output, $delay) = @_;

   $output ||= $self->output;
   $delay ||= $self->delay;
   $self->brik_help_run_undef_arg('to_animated_gif', $files) or return;
   $self->brik_help_run_invalid_arg('to_animated_gif', $files, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('to_animated_gif', $files) or return;

   my $file_list = join(' ', @$files);
   $self->execute("convert -delay $delay -loop 0 $file_list $output") or return;

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::Image::Convert - image::convert Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
