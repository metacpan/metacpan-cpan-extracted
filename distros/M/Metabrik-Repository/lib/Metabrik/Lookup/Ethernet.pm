#
# $Id: Ethernet.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# lookup::ethernet Brik
#
package Metabrik::Lookup::Ethernet;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         from_dec => [ qw(dec_number) ],
         from_hex => [ qw(hex_number) ],
         from_string => [ qw(ethernet_type) ],
      },
   };
}

sub _lookup {
   my $self = shift;

   my $lookup = {
      '0x0800' => 'ipv4',
      '0x0805' => 'x25',
      '0x0806' => 'arp',
      '0x2001' => 'cgmp',
      '0x2452' => '802.11',
      '0x8021' => 'pppipcp',
      '0x8035' => 'rarp',
      '0x809b' => 'ddp',
      '0x80f3' => 'aarp',
      '0x80fd' => 'pppccp',
      '0x80ff' => 'wcp',
      '0x8100' => '802.1q',
      '0x8137' => 'ipx',
      '0x8181' => 'stp',
      '0x86dd' => 'ipv6',
      '0x872d' => 'wlccp',
      '0x8847' => 'mpls',
      '0x8863' => 'pppoed',
      '0x8864' => 'pppoes',
      '0x888e' => '802.1x',
      '0x88a2' => 'aoe',
      '0x88c7' => '802.11i',
      '0x88cc' => 'lldp',
      '0x88d9' => 'lltd',
      '0x9000' => 'loop',
      '0x9100' => 'vlan',
      '0xc023' => 'ppppap',
      '0xc223' => 'pppchap',
   };

   return $lookup;
}

sub from_hex {
   my $self = shift;
   my ($hex) = @_;

   $self->brik_help_run_undef_arg('from_hex', $hex) or return;

   $hex =~ s/^0x//;
   if ($hex !~ /^[0-9a-f]+$/i) {
      return $self->log->error("from_hex: invalid format for hex [$hex]");
   }
   $hex = sprintf("0x%04s", $hex);

   return $self->_lookup->{$hex} || 'undef';
}

sub from_dec {
   my $self = shift;
   my ($dec) = @_;

   $self->brik_help_run_undef_arg('from_dec', $dec) or return;

   if ($dec !~ /^[0-9]+$/) {
      return $self->log->error("from_dec: invalid format for dec [$dec]");
   }
   my $hex = sprintf("0x%04x", $dec);

   return $self->hex($hex);
}

sub from_string {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('from_string', $string) or return;

   my $lookup = $self->_lookup;

   my $rev = {};
   while (my ($key, $val) = each(%$lookup)) {
      $rev->{$val} = $key;
   }

   return $rev->{$string} || 'undef';
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Ethernet - lookup::ethernet Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
