#
# $Id: Clamav.pm,v 4f5647eb9e58 2017/03/05 12:22:13 gomor $
#
# antivirus::clamav Brik
#
package Metabrik::Antivirus::Clamav;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 4f5647eb9e58 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      attributes_default => {
         use_sudo => 0,
      },
      commands => {
         install => [ ], # Inherited
         update => [ ],
         scan => [ qw(target) ], # file or directory
      },
      require_binaries => {
         'freshclam' => [ ],
         'clamscan' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(clamav) ],
         debian => [ qw(clamav) ],
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;

   my $cmd = "freshclam";

   $self->log->verbose($cmd);

   return $self->sudo_system($cmd);
}

sub scan {
   my $self = shift;
   my ($target) = @_;

   $self->brik_help_run_undef_arg('scan', $target) or return;

   my $datadir = $self->datadir;
   if (! -f $target && ! -d $target) {
      return $self->log->error("scan: target [$target] not found");
   }

   my $cmd = "clamscan -r -l $datadir/out.av -i $target";

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Antivirus::Clamav - antivirus::clamav Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
