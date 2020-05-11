#
# $Id$
#
# network::freebsd::ping Brik
#
package Metabrik::Network::Freebsd::Ping;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

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
         is_alive => [ qw(host try|OPTIONAL timeout|OPTIONAL) ],
      },
      require_binaries => {
         ping => [ ],  # ping is a standard userlang command in FreeBSD
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

   my $cmd = "ping -c $try -t $timeout $host > /dev/null 2>&1";

   my $r = $self->system($cmd) or return;
   if ($r == 1) {
      return 1;  # Host is alive
   }

   return 0;  # Host not alive
}

1;

__END__

=head1 NAME

Metabrik::Network::Freebsd::Ping - network::freebsd::ping Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
