#
# $Id$
#
# xorg::xwininfo Brik
#
package Metabrik::Xorg::Xwininfo;
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
         display => [ qw(display) ],
      },
      attributes_default => {
         display => ':0.0',
      },
      commands => {
         install => [ ],  # Inherited
         list => [ qw(display|OPTIONAL) ],
         show => [ qw(display|OPTIONAL) ],
      },
      require_binaries => {
         xwininfo => [ ],
      },
      need_packages => {
         ubuntu => [ qw(x11-utils) ],
         debian => [ qw(x11-utils) ],
         kali => [ qw(x11-utils) ],
      },
   };
}

sub list {
   my $self = shift;
   my ($display) = @_;

   $display ||= $self->display;

   my $cmd = "xwininfo -root -tree -display $display";
   my $lines = $self->capture($cmd) or return;

   my @r = ();
   my $c = 0;
   for (@$lines) {
      # "   Root window id: 0xd5 (the root window) \"i3\"",
      if (/Root window id/) {
         my ($id) = $_ =~ m{Root window id:\s+(\S+)};
         $r[$c]->{id} = $id;
         $r[$c]->{nid} = int(hex($id));
         $r[$c]->{name} = 'root';
         $r[$c]->{command} = '';
         $r[$c]->{title} = '';
         $r[$c]->{geometry} = '';
         $r[$c]->{position} = '';
         $c++;
      }
      # "     0x14232ea \"Xfce Terminal\": (\"xfce4-terminal\" \"Xfce4-terminal\")  171x211+1083+388  +1083+388",
      elsif (/^\s+0x/) {
         my ($id, $name, $command, $geometry, $position) = $_ =~
            m{^\s+(\S+)\s+([^:]+):\s+\(([^)]*)\)\s+(\S+)\s+(\S+)};
         $name =~ s/(?:^"|"$)//g;
         my ($com, $title) = $command =~ m{^"([^"]*)"\s+"([^"]*)"$};
         $r[$c]->{id} = $id;
         $r[$c]->{nid} = int(hex($id));
         $r[$c]->{name} = $name;
         $r[$c]->{command} = $com || $command;
         $r[$c]->{title} = $title || '';
         $r[$c]->{geometry} = $geometry;
         $r[$c]->{position} = $position;
         $c++;
      }
   }

   return \@r;
}

sub show {
   my $self = shift;
   my ($display) = @_;

   $display ||= $self->display;

   my $cmd = "xwininfo -root -tree -display $display";
   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Xorg::Xwininfo - xorg::xwininfo Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
