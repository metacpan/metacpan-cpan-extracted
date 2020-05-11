#
# $Id$
#
# system::linux::cpuinfo Brik
#
package Metabrik::System::Linux::Cpuinfo;
use strict;
use warnings;

use base qw(Metabrik::File::Text);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes_default => {
         as_array => 1,
         strip_crlf => 1,
      },
      commands => {
         read => [ ],
         count_processors => [ ],
      },
   };
}

sub read {
   my $self = shift;

   my $cpuinfo = '/proc/cpuinfo';
   if (! -f $cpuinfo) {
      return $self->log->info("read: cpuinfo file [$cpuinfo] not found");
   }

   my $lines = $self->SUPER::read($cpuinfo) or return;

   my $current = 0;
   my @infos = ();
   for (@$lines) {
      my ($k, $v) = split(/\s*:\s*/, $_);
      if (! defined($v)) { # New line
         $current++;
         next;
      }
      $infos[$current]->{$k} = $v;
   }

   return \@infos;
}

sub count_processors {
   my $self = shift;

   my $infos = $self->read or return;

   my $count = 0;
   for my $this (@$infos) {
      if (exists($this->{processor})) {
         $count++;
      }
   }

   return $count;
}

1;

__END__

=head1 NAME

Metabrik::System::Linux::Cpuinfo - system::linux::cpuinfo Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
