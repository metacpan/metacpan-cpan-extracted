#
# $Id$
#
# system::ubuntu::service Brik
#
package Metabrik::System::Ubuntu::Service;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

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
         enable => [ qw(service_name) ],
         disable => [ qw(service_name) ],
      },
      require_binaries => {
         'update-rc.d' => [ ],
      },
      #need_packages => {
         #ubuntu => [ qw() ],
         #debian => [ qw() ],
         #kali => [ qw() ],
      #},
   };
}

sub enable {
   my $self = shift;
   my ($service_name) = @_;

   $self->brik_help_run_undef_arg('enable', $service_name) or return;

   my $cmd = "update-rc.d \"$service_name\" enable";

   return $self->sudo_execute($cmd);
}

sub disable {
   my $self = shift;
   my ($service_name) = @_;

   $self->brik_help_run_undef_arg('disable', $service_name) or return;

   my $cmd = "update-rc.d \"$service_name\" disable";

   return $self->sudo_execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Ubuntu::Service - system::ubuntu::service Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
