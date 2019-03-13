#
# $Id: Libvirt.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# system::libvirt Brik
#
package Metabrik::System::Libvirt;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable virtualisation) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         driver => [ qw(qemu|vbox) ],
         capture_mode => [ qw(0|1) ],
      },
      attributes_default => {
         driver => 'qemu',
         capture_mode => 1,
      },
      commands => {
         install => [ ], # Inherited
         is_kvm_supported => [ ],
         command => [ qw(command driver|OPTIONAL) ],
         list => [ qw(driver|OPTIONAL) ],
         reboot => [ qw(name driver|OPTIONAL) ],
         restart => [ qw(name driver|OPTIONAL) ], # Alias for reboot
         start => [ qw(name driver|OPTIONAL) ],
         shutdown => [ qw(name driver|OPTIONAL) ],
         stop => [ qw(name driver|OPTIONAL) ], # Alias for shutdown
         save => [ qw(name file driver|OPTIONAL) ],
         restore => [ qw(name file driver|OPTIONAL) ],
      },
      require_binaries => {
         virsh => [ ],
         'kvm-ok' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(qemu-kvm libvirt-bin virtinst) ],
         debian => [ qw(qemu-kvm libvirt-bin virtinst) ],
         kali => [ qw(qemu-kvm libvirt-bin virtinst) ],
      },
   };
}

#
# https://help.ubuntu.com/lts/serverguide/libvirt.html
#

sub is_kvm_supported {
   my $self = shift;

   my $lines = $self->capture('kvm-ok');

   my $ok = 0;
   for my $line (@$lines) {
      if ($line =~ /can be used/) {
         $ok = 1;
         last;
      }
   }

   return $ok;
}

sub command {
   my $self = shift;
   my ($command, $driver) = @_;

   $driver ||= $self->driver;
   $self->brik_help_run_undef_arg('command', $command) or return;
   $self->brik_help_run_undef_arg('command', $driver) or return;

   my $uri = $driver.':///system';
   if ($driver eq 'vbox') {
      $uri = $driver.':///session';
   }

   my $cmd = "virsh -c $uri $command";

   return $self->execute($cmd);
}

sub list {
   my $self = shift;
   my ($driver) = @_;

   $driver ||= $self->driver;
   $self->brik_help_run_undef_arg('list', $driver) or return;

   my %list = ();

   my $lines = $self->command('list', $driver) or return;
   for my $line (@$lines) {
      $line =~ s/^\s*//;
      $line =~ s/\s*$//;
      my @toks = split(/\s+/, $line);

      if ($toks[0] =~ /^\d+$/) {  # We have a valid line
         my $id = shift @toks;
         my $state = pop @toks;
         my $name = join(' ', @toks);
         if (defined($id) && defined($state) && defined($name)) {
            $list{$id} = { id => $id, state => $state, name => $name };
         }
         else {
            $self->log->warning("list: error occured while parsing line [$line]");
         }
      }
   }

   return \%list;
}

sub reboot {
   my $self = shift;
   my ($name, $driver) = @_;

   $driver ||= $self->driver;
   $self->brik_help_run_undef_arg('reboot', $name) or return;
   $self->brik_help_run_undef_arg('reboot', $driver) or return;

   return $self->command("reboot \"$name\"", $driver);
}

sub restart {
   my $self = shift;

   return $self->reboot(@_);
}

sub start {
   my $self = shift;
   my ($name, $driver) = @_;

   $driver ||= $self->driver;
   $self->brik_help_run_undef_arg('start', $name) or return;
   $self->brik_help_run_undef_arg('start', $driver) or return;

   return $self->command("start \"$name\"", $driver);
}

sub shutdown {
   my $self = shift;
   my ($name, $driver) = @_;

   $driver ||= $self->driver;
   $self->brik_help_run_undef_arg('shutdown', $name) or return;
   $self->brik_help_run_undef_arg('shutdown', $driver) or return;

   return $self->command("shutdown \"$name\"", $driver);
}

sub stop {
   my $self = shift;

   return $self->shutdown(@_);
}

sub save {
   my $self = shift;
   my ($name, $file, $driver) = @_;

   $driver ||= $self->driver;
   $self->brik_help_run_undef_arg('save', $name) or return;
   $self->brik_help_run_undef_arg('save', $file) or return;
   $self->brik_help_run_undef_arg('save', $driver) or return;

   return $self->command("save \"$name\" $file", $driver);
}

sub restore {
   my $self = shift;
   my ($name, $file, $driver) = @_;

   $driver ||= $self->driver;
   $self->brik_help_run_undef_arg('restore', $name) or return;
   $self->brik_help_run_undef_arg('restore', $file) or return;
   $self->brik_help_run_undef_arg('restore', $driver) or return;

   return $self->command("restore \"$name\" $file", $driver);
}

1;

__END__

=head1 NAME

Metabrik::System::Libvirt - system::libvirt Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
