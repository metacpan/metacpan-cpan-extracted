#
# $Id$
#
# remote::tcpdump Brik
#
package Metabrik::Remote::Tcpdump;
use strict;
use warnings;

use base qw(Metabrik::Client::Ssh);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         _started => [ qw(INTERNAL) ],
         _channel => [ qw(INTERNAL) ],
         _out => [ qw(INTERNAL) ],
         _dump => [ qw(INTERNAL) ],
      },
      attributes_default => {
         username => 'root',
         hostname => 'localhost',
         port => 22,
         _started => 0,
         _channel => undef,
      },
      commands => {
         start => [ ],
         status => [ ],
         stop => [ ],
         next => [ ],
         nextall => [ ],
      },
      require_modules => {
         'Net::Frame::Dump::Offline' => [],
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

sub start {
   my $self = shift;

   if ($self->_started) {
      return $self->log->verbose("start: already started");
   }

   $self->connect or return;
   $self->log->verbose("ssh connection successful");

   my $dump = Net::Frame::Dump::Offline->new;
   $self->_dump($dump);

   $self->log->debug("dump file[".$dump->file."]");

   open(my $out, '>', $dump->file)
      or return $self->log->error("cannot open file: $!");
   my $old = select($out);
   $|++;
   select($old);
   $self->_out($out);

   my $device = $self->device;

   my $channel = $self->exec("tcpdump -U -i $device -w - 2> /dev/null") or return;

   $self->log->debug("tcpdump started");

   $self->_started(1);

   return $self->_channel($channel);
}

sub status {
   my $self = shift;

   return $self->_started;
}

sub stop {
   my $self = shift;

   if (! $self->_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   $self->nextall;

   my $r = $self->disconnect;
   $self->_dump->stop;
   unlink($self->_dump->file);
   close($self->_out);

   $self->_started(0);
   $self->_channel(undef);
   $self->_out(undef);
   $self->_dump(undef);

   return $r;
}

sub next {
   my $self = shift;

   if (! $self->_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->error("next: channel not found");
   }

   my $out = $self->_out;
   while (my $line = <$channel>) {
      print $out $line;
   }

   # If reader not already open, we open it
   my $dump = $self->_dump;
   if (! $dump->isRunning) {
      $dump->start or return $self->log->error("unable to start pcap reader");
   }

   if (my $h = $dump->next) {
      return $h;
   }

   return;
}

sub nextall {
   my $self = shift;

   if (! $self->_started) {
      return $self->log->error($self->brik_help_run('start'));
   }

   my $channel = $self->_channel;
   if (! defined($channel)) {
      return $self->log->error("nextall: channel not found");
   }

   my $out = $self->_out;
   while (my $line = <$channel>) {
      print $out $line;
   }

   # If reader not already open, we open it
   my $dump = $self->_dump;
   if (! $dump->isRunning) {
      $dump->start or return $self->log->error("nextall: unable to start pcap reader");
   }

   my @next = ();
   while (my $h = $dump->next) {
      push @next, $h;
   }

   return \@next;
}

1;

__END__

=head1 NAME

Metabrik::Remote::Tcpdump - remote::tcpdump Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
