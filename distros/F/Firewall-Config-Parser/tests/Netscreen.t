#!/usr/bin/env perl
use strict;
use warnings;
use 5.018;
use Test::Simple tests => 17;
use Mojo::Util qw(dumper);

use Firewall::Config::Content::Static;
use Firewall::Config::Parser::Netscreen;
use Firewall::Config::Parser::Elements;

my $preDefinedService = {
  'aol' => Firewall::Config::Element::Service::Netscreen->new(
    fwId     => 1,
    srvName  => 'aol',
    protocol => 'tcp',
    srcPort  => '0-65535',
    dstPort  => '5190-5194'
  ),
  'apple-ichat-snatmap' => Firewall::Config::Element::Service::Netscreen->new(
    fwId     => 1,
    srvName  => 'apple-ichat-snatmap',
    protocol => 'udp',
    srcPort  => '0-65535',
    dstPort  => '5678'
  ),
};

my $parser = Firewall::Config::Parser::Netscreen->new(
  config => Firewall::Config::Content::Static->new(
    config => [],
    fwId   => 1,
    fwName => 'lala',
    fwType => 'Netscreen'
  ),
  preDefinedService => $preDefinedService
);
my $config;

testParse: {
  ok(
    do {
      my ( $fwId1, $fwId2 ) = ( 4, 7 );
      $parser = Firewall::Config::Parser::Netscreen->new(
        config => Firewall::Config::Content::Static->new(
          config => [],
          fwId   => $fwId1,
          fwName => 'lala',
          fwType => 'Netscreen'
        ),
        preDefinedService => $preDefinedService
      );
      my $oldFwId = $parser->fwId;
      $parser->parse(
        Firewall::Config::Content::Static->new(
          config => ["lala"],
          fwId   => $fwId2,
          fwName => 'lala',
          fwType => 'Netscreen'
        )
      );
      my $newFwId = $parser->fwId;
      $oldFwId == $fwId1 and $newFwId == $fwId2;
    },
    ' parse 方法'
  );
}

=cut
testStaticNat: {
    my $string = qq{set interface "ethernet0/0" mip 10.37.172.25 host 192.168.184.25 netmask 255.255.255.255 vr "trust-vr"\n};
    ok(
        do {
            $parser->isStaticNat($string) == 1 ? 1 : 0;
        },
        ' isStaticNat 方法');

    ok(
        do {
            eval {
                $parser->{elements} = new Firewall::Config::Parser::Elements;
                $parser->{config} = Firewall::Config::Content::Static->new( config => [$string], fwId => 1, fwName => 'lala', fwType => 'Netscreen');
            };
            warn $@ if $@;
            $parser->parseStaticNat($parser->nextUnParsedLine);
            $parser->elements->{staticNat}{'10.37.172.25'}->interface eq 'ethernet0/0'
                and $parser->elements->{staticNat}{'10.37.172.25'}->ip eq '10.37.172.25'
                and $parser->elements->{staticNat}{'10.37.172.25'}->natIp eq '192.168.184.25'
                and $parser->elements->{staticNat}{'10.37.172.25'}->natMask eq '255.255.255.255'
        },
        ' parseStaticNat 方法');
}


testDynamicNat: {
    my $string = qq{set interface ethernet0/2 ext ip 10.49.248.1 255.255.255.255 dip 10 10.49.248.1 10.49.248.1\n};
    ok(
        do {
            $parser->isDynamicNat($string) == 1 ? 1 : 0;
        },
        ' isDynamicNat 方法');

    $string = <<_STRING_;
set interface ethernet0/2.3 dip 19 145.144.64.35 145.144.64.35
set interface ethernet0/2 ext ip 10.49.248.1 255.255.255.255 dip 10 10.49.248.1 10.49.248.1
_STRING_

    ok(
        do {
            eval {
                $parser->{elements} = new Firewall::Config::Parser::Elements;
                $parser->{config} = Firewall::Config::Content::Static->new( config => [map {"$_\n"} split(/\n/, $string)], fwId => 1, fwName => 'lala', fwType => 'Netscreen');
            };
            warn $@ if $@;
            while(my $lala = $parser->nextUnParsedLine) {
                $parser->parseDynamicNat($lala);
            }
            $parser->elements->{dynamicNat}{'19'}->id eq '19'
                and $parser->elements->{dynamicNat}{'19'}->interface eq 'ethernet0/2.3'
                and $parser->elements->{dynamicNat}{'19'}->minIp eq '145.144.64.35'
                and $parser->elements->{dynamicNat}{'19'}->maxIp eq '145.144.64.35'
                and $parser->elements->{dynamicNat}{'19'}->range->min == 2442149923
                and $parser->elements->{dynamicNat}{'19'}->range->max == 2442149923
                and $parser->elements->{dynamicNat}{'10'}->extIp eq '10.49.248.1'
                and $parser->elements->{dynamicNat}{'10'}->extMask eq '255.255.255.255'
        },
        ' parseDynamicNat 方法');

}
=cut

testRoute: {
  my $string = qq{set route source 10.88.138.41/32 interface ethernet0/2.1 gateway 113.140.11.129\n};
  ok(
    do {
      $parser->isRoute($string) == 1 ? 1 : 0;
    },
    ' isRoute 方法'
  );

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [$string],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Netscreen'
        );
      };
      warn $@ if $@;
      $parser->parseRoute( $parser->nextUnParsedLine );
      say dumper $parser->elements;
    },
    ' parserRoute 方法'
  );
}

testAddress: {
  my $string = qq{set address "V1-Untrust" "Host_10.29.38.10" 10.29.38.10 255.255.255.255 "hsh-1219"\n};
  ok(
    do {
      $parser->isAddress($string) == 1 ? 1 : 0;
    },
    ' isAddress 方法'
  );

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [$string],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Netscreen'
        );
      };
      warn $@ if $@;
      $parser->parseAddress( $parser->nextUnParsedLine );
            $parser->elements->{address}{'V1-Untrust<|>Host_10.29.38.10'}->ip eq '10.29.38.10'
        and $parser->elements->{address}{'V1-Untrust<|>Host_10.29.38.10'}->mask eq '255.255.255.255'
        and $parser->elements->{address}{'V1-Untrust<|>Host_10.29.38.10'}->description eq 'hsh-1219'
        and $parser->elements->{address}{'V1-Untrust<|>Host_10.29.38.10'}->addrName eq 'Host_10.29.38.10'
        and $parser->elements->{address}{'V1-Untrust<|>Host_10.29.38.10'}->range->min == 169682442
        and $parser->elements->{address}{'V1-Untrust<|>Host_10.29.38.10'}->range->max == 169682442
        and $parser->getAddress( 'V1-Untrust', 'Host_10.29.38.10' );
    },
    ' parseAddress 方法'
  );
}

testAddressGroup: {
  my $string = qq{set group address "V1-Trust" "g_cache_server" comment " "\n};
  ok(
    do {
      $parser->isAddressGroup($string) == 1 ? 1 : 0;
    },
    ' isAddressGroup 方法'
  );
  $string = <<_STRING_;
set group address "V1-Trust" "A_LINUX_DNS_2012" comment " "
set group address "V1-Trust" "A_LINUX_DNS_2012" add "H_10.31.120.1"
set group address "V1-Trust" "A_LINUX_DNS_2012" add "H_10.31.120.2"
_STRING_
  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Netscreen'
        );
        my $address = Firewall::Config::Element::Address::Netscreen->new(
          fwId     => 1,
          addrName => 'H_10.31.120.1',
          ip       => '10.31.120.1',
          mask     => '255.255.255.255',
          zone     => 'V1-Trust'
        );
        $parser->elements->{address}{ $address->sign } = $address;
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseAddressGroup($lala);
      }
      $parser->elements->{addressGroup}{'V1-Trust<|>A_LINUX_DNS_2012'}->description eq ' '
        and exists $parser->elements->{addressGroup}{'V1-Trust<|>A_LINUX_DNS_2012'}->addrGroupMembers->{'H_10.31.120.1'}
        and exists $parser->elements->{addressGroup}{'V1-Trust<|>A_LINUX_DNS_2012'}->addrGroupMembers->{'H_10.31.120.2'}
        and $parser->elements->{addressGroup}{'V1-Trust<|>A_LINUX_DNS_2012'}->addrGroupName eq 'A_LINUX_DNS_2012'
        and $parser->elements->{addressGroup}{'V1-Trust<|>A_LINUX_DNS_2012'}->range->min == 169834497
        and $parser->elements->{addressGroup}{'V1-Trust<|>A_LINUX_DNS_2012'}->range->max == 169834497
        and $parser->getAddressGroup( 'V1-Trust', 'A_LINUX_DNS_2012' );
    },
    ' parseAddressGroup 方法'
  );

}

testService: {
  my $string = qq{set service "TCP/UDP_42430" protocol tcp src-port 0-65535 dst-port 42430-42430\n};
  ok(
    do {
      $parser->isService($string) == 1 ? 1 : 0;
    },
    ' isService 方法'
  );

  $string = <<_STRING_;
set service "TCP/UDP_42430" protocol tcp src-port 0-65535 dst-port 42430-42430 timeout 720 
set service "TCP/UDP_42430" + udp src-port 0-65535 dst-port 42430-42430 
set service "TCP/UDP_42430" timeout never
set service "TCP/UDP_42431" + tcp src-port 0-65535 dst-port 42431-42431
set service "TCP/UDP_42431" timeout never
set service "my-sunrpc-nfs" protocol sun-rpc program 100003-100003 
set service "my-sunrpc-nfs" + sun-rpc program 100227-100227
_STRING_

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Netscreen'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseService($lala);
      }
      $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>tcp<|>0-65535<|>42430-42430'}->srcPort eq
        '0-65535'
        and $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>tcp<|>0-65535<|>42430-42430'}->dstPort eq
        '42430-42430'
        and $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>tcp<|>0-65535<|>42430-42430'}->timeout eq
        'never'
        and $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>udp<|>0-65535<|>42430-42430'}->srcPort eq
        '0-65535'
        and $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>udp<|>0-65535<|>42430-42430'}->dstPort eq
        '42430-42430'
        and $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>udp<|>0-65535<|>42430-42430'}->timeout eq
        'never'
        and $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>tcp<|>0-65535<|>42430-42430'}->srvName eq
        'TCP/UDP_42430'
        and $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>tcp<|>0-65535<|>42430-42430'}
        ->dstPortRange->min == 42430
        and $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>udp<|>0-65535<|>42430-42430'}->srcPort eq
        '0-65535'
        and $parser->elements->{service}{'TCP/UDP_42430'}->metas->{'TCP/UDP_42430<|>udp<|>0-65535<|>42430-42430'}
        ->dstPortRange->max == 42430
        and not exists $parser->elements->{service}{'my-sunrpc-nfs'}
        and $parser->getService('TCP/UDP_42430')
        and $parser->getPreDefinedService('aol');
    },
    ' parseService 方法'
  );
}

testServiceGroup: {
  my $string = qq{set group service "BKUP_SERVICES" comment " "\n};
  ok(
    do {
      $parser->isServiceGroup($string) == 1 ? 1 : 0;
    },
    ' isServiceGroup 方法'
  );

  $string = <<_STRING_;
set group service "BKUP_SERVICES" comment " "
set group service "BKUP_SERVICES" add "TCP/UDP_26213"
set group service "BKUP_SERVICES" add "TCP/UDP_26214"
_STRING_

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Netscreen'
        );
        my $service = Firewall::Config::Element::Service::Netscreen->new(
          fwId     => 1,
          srvName  => 'TCP/UDP_26213',
          protocol => 'tcp',
          srcPort  => '0-65535',
          dstPort  => '26213-26213'
        );
        $service->addMeta(
          fwId     => 1,
          srvName  => 'TCP/UDP_26213',
          protocol => 'udp',
          srcPort  => '0-65535',
          dstPort  => '26213-26213'
        );
        $parser->elements->{service}{ $service->sign } = $service;
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseServiceGroup($lala);
      }
      $parser->elements->{serviceGroup}{'BKUP_SERVICES'}->description eq ' '
        and exists $parser->elements->{serviceGroup}{'BKUP_SERVICES'}->srvGroupMembers->{'TCP/UDP_26213'}
        and exists $parser->elements->{serviceGroup}{'BKUP_SERVICES'}->srvGroupMembers->{'TCP/UDP_26214'}
        and $parser->elements->{serviceGroup}{'BKUP_SERVICES'}->srvGroupName eq 'BKUP_SERVICES'
        and $parser->elements->{serviceGroup}{'BKUP_SERVICES'}->dstPortRangeMap->{'tcp'}->min == 26213
        and $parser->elements->{serviceGroup}{'BKUP_SERVICES'}->dstPortRangeMap->{'tcp'}->max == 26213
        and $parser->getServiceGroup('BKUP_SERVICES');
    },
    ' parseServiceGroup 方法'
  );
}

testSchedule: {
  my $string = qq{set scheduler "S_20120331" once start 10/10/2011 0:0 stop 3/31/2012 23:59\n};
  my $string2 =
    qq{set scheduler "S20110630" recurrent friday start 10:00 stop 12:00 start 14:00 stop 16:00 comment "test"\n};
  ok(
    do {
      $parser->isSchedule($string)
        and $parser->isSchedule($string2) ? 1 : 0;
    },
    ' isSchedule 方法'
  );

  $string = <<_STRING_;
set scheduler "S_20120331" once start 10/10/2011 0:0 stop 3/31/2012 23:59
set scheduler "S20110630" recurrent friday start 10:00 stop 12:00 start 14:00 stop 16:00 comment "test"
_STRING_

  ok(
    do {
      eval {
        $parser->{schedule} = {};
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Netscreen'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseSchedule($lala);
      }
            $parser->elements->{schedule}{'S_20120331'}->schType eq 'once'
        and $parser->elements->{schedule}{'S_20120331'}->startDate eq '10/10/2011 0:0'
        and $parser->elements->{schedule}{'S_20120331'}->endDate eq '3/31/2012 23:59'
        and $parser->elements->{schedule}{'S20110630'}->schType eq 'recurrent'
        and $parser->elements->{schedule}{'S20110630'}->weekday eq 'friday'
        and $parser->elements->{schedule}{'S20110630'}->startTime1 eq '10:00'
        and $parser->elements->{schedule}{'S20110630'}->endTime1 eq '12:00'
        and $parser->elements->{schedule}{'S20110630'}->startTime2 eq '14:00'
        and $parser->elements->{schedule}{'S20110630'}->endTime2 eq '16:00'
        and $parser->elements->{schedule}{'S20110630'}->description eq 'test'
        and $parser->elements->{schedule}{'S_20120331'}->schName eq 'S_20120331'
        and $parser->getSchedule('S20110630');
    },
    ' parseSchedule 方法'
  );

}

testRule: {
  my $string =
    qq{set policy id 4090 name "781515" from "V1-Untrust" to "V1-Trust"  "Host_10.25.118.40" "Host_10.31.9.63" "SSH" permit log\n};
  ok(
    do {
      $parser->isRule($string) == 1 ? 1 : 0;
    },
    ' isRule 方法'
  );
  $string = <<_STRING_;
set policy id 4227 name "78154" from "V1-Untrust" to "V1-Trust"  "Host_10.65.1.137" "Host_10.31.102.117" "TCP_1521" permit schedule "S20131227" log
set policy id 4227 disable
set policy id 4227 application "IGNORE"
set policy id 4227
set src-address "Host_10.65.1.152"
set dst-address "Host_10.31.9.81"
set service "tcp_3389"
set service "tcp_5901"
exit
_STRING_
  my $string1 = <<_STRING1_;
set policy id 697 from "Trust" to "Global"  "Host_10.8.35.88" "MIP(10.37.174.134)" "S_BIB-TPDS_never" permit log sess-limit per-src-ip 3200
set log session-init
exit
set policy id 1096 name "459646" from "DMZ-2" to "Untrust"  "BCAP-FXMS-AIO-FRONT-RTNS" "PN-REUTER-DOWNLOAD" "HTTPS" nat src permit
exit
set policy id 1840 from "DMZ-2" to "Untrust"  "Host_192.168.177.53" "Host_9.234.250.43" "TCP_60206" nat src dip-id 79 permit
exit
set policy id 1830 from "Untrust" to "DMZ-2"  "Host_13.168.10.41" "Host_172.16.41.21" "TCP_8007" nat dst ip 192.168.188.21 permit log
exit
set policy id 335 from "Untrust" to "Untrust"  "Host_199.100.101.21" "Host_172.41.1.21" "TCP_30110" nat dst ip 172.40.16.42 port 8007 permit log count
exit
set policy id 1347 from "Trust" to "Untrust"  "Host_172.40.13.57" "Host_172.27.16.16" "SSH" nat src dip-id 38 dst ip 172.27.16.16 port 1688 permit log
exit
set policy id 1773 from "Untrust" to "DMZ-2"  "XieCheng_10.2.254.17" "Host_172.16.41.21" "SSH" nat src dip-id 109 dst ip 192.168.188.21 permit log
exit
set policy id 1551 from "Untrust" to "Trust"  "G_Windows_Svr" "G_OA_DC_Server" "G_OA_DC_Service" permit log count
set policy id 1551
exit
_STRING1_
  ok(
    do {
      eval {
        $parser->{rule}   = {};
        $parser->{config} = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string . $string1 ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Netscreen'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseRule($lala);
      }
            $parser->elements->{rule}{'4227'}->action eq 'permit'
        and $parser->elements->{rule}{'4227'}->hasLog eq 'log'
        and $parser->elements->{rule}{'4227'}->schName eq 'S20131227'
        and $parser->elements->{rule}{'4227'}->content eq $string
        and $parser->elements->{rule}{'4227'}->policyId eq '4227'
        and $parser->elements->{rule}{'4227'}->fromZone eq 'V1-Untrust'
        and $parser->elements->{rule}{'4227'}->toZone eq 'V1-Trust'
        and $parser->elements->{rule}{'4227'}->isDisable eq 'disable'
        and $parser->elements->{rule}{'4227'}->hasApplicationCheck eq 'IGNORE'
        and $parser->elements->{rule}{'4227'}->alias eq '78154'
        and $parser->elements->{rule}{'4227'}->priority == 1
        and exists $parser->elements->{rule}{'4227'}->srcAddressMembers->{'Host_10.65.1.137'}
        and exists $parser->elements->{rule}{'4227'}->srcAddressMembers->{'Host_10.65.1.152'}
        and exists $parser->elements->{rule}{'4227'}->dstAddressMembers->{'Host_10.31.102.117'}
        and exists $parser->elements->{rule}{'4227'}->dstAddressMembers->{'Host_10.31.9.81'}
        and exists $parser->elements->{rule}{'4227'}->serviceMembers->{'TCP_1521'}
        and exists $parser->elements->{rule}{'4227'}->serviceMembers->{'tcp_3389'}
        and exists $parser->elements->{rule}{'4227'}->serviceMembers->{'tcp_5901'}
        and $parser->elements->{rule}{'4227'}->policyId eq '4227'
        and $parser->elements->{rule}{'697'}->hasLog eq 'log'
        and $parser->elements->{rule}{'1096'}->alias eq '459646'
        and exists $parser->elements->{rule}{'1840'}->srcAddressMembers->{'Host_192.168.177.53'}
        and exists $parser->elements->{rule}{'1830'}->srcAddressMembers->{'Host_13.168.10.41'}
        and exists $parser->elements->{rule}{'1773'}->srcAddressMembers->{'XieCheng_10.2.254.17'}
        and $parser->elements->{rule}{'335'}->policyId == 335
        and $parser->elements->{rule}{'1347'}->policyId == 1347
        and $parser->getRule(1773);
    },
    ' parseRule 方法'
  );
}

