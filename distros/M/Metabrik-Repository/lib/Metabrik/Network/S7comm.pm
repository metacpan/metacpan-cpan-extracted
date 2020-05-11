#
# $Id$
#
# network::s7comm Brik
#
package Metabrik::Network::S7comm;
use strict;
use warnings;

use base qw(Metabrik::Client::Tcp);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         probe => [ qw(host port|OPTIONAL) ],
      },
   };
}

sub probe {
   my $self = shift;
   my ($host, $port) = @_;

   $host ||= $self->host;
   $port ||= 102;
   $self->brik_help_run_undef_arg('probe', $host) or return;

   # To port 102/TCP (from plcscan)
   my $probe =
      "\x03\x00\x00\x16\x11\xe0\x00\x00".
      "\x00\x0b\x00\xc1\x02\x01\x00\xc2".
      "\x02\x01\x02\xc0\x01\x0a";

   $self->host($host);
   $self->port($port);
   $self->connect or return;
   $self->write($probe) or return;
   my $response = $self->read or return;
   $self->disconnect;

   return $response;
}

1;

__END__

=head1 NAME

Metabrik::Network::S7comm - network::s7comm Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
