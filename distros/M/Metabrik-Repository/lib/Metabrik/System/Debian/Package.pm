#
# $Id: Package.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# system::debian::package Brik
#
package Metabrik::System::Debian::Package;
use strict;
use warnings;

use base qw(Metabrik::System::Ubuntu::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes_default => {
         ignore_error => 0,
      },
      commands => {
         search => [ qw(string) ],
         install => [ qw(package|$package_list) ],
         remove => [ qw(package|$package_list) ],
         update => [ ],
         upgrade => [ ],
         list => [ ],
         is_installed => [ qw(package|$package_list) ],
         which => [ qw(file) ],
         system_update => [ ],
         system_upgrade => [ ],
      },
      optional_binaries => {
         aptitude => [ ],
      },
      require_binaries => {
         'apt-get' => [ ],
         dpkg => [ ],
      },
      need_packages => {
         debian => [ qw(aptitude) ],
      },
   };
}

1;

__END__

=head1 NAME

Metabrik::System::Debian::Package - system::debian::package Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
