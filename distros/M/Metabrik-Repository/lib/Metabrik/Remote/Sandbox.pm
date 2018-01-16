#
# $Id: Sandbox.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# remote::sandbox Brik
#
package Metabrik::Remote::Sandbox;
use strict;
use warnings;

use base qw(Metabrik::Remote::Winexe);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         es_nodes => [ qw(nodes) ],
         es_indices => [ qw(indices) ],
         win_host => [ qw(host) ],
         win_user => [ qw(user) ],
         win_password => [ qw(password) ],
         vm_id => [ qw(id) ],
         vm_snapshot_name => [ qw(name) ],
         use_regex_match => [ qw(0|1) ],
         _client => [ qw(INTERNAL) ],
         _ci => [ qw(INTERNAL) ],
         _em => [ qw(INTERNAL) ],
         _fb => [ qw(INTERNAL) ],
         _sf => [ qw(INTERNAL) ],
         _fr => [ qw(INTERNAL) ],
         _cs => [ qw(INTERNAL) ],
         _ce => [ qw(INTERNAL) ],
         _rs => [ qw(INTERNAL) ],
         _rw => [ qw(INTERNAL) ],
         _rwd => [ qw(INTERNAL) ],
         _sv => [ qw(INTERNAL) ],
         _fs => [ qw(INTERNAL) ],
      },
      attributes_default => {
         es_nodes => [ qw(http://localhost:9200) ],
         es_indices => 'winlogbeat-*',
         vm_snapshot_name => '666_before_malware',
         use_regex_match => 0,
      },
      commands => {
         create_client => [ ],
         save_elasticsearch_state => [ qw(name|OPTIONAL) ],
         restore_elasticsearch_state => [ ],
         restart_sysmon_collector => [ ],
         upload_and_execute => [ qw(file) ],
         diff_ps_state => [ qw(processes|OPTIONAL) ],
         diff_ps_network_connections => [ qw(processes|OPTIONAL) ],
         diff_ps_target_filename_created => [ qw(processes|OPTIONAL) ],
         diff_ps_registry_value_set => [ qw(processes|OPTIONAL) ],
         diff_ps_registry_object_added_or_deleted => [ qw(processes|OPTIONAL) ],
         diff_ps_target_process_accessed => [ qw(processes|OPTIONAL) ],
         loop_and_download_created_files => [ qw(processes|OPTIONAL) ],
         memdump_as_volatility => [ qw(output|OPTIONAL) ],
         stop_vm => [ ],
         restore_vm => [ ],
      },
      require_modules => {
         'Metabrik::System::File' => [ ],
         'Metabrik::String::Password' => [ ],
         'Metabrik::Client::Smbclient' => [ ],
         'Metabrik::Client::Elasticsearch' => [ ],
         'Metabrik::Remote::Sysmon' => [ ],
         'Metabrik::Remote::Winsvc' => [ ],
         'Metabrik::Remote::Windefend' => [ ],
         'Metabrik::System::Virtualbox' => [ ],
         'Metabrik::Forensic::Sysmon' => [ ],
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
      },
   };
}

sub brik_preinit {
   my $self = shift;

   # Do your preinit here, return 0 on error.

   return $self->SUPER::brik_preinit;
}

sub brik_init {
   my $self = shift;

   # Do your init here, return 0 on error.

   return $self->SUPER::brik_init;
}

sub create_client {
   my $self = shift;

   if ($self->_client) {
      return 1;
   }

   my $win_user = $self->win_user;
   my $win_host = $self->win_host;
   my $win_password = $self->win_password;
   my $es_nodes = $self->es_nodes;
   my $vm_id = $self->vm_id;
   $self->brik_help_set_undef_arg('win_user', $win_user) or return;
   $self->brik_help_set_undef_arg('win_host', $win_host) or return;
   $self->brik_help_set_undef_arg('vm_id', $vm_id) or return;

   if (! defined($win_password)) {
      my $sp = Metabrik::String::Password->new_from_brik_init($self) or return;
      $win_password = $sp->prompt or return;
   }

   $self->host($win_host);
   $self->user($win_user);
   $self->password($win_password);

   my $cs = Metabrik::Client::Smbclient->new_from_brik_init($self) or return;
   $cs->host($win_host);
   $cs->user($win_user);
   $cs->password($win_password);

   my $ce = Metabrik::Client::Elasticsearch->new_from_brik_init($self) or return;
   $ce->nodes($es_nodes);
   $ce->open or return;

   my $rs = Metabrik::Remote::Sysmon->new_from_brik_init($self) or return;
   $rs->host($win_host);
   $rs->user($win_user);
   $rs->password($win_password);

   my $rw = Metabrik::Remote::Winsvc->new_from_brik_init($self) or return;
   $rw->host($win_host);
   $rw->user($win_user);
   $rw->password($win_password);

   my $rwd = Metabrik::Remote::Windefend->new_from_brik_init($self) or return;
   $rwd->host($win_host);
   $rwd->user($win_user);
   $rwd->password($win_password);

   my $sv = Metabrik::System::Virtualbox->new_from_brik_init($self) or return;
   $sv->type('gui');

   my $fs = Metabrik::Forensic::Sysmon->new_from_brik_init($self) or return;
   $fs->use_regex_match($self->use_regex_match);

   $self->_cs($cs);
   $self->_ce($ce);
   $self->_rs($rs);
   $self->_rw($rw);
   $self->_rwd($rwd);
   $self->_sv($sv);
   $self->_fs($fs);

   return $self->_client(1);
}

sub save_elasticsearch_state {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $ce = $self->_ce;
   my $indices = $self->es_indices;

   return $ce->create_snapshot_for_indices($indices, $name);
}

sub restore_elasticsearch_state {
   my $self = shift;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $ce = $self->_ce;

   my $indices = $self->es_indices;

   $ce->delete_index($indices) or return;

   $ce->restore_snapshot_for_indices($indices);

   # Waiting for restoration to complete.
   while (! $ce->get_snapshot_state) {
      sleep(1);
   }

   return 1;
}

sub restart_sysmon_collector {
   my $self = shift;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $rs = $self->_rs;
   $rs->generate_conf or return;
   $rs->update_conf or return;
   $rs->redeploy or return;

   my $rw = $self->_rw;
   $rs->restart('winlogbeat') or return;

   return 1;
}

sub upload_and_execute {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;
   $self->brik_help_run_undef_arg('upload_and_execute', $file) or return;
   $self->brik_help_run_file_not_found('upload_and_execute', $file) or return;

   my $ce = $self->_ce;
   my $sv = $self->_sv;
   my $cs = $self->_cs;
   my $rwd = $self->_rwd;
   my $fs = $self->_fs;

   $self->log->info("upload_and_execute: restoring Elasticsearch state...");
   $self->restore_elasticsearch_state or return;
   $self->log->info("upload_and_execute: done.");

   # We create a restore point if none exists yet.
   # Or we restore the previous one.
   my $list = $sv->snapshot_list($self->vm_id) or return;
   my $found = 0;
   for my $this (@$list) {
      if ($this->{name} eq $self->vm_snapshot_name) {
         $found = 1;
         last;
      }
   }
   if (! $found) {
      $self->log->info("upload_and_execute: snapshoting VM state...");
      $sv->snapshot_live($self->vm_id, $self->vm_snapshot_name) or return;
      $self->log->info("upload_and_execute: done.");
   }
   else {
      $self->log->info("upload_and_execute: restoring VM state...");
      $sv->stop($self->vm_id);
      $sv->snapshot_restore($self->vm_id, $self->vm_snapshot_name) or return;
      $sv->start($self->vm_id) or return;
      $self->log->info("upload_and_execute: done.");
   }

   sleep(5);  # Waiting for VM to start.

   $self->log->info("upload_and_execute: disabling Windows Defender...");
   $rwd->disable or return;
   $self->log->info("upload_and_execute: done.");

   $self->log->info("upload_and_execute: uploading file...");
   $cs->upload($file) or return;
   $self->log->info("upload_and_execute: done.");

   $self->log->info("upload_and_execute: saving sysmon state...");
   $fs->save_state or return;
   $self->log->info("upload_and_execute: done.");

   $self->log->info("upload_and_execute: executing malware...");
   $self->execute('"c:\\windows\\temp\\'.$file.'"');
   $self->log->info("upload_and_execute: done.");

   return 1;
}

sub diff_ps_state {
   my $self = shift;
   my ($processes) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   if (defined($processes)) {
      $self->brik_help_run_invalid_arg('diff_ps_state',
         $processes, 'ARRAY') or return;
   }

   my $fs = $self->_fs;

   return $fs->diff_current_state('ps', $processes);
}

sub diff_ps_network_connections {
   my $self = shift;
   my ($processes) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   if (defined($processes)) {
      $self->brik_help_run_invalid_arg('diff_ps_network_connections',
         $processes, 'ARRAY') or return;
   }

   my $fs = $self->_fs;

   return $fs->diff_current_state('ps_network_connections', $processes);
}

sub diff_ps_target_filename_created {
   my $self = shift;
   my ($processes) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   if (defined($processes)) {
      $self->brik_help_run_invalid_arg('diff_ps_target_filename_created',
         $processes, 'ARRAY') or return;
   }

   my $fs = $self->_fs;

   return $fs->diff_current_state('ps_target_filename_created', $processes);
}

sub diff_ps_registry_value_set {
   my $self = shift;
   my ($processes) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   if (defined($processes)) {
      $self->brik_help_run_invalid_arg('diff_ps_registry_value_set',
         $processes, 'ARRAY') or return;
   }

   my $fs = $self->_fs;

   return $fs->diff_current_state('ps_registry_value_set', $processes);
}

sub diff_ps_registry_object_added_or_deleted {
   my $self = shift;
   my ($processes) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   if (defined($processes)) {
      $self->brik_help_run_invalid_arg('diff_ps_registry_object_added_or_deleted',
         $processes, 'ARRAY') or return;
   }

   my $fs = $self->_fs;

   return $fs->diff_current_state('ps_registry_object_added_or_deleted', $processes);
}

sub diff_ps_target_process_accessed {
   my $self = shift;
   my ($processes) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   if (defined($processes)) {
      $self->brik_help_run_invalid_arg('diff_ps_target_process_accessed',
         $processes, 'ARRAY') or return;
   }

   my $fs = $self->_fs;

   return $fs->diff_current_state('ps_target_process_accessed', $processes);
}

sub loop_and_download_created_files {
   my $self = shift;
   my ($processes, $output_dir) = @_;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   $output_dir ||= defined($self->shell) && $self->shell->full_pwd || '/tmp';

   if (defined($processes)) {
      $self->brik_help_run_undef_arg('loop_and_download_created_files', $processes)
         or return;
      $self->brik_help_run_invalid_arg('loop_and_download_created_files', $processes,
         'ARRAY', 'SCALAR') or return;
   }

   my $cs = $self->_cs;
   my $fs = $self->_fs;

   $output_dir .= "/download";
   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($output_dir) or return;

   while (1) {
      my $diff = $fs->diff_current_state('ps_target_filename_created', $processes)
         or return;

      if (exists($diff->{ps_target_filename_created})) {
         my $created = $diff->{ps_target_filename_created};
         for my $process (keys %$created) {
            for my $file (@{$created->{$process}}) {
               $self->log->info("loop_and_download_created_files: ".
                  "downloading file [$file]");
               $cs->download_in_background($file, $output_dir);
            }
         }
      }
   }

   return 1;
}

sub memdump_as_volatility {
   my $self = shift;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $vm_id = $self->vm_id;
   my $sv = $self->_sv;

   my $output = $sv->dumpvmcore($vm_id) or return;

   return $sv->extract_memdump_from_dumpguestcore($output);
}

sub stop_vm {
   my $self = shift;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $vm_id = $self->vm_id;
   my $sv = $self->_sv;

   return $sv->stop($vm_id);
}

sub restore_vm {
   my $self = shift;

   $self->brik_help_run_undef_arg('create_client', $self->_client) or return;

   my $vm_id = $self->vm_id;
   my $sv = $self->_sv;

   $sv->stop($vm_id);

   return $sv->snapshot_restore($self->vm_id, $self->vm_snapshot_name);
}

sub brik_fini {
   my $self = shift;

   # Do your fini here, return 0 on error.

   return $self->SUPER::brik_fini;
}

1;

__END__

=head1 NAME

Metabrik::Remote::Sandbox - remote::sandbox Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
