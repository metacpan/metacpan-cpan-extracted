#
# $Id: Tcpdump.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# client::tcpdump Brik
#
package Metabrik::Client::Tcpdump;
use strict;
use warnings;

use base qw(Metabrik::Network::Read);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         output => [ qw(output) ],
      },
      commands => {
         capture => [ qw(output layer|OPTIONAL device|OPTIONAL filter|OPTIONAL count|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Pcap' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => $self->global->device,
      },
   };
}

sub capture {
   my $self = shift;
   my ($output, $layer, $device, $filter, $count) = @_;

   $layer ||= $self->layer;
   $device ||= $self->device;
   $filter ||= $self->filter;
   $count ||= $self->count;
   $self->brik_help_run_undef_arg('capture', $output) or return;

   my $fp = Metabrik::File::Pcap->new_from_brik_init($self) or return;
   $fp->open($output, 'write') or return;

   $self->open($layer, $device, $filter) or return;

   my $read_count = 0;
   while (1) {
      my $next = $self->read or next;
      if (@$next > 0) {
         $read_count += @$next;
         $fp->write($next);
      }
      last if $count && $read_count >= $count;
   }

   $self->close;

   $fp->close;

   return $read_count;
}

1;

__END__

=head1 NAME

Metabrik::Client::Tcpdump - client::tcpdump Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
