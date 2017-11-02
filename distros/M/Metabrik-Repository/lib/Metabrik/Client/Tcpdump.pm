#
# $Id: Tcpdump.pm,v a483f00cce99 2017/03/20 16:50:45 gomor $
#
# client::tcpdump Brik
#
package Metabrik::Client::Tcpdump;
use strict;
use warnings;

use base qw(Metabrik::Network::Read);

sub brik_properties {
   return {
      revision => '$Revision: a483f00cce99 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         output => [ qw(output) ],
         device => [ qw(device) ], # Inherited
         layer => [ qw(2|3|4) ], # Inherited
         filter => [ qw(pcap_filter) ], # Inherited
         count => [ qw(count) ], # Inherited
         _sp => [ qw(INTERNAL) ],
         _pidfile => [ qw(INTERNAL) ],
      },
      commands => {
         capture => [ qw(output layer|OPTIONAL device|OPTIONAL filter|OPTIONAL count|OPTIONAL) ],
         capture_in_background => [ qw(output layer|OPTIONAL device|OPTIONAL filter|OPTIONAL count|OPTIONAL) ],
         stop => [ ],
      },
      require_modules => {
         'Metabrik::File::Pcap' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::System::Process' => [ ],
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
      if (my $next = $self->read or next) {
         if (@$next > 0) {
            $read_count += @$next;
            $fp->write($next);
         }
      }
      $self->log->debug("capture: read returned");

      # We need to reset the timeout, otherwise read() will 
      # always return immediately after each call, causing a full CPU 
      # to become busy. Yes, read() is blocking until a timeout occurs.
      if ($self->has_timeout) {
         $self->reset_timeout;
      }

      last if $count && $read_count >= $count;
   }

   $self->close;

   $fp->close;

   return $read_count;
}

sub capture_in_background {
   my $self = shift;
   my ($output, $layer, $device, $filter, $count) = @_;

   $layer ||= $self->layer;
   $device ||= $self->device;
   $filter ||= $self->filter;
   $count ||= $self->count;
   $self->brik_help_run_undef_arg('capture_in_background', $output) or return;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;

   my $datadir = $self->datadir;
   if ($sf->is_relative($output)) {
      my $basefile = $sf->basefile($output) or return;
      $output = $datadir.'/'.$basefile;
   }

   $self->log->info("capture_in_background: writing to output [$output]");

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   $sp->close_output_on_start(0);

   my $pidfile = $sp->start_with_pidfile(sub {
      $self->capture($output, $layer, $device, $filter, $count)
   });

   $self->_sp($sp);
   $self->_pidfile($pidfile);

   return $pidfile;
}

sub stop {
   my $self = shift;

   my $sp = $self->_sp;
   my $pidfile = $self->_pidfile;

   if (defined($sp)) {
      $sp->kill_from_pidfile($pidfile);
      $self->_sp(undef);
      $self->_pidfile(undef);
   }

   return 1;
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
