#
# $Id: Pf.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# system::freebsd::pf Brik
#
package Metabrik::System::Freebsd::Pf;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable packet filter fw firewall) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         edit => [ ],
         reload => [ ],
         console => [ qw(jail_name) ],
      },
      require_binaries => {
         'pfctl' => [ ],
      },
   };
}

sub edit {
   my $self = shift;

   my $cmd = "sudo vi /etc/pf.conf";

   return $self->execute($cmd);
}

sub reload {
   my $self = shift;

   my $cmd = "sudo pfctl -f /etc/pf.conf";

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Pf - system::freebsd::pf Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
