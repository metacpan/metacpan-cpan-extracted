#
# $Id$
#
# network::address Brik
#
package Metabrik::Network::Address;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable netmask convert ascii) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         subnet => [ qw(subnet) ],
         _ipv4_re => [ qw(INTERNAL) ],
         _ipv6_re => [ qw(INTERNAL) ],
      },
      commands => {
         match => [ qw(ip_address subnet|OPTIONAL) ],
         network_address => [ qw(subnet|OPTIONAL) ],
         broadcast_address => [ qw(subnet|OPTIONAL) ],
         netmask_address => [ qw(subnet|OPTIONAL) ],
         netmask_to_cidr => [ qw(netmask) ],
         range_to_cidr => [ qw(first_ip_address last_ip_address) ],
         is_ipv4 => [ qw(ipv4_address) ],
         is_ipv6 => [ qw(ipv6_address) ],
         is_ip => [ qw(ip_address) ],
         is_rfc1918 => [ qw(ip_address) ],
         ipv4_list => [ qw(subnet|OPTIONAL) ],
         ipv6_list => [ qw(subnet|OPTIONAL) ],
         count_ipv4 => [ qw(subnet|OPTIONAL) ],
         count_ipv6 => [ qw(subnet|OPTIONAL) ],
         get_ipv4_cidr => [ qw(subnet|OPTIONAL) ],
         get_ipv6_cidr => [ qw(subnet|OPTIONAL) ],
         is_ipv4_subnet => [ qw(subnet|OPTIONAL) ],
         merge_cidr => [ qw($cidr_list) ],
         ipv4_to_integer => [ qw(ipv4_address) ],
         ipv6_to_integer => [ qw(ipv6_address) ],
         integer_to_ipv4 => [ qw(integer) ],
         ipv4_reserved_subnets => [ ],
         ipv6_reserved_subnets => [ ],
         is_ipv4_reserved => [ qw(ipv4_address) ],
         is_ipv6_reserved => [ qw(ipv6_address) ],
         is_ip_reserved => [ qw(ip_address) ],
         ipv6_to_string_preferred => [ qw(ipv6_address) ],
         ipv4_first_address => [ qw(ipv4_address) ],
         ipv4_last_address => [ qw(ipv4_address) ],
         ipv6_first_address => [ qw(ipv6_address) ],
         ipv6_last_address => [ qw(ipv6_address) ],
      },
      require_modules => {
         'Bit::Vector' => [ ],
         'Net::Netmask' => [ ],
         'Net::IPv4Addr' => [ ],
         'Net::IPv6Addr' => [ ],
         'IPv6::Address' => [ ],
         'NetAddr::IP' => [ ],
         'Net::CIDR' => [ ],
         'Socket' => [ ],
         'Regexp::IPv4' => [ qw($IPv4_re) ],
         'Regexp::IPv6' => [ qw($IPv6_re) ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $init = $self->SUPER::brik_init or return;

   my $ipv4_re = qr/^${Regexp::IPv4::IPv4_re}$/;
   my $ipv6_re = qr/^${Regexp::IPv6::IPv6_re}$/;

   $self->_ipv4_re($ipv4_re);
   $self->_ipv6_re($ipv6_re);

   return $init;
}

sub match {
   my $self = shift;
   my ($ip, $subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('match', $subnet) or return;

   if (! $self->is_ip($ip) || ! $self->is_ip($subnet)) {
      return $self->log->error("match: invalid format for ip [$ip] or subnet [$subnet]");
   }

   if ($self->is_ipv4($ip) && ! $self->is_ipv4($subnet)) {
      return $self->log->error("match: cannot match IPv4 [$ip] against IPv6 ".
         "subnet [$subnet]");
   }

   if ($self->is_ipv6($ip) && ! $self->is_ipv6($subnet)) {
      return $self->log->error("match: cannot match IPv6 [$ip] against IPv4 ".
         "subnet [$subnet]");
   }

   my $r;
   eval {
      $r = Net::CIDR::cidrlookup($ip, $subnet);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("match: cidrlookup failed with ".
         "ip [$ip] subnet [$subnet] with error [$@]");
   }

   if ($r) {
      $self->log->debug("match: $ip is in the same subnet as $subnet");
      return 1;
   }
   else {
      $self->log->debug("match: $ip is NOT in the same subnet as $subnet");
      return 0;
   }

   return 0;
}

sub network_address {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('network_address', $subnet) or return;

   if (! $self->is_ipv4($subnet)) {
      return $self->log->error("network_address: invalid format [$subnet], not an IPv4 address");
   }

   my ($address) = Net::IPv4Addr::ipv4_network($subnet);

   return $address;
}

sub broadcast_address {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('broadcast_address', $subnet) or return;

   if (! $self->is_ipv4($subnet)) {
      return $self->log->error("broadcast_address: invalid format [$subnet], not an IPv4 address");
   }

   my ($address) = Net::IPv4Addr::ipv4_broadcast($subnet);

   return $address;
}

sub netmask_address {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('netmask_address', $subnet) or return;

   # XXX: Not IPv6 compliant
   my $block = Net::Netmask->new($subnet);
   my $mask = $block->mask;

   return $mask;
}

sub range_to_cidr {
   my $self = shift;
   my ($first, $last) = @_;

   $self->brik_help_run_undef_arg('range_to_cidr', $first) or return;
   $self->brik_help_run_undef_arg('range_to_cidr', $last) or return;

   if ($self->is_ip($first) && $self->is_ip($last)) {
      # IPv4 and IPv6 compliant
      my @list;
      eval {
         @list = Net::CIDR::range2cidr("$first-$last");
      };
      if ($@) {
         chomp($@);
         return $self->log->error("range_to_cidr: range2cidr failed with ".
            "first [$first] last [$last] with error [$@]");
      }

      return \@list;
   }

   return $self->log->error("range_to_cidr: first [$first] or last [$last] not a valid IP address");
}

sub is_ip {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_ip', $ip) or return;

   if ($self->is_ipv4($ip) || $self->is_ipv6($ip)) {
      return 1;
   }

   return 0;
}

sub is_rfc1918 {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_rfc1918', $ip) or return;

   if (! $self->is_ipv4($ip)) {
      return $self->log->error("is_rfc1918: invalid format [$ip]");
   }

   (my $local = $ip) =~ s/\/\d+$//;

   my $new = NetAddr::IP->new($local);
   my $is;
   eval {
      $is = $new->is_rfc1918;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("is_rfc1918: is_rfc1918 failed for [$local] with error [$@]");
   }

   return $is ? 1 : 0;
}

sub is_ipv4 {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_ipv4', $ip) or return;

   (my $local = $ip) =~ s/\/\d+$//;

   my $ipv4_re = $self->_ipv4_re;

   if ($local =~ $ipv4_re) {
      return 1;
   }

   return 0;
}

sub is_ipv6 {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_ipv6', $ip) or return;

   (my $local = $ip) =~ s/\/\d+$//;

   my $ipv6_re = $self->_ipv6_re;

   if ($local =~ $ipv6_re) {
      return 1;
   }

   return 0;
}

sub netmask_to_cidr {
   my $self = shift;
   my ($netmask) = @_;

   $self->brik_help_run_undef_arg('netmask_to_cidr', $netmask) or return;

   # We use a fake address, cause we are only interested in netmask
   my $cidr;
   eval {
      $cidr = Net::CIDR::addrandmask2cidr("127.0.0.0", $netmask);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("netmask_to_cidr: addrandmask2cidr failed ".
         "with netmask [$netmask] with error [$@]");
   }

   my ($size) = $cidr =~ m{/(\d+)$};

   return $size;
}

sub ipv4_list {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('ipv4_list', $subnet) or return;

   if (! $self->is_ipv4($subnet)) {
      return $self->log->error("ipv4_list: invalid format [$subnet], not IPv4");
   }

   # This will allow handling of IPv4 /12 networks (~ 1_000_000 IP addresses)
   NetAddr::IP::netlimit(20);

   my $a = $self->network_address($subnet) or return;
   my $m = $self->netmask_address($subnet) or return;

   my $ip = NetAddr::IP->new($a, $m);
   my $r;
   eval {
      $r = $ip->hostenumref;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("ipv4_list: hostenumref failed for [$a] [$m] with error [$@]");
   }

   my @list = ();
   for my $ip (@$r) {
      push @list, $ip->addr;
   }

   return \@list;
}

sub ipv6_list {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('ipv6_list', $subnet) or return;

   if (! $self->is_ipv6($subnet)) {
      return $self->log->error("ipv6_list: invalid format [$subnet], not IPv6");
   }

   # Makes IPv6 fully lowercase
   eval("use NetAddr::IP qw(:lower);");

   # Will allow building a list of ~ 1_000_000 IP addresses
   NetAddr::IP::netlimit(20);

   my $ip = NetAddr::IP->new($subnet);
   my $r;
   eval {
      $r = $ip->hostenumref;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("ipv6_list: hostenumref failed for [$subnet] with error [$@]");
   }

   my @list = ();
   for my $ip (@$r) {
      push @list, $ip->addr;
   }

   return \@list;
}

sub get_ipv4_cidr {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('get_ipv4_cidr', $subnet) or return;

   my ($cidr) = $subnet =~ m{/(\d+)$};
   if (! defined($cidr)) {
      return $self->log->error("get_ipv4_cidr: no CIDR mask found");
   }

   if ($cidr < 0 || $cidr > 32) {
      return $self->log->error("get_ipv4_cidr: invalid CIDR mask [$cidr]");
   }

   return $cidr;
}

sub get_ipv6_cidr {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('get_ipv6_cidr', $subnet) or return;

   my ($cidr) = $subnet =~ m{/(\d+)$};
   if (! defined($cidr)) {
      return $self->log->error("get_ipv6_cidr: no CIDR mask found");
   }

   if ($cidr < 0 || $cidr > 128) {
      return $self->log->error("get_ipv6_cidr: invalid CIDR mask [$cidr]");
   }

   return $cidr;
}

sub count_ipv4 {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('count_ipv4', $subnet) or return;

   if (! $self->is_ipv4($subnet)) {
      return $self->log->error("count_ipv4: invalid format [$subnet], not IPv4");
   }

   my $cidr = $self->get_ipv4_cidr($subnet) or return;

   return 2 ** (32 - $cidr);
}

sub count_ipv6 {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('count_ipv6', $subnet) or return;

   if (! $self->is_ipv6($subnet)) {
      return $self->log->error("count_ipv6: invalid format [$subnet], not IPv6");
   }

   my $cidr = $self->get_ipv6_cidr($subnet) or return;

   return 2 ** (128 - $cidr);
}

sub is_ipv4_subnet {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   $self->brik_help_run_undef_arg('is_ipv4_subnet', $subnet) or return;

   my ($address, $cidr) = $subnet =~ m{^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d+)$};
   if (! defined($address) || ! defined($cidr)) {
      $self->log->debug("is_ipv4_subnet: not a subnet [$subnet]");
      return 0;
   }

   if ($cidr < 0 || $cidr > 32) {
      $self->log->debug("is_ipv4_subnet: not a valid CIDR mask [$cidr]");
      return 0;
   }

   return 1;
}

sub merge_cidr {
   my $self = shift;
   my ($list) = @_;

   $self->brik_help_run_undef_arg('merge_cidr', $list) or return;
   $self->brik_help_run_invalid_arg('merge_cidr', $list, 'ARRAY') or return;

   my @list;
   eval {
      @list = Net::CIDR::cidradd(@$list) or return;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("merge_cidr: cidradd failed with error [$@]");
   }

   return \@list;
}

sub ipv4_to_integer {
   my $self = shift;
   my ($ipv4_address) = @_;

   $self->brik_help_run_undef_arg('ipv4_to_integer', $ipv4_address) or return;

   if (! $self->is_ipv4($ipv4_address)) {
      return $self->log->error("ipv4_to_integer: invalid IPv4 address [$ipv4_address]");
   }

   ($ipv4_address) =~ s/\/\d+$//;  # Remove /CIDR if any

   return CORE::unpack('N', Socket::inet_aton($ipv4_address));
}

sub ipv6_to_integer {
   my $self = shift;
   my ($ipv6_address) = @_;

   $self->brik_help_run_undef_arg('ipv6_to_integer', $ipv6_address) or return;

   if (! $self->is_ipv6($ipv6_address)) {
      return $self->log->error("ipv6_to_integer: invalid IPv6 address [$ipv6_address]");
   }

   ($ipv6_address) =~ s/\/\d+$//;  # Remove /CIDR if any

   my $f = IPv6::Address->new("$ipv6_address/128")->get_bitstr;

   my ($b) = CORE::unpack('B128', $f);
   return Bit::Vector->new_Bin(128, $b)->to_Dec;
}

sub integer_to_ipv4 { 
   my $self = shift;
   my ($integer) = @_;

   $self->brik_help_run_undef_arg('integer_to_ipv4', $integer) or return;

   return Socket::inet_ntoa(pack('N', $integer));
}

#
# https://metacpan.org/source/MAXMIND/MaxMind-DB-Writer-0.202000/lib/MaxMind/DB/Writer/Tree.pm
#
sub ipv4_reserved_subnets {
   my $self = shift;

   return [ qw(
      0.0.0.0/8
      10.0.0.0/8
      100.64.0.0/10
      127.0.0.0/8
      169.254.0.0/16
      172.16.0.0/12
      192.0.0.0/29
      192.0.2.0/24
      192.88.99.0/24
      192.168.0.0/16
      198.18.0.0/15
      198.51.100.0/24
      203.0.113.0/24
      224.0.0.0/4
      240.0.0.0/4
   ) ];
}

sub ipv6_reserved_subnets {
   my $self = shift;

   return [ qw(
      0::/8
      100::/64
      2001:1::/32
      2001:2::/31
      2001:4::/30
      2001:8::/29
      2001:10::/28
      2001:20::/27
      2001:40::/26
      2001:80::/25
      2001:100::/24
      2001:db8::/32
      fc00::/7
      fe80::/10
      ff00::/8
   ) ];
}

sub is_ipv4_reserved {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_ipv4_reserved', $ip) or return;

   if (! $self->is_ipv4($ip)) {
      return $self->log->error("is_ipv4_reserved: ip[$ip] is not IPv4");
   }

   my $list = $self->ipv4_reserved_subnets;
   my $is_reserved = 0;
   for (@$list) {
      if ($self->match($ip, $_)) {
         $is_reserved = 1;
         last;
      }
   }

   return $is_reserved;
}

sub is_ipv6_reserved {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_ipv6_reserved', $ip) or return;

   if (! $self->is_ipv6($ip)) {
      return $self->log->error("is_ipv6_reserved: ip[$ip] is not IPv6");
   }

   my $list = $self->ipv6_reserved_subnets;
   my $is_reserved = 0;
   for (@$list) {
      if ($self->match($ip, $_)) {
         $is_reserved = 1;
         last;
      }
   }

   return $is_reserved;
}

sub is_ip_reserved {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('is_ip_reserved', $ip) or return;

   if (! $self->is_ip($ip)) {
      return $self->log->error("is_ip_reserved: ip[$ip] is not IPv4 nor IPv6");
   }

   my $list;
   if ($self->is_ipv4($ip)) {
      $list = $self->ipv4_reserved_subnets;
   }
   else {
      $list = $self->ipv6_reserved_subnets;
   }

   my $is_reserved = 0;
   for (@$list) {
      if ($self->match($ip, $_)) {
         $is_reserved = 1;
         last;
      }
   }

   return $is_reserved;
}

sub ipv6_to_string_preferred {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('ipv6_to_string_preferred', $ip) or return;

   if (! $self->is_ipv6($ip)) {
      return $self->log->error("ipv6_to_string_preferred: not an IPv6 address");
   }

   my $pref;
   eval {
      $pref = Net::IPv6Addr::to_string_preferred($ip);
   };
   if ($@) {
      return $self->log->error("ipv6_to_string_preferred: unable to convert IPv6 ".
         "address: [$ip]");
   }

   return $pref;
}

sub ipv4_first_address {
   my $self = shift;
   my ($ip) = @_;

   return $self->network_address($ip);
}

sub ipv4_last_address {
   my $self = shift;
   my ($ip) = @_;

   return $self->broadcast_address($ip);
}

sub ipv6_first_address {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('ipv6_first_address', $ip) or return;

   if (! $self->is_ipv6($ip)) {
      return $self->log->error("ipv6_first_address: not a valid IPv6 address: [$ip]");
   }

   my $ipv6 = IPv6::Address->new($ip);
   my $string = $ipv6->first_address->to_string;
   $string =~ s{/\d+$}{};

   return $string;
}

sub ipv6_last_address {
   my $self = shift;
   my ($ip) = @_;

   $self->brik_help_run_undef_arg('ipv6_last_address', $ip) or return;

   if (! $self->is_ipv6($ip)) {
      return $self->log->error("ipv6_last_address: not a valid IPv6 address: [$ip]");
   }

   my $ipv6 = IPv6::Address->new($ip);
   my $string = $ipv6->last_address->to_string;
   $string =~ s{/\d+$}{};

   return $string;
}

1;

__END__

=head1 NAME

Metabrik::Network::Address - network::address Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
