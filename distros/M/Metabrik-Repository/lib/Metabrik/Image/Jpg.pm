#
# $Id$
#
# image::jpg Brik
#
package Metabrik::Image::Jpg;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable jpeg) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ], # Inherited
         info => [ qw(image.jpg) ],
      },
      require_binaries => {
         'jhead' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(jhead) ],
         debian => [ qw(jhead) ],
         kali => [ qw(jhead) ],
      },
   };
}

sub info {
   my $self = shift;
   my ($image) = @_;

   $self->brik_help_run_undef_arg('info', $image) or return;
   $self->brik_help_run_file_not_found('info', $image) or return;

   my $cmd = "jhead \"$image\"";
   my $out = $self->capture($cmd) or return;

   my $info = {};
   for my $this (@$out) {
      my ($key, $val) = $this =~ /^(.*?)\s+:\s+(.*)$/;
      $self->log->debug("info: key [$key] val [$val]");
      $key = lc($key);
      $key =~ s/\s+/_/g;
      $info->{$key} = $val;
   }

   return $info;
}

1;

__END__

=head1 NAME

Metabrik::Image::Jpg - image::jpg Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
