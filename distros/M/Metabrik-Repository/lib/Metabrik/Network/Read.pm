#
# $Id: Read.pm,v 50c217684c90 2018/07/17 12:37:05 gomor $
#
# network::read Brik
#
package Metabrik::Network::Read;
use strict;
use warnings;

use base qw(Metabrik::Network::Frame);

sub brik_properties {
   return {
      revision => '$Revision: 50c217684c90 $',
      tags => [ qw(unstable ethernet ip raw socket) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         rtimeout => [ qw(seconds) ],
         family => [ qw(ipv4|ipv6) ],
         protocol => [ qw(tcp|udp) ],
         layer => [ qw(2|3|4) ],
         filter => [ qw(pcap_filter) ],
         count => [ qw(count) ],
         _dump => [ qw(INTERNAL) ],
      },
      attributes_default => {
         layer => 2,
         count => 0,
         family => 'ipv4',
         protocol => 'tcp',
         rtimeout => 5,
         filter => '',
      },
      commands => {
         open => [ qw(layer|OPTIONAL device|OPTIONAL filter|OPTIONAL) ],
         read => [ ],
         read_next => [ qw(count) ],
         read_until_timeout => [ qw(count timeout|OPTIONAL) ],
         close => [ ],
         has_timeout => [ ],
         reset_timeout => [ ],
         reply => [ qw(frame) ],
         to_simple => [ qw(frame|$frame_list) ],
      },
      require_modules => {
         'Net::Frame::Dump' => [ ],
         'Net::Frame::Dump::Online2' => [ ],
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

sub open {
   my $self = shift;
   my ($layer, $device, $filter) = @_;

   $self->brik_help_run_must_be_root('open') or return;

   $layer ||= 2;
   $device ||= $self->device;
   $filter ||= $self->filter;

   my $family = $self->family eq 'ipv6' ? 'ip6' : 'ip';

   my $protocol = defined($self->protocol) ? $self->protocol : 'tcp';

   my $dump;
   if ($layer == 2) {
      $self->log->debug("open: timeoutOnNext: ".$self->rtimeout);
      $self->log->debug("open: filter: ".$filter);

      $dump = Net::Frame::Dump::Online2->new(
         dev => $device,
         timeoutOnNext => $self->rtimeout,
         filter => $filter,
      ) or return $self->log->error("open: Net::Frame::Dump::Online2->new failed");
   }
   elsif ($self->layer != 3) {
      return $self->log->error("open: not implemented");
   }

   $dump->start or return $self->log->error("open: Net::Frame::Dump::Online2->start failed");

   return $self->_dump($dump);
}

sub read {
   my $self = shift;

   my $dump = $self->_dump;
   $self->brik_help_run_undef_arg('open', $dump) or return;

   my @next = ();
   my $count = 0;
   while (my $next = $dump->next) {
      $self->log->verbose("read: read ".++$count." packet(s)");
      if (ref($next) eq 'ARRAY') {
         push @next, @$next;
      }
      else {
         push @next, $next;
      }
   }

   return \@next;
}

sub read_next {
   my $self = shift;
   my ($count) = @_;

   $count ||= $self->count;
   my $dump = $self->_dump;
   $self->brik_help_run_undef_arg('open', $dump) or return;

   my @next = ();
   my $read_count = 0;
   while (1) {
      my $next = $dump->next;
      if (defined($next)) {
         $read_count++;
         push @next, $next;
         $self->log->debug("read_next: read $read_count packet(s)");
         last if $read_count >= $count;
      }
   }

   return \@next;
}

sub read_until_timeout {
   my $self = shift;
   my ($count, $rtimeout) = @_;

   $count ||= $self->count;
   $rtimeout ||= $self->rtimeout;
   my $dump = $self->_dump;
   $self->brik_help_run_undef_arg('open', $dump) or return;

   my $prev = $dump->timeoutOnNext;
   $dump->timeoutOnNext($rtimeout);

   $self->log->debug("next_until_timeout: will read until [$rtimeout] ".
      "seconds or [$count] packet(s) have been read");

   my $read_count = 0;
   my @next = ();
   while (! $dump->timeout) {
      if ($count && $read_count >= $count) {
         last;
      }
 
      if (my $next = $dump->next) {
         push @next, $next;
         $read_count++;
      }
   }

   if ($self->log->level > 2) {
      if ($dump->timeout) {
         $self->log->debug("next_until_timeout: timeout reached after [$rtimeout]");
      }
      else {
         $self->log->debug("next_until_timeout: packet count reached after [$read_count]");
      }
   }

   $dump->timeoutOnNext($prev);

   return \@next;
}

sub reply {
   my $self = shift;
   my ($frame) = @_;

   my $dump = $self->_dump;
   $self->brik_help_run_undef_arg('open', $dump) or return;
   $self->brik_help_run_undef_arg('reply', $frame) or return;
   $self->brik_help_run_invalid_arg('reply', $frame, 'Net::Frame::Simple') or return;

   return $dump->getFramesFor($frame);
}

sub has_timeout {
   my $self = shift;

   my $dump = $self->_dump;
   # We do not check for openness, simply returns 0 is ok to say we don't have a timeout now.
   if (! defined($dump)) {
      $self->log->debug("has_timeout: here: has_timeout [0]");
      return 0;
   }

   my $has_timeout = $dump->timeout;
   $self->log->debug("has_timeout: has_timeout [$has_timeout]");

   return $has_timeout;
}

sub reset_timeout {
   my $self = shift;

   my $dump = $self->_dump;
   # We do not check for openness, simply returns 1 is ok to say no need for timeout reset.
   if (! defined($dump)) {
      return 1;
   }

   return $dump->timeoutReset;
}

sub close {
   my $self = shift;

   my $dump = $self->_dump;
   if (! defined($dump)) {
      return 1;
   }

   # Free saved frames.
   $self->log->debug("close: flush frames");
   $dump->flush;

   $self->log->debug("close: closing dump...");
   $dump->stop;
   $self->_dump(undef);
   $self->log->debug("close: closing dump...done");

   return 1;
}

sub to_simple {
   my $self = shift;
   my ($frames) = @_;

   $self->brik_help_run_undef_arg('to_simple', $frames) or return;
   my $ref = $self->brik_help_run_invalid_arg('to_simple', $frames, 'ARRAY', 'SCALAR')
      or return;
   if ($ref eq 'ARRAY') {
      $self->brik_help_run_empty_array_arg('to_simple', $frames) or return;
   }

   return $self->from_read($frames);
}

1;

__END__

=head1 NAME

Metabrik::Network::Read - network::read Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
