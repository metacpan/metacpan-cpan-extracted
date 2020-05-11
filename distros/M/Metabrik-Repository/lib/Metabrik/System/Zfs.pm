#
# $Id$
#
# system::zfs Brik
#
package Metabrik::System::Zfs;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
      },
      attributes_default => {
      },
      commands => {
         list => [ ],
         list_snapshots => [ ],
         delete_snapshot => [ qw(name|name_list) ],
      },
      require_modules => {
      },
      require_binaries => {
         zfs => [ ],
      },
      optional_binaries => {
      },
      need_packages => {
      },
   };
}

sub list {
   my $self = shift;

   my $cmd = "zfs list";
   my $lines = $self->capture($cmd) or return;

   # NAME                                           USED  AVAIL  REFER  MOUNTPOINT
   # zroot                                         1.23T   526G    96K  none

   my $header = 0;
   my @list = ();
   for (@$lines) {
      if (! $header) {  # Skip first header line
         $header++;
         next;
      }

      my @t = split(/\s+/, $_);

      my $name = $t[0];
      my $used = $t[1];
      my $avail = $t[2];
      my $refer = $t[3];
      my $mountpoint = $t[4];

      push @list, {
         name => $name,
         used => $used,
         avail => $avail,
         refer => $refer,
         mountpoint => $mountpoint,
      };
   }

   return \@list;
}

sub list_snapshots {
   my $self = shift;

   my $cmd = "zfs list -t snapshot";
   my $lines = $self->capture($cmd) or return;

   # NAME                                           USED  AVAIL  REFER  MOUNTPOINT
   # zroot/iocage/jails/...                         228K      -   898M  -

   my $header = 0;
   my @list = ();
   for (@$lines) {
      if (! $header) {  # Skip first header line
         $header++;
         next;
      }

      my @t = split(/\s+/, $_);

      my $name = $t[0];
      my $used = $t[1];
      my $avail = $t[2];
      my $refer = $t[3];
      my $mountpoint = $t[4];

      my $h = {
         name => $name,
         used => $used,
         avail => $avail,
         refer => $refer,
         mountpoint => $mountpoint,
      };

      my ($tag, $snapshot) = $name =~ m{^.*/([^\@]+)\@(.+)$};
      if (defined($tag) && defined($snapshot)) {
         $h->{tag} = $tag;
         $h->{snapshot} = $snapshot;
      }

      push @list, $h;
   }

   return \@list;
}

sub delete_snapshot {
   my $self = shift;
   my ($name) = @_;

   $self->brik_help_run_undef_arg('delete_snapshot', $name) or return;
   my $ref = $self->brik_help_run_invalid_arg('delete_snapshot', $name, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      for my $this (@$name) {
         $self->log->info("delete_snapshot: deleting snapshot [$name]");
         $self->delete_snapshot($this);
      }
   }
   else {
      if ($name !~ m{^.+@.+$}) {
         return $self->log->error("delete_snapshot: name [$name] is not a snapshot");
      }

      my $cmd = "zfs destroy $name";
      $self->sudo_system($cmd);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::System::Zfs - system::zfs Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
