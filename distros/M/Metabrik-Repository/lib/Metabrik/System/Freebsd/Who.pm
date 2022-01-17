#
# $Id$
#
# system::freebsd:who Brik
#
package Metabrik::System::Freebsd::Who;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         get => [ ],
      },
      require_binaries => {
         who => [ ],
      },
   };
}

sub get {
   my $self = shift;

   my $cmd = 'who -H';

   #
   # FreeBSD 10.2-RELEASE
   #
   # 0: NAME             LINE         TIME         FROM
   # 1: <user>           pts/3        Oct 29 10:36 (<ip>)

   my $lines = $self->capture($cmd) or return;

   my $info = {
      raw => $lines,
   };
   my $first = 1;
   for my $line (@$lines) {
      if ($first) {
         $first = 0;
         next;
      }

      $line =~ s{^\s*}{};
      $line =~ s{\s*$}{};

      my @t = $line =~ m{^(\S+)\s+(\S+)\s+(\d+ \S+ \S+)\s+\((\S+)\)$};

      my $user = $t[0];
      my $where = $t[1];
      my $time = $t[2];
      my $from = $t[3];

      $where =~ s{/}{_}g;

      $info->{$where} = {
         user => $user,
         connection_time => $time,
         from => $from,
      };
   }

   return $info;
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Who - system::freebsd::who Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
