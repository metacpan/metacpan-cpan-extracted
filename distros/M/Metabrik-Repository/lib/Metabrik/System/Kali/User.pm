#
# $Id$
#
# system::kali::user Brik
#
package Metabrik::System::Kali::User;
use strict;
use warnings;

use base qw(Metabrik::System::Ubuntu::User);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable manage management creation group create) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ], # Inherited
         create_user => [ qw(user) ],
         add_user_to_group => [ qw(user group) ],
      },
      require_binaries => {
         adduser => [ ],
      },
      need_packages => {
         kali => [ qw(adduser) ],
      },
   };
}

1;

__END__

=head1 NAME

Metabrik::System::Kali::User - system::kali::user Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
