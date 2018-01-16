#
# $Id: Smbclient.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# client::smbclient Brik
#
package Metabrik::Client::Smbclient;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
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
         download => [ qw(file|file_list output_dir|OPTIONAL remote_path|OPTIONAL) ],
         download_in_background => [ qw(file|file_list output_dir|OPTIONAL remote_path|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::System::Process' => [ ],
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
      my ($this_file) = $files =~ m{^(?:.*/)?(.*)$};
      my $cmd = "smbclient -U $domain/$username%$password //$host/$share -c ".
         "'put \"$files\" $remote_path\\$this_file'";

      (my $cmd_hidden = $cmd) =~ s{$password}{XXX};
      $self->log->verbose("upload: cmd[$cmd_hidden]");

      my $level = $self->log->level;
      $self->log->level(0);
      $self->system($cmd) or return;
      $self->log->level($level);

      return "$remote_path\\$this_file";
   }

   return $self->log->error("upload: unhandled exception");
}

#
# run client::smbclient download c:\\windows\temp\file.txt /tmp/
#
sub download {
   my $self = shift;
   my ($files, $output_dir, $share) = @_;

   $output_dir ||= defined($self->shell) && $self->shell->full_pwd || '/tmp';
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
         my $this = $self->download($file, $output_dir, $share) or next;
         push @files, $this;
      }

      return \@files;
   }
   else {
      # Convert path to \\ and remove potentiel initial drive letter
      $files =~ s{/}{\\}g;
      my ($drive) = $files =~ m{^([a-zA-Z]):};
      my ($output_file) = $files =~ m{\\([^\\]+)$};
      $files =~ s{^[a-zA-Z]:}{};
      $drive ? ($drive .= '$') : ($drive = $share);
      $output_file ||= '';

      my $output = $output_dir ? "$output_dir/$output_file" : $output_file;

      my $cmd = "smbclient -U $domain/$username%$password //$host/$drive -c ".
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

sub download_in_background {
   my $self = shift;
   my ($files, $output_dir, $share) = @_;

   $output_dir ||= defined($self->shell) && $self->shell->full_pwd || '/tmp';
   $share ||= $self->share;
   $self->brik_help_run_undef_arg('download_in_background', $files) or return;
   my $ref = $self->brik_help_run_invalid_arg('download_in_background', $files,
      'ARRAY', 'SCALAR') or return;

   my $domain = $self->domain;
   my $username = $self->user;
   my $password = $self->password;
   my $host = $self->host;
   $self->brik_help_set_undef_arg('download_in_background', $domain) or return;
   $self->brik_help_set_undef_arg('download_in_background', $username) or return;
   $self->brik_help_set_undef_arg('download_in_background', $password) or return;
   $self->brik_help_set_undef_arg('download_in_background', $host) or return;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   $sp->close_output_on_start(1);

   # Convert SCALAR to ARRAY
   if (ref($files) eq '') {
      $files = [ $files ];
   }

   for my $this ($files) {
      $sp->start(sub {
         $self->download($this, $output_dir, $share);
      });
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Smbclient - client::smbclient Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
