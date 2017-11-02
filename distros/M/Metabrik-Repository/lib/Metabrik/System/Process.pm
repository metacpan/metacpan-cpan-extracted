#
# $Id: Process.pm,v 50fa661db186 2017/02/25 18:06:07 gomor $
#
# system::process Brik
#
package Metabrik::System::Process;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: 50fa661db186 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         force_kill => [ qw(0|1) ],
         close_output_on_start => [ qw(0|1) ],
         use_pidfile => [ qw(0|1) ],
         pidfile => [ qw(file) ],
      },
      attributes_default => {
         force_kill => 0,
         close_output_on_start => 1,
         use_pidfile => 1,
      },
      commands => {
         parse_ps_output => [ qw(data) ],
         list => [ ],
         is_running => [ qw(process) ],
         is_running_from_string => [ qw(string) ],
         get_pid_from_string => [ qw(string) ],
         get_process_info => [ qw(process) ],
         kill => [ qw(process|pid) ],
         start => [ qw($sub) ],
         start_with_pidfile => [ qw($sub) ],
         list_daemons => [ ],
         get_latest_daemon_id => [ ],
         kill_from_pidfile => [ qw(pidfile) ],
         is_running_from_pidfile => [ qw(pidfile) ],
         grep_by_name => [ qw(process_name) ],
         get_new_pidfile => [ ],
         get_latest_pidfile => [ ],
         write_pidfile => [ qw(pidfile|OPTIONAL) ],
         delete_pidfile => [ qw(pidfile) ],
         wait_for_pidfile => [ qw(pidfile) ],
         info_process_is_running => [ ],
         info_process_is_not_running => [ ],
         verbose_process_is_running => [ ],
         verbose_process_is_not_running => [ ],
         error_process_is_running => [ ],
         error_process_is_not_running => [ ],
      },
      require_modules => {
         'Daemon::Daemonize' => [ ],
         'POSIX' => [ qw(:sys_wait_h) ],
         'Time::HiRes' => [ qw(usleep) ],
         'Metabrik::File::Find' => [ ],
      },
      require_binaries => {
         ps => [ ],
      },
      need_packages => {
         ubuntu => [ qw(procps) ],
         debian => [ qw(procps) ],
      },
   };
}

sub parse_ps_output {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('parse_ps_output', $data) or return;

   my @a = ();
   my $first = shift @$data;
   my $header = [ split(/\s+/, $first) ];
   my $count = scalar(@$header) - 1;
   for my $this (@$data) {
      my @toks = split(/\s+/, $this);
      my $h = {};
      for my $n (0..$count) {
         $h->{$header->[$n]} = $toks[$n];
      }
      my $ntoks = scalar(@toks) - 1;
      if ($ntoks > $count) {
         for my $n (($count+1)..$ntoks) {
            $h->{$header->[-1]} .= ' '.$toks[$n];
         }
      }
      push @a, $h;
   }

   return \@a;
}

sub list {
   my $self = shift;

   my $res = $self->capture("ps awuxw") or return;

   return $self->parse_ps_output($res);
}

sub is_running {
   my $self = shift;
   my ($process) = @_;

   $self->brik_help_run_undef_arg('is_running', $process) or return;

   my $list = $self->list or return;
   for my $this (@$list) {
      my $command = $this->{COMMAND};
      if ($command =~ m{^\[.*\]$}) {   # Example: "[migration/0]"
         $self->log->debug("is_running: list[$command] process[$process]");
         if ($command eq $process) {
            return 1;
         }
      }
      else {
         my @toks = split(/\s+/, $command);
         $toks[0] =~ s/^.*\/(.*?)$/$1/;
         $self->log->debug("is_running: list[$toks[0]] process[$process]");
         if ($toks[0] eq $process) {
            return 1;
         }
      }
   }

   return 0;
}

sub is_running_from_string {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('is_running_from_string', $string) or return;

   my $list = $self->list or return;
   for my $this (@$list) {
      my $command = $this->{COMMAND};
      if ($command =~ m{$string}i) {
         return 1;
      }
   }

   return 0;
}

sub get_pid_from_string {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('get_pid_from_string', $string) or return;

   my $list = $self->list or return;
   for my $this (@$list) {
      my $command = $this->{COMMAND};
      if ($command =~ m{$string}i) {
         return $this->{PID};
      }
   }

   return 0;
}

sub get_process_info {
   my $self = shift;
   my ($process) = @_;

   $self->brik_help_run_undef_arg('get_process_info', $process) or return;

   my @results = ();
   my $list = $self->list or return;
   for my $this (@$list) {
      my $command = $this->{COMMAND} or next;
      my @toks = split(/\s+/, $command);
      $toks[0] =~ s/^.*\/(.*?)$/$1/;
      if ($toks[0] eq $process) {
         push @results, $this;
      }
   }

   return \@results;
}

sub kill {
   my $self = shift;
   my ($process) = @_;

   $self->brik_help_run_undef_arg('kill', $process) or return;

   my $signal = $self->force_kill ? 'KILL' : 'TERM';

   if ($process =~ /^\d+$/) {
      kill($signal, $process);
      my $kid = waitpid(-1, POSIX::WNOHANG());
   }
   else {
      my $list = $self->get_process_info($process) or return;
      for my $this (@$list) {
         kill($signal, $this->{PID});
         my $kid = waitpid(-1, POSIX::WNOHANG());
      }
   }

   return 1;
}

#
# start process sub from user program has to call write_pidfile Command to create the pidfile.
# Then parent process can use wait_for_pidfile Command with the $pidfile returned from 
# start Command to wait for the process to really start.
#
sub start {
   my $self = shift;
   my ($sub) = @_;

   my %opts = (
      close => $self->close_output_on_start,
   );

   my $r;
   # Daemonize the given subroutine
   if (defined($sub)) {
      $r = Daemon::Daemonize->daemonize(
         %opts,
         run => $sub,
      );
   }
   # Or myself.
   else {
      $r = Daemon::Daemonize->daemonize(
         %opts,
      );
   }

   if ($self->use_pidfile) {
      my $pidfile = $self->get_new_pidfile or return;

      $self->log->verbose("start: new daemon started with pidfile [$pidfile]");

      return $pidfile;
   }

   return 1;
}

sub start_with_pidfile {
   my $self = shift;
   my ($sub) = @_;

   my %opts = (
      close => $self->close_output_on_start,
   );

   my $pidfile = $self->get_new_pidfile or return;

   my $r;
   # Daemonize the given subroutine
   if (defined($sub)) {
      $r = Daemon::Daemonize->daemonize(
         %opts,
         run => sub {
            $self->write_pidfile($pidfile);
            &$sub();
         },
      );
   }
   # Or myself.
   else {
      $r = Daemon::Daemonize->daemonize(
         %opts,
      );
   }

   $self->log->verbose("start: new daemon started with pidfile [$pidfile]");

   return $pidfile;
}

sub list_daemons {
   my $self = shift;

   my $datadir = $self->datadir;

   my $ff = Metabrik::File::Find->new_from_brik_init($self) or return;
   my $list = $ff->files($datadir, 'daemonpid\.\d+');

   my %daemons = ();
   for (@$list) {
      my ($id) = $_ =~ m{\.(\d+)$};
      my $pid = Daemon::Daemonize->read_pidfile($_) or next;
      $daemons{$id} = { file => $_, pid => $pid };
   }

   return \%daemons;
}

sub get_latest_daemon_id {
   my $self = shift;

   my $list = $self->list_daemons or return;

   my $id = 0;
   for (keys %$list) {
      if ($_ > $id) {
         $id = $_;
      }
   }

   return $id;
}

sub kill_from_pidfile {
   my $self = shift;
   my ($pidfile) = @_;

   $self->brik_help_run_undef_arg('kill_from_pidfile', $pidfile) or return;
   $self->brik_help_run_file_not_found('kill_from_pidfile', $pidfile) or return;

   if (my $pid = Daemon::Daemonize->check_pidfile($pidfile)) {
      $self->log->verbose("kill_from_pidfile: file[$pidfile] and pid[$pid]");
      $self->kill($pid);
      Daemon::Daemonize->delete_pidfile($pidfile);
   }

   return 1;
}

sub is_running_from_pidfile {
   my $self = shift;
   my ($pidfile) = @_;

   $self->brik_help_run_undef_arg('is_running_from_pidfile', $pidfile) or return;

   # Not file found, so probably not running
   if (! -f $pidfile) {
      return 0;
   }

   if (my $pid = Daemon::Daemonize->check_pidfile($pidfile)) {
      $self->debug && $self->log->debug("is_running_from_pidfile: yes");
      return 1;
   }

   $self->debug && $self->log->debug("is_running_from_pidfile: no");

   return 0;
}

sub grep_by_name {
   my $self = shift;
   my ($process_name) = @_;

   $self->brik_help_run_undef_arg('grep_by_name', $process_name) or return;

   my $list = $self->list or return;
   for my $p (@$list) {
      if (lc($p->{COMMAND}) =~ m{$process_name}i) {
         return $p;
      }
   }

   return 0;
}

sub get_new_pidfile {
   my $self = shift;

   # Use provided one.
   my $pidfile = $self->pidfile;
   if (defined($pidfile)) {
      return $pidfile;
   }

   my $id = $self->get_latest_daemon_id;
   defined($id) ? $id++ : ($id = 1);
   $pidfile = sprintf("%s/daemonpid.%05d", $self->datadir, $id);

   return $pidfile;
}

sub get_latest_pidfile {
   my $self = shift;

   # Return user provided one.
   my $pidfile = $self->pidfile;
   if (defined($pidfile)) {
      return $pidfile;
   }

   my $id = $self->get_latest_daemon_id;
   if (defined($id)) {
      $pidfile = sprintf("%s/daemonpid.%05d", $self->datadir, $id);
   }
   else {
      return $self->log->error("get_latest_pidfile: no pidfile found");
   }

   return $pidfile;
}

#
# To be called by a sub used by start Command
#
sub write_pidfile {
   my $self = shift;

   my $pidfile = $self->get_new_pidfile or return;

   my $pid = $$;

   my $r = Daemon::Daemonize->write_pidfile($pidfile, $pid);
   if (! defined($r)) {
      return $self->log->erro("write_pidfile: failed to write pidfile [$pidfile]: $!");
   }

   return $pid;
}

#
# To be used by parent process
#
sub delete_pidfile {
   my $self = shift;
   my ($pidfile) = @_;

   $self->brik_help_run_undef_arg('delete_pidfile', $pidfile) or return;

   if (! -f $pidfile) {
      # Nothing to delete
      return 0;
   }

   my $r = Daemon::Daemonize->delete_pidfile($pidfile);
   if (! defined($r)) {
      return $self->log->erro("delete_pidfile: failed to delete pidfile [$pidfile]: $!");
   }

   return 1;
}

# XXX: Move to system::file and use a helper here
#
# To be used by parent process
#
sub wait_for_pidfile {
   my $self = shift;
   my ($pidfile) = @_;

   $self->brik_help_run_undef_arg('wait_pidfile', $pidfile) or return;

   my $found = 0;
   # 50 * 100 ms = 5s
   for (0..49) {
      if (-e $pidfile) {
         $found++;
         last;
      }
      Time::HiRes::usleep(100_000); # 100_000us => 100ms => 0.1s
      # 0.1s * 50 = 5s
   }

   return $found;
}

sub info_process_is_running {
   my $self = shift;

   return $self->log->info("process is running");
}

sub info_process_is_not_running {
   my $self = shift;

   return $self->log->info("process is NOT running");
}

sub verbose_process_is_running {
   my $self = shift;

   return $self->log->verbose("process is running");
}

sub verbose_process_is_not_running {
   my $self = shift;

   return $self->log->verbose("process is NOT running");
}

sub error_process_is_running {
   my $self = shift;

   return $self->log->error("process is running");
}

sub error_process_is_not_running {
   my $self = shift;

   return $self->log->error("process is NOT running");
}

# XXX: Broken.
sub _brik_fini {
   my $self = shift;

   my $pidfile = $self->get_latest_pidfile;
   if (-f $pidfile) {
      $self->delete_pidfile($pidfile);
   }

   return $self->SUPER::brik_fini;
}

1;

__END__

=head1 NAME

Metabrik::System::Process - system::process Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
