#
# $Id$
#
# network::portscan Brik
#
package Metabrik::Network::Portscan;
use strict;
use warnings;

use base qw(Metabrik::Network::Device);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable scan syn port synscan tcpscan) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         listen_device => [ qw(device) ],
         ports => [ qw(port_array) ],
         top10 => [ qw(top10_port_array) ],
         top100 => [ qw(top100_port_array) ],
         top1000 => [ qw(top1000_port_array) ],
         pps => [ qw(pps) ],
         try => [ qw(try) ],
         bandwidth => [ qw(bandwidth) ],
         wait => [ qw(seconds) ],
         use_ipv6 => [ qw(0|1) ],
         src_ip => [ qw(ip_address) ],
         filter_code_optimizer => [ qw(0|1) ],
         _nr => [ qw(INTERNAL) ],
      },
      attributes_default => { 
         top10 => [ qw(
            21 22 23 25 80 135 139 443 445 3389
         ) ],
         top100 => [ qw(
            7 9 13 21 22 23 25 26 37 53 79 80 81 88 106 110 111 113
            119 135 139 143 144 179 199 389 427 443 444 445 465 513 514
            515 543 544 548 554 587 631 646 873 990 993 995 1025 1026 1027
            1028 1029 1110 1433 1720 1723 1755 1900 2000 2001 2049 2121 2717
            3000 3128 3306 3389 3986 4899 5000 5009 5051 5060 5101 5190 5357
            5432 5631 5666 5800 5900 6000 6001 6646 7070 8000 8008 8009 8080
            8081 8443 8888 9100 9999 10000 32768 49152 49153 49154 49155
            49156 49157
         ) ],
         top1000 => [ qw(
            1 3 4 6 7 9 13 17 19 20 21 22 23 24 25 26 30 32 33 37
            42 43 49 53 70 79 80 81 82 83 84 85 88 89 90 99 100 106
            109 110 111 113 119 125 135 139 143 144 146 161 163 179 199
            211 212 222 254 255 256 259 264 280 301 306 311 340 366 389
            406 407 416 417 425 427 443 444 445 458 464 465 481 497 500
            512 513 514 515 524 541 543 544 545 548 554 555 563 587 593
            616 617 625 631 636 646 648 666 667 668 683 687 691 700 705
            711 714 720 722 726 749 765 777 783 787 800 801 808 843 873
            880 888 898 900 901 902 903 911 912 981 987 990 992 993 995
            999 1000 1001 1002 1007 1009 1010 1011 1021 1022 1023 1024 1025
            1026 1027 1028 1029 1030 1031 1032 1033 1034 1035 1036 1037 1038
            1039 1040 1041 1042 1043 1044 1045 1046 1047 1048 1049 1050 1051
            1052 1053 1054 1055 1056 1057 1058 1059 1060 1061 1062 1063 1064
            1065 1066 1067 1068 1069 1070 1071 1072 1073 1074 1075 1076 1077
            1078 1079 1080 1081 1082 1083 1084 1085 1086 1087 1088 1089 1090
            1091 1092 1093 1094 1095 1096 1097 1098 1099 1100 1102 1104 1105
            1106 1107 1108 1110 1111 1112 1113 1114 1117 1119 1121 1122 1123
            1124 1126 1130 1131 1132 1137 1138 1141 1145 1147 1148 1149 1151
            1152 1154 1163 1164 1165 1166 1169 1174 1175 1183 1185 1186 1187
            1192 1198 1199 1201 1213 1216 1217 1218 1233 1234 1236 1244 1247
            1248 1259 1271 1272 1277 1287 1296 1300 1301 1309 1310 1311 1322
            1328 1334 1352 1417 1433 1434 1443 1455 1461 1494 1500 1501 1503
            1521 1524 1533 1556 1580 1583 1594 1600 1641 1658 1666 1687 1688
            1700 1717 1718 1719 1720 1721 1723 1755 1761 1782 1783 1801 1805
            1812 1839 1840 1862 1863 1864 1875 1900 1914 1935 1947 1971 1972
            1974 1984 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008
            2009 2010 2013 2020 2021 2022 2030 2033 2034 2035 2038 2040 2041
            2042 2043 2045 2046 2047 2048 2049 2065 2068 2099 2100 2103 2105
            2106 2107 2111 2119 2121 2126 2135 2144 2160 2161 2170 2179 2190
            2191 2196 2200 2222 2251 2260 2288 2301 2323 2366 2381 2382 2383
            2393 2394 2399 2401 2492 2500 2522 2525 2557 2601 2602 2604 2605
            2607 2608 2638 2701 2702 2710 2717 2718 2725 2800 2809 2811 2869
            2875 2909 2910 2920 2967 2968 2998 3000 3001 3003 3005 3006 3007
            3011 3013 3017 3030 3031 3050 3052 3071 3077 3128 3168 3211 3221
            3260 3261 3268 3269 3283 3300 3301 3306 3322 3323 3324 3325 3333
            3351 3367 3369 3370 3371 3372 3389 3390 3404 3476 3493 3517 3527
            3546 3551 3580 3659 3689 3690 3703 3737 3766 3784 3800 3801 3809
            3814 3826 3827 3828 3851 3869 3871 3878 3880 3889 3905 3914 3918
            3920 3945 3971 3986 3995 3998 4000 4001 4002 4003 4004 4005 4006
            4045 4111 4125 4126 4129 4224 4242 4279 4321 4343 4443 4444 4445
            4446 4449 4550 4567 4662 4848 4899 4900 4998 5000 5001 5002 5003
            5004 5009 5030 5033 5050 5051 5054 5060 5061 5080 5087 5100 5101
            5102 5120 5190 5200 5214 5221 5222 5225 5226 5269 5280 5298 5357
            5405 5414 5431 5432 5440 5500 5510 5544 5550 5555 5560 5566 5631
            5633 5666 5678 5679 5718 5730 5800 5801 5802 5810 5811 5815 5822
            5825 5850 5859 5862 5877 5900 5901 5902 5903 5904 5906 5907 5910
            5911 5915 5922 5925 5950 5952 5959 5960 5961 5962 5963 5987 5988
            5989 5998 5999 6000 6001 6002 6003 6004 6005 6006 6007 6009 6025
            6059 6100 6101 6106 6112 6123 6129 6156 6346 6389 6502 6510 6543
            6547 6565 6566 6567 6580 6646 6666 6667 6668 6669 6689 6692 6699
            6779 6788 6789 6792 6839 6881 6901 6969 7000 7001 7002 7004 7007
            7019 7025 7070 7100 7103 7106 7200 7201 7402 7435 7443 7496 7512
            7625 7627 7676 7741 7777 7778 7800 7911 7920 7921 7937 7938 7999
            8000 8001 8002 8007 8008 8009 8010 8011 8021 8022 8031 8042 8045
            8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 8090 8093 8099
            8100 8180 8181 8192 8193 8194 8200 8222 8254 8290 8291 8292 8300
            8333 8383 8400 8402 8443 8500 8600 8649 8651 8652 8654 8701 8800
            8873 8888 8899 8994 9000 9001 9002 9003 9009 9010 9011 9040 9050
            9071 9080 9081 9090 9091 9099 9100 9101 9102 9103 9110 9111 9200
            9207 9220 9290 9415 9418 9485 9500 9502 9503 9535 9575 9593 9594
            9595 9618 9666 9876 9877 9878 9898 9900 9917 9943 9944 9968 9998
            9999 10000 10001 10002 10003 10004 10009 10010 10012 10024 10025
            10082 10180 10215 10243 10566 10616 10617 10621 10626 10628 10629
            10778 11110 11111 11967 12000 12174 12265 12345 13456 13722 13782
            13783 14000 14238 14441 14442 15000 15002 15003 15004 15660 15742
            16000 16001 16012 16016 16018 16080 16113 16992 16993 17877 17988
            18040 18101 18988 19101 19283 19315 19350 19780 19801 19842 20000
            20005 20031 20221 20222 20828 21571 22939 23502 24444 24800 25734
            25735 26214 27000 27352 27353 27355 27356 27715 28201 30000 30718
            30951 31038 31337 32768 32769 32770 32771 32772 32773 32774 32775
            32776 32777 32778 32779 32780 32781 32782 32783 32784 32785 33354
            33899 34571 34572 34573 35500 38292 40193 40911 41511 42510 44176
            44442 44443 44501 45100 48080 49152 49153 49154 49155 49156 49157
            49158 49159 49160 49161 49163 49165 49167 49175 49176 49400 49999
            50000 50001 50002 50003 50006 50300 50389 50500 50636 50800 51103
            51493 52673 52822 52848 52869 54045 54328 55055 55056 55555 55600
            56737 56738 57294 57797 58080 60020 60443 61532 61900 62078 63331
            64623 64680 65000 65129 65389
         ) ],
         pps => 10_000,
         try => 2,
         wait => 5, # Wait 5 seconds for last packet
         use_ipv6 => 0,
         filter_code_optimizer => 0,
      },
      commands => {
         estimate_runtime => [ qw($ip_list $port_list|OPTIONAL pps|OPTIONAL try|OPTIONAL) ],
         estimate_bandwidth => [ qw(pps|OPTIONAL size|OPTIONAL) ],
         estimate_pps => [ qw(bandwidth|OPTIONAL size|OPTIONAL) ],
         tcp_syn_sender => [ qw($ip_list $port_list|OPTIONAL pps|OPTIONAL try|OPTIONAL) ],
         tcp_syn_start_receiver => [ qw($port_list|OPTIONAL filter|OPTIONAL listen_device|OPTIONAL) ],
         tcp_syn_stop_receiver => [ ],
         tcp_syn_scan => [ qw($ip_list $port_list|OPTIONAL pps|OPTIONAL try|OPTIONAL) ],
         tcp_syn_receive_until_sender_exit => [ qw(pid pps|OPTIONAL wait|OPTIONAL use_ipv6|OPTIONAL) ],
      },
      require_modules => {
         'Net::Write::Fast' => [ ],
         'Net::Frame::Simple' => [ ],
         'POSIX' => [ qw(ceil) ],
         'Metabrik::Network::Address' => [ ],
         'Metabrik::Network::Read' => [ ],
         'Metabrik::System::Process' => [ ],
         'Metabrik::Worker::Fork' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => defined($self->global) && $self->global->device || 'eth0',
         listen_device => defined($self->global) && $self->global->device || 'eth0',
      },
   };
}

sub estimate_runtime {
   my $self = shift;
   my ($ip_list, $port_list, $pps, $try) = @_;

   $port_list ||= $self->ports || $self->top100;
   $pps ||= $self->pps;
   $try ||= $self->try;
   $self->brik_help_run_undef_arg('estimate_runtime', $ip_list) or return;
   $self->brik_help_run_undef_arg('estimate_runtime', $port_list) or return;

   my $runtime = Net::Write::Fast::estimate_runtime({
      targets => $ip_list,
      ports => $port_list,
      pps => $pps,
      try => $try,
   }) or return $self->log->error('estimate_runtime: failed');

   return $runtime;
}


sub estimate_bandwidth {
   my $self = shift;
   my ($pps, $size) = @_;

   $pps ||= $self->pps;
   #$size ||= 74; # Ethernet (14) + IP (20), + TCP (20) + TCP options (20)
   $size ||= 60; # IP (20), + TCP (20) + TCP options (20)

   my $count = $pps * $size;

   if (length($pps) > 8) {
      $count /= 1_000_000_000;
      return "${count}G";
   }
   elsif (length($pps) > 5) {
      $count /= 1_000_000;
      return "${count}M";
   }
   elsif (length($pps) > 2) {
      $count /= 1_000;
      return "${count}K";
   }

   return "${count}B";
}

sub estimate_pps {
   my $self = shift;
   my ($bandwidth, $size) = @_;

   $bandwidth ||= $self->bandwidth;
   #$size ||= 74; # Ethernet (14) + IP (20), + TCP (20) + TCP options (20)
   $size ||= 60; # IP (20), + TCP (20) + TCP options (20)

   my $count = 0;
   if ($bandwidth =~ m{B$}) {
      $bandwidth =~ s/.$//;
      $count = $bandwidth;
   }
   elsif ($bandwidth =~ m{K$}) {
      $bandwidth =~ s/.$//;
      $count = $bandwidth * 1_000;
   }
   elsif ($bandwidth =~ m{M$}) {
      $bandwidth =~ s/.$//;
      $count = $bandwidth * 1_000_000;
   }
   elsif ($bandwidth =~ m{G$}) {
      $bandwidth =~ s/.$//;
      $count = $bandwidth * 1_000_000_000;
   }

   return $count / $size;
}

sub tcp_syn_sender {
   my $self = shift;
   my ($ip_list, $port_list, $pps, $try) = @_;

   $port_list ||= $self->ports || $self->top100;
   $pps ||= $self->pps;
   $try ||= $self->try;
   $self->brik_help_run_undef_arg('tcp_syn_sender', $ip_list) or return;
   $self->brik_help_run_invalid_arg('tcp_syn_sender', $ip_list, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('tcp_syn_sender', $ip_list, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('tcp_syn_sender', $port_list) or return;
   $self->brik_help_run_invalid_arg('tcp_syn_sender', $port_list, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('tcp_syn_sender', $port_list, 'ARRAY') or return;

   my $device = $self->device;
   my $use_ipv6 = $self->use_ipv6;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;

   # Set source IP address.
   my $ip4;
   my $ip6;
   if ($use_ipv6) {
      $ip6 = defined($self->src_ip) ? $self->src_ip : $self->my_ipv6;
      if (! defined($ip6)) {
         return $self->log->error("tcp_syn_sender: IPv6 not found for device [$device]");
      }
   }
   else {
      $ip4 = defined($self->src_ip) ? $self->src_ip : $self->my_ipv4;
      if (! defined($ip4)) {
         return $self->log->error("tcp_syn_sender: IPv4 not found for device [$device]");
      }
   }

   my $ip = $ip_list->[0];
   if ($self->use_ipv6) {
      if (! $na->is_ipv6($ip)) {
         return $self->log->error("tcp_syn_sender: address [$ip] is not IPv6 in ip_list");
      }
      $self->log->verbose("tcp_syn_sender: using source IPv6 [$ip6]");
   }
   else {
      if (! $na->is_ipv4($ip)) {
         return $self->log->error("tcp_syn_sender: address [$ip] is not IPv4 in ip_list");
      }
      $self->log->verbose("tcp_syn_sender: using source IPv4 [$ip4]");
   }

   $self->log->verbose("tcp_syn_sender: sender started");

   # We have to split by chunks of $chunk_size elements, to avoid taking to
   # much memory in one row. And there is a SIGSEGV if we don't do so ;)
   my $chunk_size = 1_000_000; # We can load that much into a ARRAYREF before a SIGSEGV
   my $n_targets = scalar(@$ip_list);
   my $n_ports = scalar(@$port_list);
   my $n_chunks = POSIX::ceil($n_targets / $chunk_size);
   for my $n (0..$n_chunks-1) {
      my $first = $chunk_size * $n;
      my $last = ($chunk_size - 1) + ($chunk_size * $n);
      if ($last > ($n_targets - 1)) {
         $last = $n_targets - 1;
      }

      # By default, we think we scan less than $chunk_size hosts
      my $target_list = $ip_list;

      # But if we don't, we cut in chunks and $target_list gets a slice
      if ($n_chunks > 1) {
         my @this = @$ip_list[$first..$last];
         $target_list = \@this;
         $self->log->verbose("tcp_syn_sender: scanning chunk @{[$n+1]}/@{[($n_chunks)]} ".
            "($first-$last)");
      }

      my $r = Net::Write::Fast::l4_send_tcp_syn_multi(
         $use_ipv6 ? $ip6 : $ip4,
         $target_list,
         $port_list,
         $pps,
         $try,
         $use_ipv6,
         1,  # display warnings or not
      );
      if ($r == 0) {
         $self->log->error("tcp_syn_sender: l4_send_tcp_syn_multi: ".
            Net::Write::Fast::nwf_geterror());
      }
   }

   $self->log->verbose("tcp_syn_sender: sender finished");

   # We return the number of packets sent
   return $n_targets * $n_ports;
}

sub tcp_syn_start_receiver {
   my $self = shift;
   my ($port_list, $filter, $listen_device) = @_;

   if (defined($port_list)) {
      $self->brik_help_run_invalid_arg('tcp_syn_start_receiver', $port_list, 'ARRAY')
         or return;
      $self->brik_help_run_empty_array_arg('tcp_syn_start_receiver', $port_list)
         or return;
   }

   $listen_device ||= $self->listen_device;

   my $nr = Metabrik::Network::Read->new_from_brik_init($self) or return;
   $nr->filter_code_optimizer($self->filter_code_optimizer);

   my $ip = '';
   if ($self->use_ipv6) {
      $ip = (defined($self->src_ip) ? $self->src_ip : $self->my_ipv6) or return;
   }
   else {
      $ip = (defined($self->src_ip) ? $self->src_ip : $self->my_ipv4) or return;
   }

   if (defined($port_list)) {
      $self->log->verbose("tcp_syn_start_receiver: scanning for ".scalar(@$port_list).
         " port(s)");
   }
    
   # Create a filter if not provided by user
   if (! defined($filter)) {
      $filter = $self->use_ipv6
         ? 'tcp and (ip6 and dst host '.$ip.')'
         : 'tcp and (((tcp[13] & 2 != 0) and (tcp[13] & 16 != 0) and dst host '.$ip.')'.
           ' or '.
           '((tcp[13] & 4 != 0) and (tcp[13] & 16 != 0) and dst host '.$ip.'))';

      # If only a few ports specified, we use that in the filter
      if (defined($port_list) && @$port_list <= 10) {
         $filter .= " and (";
         for (@$port_list) {
            $filter .= "src port $_ or ";
         }
         $filter =~ s/ or $/)/;
      }
   }

   $nr->filter($filter);
   $nr->device($listen_device);

   $self->log->verbose("tcp_syn_start_receiver: using filter [$filter] and ".
      "device [$listen_device]");

   $nr->open or return;
 
   return $self->_nr($nr);
}

sub tcp_syn_stop_receiver {
   my $self = shift;

   my $nr = $self->_nr;
   if (! defined($nr)) {
      return 1;
   }

   $self->log->debug("tcp_syn_stop_receiver: closing nr...");
   $nr->close;
   $self->_nr(undef);
   $self->log->debug("tcp_syn_stop_receiver: closing nr...done");

   return 1;
}

sub tcp_syn_receive_until_sender_exit {
   my $self = shift;
   my ($pid, $pps, $wait, $use_ipv6) = @_;

   $pps ||= $self->pps;
   $wait ||= $self->wait;
   my $nr = $self->_nr;
   $use_ipv6 = 0;
   $self->brik_help_run_undef_arg('tcp_syn_receive_until_sender_exit', $pid) or return;
   $self->brik_help_run_undef_arg('tcp_syn_receive_until_sender_exit', $pps) or return;
   $self->brik_help_run_undef_arg('tcp_syn_receive_until_sender_exit', $wait) or return;
   $self->brik_help_run_undef_arg('tcp_syn_start_receiver', $nr) or return;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;

   my %open;
   my %closed;
   while (! $nr->has_timeout) {
      # We blocking until X frames are read or a Y second timeout has occured
      # X is calcluted as a ratio of the pps rate.
      $self->log->debug("tcp_syn_receive_until_sender_exit: waiting stuff");
      if (my $next = $nr->read_until_timeout($pps / 30, $wait)) {  
         $self->log->debug("tcp_syn_receive_until_sender_exit: read_until_timeout has stuff");
         for my $f (@$next) {
            my $s = Net::Frame::Simple->newFromDump($f);
            if ($s->ref->{TCP}) {
               my $ip  = $use_ipv6 ? $s->ref->{IPv6} : $s->ref->{IPv4};
               my $tcp = $s->ref->{TCP};
               if ($tcp->flags == 0x12) { # SYN+ACK
                  $open{$ip->src}{$tcp->src} = {
                     ip => $ip->src,
                     port => $tcp->src,
                     id => $use_ipv6 ? $ip->flowLabel : $ip->id,
                     ttl => $use_ipv6 ? $ip->hopLimit : $ip->ttl,
                     win => $tcp->win,
                     opt => unpack('H*', $tcp->options),
                     flags => 'SA',
                  };
                  $self->log->debug("tcp_syn_receive_until_sender_exit: ".sprintf(
                     "tcp  %s  [%-15s]:%-5d   %-5d  %-3d  %-5d  %s",
                        $open{$ip->src}{$tcp->src}->{flags},
                        $ip->src,
                        $tcp->src,
                        $open{$ip->src}{$tcp->src}->{id},
                        $open{$ip->src}{$tcp->src}->{ttl},
                        $open{$ip->src}{$tcp->src}->{win},
                        $open{$ip->src}{$tcp->src}->{opt},
                     ),
                  );
               }
               elsif ($tcp->flags == 0x14) { # RST+ACK
                  $closed{$ip->src}{$tcp->src} = {
                     ip => $ip->src,
                     port => $tcp->src,
                     id => $use_ipv6 ? $ip->flowLabel : $ip->id,
                     ttl => $use_ipv6 ? $ip->hopLimit  : $ip->ttl,
                     win => $tcp->win,
                     opt => unpack('H*', $tcp->options),
                     flags => 'RA',
                  };
               }
            }
         }
         if ($nr->has_timeout) {
            $self->log->debug("tcp_syn_receive_until_sender_exit: has_timeout");
            if (! $sp->is_running($pid)) {
               $self->log->verbose("tcp_syn_receive_until_sender_exit: no more sender, stopping loop");
               last;
            }
            $self->log->debug("tcp_syn_receive_until_sender_exit: reset_timeout");
            $nr->reset_timeout;
         }
      }
   }

   return { open => \%open, closed => \%closed };
}

sub tcp_syn_scan {
   my $self = shift;
   my ($ip_list, $port_list, $pps, $try) = @_;

   $port_list ||= $self->ports;
   $port_list ||= $self->top100;
   $pps ||= $self->pps;
   $try ||= $self->try;
   $self->brik_help_run_undef_arg('tcp_syn_scan', $ip_list) or return;
   my $ref1 = $self->brik_help_run_invalid_arg('tcp_syn_scan', $ip_list, 'ARRAY', 'SCALAR')
      or return;
   if ($ref1 eq 'SCALAR') {
      $ip_list = [ $ip_list ];
   }
   $self->brik_help_run_empty_array_arg('tcp_syn_scan', $ip_list) or return;
   $self->brik_help_run_undef_arg('tcp_syn_scan', $port_list, 'ARRAY') or return;
   my $ref2 = $self->brik_help_run_invalid_arg('tcp_syn_scan', $port_list, 'ARRAY', 'SCALAR')
      or return;
   if ($ref2 eq 'SCALAR') {
      $port_list = [ $port_list ]; 
   }
   $self->brik_help_run_empty_array_arg('tcp_syn_scan', $port_list) or return;

   my $wait = $self->wait;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;

   my $nr = $self->tcp_syn_start_receiver($port_list) or return;

   my $estimate = $self->estimate_runtime($ip_list, $port_list, $pps, $try);
   if (defined($estimate)) {
      my $string = sprintf(
         "Estimated runtime: %d day(s) %d hour(s) %d minute(s) %d second(s) for %d host(s)",
         $estimate->{days},
         $estimate->{hours},
         $estimate->{minutes},
         $estimate->{seconds},
         $estimate->{nhosts},
      );
      $self->log->verbose("tcp_syn_scan: $string");
   }

   my $start = time();

   # Fork sender process
   my $wf = Metabrik::Worker::Fork->new_from_brik_init($self) or return;
   defined(my $pid = $wf->start) or return $self->log->error("tcp_syn_scan: start failed");

   if (! $pid) { # Son
      $self->log->debug("tcp_syn_scan: son starts its task...");
      $self->tcp_syn_sender($ip_list, $port_list, $pps, $try);
      $self->log->debug("tcp_syn_scan: son finished its task, exiting");
      exit(0);
   }

   my $use_ipv6 = $na->is_ipv6($ip_list->[0]) ? 1 : 0;

   # Father: analyse received frames
   $self->log->debug("tcp_syn_scan: father starts");
   my $r = $self->tcp_syn_receive_until_sender_exit($pid, $pps, $wait, $use_ipv6);
   $self->log->debug("tcp_syn_scan: father finished");
   
   $self->tcp_syn_stop_receiver($nr);

   $self->log->verbose("tcp_syn_scan: completed in ".(time() - $start)." second(s)");

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Network::Portscan - network::portscan Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
