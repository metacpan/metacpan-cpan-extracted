#
# $Id: Rsync.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# client::rsync Brik
#
package Metabrik::Client::Rsync;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable network) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         sync => [ qw(source destination ssh_port|OPTIONAL args|OPTIONAL) ],
      },
      attributes => {
         use_ssh => [ qw(0|1) ],
         ssh_port => [ qw(port) ],
         ssh_args => [ qw(args) ],
         args => [ qw(args) ],
      },
      attributes_default => {
         use_ssh => 1,
         ssh_port => 22,
         ssh_args => '',
         args => '-azv',
         capture_stderr => 1,
      },
      need_packages => {
         ubuntu => [ qw(rsync) ],
         debian => [ qw(rsync) ],
         kali => [ qw(rsync) ],
      },
      require_binaries => {
         rsync => [ ],
      },
   };
}

sub sync {
   my $self = shift;
   my ($source, $destination, $ssh_port, $args) = @_;

   $ssh_port ||= $self->ssh_port;
   $args ||= $self->args;
   $self->brik_help_run_undef_arg('sync', $source) or return;
   $self->brik_help_run_undef_arg('sync', $destination) or return;

   my $use_ssh = $self->use_ssh;
   my $ssh_args = $self->ssh_args;

   my $cmd = 'rsync';
   if ($use_ssh) {
      $cmd .= " -e \"ssh -p $ssh_port $ssh_args\" $args $source $destination";
   }
   else {
      $cmd .= " $args $source $destination";
   }

   return $self->capture($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Client::Rsync - client::rsync Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
