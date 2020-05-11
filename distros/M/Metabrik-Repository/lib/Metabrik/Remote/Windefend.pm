#
# $Id$
#
# remote::windefend Brik
#
package Metabrik::Remote::Windefend;
use strict;
use warnings;

use base qw(Metabrik::Remote::Winexe);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         host => [ qw(host) ],   # Inherited
         user => [ qw(username) ],   # Inherited
         password => [ qw(password) ],   # Inherited
         domain => [ qw(domain) ],   # Inherited
      },
      commands => {
         disable => [ qw(host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         enable => [ qw(host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
      },
   };
}

sub disable {
   my $self = shift;
   my ($host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_set_undef_arg('host', $host) or return;
   $self->brik_help_set_undef_arg('user', $user) or return;
   $self->brik_help_set_undef_arg('password', $password) or return;

   my $cmd = '"powershell.exe Set-MpPreference -DisableRealtimeMonitoring \$true"';

   return $self->execute_in_background($cmd);
}

sub enable {
   my $self = shift;
   my ($host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_set_undef_arg('host', $host) or return;
   $self->brik_help_set_undef_arg('user', $user) or return;
   $self->brik_help_set_undef_arg('password', $password) or return;

   my $cmd = '"powershell.exe Set-MpPreference -DisableRealtimeMonitoring \$false"';

   return $self->execute_in_background($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Remote::Windefend - remote::windefend Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
