#
# $Id: Windows.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# remote::windows Brik
#
package Metabrik::Remote::Windows;
use strict;
use warnings;

use base qw(Metabrik::Remote::Winexe);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         host => [ qw(host) ],
         user => [ qw(username) ],
         password => [ qw(password) ],
         registry => [ qw(key) ],
      },
      attributes_default => {
         registry => 'HKLM',
      },
      commands => {
         install => [ ],  # Inherited
         dump_registry => [ qw(key|OPTIONAL output|OPTIONAL) ],
      },
   };
}

sub dump_registry {
   my $self = shift;
   my ($registry, $output) = @_;

   $registry ||= $self->registry;
   $output ||= 'C:\\windows\\temp\\'.$registry.'.reg';

   return $self->execute("\"reg export $registry $output\"");
}

1;

__END__

=head1 NAME

Metabrik::Remote::Windows - remote::windows Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
