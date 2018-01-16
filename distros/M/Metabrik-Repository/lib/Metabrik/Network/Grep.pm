#
# $Id: Grep.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# network::grep Brik
#
package Metabrik::Network::Grep;
use strict;
use warnings;

use base qw(Metabrik::Network::Read);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         filter => [ qw(filter) ],
      },
      attributes_default => {
         filter => '',
      },
      commands => {
         from_network => [ qw(string filter|OPTIONAL device|OPTIONAL) ],
         from_pcap_file => [ qw(string pcap_file filter|OPTIONAL) ],
      },
      require_modules => {
         'Net::Frame::Simple' => [ ],
         'Metabrik::File::Pcap' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => defined($self->global) && $self->global->device || 'eth0',
      },
   };
}

sub from_network {
   my $self = shift;
   my ($string, $filter, $device) = @_;

   $device ||= $self->device;
   $filter ||= $self->filter;
   $self->brik_help_run_undef_arg('from_network', $string) or return;
   $self->brik_help_run_undef_arg('from_network', $device) or return;

   $self->open(2, $device, $filter) or return;

   my @match = ();
   while (1) {
      my $h = $self->next or next;
      my $simple = Net::Frame::Simple->newFromDump($h) or next;
      my $layer = $simple->ref->{TCP} || $simple->ref->{UDP};
      if (defined($layer) && length($layer->payload)) {
         my $payload = $layer->payload;
         if ($payload =~ m{$string}) {
            $self->log->info("from_network: payload: [$payload]");
            push @match, $simple;
         }
      }
   }

   return \@match;
}

sub from_pcap_file {
   my $self = shift;
   my ($string, $pcap_file, $filter) = @_;

   $filter ||= $self->filter;
   $self->brik_help_run_undef_arg('from_pcap_file', $string) or return;
   $self->brik_help_run_undef_arg('from_pcap_file', $pcap_file) or return;
   $self->brik_help_run_file_not_found('from_pcap_file', $pcap_file) or return;

   my $fp = Metabrik::File::Pcap->new_from_brik_init($self) or return;
   $fp->open($pcap_file, 'read', $filter) or return;
   my $read = $fp->read or return;
   $fp->close;

   my @match = ();
   for my $h (@$read) {
      my $simple = Net::Frame::Simple->newFromDump($h) or next;
      my $layer = $simple->ref->{TCP} || $simple->ref->{UDP};
      if (defined($layer) && length($layer->payload)) {
         my $payload = $layer->payload;
         if ($payload =~ m{$string}) {
            $self->log->info("from_pcap_file: payload: [$payload]");
            push @match, $simple;
         }
      }
   }

   return \@match;
}

1;

__END__

=head1 NAME

Metabrik::Network::Grep - network::grep Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
