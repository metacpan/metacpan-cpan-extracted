#
# $Id$
#
# hardware::temperature Brik
#
package Metabrik::Hardware::Temperature;
use strict;
use warnings;

use base qw(Metabrik::File::Text);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         cpu => [ ],
      },
   };
}

sub cpu {
   my $self = shift;

   my $file = "/sys/class/thermal/thermal_zone0/temp";
   $self->brik_help_run_file_not_found('cpu', $file) or return;

   my $text = $self->read($file) or return;

   if (length($text)) {
      chomp($text);
      if ($text =~ /^\d+$/) {
         return $text / 1000;
      }
   }

   return $self->log->error("cpu: invalid content in file [$file]");
}

1;

__END__

=head1 NAME

Metabrik::Hardware::Temperature - hardware::temperature Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
