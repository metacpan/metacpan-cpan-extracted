#
# $Id: Smbclient.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# client::smbclient Brik
#
package Metabrik::Client::Smbclient;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         domain => [ qw(domain) ],
         user => [ qw(username) ],
         password => [ qw(password) ],
         host => [ qw(host) ],
         share => [ qw(path) ],
         remote_path => [ qw(path) ],
      },
      attributes_default => {
         domain => 'WORKGROUP',
         user => 'Administrator',
         host => '127.0.0.1',
         share => 'c$',
         remote_path => '\\windows\\temp',
      },
      commands => {
         install => [ ],  # Inherited
         upload => [ qw(file|file_list remote_path|OPTIONAL) ],
         download => [ qw(file|file_list remote_path|OPTIONAL) ],
      },
      require_modules => {
      },
      require_binaries => {
         smbclient => [ ],
      },
      need_packages => {
         ubuntu => [ qw(smbclient) ],
         debian => [ qw(smbclient) ],
      },
   };
}

#
# More good stuff here: https://github.com/jrmdev/smbwrapper
#

#
# run client::smbclient upload $file \\windows\temp\ c$
#
sub upload {
   my $self = shift;
   my ($files, $remote_path, $share) = @_;

   $remote_path ||= $self->remote_path;
   $share ||= $self->share;
   $self->brik_help_run_undef_arg('upload', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('upload', $files, 'ARRAY', 'SCALAR')
      or return;

   my $domain = $self->domain;
   my $username = $self->user;
   my $password = $self->password;
   my $host = $self->host;
   $self->brik_help_set_undef_arg('upload', $domain) or return;
   $self->brik_help_set_undef_arg('upload', $username) or return;
   $self->brik_help_set_undef_arg('upload', $password) or return;
   $self->brik_help_set_undef_arg('upload', $host) or return;

   if ($ref eq 'ARRAY') {
      my @files = ();
      for my $file (@$files) {
         my $this = $self->upload($file, $remote_path, $share) or next;
         push @files, $this;
      }

      return \@files;
   }
   else {
      my $cmd = "smbclient -U $domain/$username%$password //$host/$share -c ".
         "'put \"$files\" $remote_path\\$files'";

      (my $cmd_hidden = $cmd) =~ s{$password}{XXX};
      $self->log->verbose("upload: cmd[$cmd_hidden]");

      my $level = $self->log->level;
      $self->log->level(0);
      $self->system($cmd) or return;
      $self->log->level($level);

      return "$remote_path\\$files";
   }

   return $self->log->error("upload: unhandled exception");
}

#
# run client::smbclient download \\windows\temp\file.txt c$
#
sub download {
   my $self = shift;
   my ($files, $share) = @_;

   $share ||= $self->share;
   $self->brik_help_run_undef_arg('download', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('download', $files, 'ARRAY', 'SCALAR')
      or return;

   my $domain = $self->domain;
   my $username = $self->user;
   my $password = $self->password;
   my $host = $self->host;
   $self->brik_help_set_undef_arg('download', $domain) or return;
   $self->brik_help_set_undef_arg('download', $username) or return;
   $self->brik_help_set_undef_arg('download', $password) or return;
   $self->brik_help_set_undef_arg('download', $host) or return;

   if ($ref eq 'ARRAY') {
      my @files = ();
      for my $file (@$files) {
         my $this = $self->download($file, $share) or next;
         push @files, $this;
      }

      return \@files;
   }
   else {
      my ($output) = $files =~ m{\\([^\\]+)$};
      my $cmd = "smbclient -U $domain/$username%$password //$host/$share -c ".
         "'get $files $output'";

      (my $cmd_hidden = $cmd) =~ s{$password}{XXX};
      $self->log->verbose("download: cmd[$cmd_hidden]");

      my $level = $self->log->level;
      $self->log->level(0);
      $self->system($cmd) or return;
      $self->log->level($level);

      return $output;
   }

   return $self->log->error("download: unhandled exception");
}

1;

__END__

=head1 NAME

Metabrik::Client::Smbclient - client::smbclient Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
