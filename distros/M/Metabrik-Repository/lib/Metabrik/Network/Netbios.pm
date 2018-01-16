#
# $Id: Netbios.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# network::netbios Brik
#
package Metabrik::Network::Netbios;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         probe => [ qw(ipv4_address) ],
      },
      require_modules => {
         'Net::NBName' => [ ],
      },
   };
}

sub probe {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('probe', $ip) or return;

   my $nb = Net::NBName->new;
   if (! $nb) {
      return $self->log->error("probe: Net::NBName new failed");
   }

   my %result = ();

   my $ns = $nb->node_status($ip);
   if ($ns) {
      my ($domain, $user, $machine);
      for my $rr ($ns->names) {
         if ($rr->suffix == 0 && $rr->G eq "GROUP") {
            $domain = $rr->name;
         }
         if ($rr->suffix == 3 && $rr->G eq "UNIQUE") {
            $user = $rr->name;
         }
         if ($rr->suffix == 0 && $rr->G eq "UNIQUE") {
            $machine = $rr->name unless $rr->name =~ /^IS~/;
         }
      }

      $result{mac} = $ns->mac_address;
      $result{domain} = $domain;
      $result{user} = $user;
      $result{machine} = $machine;

      my $raw = $ns->as_string;
      $result{raw} = [ split(/\n/, $raw) ];
   }

   return \%result;
}

1;

__END__

=head1 NAME

Metabrik::Network::Netbios - network::netbios Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
