#
# $Id$
#
# file::pcap Brik
#
package Metabrik::File::Pcap;
use strict;
use warnings;

use base qw(Metabrik::Network::Frame);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable frame packet) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(input) ],
         output => [ qw(output) ],
         eof => [ qw(0|1) ],
         count => [ qw(count) ],
         filter => [ qw(filter) ],
         mode => [ qw(read|write) ],
         first_layer => [ qw(layer) ],
         _dump => [ qw(INTERNAL) ],
      },
      attributes_default => {
         eof => 0,
         filter => '',
         mode => 'read',
         first_layer => 'ETH',
      },
      commands => {
         open => [ qw(input mode|OPTIONAL filter|first_layer|OPTIONAL) ],
         close => [ ],
         read => [ ],
         read_next => [ qw(count|OPTIONAL) ],
         is_eof => [ ],
         from_read => [ qw(frame|$frame_list) ],  # Inherited from N:F
         to_read => [ qw(simple|$simple_list) ],  # Inherited from N:F
         write => [ qw(frame|$frame_list) ],
      },
      require_modules => {
         'Net::Frame::Dump::Offline' => [ ],
         'Net::Frame::Dump::Writer' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($file, $mode, $arg3) = @_;

   if ($self->_dump) {
      return $self->log->error("open: already opened");
   }

   $mode ||= $self->mode;
   $self->brik_help_run_undef_arg('open', $mode) or return;

   my $dump;
   if ($mode eq 'read') {
      $file ||= $self->input;
      $self->brik_help_run_undef_arg('open', $file) or return;
      $self->brik_help_run_file_not_found('open', $file) or return;

      my $filter = $arg3 || $self->filter || '';
      $dump = Net::Frame::Dump::Offline->new(
         file => $file,
         filter => $filter,
         keepTimestamp => 1,
      );
      $dump->start or return $self->log->error("open: offline start failed");
   }
   elsif ($mode eq 'write') {
      $file ||= $self->output;
      $self->brik_help_run_undef_arg('open', $file) or return;

      my $first_layer = $arg3 || $self->first_layer || 'ETH';
      $dump = Net::Frame::Dump::Writer->new(
         file => $file,
         firstLayer => $first_layer,
      );

      $dump->start or return $self->log->error("open: writer start failed");
   }
   else {
      return $self->log->error("open: mode must be either read or write");
   }

   return $self->_dump($dump);
}

sub close {
   my $self = shift;

   my $dump = $self->_dump;
   if (defined($dump)) {
      $dump->stop;
      $self->eof(0);
      $self->_dump(undef);
   }

   return 1;
}

# Will read everything until the end-of-file
sub read {
   my $self = shift;

   if ($self->is_eof) {
      return $self->log->error("read: end-of-file already reached");
   }

   my $dump = $self->_dump;
   $self->brik_help_run_undef_arg('open', $dump) or return;

   my @h = ();
   while (my $h = $dump->next) {
      push @h, $h;
   }

   $self->eof(1);

   return \@h;
}

sub read_next {
   my $self = shift;
   my ($count) = @_;

   $count ||= 1;
   my $dump = $self->_dump;
   $self->brik_help_run_undef_arg('open', $dump) or return;

   my @next = ();
   my $read_count = 0;
   while (my $h = $dump->next) {
      push @next, $h;
      last if ++$read_count == $count;
   }

   return \@next;
}

sub is_eof {
   my $self = shift;

   return $self->eof;
}

sub write {
   my $self = shift;
   my ($frames) = @_;

   my $dump = $self->_dump;
   $self->brik_help_run_undef_arg('open', $dump) or return;
   $self->brik_help_run_undef_arg('write', $frames) or return;
   my $ref = $self->brik_help_run_invalid_arg('write', $frames, 'ARRAY', 'HASH')
      or return;

   my $first = $ref eq 'ARRAY' ? $frames->[0] : $frames;
   if ($ref eq 'ARRAY') {
      if (@$frames <= 0) {
         return $self->log->error("write: frames ARRAYREF is empty");
      }
      if (! exists($first->{raw})
      ||  ! exists($first->{timestamp})
      ||  ! exists($first->{firstLayer})) {
         return $self->log->error("write: frames ARRAYREF does not contain a valid frame");
      }
   }
   else { # Must be HASH because of previous checks
      if (! exists($first->{raw})
      ||  ! exists($first->{timestamp})
      ||  ! exists($first->{firstLayer})) {
         return $self->log->error("write: frames HASHREF does not contain a valid frame");
      }
   }

   if ($ref eq 'ARRAY') {
      for my $simple (@$frames) {
         $dump->write($simple);
      }
   }
   else {
      $dump->write($frames);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::File::Pcap - file::pcap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
