#
# $Id: Ftp.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# network::ftp Brik
#
package Metabrik::Network::Ftp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         hostname => [ qw(hostname) ],
         port => [ qw(port) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         recurse => [ qw(0|1) ],
         _ftp => [ qw(INTERNAL) ],
      },
      attributes_default => {
         port => 21,
         username => 'anonymous',
         password => 'nop@metabrik.org',
         recurse => 0,
      },
      commands => {
         open => [ ],
         cwd => [ qw(directory|OPTIONAL) ],
         pwd => [ ],
         ls => [ qw(directory|OPTIONAL) ],
         dir => [ qw(directory|OPTIONAL) ],
         binary => [ ],
         ascii => [ ],
         rmdir => [ qw(directory) ],
         mkdir => [ qw(directory) ],
         get => [ qw(remote_file local_file) ],
         close => [ ],
      },
      require_modules => {
         'Net::FTP' => [ ],
      },
   };
}

sub open {
   my $self = shift;

   my $hostname = $self->hostname;
   $self->brik_help_run_undef_arg('open', $hostname) or return;

   my $port = $self->port;
   my $username = $self->username;
   my $password = $self->password;

   my $ftp = Net::FTP->new(
      $hostname,
      Port => $port,
      Debug => $self->debug,
   ) or return $self->log->error("open: Net::FTP failed with [$@]");

   $ftp->login($username, $password)
      or return $self->log->error("open: Net::FTP login failed with [".$ftp->message."]");

   return $self->_ftp($ftp);
}

sub cwd {
   my $self = shift;
   my ($directory) = @_;

   $directory ||= '';
   my $ftp = $self->_ftp;
   $self->brik_help_run_undef_arg('open', $ftp) or return;

   my $r = $ftp->cwd($directory);

   return $r;
}

sub pwd {
   my $self = shift;

   my $ftp = $self->_ftp;
   $self->brik_help_run_undef_arg('open', $ftp) or return;

   my $r = $ftp->pwd;

   return $r;
}

sub ls {
   my $self = shift;
   my ($directory) = @_;

   my $ftp = $self->_ftp;
   $self->brik_help_run_undef_arg('open', $ftp) or return;

   $directory ||= $ftp->pwd;

   my $list = $ftp->ls($directory);

   return $list;
}

sub dir {
   my $self = shift;
   my ($directory) = @_;

   my $ftp = $self->_ftp;
   $self->brik_help_run_undef_arg('open', $ftp) or return;

   $directory ||= $ftp->pwd;

   my $list = $ftp->dir($directory);

   return $list;
}

sub rmdir {
   my $self = shift;
   my ($directory) = @_;

   my $ftp = $self->_ftp;
   $self->brik_help_run_undef_arg('open', $ftp) or return;
   $self->brik_help_run_undef_arg('rmdir', $directory) or return;

   my $r = $ftp->rmdir($directory, $self->recurse);

   return $r;
}

sub mkdir {
   my $self = shift;
   my ($directory) = @_;

   my $ftp = $self->_ftp;
   $self->brik_help_run_undef_arg('open', $ftp) or return;
   $self->brik_help_run_undef_arg('mkdir', $directory) or return;

   my $r = $ftp->mkdir($directory, $self->recurse);

   return $r;
}

sub binary {
   my $self = shift;

   my $ftp = $self->_ftp;
   $self->brik_help_run_undef_arg('open', $ftp) or return;

   my $r = $ftp->binary;

   return $r;
}

sub ascii {
   my $self = shift;

   my $ftp = $self->_ftp;
   $self->brik_help_run_undef_arg('open', $ftp) or return;

   my $r = $ftp->ascii;

   return $r;
}

sub get {
   my $self = shift;
   my ($remote, $local) = @_;

   my $ftp = $self->_ftp;
   $self->brik_help_run_undef_arg('open', $ftp) or return;
   $self->brik_help_run_undef_arg('get', $remote) or return;
   $self->brik_help_run_undef_arg('get', $local) or return;

   my $r = $ftp->get($remote, $local);

   return $r;
}

sub close {
   my $self = shift;

   if (defined($self->_ftp)) {
      $self->_ftp->quit;
      $self->_ftp(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Network::Ftp - network::ftp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
