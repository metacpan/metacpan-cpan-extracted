#
# $Id$
#
# system::kali::service Brik
#
package Metabrik::System::Kali::Service;
use strict;
use warnings;

use base qw(Metabrik::System::Ubuntu::Service);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
      },
      attributes_default => {
      },
      commands => {
         enable => [ qw(service_name) ],
         disable => [ qw(service_name) ],
      },
      require_binaries => {
         'update-rc.d' => [ ],
      },
      #need_packages => {
         #ubuntu => [ qw() ],
         #debian => [ qw() ],
         #kali => [ qw() ],
      #},
   };
}

1;

__END__

=head1 NAME

Metabrik::System::Kali::Service - system::kali::service Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
