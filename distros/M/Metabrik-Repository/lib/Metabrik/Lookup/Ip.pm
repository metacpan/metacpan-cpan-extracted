#
# $Id$
#
# lookup::ip Brik
#
package Metabrik::Lookup::Ip;
use strict;
use warnings;

use base qw(Metabrik::Lookup::Ethernet);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable ipv4 ipv6) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         from_dec => [ qw(dec_number) ],
         from_hex => [ qw(hex_number) ],
         from_string => [ qw(ip_type) ],
      },
   };
}

sub _lookup {
   my $self = shift;

   my $lookup = {
      '0x00' => 'ipv6_hopbyhop',
      '0x01' => 'icmpv4',
      '0x02' => 'igmp',
      '0x03' => 'ggp',
      '0x04' => 'ipip',
      '0x05' => 'st',
      '0x06' => 'tcp',
      '0x07' => 'cbt',
      '0x08' => 'egp',
      '0x09' => 'igrp',
      '0x0c' => 'pup',
      '0x0d' => 'argus',
      '0x0e' => 'emcon',
      '0x0f' => 'xnet',
      '0x10' => 'chaos',
      '0x11' => 'udp',
      '0x12' => 'mux',
      '0x13' => 'dcnmeas',
      '0x14' => 'hmp',
      '0x15' => 'prm',
      '0x16' => 'idp',
      '0x17' => 'trunk1',
      '0x18' => 'trunk2',
      '0x19' => 'leaf1',
      '0x20' => 'leaf2',
      '0x21' => 'dccp',
      '0x22' => '3pc',
      '0x23' => 'idpr',
      '0x24' => 'xtp',
      '0x25' => 'ddp',
      '0x26' => 'idprcmtp',
      '0x27' => 'tpplusplus',
      '0x28' => 'il',
      '0x29' => 'ipv6',
      '0x2a' => 'sdrp',
      '0x2b' => 'ipv6_routing',
      '0x2c' => 'ipv6_fragment',
      '0x2d' => 'idrp',
      '0x2e' => 'rsvp',
      '0x2f' => 'gre',
      '0x32' => 'esp',
      '0x33' => 'ah',
      '0x3a' => 'icmpv6',
      '0x3b' => 'ipv6_nonext',
      '0x3c' => 'ipv6_destination',
      '0x58' => 'eigrp',
      '0x59' => 'ospf',
      '0x61' => 'etherip',
      '0x67' => 'pim',
      '0x70' => 'vrrp',
      '0x76' => 'stp',
      '0x84' => 'sctp',
      '0x87' => 'ipv6_mobility',
      '0x88' => 'udplite',
   };

   return $lookup;
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Ip - lookup::ip Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
