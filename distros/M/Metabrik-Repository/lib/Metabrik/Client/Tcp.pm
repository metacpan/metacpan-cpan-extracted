#
# $Id$
#
# client::tcp Brik
#
package Metabrik::Client::Tcp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable socket netcat) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         host => [ qw(host) ],
         port => [ qw(port) ],
         protocol => [ qw(tcp) ],
         eof => [ qw(0|1) ],
         timeout => [ qw(0|1) ],
         size => [ qw(size) ],
         rtimeout => [ qw(read_timeout) ],
         use_ipv6 => [ qw(0|1) ],
         _socket => [ qw(INTERNAL) ],
      },
      attributes_default => {
         protocol => 'tcp',
         eof => 0,
         timeout => 0,
         size => 1024,
         use_ipv6 => 0,
      },
      commands => {
         connect => [ qw(host|OPTIONAL port|OPTIONAL) ],
         read => [ qw(stdin|OPTIONAL) ],
         read_size => [ qw(size stdin|OPTIONAL) ],
         read_line => [ qw(stdin|OPTIONAL) ],
         write => [ qw($data stdout|OPTIONAL) ],
         loop => [ qw(stdin|OPTIONAL stdout|OPTIONAL stderr|OPTIONAL) ],
         disconnect => [ ],
         is_connected => [ ],
         chomp => [ qw($data) ],
         reset_timeout => [ ],
         reset_eof => [ ],
      },
      require_modules => {
         'IO::Socket::INET' => [ ],
         'IO::Socket::INET6' => [ ],
         'IO::Select' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         rtimeout => defined($self->global) && $self->global->rtimeout || 3,
      },
   };
}

sub connect {
   my $self = shift;
   my ($host, $port) = @_;

   $host ||= $self->host;
   $port ||= $self->port;
   $self->brik_help_run_undef_arg('connect', $host) or return;
   $self->brik_help_run_undef_arg('connect', $port) or return;

   my $mod = $self->use_ipv6 ? 'IO::Socket::INET6' : 'IO::Socket::INET';

   my $socket = $mod->new(
      PeerHost => $host,
      PeerPort => $port,
      Proto => $self->protocol,
      Timeout => $self->rtimeout,
      ReuseAddr => 1,
   );
   if (! defined($socket)) {
      return $self->log->error("connect: failed connecting to target [$host:$port]: $!");
   }
         
   $socket->blocking(1);
   $socket->autoflush(1);

   my $select = IO::Select->new or return $self->log->error("connect: IO::Select failed: $!");
   $select->add($socket);

   $self->_socket($socket);

   $self->log->verbose("connect: successfully connected to [$host:$port]");

   my $conn = {
      ip => $socket->peerhost,
      port => $socket->peerport,
      my_ip => $socket->sockhost,
      my_port => $socket->sockport,
   };

   return $conn;
}

sub disconnect {
   my $self = shift;

   if ($self->_socket) {
      $self->_socket->close;
      $self->_socket(undef);
      $self->log->verbose("disconnect: successfully disconnected");
   }
   else {
      $self->log->verbose("disconnect: nothing to disconnect");
   }

   return 1;
}

sub is_connected {
   my $self = shift;

   if ($self->_socket) {
      return 1;
   }

   return 0;
}

sub write {
   my $self = shift;
   my ($data, $stdout) = @_;

   if (! $self->is_connected) {
      return $self->log->error($self->brik_help_run('connect'));
   }
   $self->brik_help_run_undef_arg('write', $data) or return;

   my $socket = $self->_socket;
   $stdout ||= $socket;

   my $ret = $stdout->syswrite($data, length($data));
   if (! $ret) {
      return $self->log->error("write: syswrite failed with error [$!]");
   }

   return $ret;
}

sub reset_timeout {
   my $self = shift;

   $self->timeout(0);

   return 1;
}

sub reset_eof {
   my $self = shift;

   $self->eof(0);

   return 1;
}

sub read_size {
   my $self = shift;
   my ($size, $stdin) = @_;

   $size ||= $self->size;
   if (! $self->is_connected) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $socket = $self->_socket;
   $stdin ||= $socket;

   my $select = IO::Select->new;
   $select->add($stdin);

   my $read = 0;
   my $eof = 0;
   my $data = '';
   my @ready = ();
   while (@ready = $select->can_read($self->rtimeout)) {
      my $ret = $stdin->sysread($data, $size);
      if (! defined($ret)) {
         return $self->log->error("read_size: sysread failed with error [$!]");
      }
      elsif ($ret == 0) { # EOF
         $self->eof(1);
         $eof++;
         last;
      }
      elsif ($ret > 0) { # Read stuff
         $read++;
         last;
      }
      else {
         return $self->log->fatal("read_size: What?!?");
      }
   }

   if (@ready == 0) {
      $self->timeout(1);
      $self->log->verbose("read_size: timeout occured");
   }

   return $data;
}

sub read_line {
   my $self = shift;
   my ($stdin) = @_;

   if (! $self->is_connected) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $socket = $self->_socket;
   $stdin ||= $socket;

   my $select = IO::Select->new;
   $select->add($stdin);

   my $read = 0;
   my $eof = 0;
   my $data = '';
   my @ready = ();
   while (@ready = $select->can_read($self->rtimeout)) {
      $data = $stdin->getline;
      if (! defined($data)) {
         return $self->log->error("read_line: getline failed with error [$!]");
      }
      last;
   }

   if (@ready == 0) {
      $self->timeout(1);
      $self->log->verbose("read_line: timeout occured");
   }

   return $data;
}

sub read {
   my $self = shift;
   my ($stdin) = @_;

   if (! $self->is_connected) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $socket = $self->_socket;
   $stdin ||= $socket;

   my $select = IO::Select->new;
   $select->add($stdin);

   my $read = 0;
   my $eof = 0;
   my $data = '';
   my $chunk = 500;
   my @ready = ();
   while (@ready = $select->can_read($self->rtimeout)) {
   AGAIN:
      my $buf = '';
      my $ret = $stdin->sysread($buf, $chunk);
      if (! defined($ret)) {
         return $self->log->error("read: sysread failed with error [$!]");
      }
      elsif ($ret == 0) { # EOF
         $self->log->debug("read: eof");
         $self->eof(1);
         $eof++;
         last;
      }
      elsif ($ret > 0) { # Read stuff
         $read++;
         $data .= $buf;
         $self->log->debug("read: stuff len[$ret]");
         if ($ret == $chunk) {
            $self->log->debug("read: AGAIN");
            goto AGAIN;
         }
         last;
      }
      else {
         return $self->log->fatal("read: What?!?");
      }
   }

   if (@ready == 0) {
      $self->timeout(1);
      $self->log->verbose("read: timeout occured");
   }

   return $data;
}

sub loop {
   my $self = shift;
   my ($stdin, $stdout, $stderr) = @_;

   if (! $self->is_connected) {
      return $self->log->error($self->brik_help_run('connect'));
   }

   my $socket = $self->_socket;
   $stdin ||= \*STDIN;
   $stdout ||= $socket;
   $stderr ||= \*STDERR;

   my $select = IO::Select->new;
   $select->add($stdin);  # Client
   $select->add($stdout); # Server

   my @ready = ();
   my $data = '';
   while (@ready = $select->can_read($self->rtimeout)) {
      my $eof = 0;
      for my $std (@ready) {
         if ($std == $stdin) {  # client $stdin has sent stuff we can read
            $data = $self->read_line($stdin);
            $self->write($data, $stdout);
         }
         else { # server $stdout has sent stuff we can read
            $data = $self->read($stdout);
            if ($self->eof) {
               $self->log->verbose("loop: server sent eof");
               $eof++;
               last;
            }
            print $data;
         }
      }
      last if $eof;
   }

   if (@ready == 0) {
      $self->log->verbose("loop: timeout occured");
   }

   return $data;
}

sub chomp {
   my $self = shift;
   my ($data) = @_;

   $data =~ s/\r\n$//;
   $data =~ s/\r$//;
   $data =~ s/\n$//;

   $data =~ s/\r/\\x0d/g;
   $data =~ s/\n/\\x0a/g;

   return $data;
}

1;

__END__

=head1 NAME

Metabrik::Client::Tcp - client::tcp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
