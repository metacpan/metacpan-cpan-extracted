#
# $Id$
#
# remote::sysmon Brik
#
package Metabrik::Remote::Sysmon;
use strict;
use warnings;

use base qw(Metabrik::Remote::Winexe Metabrik::Client::Smbclient);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         host => [ qw(host) ],   # Inherited
         user => [ qw(username) ],   # Inherited
         password => [ qw(password) ],   # Inherited
         remote_path => [ qw(path) ],   # Inherited
         domain => [ qw(domain) ],   # Inherited
         sysmon_exe => [ qw(version) ],
         conf_file => [ qw(file) ],
      },
      attributes_default => {
         sysmon_exe => 'Sysmon64.exe',
         conf_file => 'sysmon.xml',
      },
      commands => {
         update => [ ],
         get_sysmon_exe => [ ],
         deploy => [ qw(host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         undeploy => [ ],
         redeploy => [ ],
         generate_conf => [ ],
         update_conf => [ ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Compress' => [ ],
         'Metabrik::File::Text' => [ ],
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->user_agent("Metabrik-Remote-Sysmon-mirror/1.00");
   $cw->datadir($datadir);

   my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
   $fc->datadir($datadir);

   my $input = 'Sysmon.zip';
   my $files = $cw->mirror('https://download.sysinternals.com/files/'.$input);
   if (! defined($files)) {
      return $self->log->errpr("update: mirror fail");
   }

   my @updated = ();
   for my $this (@$files) {
      my $this_files = $fc->unzip($this, $datadir) or return;
      push @updated, @$this_files;
   }

   return \@updated;
}

sub get_sysmon_exe {
   my $self = shift;

   my $datadir = $self->datadir;
   my $sysmon_exe = $self->sysmon_exe;
   my $full_path = "$datadir/$sysmon_exe";

   if (-f $full_path) {
      return $full_path;
   }

   return $self->log->error("get_sysmon_exe: file not found, call update Command");
}

sub generate_conf {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file;
   $self->brik_help_set_undef_arg('generate_conf', $conf_file) or return;

   my $datadir = $self->datadir;
   $conf_file = "$datadir/$conf_file";

   my $conf =<<EOF
<Sysmon schemaversion="3.30">
   <HashAlgorithms>SHA1</HashAlgorithms>
   <!-- Log everything -->
   <EventFiltering>
      <ProcessCreate onmatch="exclude" /> <!-- event_id:1 -->
      <FileCreateTime onmatch="exclude" /> <!-- event_id:2 -->
      <NetworkConnect onmatch="exclude" /> <!-- event_id:3 -->
      <!--SYSMON EVENT ID 4 : RESERVED FOR SYSMON STATUS MESSAGES, THIS LINE IS INCLUDED FOR DOCUMENTATION PURPOSES ONLY -->
      <ProcessTerminate onmatch="exclude" /> <!-- event_id:5 -->
      <DriverLoad onmatch="exclude" /> <!-- event_id:6 -->
      <ImageLoad onmatch="exclude" /> <!-- event_id:7 -->
      <CreateRemoteThread onmatch="exclude" /> <!-- event_id:8 -->
      <RawAccessRead onmatch="exclude" /> <!-- event_id:9 -->
      <ProcessAccess onmatch="exclude" /> <!-- event_id:10 -->
      <FileCreate onmatch="exclude" /> <!-- event_id:11 -->
      <RegistryEvent onmatch="exclude" /> <!-- event_id:12,13,14 -->
      <FileCreateStreamHash onmatch="exclude" /> <!-- event_id:15 -->
      <!--SYSMON EVENT ID 16 : SYSMON CONFIGURATION CHANGE, THIS LINE IS INCLUDED FOR DOCUMENTATION PURPOSES ONLY [ SYSMON 6.00+ ] -->
      <!--SYSMON EVENT ID 17 : PIPE CREATED [ SYSMON 6.00+ ] -->
      <!--SYSMON EVENT ID 18 : PIPE CONNECTED [ SYSMON 6.00+ ] -->
   </EventFiltering>
</Sysmon>
EOF
;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);

   $ft->write($conf, $conf_file) or return;

   return $conf_file;
}

sub deploy {
   my $self = shift;
   my ($host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_set_undef_arg('host', $host) or return;
   $self->brik_help_set_undef_arg('user', $user) or return;
   $self->brik_help_set_undef_arg('password', $password) or return;

   my $sysmon_exe = $self->sysmon_exe;
   my $remote_path = $self->remote_path;

   my $full_path = $self->get_sysmon_exe or return;

   $self->log->verbose("deploy: uploaded file [$full_path] to remote_path[$remote_path]");

   $self->upload($full_path) or return;

   my $cmd = "\"cmd.exe /c $remote_path\\$sysmon_exe -i -accepteula -n\"";

   return $self->execute($cmd);
}

sub undeploy {
   my $self = shift;
   my ($host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_set_undef_arg('host', $host) or return;
   $self->brik_help_set_undef_arg('user', $user) or return;
   $self->brik_help_set_undef_arg('password', $password) or return;

   my $sysmon_exe = $self->sysmon_exe;
   my $remote_path = $self->remote_path;

   $self->log->verbose("undeploy: from remote_path[$remote_path] ".
      "sysmon_exe[$sysmon_exe]");

   my $cmd = "\"cmd.exe /c $remote_path\\$sysmon_exe -u\"";

   return $self->execute($cmd);
}

sub update_conf {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file;
   $self->brik_help_run_undef_arg('update_conf', $conf_file) or return;

   my $datadir = $self->datadir;
   my $base_conf_file = $conf_file;
   $conf_file = "$datadir/$conf_file";
   $self->brik_help_run_file_not_found('update_conf', $conf_file) or return;

   my $sysmon_exe = $self->sysmon_exe;
   my $remote_path = $self->remote_path;

   my $full_path = $self->get_sysmon_exe or return;

   $self->log->verbose("update_conf: uploaded file [$conf_file] ".
      "to remote_path[$remote_path]");

   $self->upload($conf_file) or return;

   my $cmd = "\"cmd.exe /c $remote_path\\$sysmon_exe -c $remote_path\\$base_conf_file\"";

   return $self->execute($cmd);
}

sub redeploy {
   my $self = shift;

   $self->undeploy;
   return $self->deploy;
}

1;

__END__

=head1 NAME

Metabrik::Remote::Sysmon - remote::sysmon Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
