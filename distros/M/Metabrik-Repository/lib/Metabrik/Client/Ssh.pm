#
# $Id: Ssh.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# client::ssh Brik
#
package Metabrik::Client::Ssh;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         hostname => [ qw(hostname) ],
         port => [ qw(integer) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         publickey => [ qw(file) ],
         privatekey => [ qw(file) ],
         ssh2 => [ qw(Net::SSH2) ],
         use_publickey => [ qw(0|1) ],
         _channel => [ qw(INTERNAL) ],
      },
      attributes_default => {
         username => 'root',
         port => 22,
         use_publickey => 1,
      },
      commands => {
         install => [ ], # Inherited
         connect => [ qw(hostname|OPTIONAL port|OPTIONAL username|OPTIONAL) ],
         execute => [ qw(command) ],
         read => [ qw(channel|OPTIONAL) ],
         read_line => [ qw(channel|OPTIONAL) ],
         read_line_all => [ qw(channel|OPTIONAL) ],
         load => [ qw(file) ],
         disconnect => [ ],
         create_channel => [ ],
         close_channel => [ ],
         execute_in_background => [ qw(command stdout_file|OPTIONAL stderr_file|OPTIONAL stdin_file|OPTIONAL) ],
         capture => [ qw(command) ],
      },
      require_modules => {
         'IO::Scalar' => [ ],
         'Net::SSH2' => [ ],
         'Metabrik::String::Password' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libssh2-1-dev) ],
         debian => [ qw(libssh2-1-dev) ],
      },
   };
}

#
# With help from http://www.perlmonks.org/?node_id=569657
#

sub connect {
   my $self = shift;
   my ($hostname, $port, $username, $password) = @_;

   if (defined($self->ssh2)) {
      return $self->log->verbose("connect: already connected");
   }

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $username ||= $self->username;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('connect', $hostname) or return;
   $self->brik_help_run_undef_arg('connect', $port) or return;
   $self->brik_help_run_undef_arg('connect', $username) or return;

   my $publickey = $self->publickey;
   my $privatekey = $self->privatekey;
   if ($self->use_publickey && ! $publickey) {
      return $self->log->error($self->brik_help_set('publickey'));
   }
   if ($self->use_publickey && ! $privatekey) {
      return $self->log->error($self->brik_help_set('privatekey'));
   }

   my $ssh2 = Net::SSH2->new;
   if (! defined($ssh2)) {
      return $self->log->error("connect: cannot create Net::SSH2 object");
   }

   my $ret = $ssh2->connect($hostname, $port);
   if (! $ret) {
      return $self->log->error("connect: can't connect via SSH2: $!");
   }

   if ($self->use_publickey) {
      $ret = $ssh2->auth(
         username => $username,
         publickey => $publickey,
         privatekey => $privatekey,
      );
      if (! $ret) {
         return $self->log->error("connect: authentication failed with publickey: $!");
      }
   }
   else {
      # Prompt for password if not given
      if (! defined($password)) {
         my $sp = Metabrik::String::Password->new_from_brik_init($self) or return;
         $password = $sp->prompt;
      }

      $ret = $ssh2->auth_password($username, $password);
      if (! $ret) {
         return $self->log->error("connect: authentication failed with password: $!");
      }
   }

   $self->log->verbose("connect: ssh2 connected to [$hostname]:$port");

   return $self->ssh2($ssh2);
}

sub disconnect {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   if (! defined($ssh2)) {
      return $self->log->verbose("disconnect: not connected");
   }

   my $r = $ssh2->disconnect;

   $self->ssh2(undef);
   $self->close_channel;

   return $r;
}

sub execute {
   my $self = shift;
   my ($cmd) = @_;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;
   $self->brik_help_run_undef_arg('execute', $cmd) or return;

   $self->debug && $self->log->debug("execute: cmd [$cmd]");

   my $channel = $self->create_channel or return;

   $channel->process('exec', $cmd)
      or return $self->log->error("execute: can't execute command [$cmd]: $!");

   return $self->_channel($channel);
}

sub create_channel {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;

   my $channel = $ssh2->channel;
   if (! defined($channel)) {
      return $self->log->error("create_channel: creation failed: [$!]");
   }

   return $self->_channel($channel);
}

sub close_channel {
   my $self = shift;

   my $channel = $self->_channel;
   if (defined($channel)) {
      $channel->close;
      $self->_channel(undef);
   }

   return 1;
}

sub execute_in_background {
   my $self = shift;
   my ($cmd, $stdout_file, $stderr_file, $stdin_file) = @_;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;
   $self->brik_help_run_undef_arg('execute_in_background', $cmd) or return;

   $stdout_file ||= '/dev/null';
   $stderr_file ||= '/dev/null';

   my $channel = $self->create_channel or return;

   $cmd .= " > $stdout_file 2> $stderr_file";
   if (defined($stdin_file)) {
      $cmd .= " < $stdin_file";
   }
   $cmd .= " &";

   $self->debug && $self->log->debug("execute_in_background: cmd [$cmd]");

   $channel->process('exec', $cmd)
      or return $self->log->error("execute_in_background: process failed: [$!]");
   $channel->send_eof
      or return $self->log->error("execute_in_background: send_eof failed: [$!]");

   $self->close_channel or return;

   return 1;
}

sub read_line {
   my $self = shift;
   my ($channel) = @_;

   $channel ||= $self->_channel;
   $self->brik_help_run_undef_arg('create_channel', $channel) or return;

   my $read = '';
   my $count = 1;
   while (1) {
      my $char = '';
      my $rc = $channel->read($char, $count);
      if (! defined($rc)) {
         return $self->log->error("read_line: read failed: [$!]");
      }
      if ($rc > 0) {
         #print "read[$char]\n";
         #print "returned[$c]\n";
         $read .= $char;

         last if $char eq "\n";
      }
      elsif ($rc < 0) {
         return $self->log->error("read_line: error [$rc]");
      }
      else {
         last;
      }
   }

   return $read;
}

sub read_line_all {
   my $self = shift;
   my ($channel) = @_;

   $channel ||= $self->_channel;
   $self->brik_help_run_undef_arg('create_channel', $channel) or return;

   my $read = $self->read($channel) or return;

   my @lines = split(/\n/, $read);

   $self->close_channel;

   return \@lines;
}

sub read {
   my $self = shift;
   my ($channel) = @_;

   $channel ||= $self->_channel;
   $self->brik_help_run_undef_arg('create_channel', $channel) or return;

   $self->log->verbose("read: channel[$channel]");

   my $read = '';
   my $count = 1024;
   while (1) {
      my $buf = '';
      my $rc = $channel->read($buf, $count);
      if (! defined($rc)) {
         return $self->log->error("read: read failed: [$!]");
      }
      if ($rc > 0) {
         #print "read[$buf]\n";
         #print "returned[$c]\n";
         $read .= $buf;

         last if $rc < $count;
      }
      elsif ($rc < 0) {
         return $self->log->error("read: error [$rc]");
      }
      else {
         last;
      }
   }

   $self->close_channel;

   return $read;
}

sub load {
   my $self = shift;
   my ($file) = @_;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;
   $self->brik_help_run_undef_arg('load', $file) or return;

   my $io = IO::Scalar->new;

   $ssh2->scp_get($file, $io)
      or return $self->log->error("load: scp_get: $file");

   $io->seek(0, 0);

   my $buf = '';
   while (<$io>) {
      $buf .= $_;
   }

   return $buf;
}

sub capture {
   my $self = shift;
   my ($cmd) = @_;

   my $ssh2 = $self->ssh2;
   $self->brik_help_run_undef_arg('connect', $ssh2) or return;
   $self->brik_help_run_undef_arg('capture', $cmd) or return;

   my $channel = $self->create_channel or return;

   $self->debug && $self->log->debug("capture: cmd [$cmd]");

   $channel->process('exec', $cmd)
      or return $self->log->error("capture: process failed: [$!]");

   my $lines = $self->read_line_all or return;
   $self->close_channel;

   return $lines;
}

sub brik_fini {
   my $self = shift;

   my $ssh2 = $self->ssh2;
   if (defined($ssh2)) {
      $ssh2->disconnect;
      $self->ssh2(undef);
      $self->_channel(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Ssh - client::ssh Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
