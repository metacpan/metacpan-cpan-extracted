#
# $Id$
#
# network::ping Brik
#
package Metabrik::Network::Ping;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         try => [ qw(count) ],
         timeout => [ qw(seconds) ],
      },
      attributes_default => {
         try => 2,
         timeout => 5,
         ignore_error => 0,  # We need return code from ping command
      },
      commands => {
         install => [ ],  # Inherited
         is_alive => [ qw(host try|OPTIONAL timeout|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::System::Os' => [ ],
         'Metabrik::Network::Linux::Ping' => [ ],
         'Metabrik::Network::Freebsd::Ping' => [ ],
      },
      require_binaries => {
         ping => [ ],
      },
      need_packages => {
         ubuntu => [ qw(iputils-ping) ],
         debian => [ qw(iputils-ping) ],
         kali => [ qw(iputils-ping) ],
      },
   };
}

#
# Sends ICMP echo-requests $try number of times or until $timeout seconds occurs.
#
sub is_alive {
   my $self = shift;
   my ($host, $try, $timeout) = @_;

   $try ||= $self->try;
   $timeout ||= $self->timeout;
   $self->brik_help_run_undef_arg('is_alive', $host) or return;

   my $np;
   my $os = Metabrik::System::Os->new_from_brik_init($self) or return;
   if ($os->is_linux) {
      $np = Metabrik::Network::Linux::Ping->new_from_brik_init($self) or return;
   }
   elsif ($os->is_freebsd) {
      $np = Metabrik::Network::Freebsd::Ping->new_from_brik_init($self) or return;
   }
   else {
      return $self->log->error("is_alive: OS unsupported");
   }

   return $np->is_alive($host, $try, $timeout);
}

1;

__END__

=head1 NAME

Metabrik::Network::Ping - network::ping Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
