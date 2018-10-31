#
# $Id: Virtualbox.pm,v 8db9610c2999 2018/09/17 15:39:24 gomor $
#
# system::virtualbox Brik
#
package Metabrik::System::Virtualbox;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 8db9610c2999 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         capture_mode => [ qw(0|1) ],
         type => [ qw(gui|sdl|headless) ],
      },
      attributes_default => {
         capture_mode => 1,
         type => 'gui',
      },
      commands => {
         install => [ ], # Inherited
         command => [ qw(command) ],
         list => [ ],
         register => [ qw(file_vbox) ],
         start => [ qw(name type|OPTIONAL) ],
         restore => [ qw(name type|OPTIONAL) ], # Alias for start
         stop => [ qw(name) ],
         save => [ qw(name) ],
         pause => [ qw(name) ],
         resume => [ qw(resume) ],
         snapshot_list => [ qw(name) ],
         snapshot_live => [ qw(name snapshot_name description|OPTIONAL) ],
         snapshot_delete => [ qw(name snapshot_name) ],
         snapshot_restore => [ qw(name snapshot_name) ],
         screenshot => [ qw(name output.png|OPTIONAL) ],
         dumpguestcore => [ qw(name output.elf|OPTIONAL) ],
         dumpvmcore => [ qw(name output.elf|OPTIONAL) ],
         extract_memdump_from_dumpguestcore => [ qw(input output.vol|OPTIONAL) ],
         restart => [ qw(name type|OPTIONAL) ],
         info => [ qw(name) ],
         is_started => [ qw(name) ],
         is_stopped => [ qw(name) ],
         get_current_snapshot_id => [ qw(name) ],
         reset_vboxnet => [ qw(device) ],
      },
      require_modules => {
         'Data::Dumper' => [ ],
         'Metabrik::File::Raw' => [ ],
         'Metabrik::File::Read' => [ ],
         'Metabrik::File::Readelf' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         vboxmanage => [ ],
      },
      need_packages => {
         ubuntu => [ qw(virtualbox) ],
         debian => [ qw(virtualbox) ],
      },
   };
}

sub command {
   my $self = shift;
   my ($command) = @_;

   $self->brik_help_run_undef_arg('command', $command) or return;

   return $self->execute("vboxmanage $command");
}

sub list {
   my $self = shift;

   my %vms = ();
   my $lines = $self->command('list vms') or return;
   for my $line (@$lines) {
      my ($name, $uuid) = $line =~ m/^\s*"([^"]+)"\s+{([^}]+)}\s*$/;
      $vms{$uuid} = { uuid => $uuid, name => $name };
   }

   return \%vms;
}

sub register {
   my $self = shift;
   my ($vbox) = @_;

   $self->brik_help_run_undef_arg('register', $vbox) or return;
   $self->brik_help_run_file_not_found('register', $vbox) or return;

   if ($vbox !~ m{\.vbox$}) {
      return $self->log->error("register: give a .vbox file as input");
   }

   return $self->command("registervm \"$vbox\"");
}

sub start {
   my $self = shift;
   my ($name, $type) = @_;

   $type ||= $self->type;
   $self->brik_help_run_undef_arg('start', $name) or return;
   $self->brik_help_run_undef_arg('start', $type) or return;

   if ($self->is_started($name)) {
      return $self->log->info("start: VM with name [$name] already started");
   }

   return $self->command("startvm \"$name\" --type $type");
}

sub restore {
   my $self = shift;

   return $self->start(@_);
}

sub stop {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('stop', $name) or return;

   if ($self->is_stopped($name)) {
      return $self->log->info("start: VM with name [$name] already stopped");
   }

   return $self->command("controlvm \"$name\" poweroff");
}

sub save {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('save', $name) or return;

   return $self->command("controlvm \"$name\" savestate");
}

sub pause {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('pause', $name) or return;

   return $self->command("controlvm \"$name\" pause");
}

sub resume {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('resume', $name) or return;

   return $self->command("controlvm \"$name\" resume");
}

sub snapshot_list {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('snapshot_list', $name) or return;

   my $lines = $self->command("snapshot \"$name\" list");

   if ($self->log->level > 1) {
      print Dumper($lines)."\n";
   }

   # No snapshot: error code 256
   if ($? != 0) {
      return $self->log->error("snapshot_list: no snapshot found?");
   }

   my @list = ();
   for my $line (@$lines) {
      if ($line =~ m{^\s*Name:}) {
         my ($descr, $id) = $line =~ m{^\s*Name:\s+([^\(]+)\(UUID:\s+([^\)]+)\)};
         if (defined($descr) && defined($id)) {
            my $current = 0;
            if ($line =~ m{\*$}) {
               $current = 1;
            }
            $descr =~ s{\s*$}{};
            push @list, {
               name => $descr,
               uuid => $id,
               current => $current,
            };
         }
      }
   }

   return \@list;
}

sub snapshot_live {
   my $self = shift;
   my ($name, $snapshot_name, $description) = @_;

   $description ||= 'snapshot';
   $self->brik_help_run_undef_arg('snapshot_live', $name) or return;
   $self->brik_help_run_undef_arg('snapshot_live', $snapshot_name) or return;

   my $lines = $self->command("snapshot \"$name\" take \"$snapshot_name\" --description \"$description\" --live");

   if ($self->log->level > 1) {
      print Dumper($lines)."\n";
   }

   if ($? != 0) {
      return $self->log->error("snapshot_live: snapshot failed");
   }

   return $self->log->info("snapshot_live: snapshot complete");
}

sub snapshot_delete {
   my $self = shift;
   my ($name, $snapshot_name) = @_;

   $self->brik_help_run_undef_arg('snapshot_delete', $name) or return;
   $self->brik_help_run_undef_arg('snapshot_delete', $snapshot_name) or return;

   my $lines = $self->command("snapshot \"$name\" delete \"$snapshot_name\"");

   # code 256: This machine does not have any snapshots
   if ($? != 0) {
      return $self->log->error("snapshot_delete: unable to delete snapshot [$snapshot_name] for vm [$name]");
   }

   return $self->log->info("snapshot_delete: snapshot [$snapshot_name] deleted successfully for vm [$name]");
}

sub snapshot_restore {
   my $self = shift;
   my ($name, $snapshot_name) = @_;

   $self->brik_help_run_undef_arg('snapshot_restore', $name) or return;
   $self->brik_help_run_undef_arg('snapshot_restore', $snapshot_name) or return;

   return $self->command("snapshot \"$name\" restore \"$snapshot_name\"");
}

sub screenshot {
   my $self = shift;
   my ($name, $output) = @_;

   $output ||= $self->datadir."/screenshot.png";
   $self->brik_help_run_undef_arg('screenshot', $name) or return;

   $self->command("controlvm \"$name\" screenshotpng \"$output\"") or return;

   return $output;
}

#
# Dump guestcore
#
sub dumpguestcore {
   my $self = shift;
   my ($name, $output) = @_;

   $output ||= $self->datadir.'/output.elf';
   $self->brik_help_run_undef_arg('dumpguestcore', $name) or return;

   if (-f $output) {
      my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
      $sf->remove($output) or return;
   }

   $self->command("debugvm \"$name\" dumpguestcore --filename \"$output\"") or return;

   return $output;
}

#
# Dump vmcore, same as dump guestcore but for newer versions of VirtualBox which renamed 
# the function
#
sub dumpvmcore {
   my $self = shift;
   my ($name, $output) = @_;

   $output ||= $self->datadir.'/output.elf';
   $self->brik_help_run_undef_arg('dumpvmcore', $name) or return;

   if (-f $output) {
      my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
      $sf->remove($output) or return;
   }

   $self->command("debugvm \"$name\" dumpvmcore --filename \"$output\"") or return;

   return $output;
}

#
# By taking information from:
# http://wiki.yobi.be/wiki/RAM_analysis#RAM_dump_with_VirtualBox:_via_ELF64_coredump
#
sub extract_memdump_from_dumpguestcore {
   my $self = shift;
   my ($input, $output) = @_;

   $output ||= $self->datadir.'/output.vol';
   $self->brik_help_run_undef_arg('extract_memdump_from_dumpguestcore', $input) or return;

   my $fraw = Metabrik::File::Raw->new_from_brik_init($self) or return;
   my $fread = Metabrik::File::Read->new_from_brik_init($self) or return;
   my $felf = Metabrik::File::Readelf->new_from_brik_init($self) or return;

   my $headers = $felf->program_headers($input) or return;

   my $offset = 0;
   my $size = 0;
   for my $section (@{$headers->{sections}}) {
      if ($section->{type} eq 'LOAD') {
         $offset = hex($section->{offset});
         $size = hex($section->{filesiz});
         last;
      }
   }
   if (! $offset || ! $size) {
      return $self->log->error("extract_memdump_from_dumpguestcore: unable to find memdump");
   }

   $self->log->verbose("extract_memdump_from_dumpguestcore: offset[$offset] size[$size]");

   $fread->encoding('ascii');  # Raw mode
   my $fdin = $fread->open($input) or return;
   $fread->seek($offset) or return;

   if (-f $output) {
      my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
      $sf->remove($output) or return;
   }

   my $written = 0;
   my $fdout = $fraw->open($output) or return;
   while (<$fdin>) {
      my $this = length($_);
      if (($written + $this) <= $size) {
         print $fdout $_;
         $written += $this;
      }
      else {
         my $rest = $size - $written;
         if ($rest < 0) {
            $self->log->warning("extract_memdump_from_dumpguestcore: error while reading input");
            last;
         }
         my $tail = substr($_, 0, $rest);
         print $fdout $tail;
         last;
      }
   }
   $fraw->close;
   $fread->close;

   return $output;
}

sub restart {
   my $self = shift;
   my ($name, $type) = @_;

   $self->brik_help_run_undef_arg('restart', $name) or return;

   $self->stop($name) or return;
   sleep(2);
   return $self->start($name, $type);
}

sub info {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('info', $name) or return;

   my $lines = $self->command("showvminfo \"$name\"") or return;

   my $info = {};
   if (@$lines > 0) {
      for my $line (@$lines) {
         my @t = split(/:/, $line, 2);
         my $k = $t[0];
         my $v = $t[1];
         next unless defined($v);
         $k =~ s{^\s*}{};
         $k =~ s{\s*$}{};
         $v =~ s{^\s*}{};
         $v =~ s{\s*$}{};
         if (length($k) && length($v)) {
            $k =~ s{ }{_}g;
            $k =~ s{(\(|\))}{}g;
            $info->{lc($k)} = $v;
         }
      }
   }

   return $info;

}

sub is_started {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('is_started', $name) or return;

   my $info = $self->info($name) or return;
   my $state = $info->{state} || 'undef';
   if ($state =~ m{running}) {
      return 1;
   }

   return 0;
}

sub is_stopped {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('is_stopped', $name) or return;

   return ! $self->is_started($name);
}

sub get_current_snapshot_id {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('get_current_snapshot_id', $name) or return;

   my $list = $self->snapshot_list($name) or return;

   for my $this (@$list) {
      if ($this->{current}) {
         return $this->{uuid};
      }
   }

   return 0;
}

sub reset_vboxnet {
   my $self = shift;
   my ($device) = @_;

   $self->brik_help_run_undef_arg('reset_vboxnet', $device) or return;

   my $lines1 = $self->command("hostonlyif remove $device") or return;
   my $lines2 = $self->command("hostonlyif create") or return;

   return [ $lines1, $lines2 ];
}

1;

__END__

=head1 NAME

Metabrik::System::Virtualbox - system::virtualbox Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
