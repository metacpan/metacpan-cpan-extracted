#
# $Id$
#
# remote::windiff Brik
#
package Metabrik::Remote::Windiff;
use strict;
use warnings;

use base qw(Metabrik::Client::Smbclient);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         domain => [ qw(domain) ],
         user => [ qw(username) ],
         password => [ qw(password) ],
         host => [ qw(host) ],
         share => [ qw(share) ],
         remote_path => [ qw(path) ],
         vm => [ qw(id) ],
         profile => [ qw(volatility_profile) ],
      },
      attributes_default => {
         profile => 'Win7SP1x64',
      },
      commands => {
         upload => [ qw(file remote_path|OPTIONAL share|OPTIONAL) ],
         execute => [ qw(command) ],
         restart => [ qw(vm) ],
         snapshot => [ qw(vm) ],
         process_diff => [ qw(source_file.vol destination_file.vol) ],
         netstat_diff => [ qw(source_file.vol destination_file.vol) ],
      },
      require_modules => {
         'Metabrik::Forensic::Volatility' => [ ],
         'Metabrik::Remote::Winexe' => [ ],
         'Metabrik::System::Virtualbox' => [ ],
         'Metabrik::Network::Address' => [ ],
      },
   };
}

sub upload {
   my $self = shift;
   my ($file, $remote_path, $share) = @_;

   $self->brik_help_run_undef_arg('execute', $file) or return;

   return $self->SUPER::upload($file, $remote_path, $share);
}

sub execute {
   my $self = shift;
   my ($command) = @_;

   $self->brik_help_run_undef_arg('execute', $command) or return;

   my $rw = Metabrik::Remote::Winexe->new_from_brik_init($self) or return;
   $rw->host($self->host);
   $rw->user($self->user);
   $rw->password($self->password);

   return $rw->execute_in_background($command);
}

sub restart {
   my $self = shift;
   my ($vm) = @_;

   $self->brik_help_run_undef_arg('restart', $vm) or return;

   if ($vm !~ m{^[-a-z0-9]+$}) {
      return $self->log->error("restart: vm [$vm] does not look like an ID");
   }

   my $sv = Metabrik::System::Virtualbox->new_from_brik_init($self) or return;
   $sv->type('headless');
   $sv->restart($vm) or return;

   return 1;
}

sub snapshot {
   my $self = shift;
   my ($vm, $output) = @_;

   $output ||= $self->datadir.'/'.$vm.'.snapshot';
   $self->brik_help_run_undef_arg('snapshot', $vm) or return;

   if ($vm !~ m{^[-a-z0-9]+$}) {
      return $self->log->error("snapshot: vm [$vm] does not look like an ID");
   }

   my $sv = Metabrik::System::Virtualbox->new_from_brik_init($self) or return;
   $sv->type('headless');

   $self->log->info("snapshot: dumping VM core...");

   my $elf = $sv->dumpvmcore($vm) or return;

   $self->log->info("snapshot: extracting memdump...");

   my $vol = $sv->extract_memdump_from_dumpguestcore($elf, $output) or return;

   $self->log->info("snapshot: done.");

   return $vol;
}

sub process_diff {
   my $self = shift;
   my ($snap1, $snap2) = @_;

   $self->brik_help_run_undef_arg('process_diff', $snap1) or return;
   $self->brik_help_run_undef_arg('process_diff', $snap2) or return;

   my $fv = Metabrik::Forensic::Volatility->new_from_brik_init($self) or return;
   $fv->profile($self->profile);

   $self->log->info("process_diff: performing pslist on first snapshot...");

   my $pslist1 = $fv->pslist($snap1) or return;

   $self->log->info("process_diff: performing pslist on second snapshot...");

   my $pslist2 = $fv->pslist($snap2) or return;

   my %pid = ();
   for my $this (@$pslist1) {
      $pid{$this->{pid}} = $this;
   }

   $self->log->info("process_diff: searching pslist diff...");

   my @new = ();
   for my $this (@$pslist2) {
      if (! exists($pid{$this->{pid}})) {
         push @new, $this;
      }
   }

   $self->log->info("process_diff: done.");

   return \@new;
}

sub netstat_diff {
   my $self = shift;
   my ($snap1, $snap2) = @_;

   $self->brik_help_run_undef_arg('netstat_diff', $snap1) or return;
   $self->brik_help_run_undef_arg('netstat_diff', $snap2) or return;

   my $fv = Metabrik::Forensic::Volatility->new_from_brik_init($self) or return;
   $fv->profile($self->profile);

   $self->log->info("netstat_diff: performing netscan on first snapshot...");

   my $netscan1 = $fv->netscan($snap1) or return;

   $self->log->info("netstat_diff: performing netscan on second snapshot...");

   my $netscan2 = $fv->netscan($snap2) or return;

   my %pid = ();
   for my $this (@$netscan1) {
      $pid{$this->{pid}} = $this;
   }

   $self->log->info("netstat_diff: searching netscan diff...");

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;

   my @new = ();
   for my $this (@$netscan2) {
      if (! exists($pid{$this->{pid}})) {
         my ($address, $port) = split(/:/, $this->{foreign_address});
         if ($na->is_ip($address) && $address !~ m{^0\.0\.0\.0$}) {
            push @new, $this;
         }
      }
   }

   $self->log->info("netstat_diff: done.");

   return \@new;
}

1;

__END__

=head1 NAME

Metabrik::Remote::Windiff - remote::windiff Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
