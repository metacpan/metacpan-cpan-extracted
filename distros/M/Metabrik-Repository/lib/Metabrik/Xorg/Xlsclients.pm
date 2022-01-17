#
# $Id$
#
# xorg::xlsclients Brik
#
package Metabrik::Xorg::Xlsclients;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ],  # Inherited
         list => [ ],
         show => [ ],
      },
      require_binaries => {
         xlsclients => [ ],
      },
      need_packages => {
         ubuntu => [ qw(x11-utils) ],
         debian => [ qw(x11-utils) ],
         kali => [ qw(x11-utils) ],
      },
   };
}

sub list {
   my $self = shift;

   my $cmd = 'xlsclients -la';
   my $lines = $self->capture($cmd) or return;

   my @r = ();
   my $c = -1;
   my $id = '0x0';
   for (@$lines) {
      if (/^Window/) {
         ($id) = $_ =~ m{Window\s+(0x\S+):};
         $c++;
         $r[$c]->{id} = $id;
         $r[$c]->{nid} = int(hex($id));
      }
      else {
         my ($name, $value) = $_ =~ m{^\s+([^:]+):\s+(.*)$};
         $name =~ s/(?:\s+|\/)/_/g;
         $r[$c]->{lc($name)} = $value; 
      }
   }

   return \@r;
}

sub show {
   my $self = shift;

   my $cmd = 'xlsclients -la';
   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Xorg::Xlsclients - xorg::xlsclients Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
