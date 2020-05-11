#
# $Id$
#
# forensic::dcfldd Brik
#
package Metabrik::Forensic::Dcfldd;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ], # Inherited
         dump => [ qw(source destination) ],
      },
      require_binaries => {
         'dcfldd' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(dcfldd) ],
         debian => [ qw(dcfldd) ],
         kali => [ qw(dcfldd) ],
      },
   };
}

sub dump {
   my $self = shift;
   my ($source, $dest) = @_;

   $self->brik_help_run_undef_arg('dump', $source) or return;
   $self->brik_help_run_undef_arg('dump', $dest) or return;

   my $cmd = "dcfldd if=$source of=$dest hash=hash512 hashlog=$dest.hs";

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Forensic::Dcfldd - forensic::dcfldd Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
