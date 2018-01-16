#
# $Id: Modbus.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# network::modbus Brik
#
package Metabrik::Network::Modbus;
use strict;
use warnings;

use base qw(Metabrik::Client::Tcp);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
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
   $port ||= 502;
   $self->brik_help_run_undef_arg('probe', $host) or return;

   # XXX: gather nmap --script modbus-discovery -p 502 <IP>

   # To port 502/TCP (from plcscan)
   my $probe =
      "\x00\x00\x00\x00\x00\x05\x00\x2b".
      "\x0e\x01\x00";

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

Metabrik::Network::Modbus - network::modbus Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
