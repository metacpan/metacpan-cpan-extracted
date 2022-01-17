#
# $Id$
#
# address::generate Brik
#
package Metabrik::Address::Generate;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable ipv4 ipv6 public routable reserved) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(directory) ],
         file_count => [ qw(integer) ],
         count => [ qw(integer) ],
      },
      attributes_default => {
         file_count => 1000,
         count => 0,
      },
      commands => {
         ipv4_reserved_ranges => [ ],
         ipv4_private_ranges => [ ],
         ipv4_public_ranges => [ ],
         ipv4_generate_space => [ qw(count|OPTIONAL file_count|OPTIONAL) ],
         ipv4_generate_space_from_subnet => [ qw(
            subnet count|OPTIONAL file_count|OPTIONAL
         ) ],
         random_ipv4_addresses => [ qw(count|OPTIONAL) ],
      },
      require_modules => {
         'BSD::Resource' => [ qw(getrlimit setrlimit) ],
         'List::Util' => [ qw(shuffle) ],
         'Metabrik::Network::Address' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $limit = 200_000;
   my $r = BSD::Resource::setrlimit(
      BSD::Resource::RLIMIT_OPEN_MAX(), $limit, $limit);
   if (! defined($r)) {
      return $self->log->error("brik_init: failed to set open file ".
         "limit to [$limit]");
   }

   return $self->SUPER::brik_init(@_);
}

#
# From zmap blacklist.conf:
#
# From IANA IPv4 Special-Purpose Address Registry
# http://www.iana.org/assignments/iana-ipv4-special-registry/iana-ipv4-special-registry.xhtml
# Updated 2013-05-22
#
# 0.0.0.0/8           # RFC1122: "This host on this network"
# 10.0.0.0/8          # RFC1918: Private-Use
# 100.64.0.0/10       # RFC6598: Shared Address Space
# 127.0.0.0/8         # RFC1122: Loopback
# 169.254.0.0/16      # RFC3927: Link Local
# 172.16.0.0/12       # RFC1918: Private-Use
# 192.0.0.0/24        # RFC6890: IETF Protocol Assignments
# 192.0.2.0/24        # RFC5737: Documentation (TEST-NET-1)
# 192.88.99.0/24      # RFC3068: 6to4 Relay Anycast
# 192.168.0.0/16      # RFC1918: Private-Use
# 198.18.0.0/15       # RFC2544: Benchmarking
# 198.51.100.0/24     # RFC5737: Documentation (TEST-NET-2)
# 203.0.113.0/24      # RFC5737: Documentation (TEST-NET-3)
# 240.0.0.0/4         # RFC1112: Reserved
# 255.255.255.255/32  # RFC0919: Limited Broadcast
#
# From IANA Multicast Address Space Registry
# http://www.iana.org/assignments/multicast-addresses/multicast-addresses.xhtml
# Updated 2013-06-25
#
# 224.0.0.0/4         # RFC5771: Multicast/Reserved
#
sub ipv4_reserved_ranges {
   my $self = shift;

   my @reserved = qw(
      0.0.0.0/8
      10.0.0.0/8
      100.64.0.0/10
      127.0.0.0/8
      169.254.0.0/16
      172.16.0.0/12
      192.0.2.0/24
      192.88.99.0/24
      192.168.0.0/16
      198.18.0.0/15
      198.51.100.0/24
      203.0.113.0/24
      224.0.0.0/4
      240.0.0.0/4
      255.255.255.255/32
   );

   return \@reserved;
}

sub ipv4_private_ranges {
   my $self = shift;

   my @private = qw(
      10.0.0.0/8
      127.0.0.0/8
      169.254.0.0/16
      172.16.0.0/12
      192.0.2.0/24
      192.168.0.0/16
   );

   return \@private;
}

sub ipv4_public_ranges {
   my $self = shift;

   # XXX: perform subnet diff from full address space and ipv4_reserved_ranges
   my $reserved = $self->ipv4_reserved_ranges;

   return 1;
}

sub ipv4_generate_space {
   my $self = shift;
   my ($count, $file_count) = @_;

   $count ||= $self->count;
   $file_count ||= $self->file_count;
   if ($file_count <= 0) {
      return $self->log->error("ipv4_generate_space: cannot generate [$file_count] file");
   }

   my $datadir = $self->datadir;
   my $n = $file_count - 1;

   my @chunks = ();
   if ($n > 0) {
      my $size = length($n);
      for (0..$n) {
         my $file = sprintf("ip4-space-%0${size}d.txt", $_);
         open(my $fd, '>', "$datadir/$file")
            or return $self->log->error("ipv4_generate_space: open: file [$datadir/$file]: $!");
         push @chunks, $fd;
      }
   }
   else {
      my $file = "ip4-space.txt";
      open(my $fd, '>', "$datadir/$file")
         or return $self->log->error("ipv4_generate_space: open: file [$datadir/$file]: $!");
      push @chunks, $fd;
   }

   my $current = 0;
   # Note: this algorithm is best suited to generate the full IPv4 address space
   for my $b4 (List::Util::shuffle(0..255)) {
      for my $b3 (List::Util::shuffle(0..255)) {
         for my $b2 (List::Util::shuffle(0..255)) {
            for my $b1 (List::Util::shuffle(1..9,11..126,128..223)) {
               # Skip:
               # 0.0.0.0/8
               # 10.0.0.0/8
               # 127.0.0.0/8
               # 224.0.0.0/4
               # 240.0.0.0/4

               next if ($b1 == 169 && $b2 == 254);               # Skip 169.254.0.0/16
               next if ($b1 == 172 && ($b2 >= 16 && $b2 <= 31)); # Skip 172.16.0.0/12
               next if ($b1 == 192 && $b2 == 168);               # Skip 192.168.0.0/16
               next if ($b1 == 192 && $b2 == 0 && $b3 == 2);     # Skip 192.0.2.0/24

               # Write randomly to one of the previously open files
               my $i;
               ($n > 0) ? ($i = int(rand($n + 1))) : ($i = 0);

               my $out = $chunks[$i];
               print $out "$b1.$b2.$b3.$b4\n";
               $current++;

               # Stop if we have the number we wanted
               if ($count && $current == $count) {
                  $self->log->info("ipv4_generate_space: generated $current IP addresses");
                  return 1;
               }
            }
         }
      }
   }

   $self->log->info("ipv4_generate_space: generated $current IP addresses");

   return 1;
}

sub ipv4_generate_space_from_subnet {
   my $self = shift;
   my ($subnet, $count, $file_count) = @_;

   $self->brik_help_run_undef_arg('ipv4_generate_space_from_subnet',
      $subnet) or return;

   $count ||= $self->count;
   $file_count ||= $self->file_count;
   if ($file_count <= 0) {
      return $self->log->error("ipv4_generate_space_from_subnet: cannot ".
         "generate [$file_count] file");
   }

   my $datadir = $self->datadir;
   my $n = $file_count - 1;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;

   # Open all file descriptors where we will write ip addresses.
   my @chunks = ();
   if ($n > 0) {
      my $size = length($n);
      for (0..$n) {
         my $file = sprintf("ip4-space-%0${size}d.txt", $_);
         open(my $fd, '>', "$datadir/$file")
            or return $self->log->error("ipv4_generate_space_from_subnet: ".
               "open: file [$datadir/$file]: $!");
         push @chunks, $fd;
      }
   }
   else {
      my $file = "ip4-space.txt";
      open(my $fd, '>', "$datadir/$file")
         or return $self->log->error("ipv4_generate_space_from_subnet: ".
            "open: file [$datadir/$file]: $!");
      push @chunks, $fd;
   }

   # Generate ip addresses from given subnet and write to open files
   # in a random order.
   my $first = $na->ipv4_first_address($subnet) or return;
   my $last = $na->ipv4_last_address($subnet) or return;

   my @bytes_first = split(/\./, $first);
   my @bytes_last = split(/\./, $last);

   my $current = 0;
   # Note: this algorithm is best suited to generate the full IPv4
   # address space
   for my $b4 (List::Util::shuffle($bytes_first[3]..$bytes_last[3])) {
      for my $b3 (List::Util::shuffle($bytes_first[2]..$bytes_last[2])) {
         for my $b2 (List::Util::shuffle($bytes_first[1]..$bytes_last[1])) {
            for my $b1 (List::Util::shuffle($bytes_first[0]..$bytes_last[0])) {
               # Write randomly to one of the previously open files
               my $i;
               ($n > 0) ? ($i = int(rand($n + 1))) : ($i = 0);

               my $out = $chunks[$i];
               print $out "$b1.$b2.$b3.$b4\n";
               $current++;

               # Stop if we have the number we wanted
               if ($count && $current == $count) {
                  $self->log->info("ipv4_generate_space_from_subnet: ".
                     "generated $current IP addresses");
                  return 1;
               }
            }
         }
      }
   }

   $self->log->info("ipv4_generate_space_from_subnet: generated ".
      "$current IP addresses");

   return 1;

}

sub random_ipv4_addresses {
   my $self = shift;
   my ($count) = @_;

   $count ||= $self->count;
   if ($count <= 0) {
      return $self->log->error("random_ipv4_addresses: cannot generate [$count] address");
   }

   my $current = 0;
   my %random = ();
   while (1) {
      my $b1 = List::Util::shuffle(1..9,11..126,128..223); # Skip 0.0.0.0/8, 224.0.0.0/4,
                                                           # 240.0.0.0/4, 10.0.0.0/8,
                                                           # 127.0.0.0/8
      my $b2 = List::Util::shuffle(0..255);
      next if ($b1 == 169 && $b2 == 254);               # Skip 169.254.0.0/16
      next if ($b1 == 172 && ($b2 >= 16 && $b2 <= 31)); # Skip 172.16.0.0/12
      next if ($b1 == 192 && $b2 == 168);               # Skip 192.168.0.0/16

      my $b3 = List::Util::shuffle(0..255);
      next if ($b1 == 192 && $b2 == 0 && $b3 == 2);  # Skip 192.0.2.0/24

      my $b4 = List::Util::shuffle(0..255);
      my $ip = "$b1.$b2.$b3.$b4";
      if (! exists($random{$ip})) {
         $random{$ip}++;
         $current++;
      }

      last if $current == $count;
   }

   return [ keys %random ];
}

1;

__END__

=head1 NAME

Metabrik::Address::Generate - address::generate Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
