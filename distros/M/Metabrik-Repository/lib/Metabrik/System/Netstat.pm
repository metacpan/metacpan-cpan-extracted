#
# $Id: Netstat.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# system::netstat Brik
#
package Metabrik::System::Netstat;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable listen) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         udp_listen => [ ],
         tcp_listen => [ ],
      },
      require_binaries => {
         'netstat', => [ ],
      },
   };
}

sub udp_listen {
   my $self = shift;

   $self->as_array(0);
   $self->as_matrix(1);
   my $lines = $self->capture("netstat -an");

   my $listen = { };
   for my $line (@$lines) {
      my $proto = $line->[0];
      if ($proto eq 'udp') {
         $proto = 'udp4'; # Rewrite for FreeBSD and uniformity
      }
      if ($proto eq 'udp4' || $line->[0] eq 'udp6') {
         my $ip_port = $line->[3];
         my ($ip, $port) = $ip_port =~ /^(.*)[:\.](\d+)$/;   # : is Linux separator, . is FreeBSD one
         $listen->{$proto}->{$ip_port} = { ip => $ip, port => $port };
      }
   }

   return $listen;
}

sub tcp_listen {
   my $self = shift;

   $self->as_array(0);
   $self->as_matrix(1);
   my $lines = $self->capture("netstat -an");

   my $listen = { };
   for my $line (@$lines) {
      my $proto = $line->[0];
      if ($proto eq 'tcp') {
         $proto = 'tcp4'; # Rewrite for FreeBSD and uniformity
      }
      if ($proto eq 'tcp4' || $proto eq 'tcp6') {
         my $ip_port = $line->[3];
         my ($ip, $port) = $ip_port =~ /^(.*)[:\.](\d+)$/;   # : is Linux separator, . is FreeBSD one
         $listen->{$proto}->{$ip_port} = { ip => $ip, port => $port };
      }
   }

   return $listen;
}

1;

__END__

=head1 NAME

Metabrik::System::Netstat - system::netstat Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
