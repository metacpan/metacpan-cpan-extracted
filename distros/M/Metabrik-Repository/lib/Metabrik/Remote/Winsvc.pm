#
# $Id$
#
# remote::winsvc Brik
#
package Metabrik::Remote::Winsvc;
use strict;
use warnings;

use base qw(Metabrik::Remote::Winexe Metabrik::Client::Smbclient);

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
         start => [ qw(service host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         stop => [ qw(service host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         restart => [ qw(service host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
      },
   };
}

sub start {
   my $self = shift;
   my ($service, $host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('start', $service) or return;
   $self->brik_help_set_undef_arg('host', $host) or return;
   $self->brik_help_set_undef_arg('user', $user) or return;
   $self->brik_help_set_undef_arg('password', $password) or return;

   my $cmd = "\"cmd.exe /c sc start $service\"";

   return $self->execute($cmd);
}

sub stop {
   my $self = shift;
   my ($service, $host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('stop', $service) or return;
   $self->brik_help_set_undef_arg('host', $host) or return;
   $self->brik_help_set_undef_arg('user', $user) or return;
   $self->brik_help_set_undef_arg('password', $password) or return;

   my $cmd = "\"cmd.exe /c sc stop $service\"";

   return $self->execute($cmd);
}

sub restart {
   my $self = shift;

   $self->stop(@_) or return;
   $self->start(@_) or return;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Remote::Sysmon - remote::sysmon Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
