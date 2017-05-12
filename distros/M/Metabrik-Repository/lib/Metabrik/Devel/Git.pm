#
# $Id: Git.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# devel::git Brik
#
package Metabrik::Devel::Git;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         capture_mode => [ qw(0|1) ],
         use_sudo => [ qw(0|1) ],
         use_pager => [ qw(0|1) ],
      },
      attributes_default => {
         capture_mode => 0,
         use_sudo => 0,
         use_pager => 1,
      },
      commands => {
         install => [ ], # Inherited
         clone => [ qw(repository directory|OPTIONAL) ],
         update => [ qw(repository directory|OPTIONAL) ],
      },
      require_binaries => {
         git => [ ],
      },
      need_packages => {
         ubuntu => [ qw(git) ],
         debian => [ qw(git) ],
      },
   };
}

sub clone {
   my $self = shift;
   my ($repository, $directory) = @_;

   $self->brik_help_run_undef_arg('clone', $repository) or return;

   if (! defined($directory)) {
      my $datadir = $self->datadir;

      $directory ||= $datadir;
      my ($name) = $repository =~ m{^.*/(.*)$};
      $directory .= '/'.$name;
   }

   my $cmd = "git clone $repository $directory";

   $self->execute($cmd) or return;

   return $directory;
}

sub update {
   my $self = shift;
   my ($repository, $directory) = @_;

   $self->brik_help_run_undef_arg('update', $repository) or return;

   if (! defined($directory)) {
      my $datadir = $self->datadir;

      $directory ||= $datadir;
      my ($name) = $repository =~ m{^.*/(.*)$};
      $directory .= '/'.$name;
   }

   my $cmd = "git pull -u $repository $directory";

   $self->execute($cmd) or return;

   return $directory;
}

1;

__END__

=head1 NAME

Metabrik::Devel::Git - devel::git Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
