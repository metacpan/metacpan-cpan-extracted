#
# $Id: User.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# system::debian::user Brik
#
package Metabrik::System::Debian::User;
use strict;
use warnings;

use base qw(Metabrik::System::Ubuntu::User);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
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
         debian => [ qw(adduser) ],
      },
   };
}

1;

__END__

=head1 NAME

Metabrik::System::Debian::User - system::debian::user Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
