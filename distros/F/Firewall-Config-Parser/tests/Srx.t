#!/usr/bin/env perl
use strict;
use warnings;
use 5.018;
use Test::Simple tests => 13;
use Mojo::Util qw(dumper);

use Firewall::Config::Content::Static;
use Firewall::Config::Parser::Srx;

my $preDefinedService = {
  'junos-rsh' => Firewall::Config::Element::Service::Srx->new(
    fwId     => 1,
    srvName  => 'junos-rsh',
    protocol => 'tcp',
    srcPort  => '1-65535',
    dstPort  => '514'
  ),
  'junos-talk' => Firewall::Config::Element::Service::Srx->new(
    fwId     => 1,
    srvName  => 'junos-talk',
    protocol => 'udp',
    srcPort  => '1-65535',
    dstPort  => '517'
  ),
};

my $parser = Firewall::Config::Parser::Srx->new(
  config => Firewall::Config::Content::Static->new(
    config => [],
    fwId   => 1,
    fwName => 'lala',
    fwType => 'Srx'
  ),
  preDefinedService => $preDefinedService
);

my $config;

testParse: {
  ok(
    do {
      my ( $fwId1, $fwId2 ) = ( 4, 7 );
      $parser = Firewall::Config::Parser::Srx->new(
        config => Firewall::Config::Content::Static->new(
          config => [],
          fwId   => $fwId1,
          fwName => 'lala',
          fwType => 'Srx'
        ),
        preDefinedService => $preDefinedService
      );
      my $oldFwId = $parser->fwId;
      $parser->parse(
        Firewall::Config::Content::Static->new(
          config => ["lala"],
          fwId   => $fwId2,
          fwName => 'lala',
          fwType => 'Srx'
        )
      );
      my $newFwId = $parser->fwId;
      $oldFwId == $fwId1 and $newFwId == $fwId2;
    },
    ' parse 方法'
  );
}

testAddress: {
  my $string = qq{set security zones security-zone l2-untrust address-book address host_10.11.104.45 10.11.104.45/32\n};
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
          fwType => 'Srx'
        );
      };
      warn $@ if $@;
      $parser->parseAddress( $parser->nextUnParsedLine );
            $parser->elements->{address}{'l2-untrust<|>host_10.11.104.45'}->ip eq '10.11.104.45'
        and $parser->elements->{address}{'l2-untrust<|>host_10.11.104.45'}->mask eq '32'
        and $parser->elements->{address}{'l2-untrust<|>host_10.11.104.45'}->addrName eq 'host_10.11.104.45'
        and $parser->getAddress( 'l2-untrust', 'host_10.11.104.45' );
    },
    ' parseAddress 方法'
  );
}

testAddressGroup: {
  my $string =
    qq{set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.104.45\n};
  ok(
    do {
      $parser->isAddressGroup($string) == 1 ? 1 : 0;
    },
    ' isAddressGroup 方法'
  );
  $string = <<_STRING_;
set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.104.45
set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.106.11
set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.77.110
set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.77.126
set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.77.18
set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.77.19
_STRING_
  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Srx'
        );
        my $address = Firewall::Config::Element::Address::Srx->new(
          fwId     => 1,
          addrName => 'host_10.11.104.45',
          ip       => '10.11.104.45',
          mask     => 32,
          zone     => 'l2-untrust'
        );
        $parser->elements->{address}{ $address->sign } = $address;
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseAddressGroup($lala);
      }
      exists $parser->elements->{addressGroup}{'l2-untrust<|>g_backup_client'}->addrGroupMembers->{'host_10.11.106.11'}
        and $parser->elements->{addressGroup}{'l2-untrust<|>g_backup_client'}->addrGroupName eq 'g_backup_client'
        and $parser->elements->{addressGroup}{'l2-untrust<|>g_backup_client'}->range->min == 168519725
        and $parser->elements->{addressGroup}{'l2-untrust<|>g_backup_client'}->range->max == 168519725
        and $parser->getAddressGroup( 'l2-untrust', 'g_backup_client' );
    },
    ' parseAddressGroup 方法'
  );

}

testService: {
  my $string = qq{set applications application TCP_UDP_135 term TCP_UDP_135 protocol tcp\n};
  ok(
    do {
      $parser->isService($string) == 1 ? 1 : 0;
    },
    ' isService 方法'
  );

  $string = <<_STRING_;
set applications application TCP_UDP_135 term TCP_UDP_135 protocol tcp
set applications application TCP_UDP_135 term TCP_UDP_135 source-port 0-65535
set applications application TCP_UDP_135 term TCP_UDP_135 destination-port 135-135
set applications application TCP_UDP_135 term TCP_UDP_135_1 protocol udp
set applications application TCP_UDP_135 term TCP_UDP_135_1 source-port 0-65535
set applications application TCP_UDP_135 term TCP_UDP_135_1 destination-port 135-135
set applications application TCP_UDP_135 term TCP_UDP_135_1 inactivity-timeout 10800
set applications application TCP_UDP_135 term TCP_UDP_135_1 alg ftp
set applications application ms-rpc-uuid-any-tcp protocol tcp
set applications application ms-rpc-uuid-any-tcp uuid ffffffff-ffff-ffff-ffff-ffffffffffff
set applications application TCP_20523 protocol tcp
set applications application TCP_20523 source-port 0-65535
set applications application TCP_20523 destination-port 20523-20523
_STRING_

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Srx'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseService($lala);
      }
            $parser->elements->{service}{'TCP_UDP_135'}->metas->{'TCP_UDP_135<|>TCP_UDP_135'}->srcPort eq '0-65535'
        and $parser->elements->{service}{'TCP_UDP_135'}->metas->{'TCP_UDP_135<|>TCP_UDP_135'}->dstPort eq '135-135'
        and $parser->elements->{service}{'TCP_UDP_135'}->metas->{'TCP_UDP_135<|>TCP_UDP_135'}->protocol eq 'tcp'
        and $parser->elements->{service}{'TCP_UDP_135'}->metas->{'TCP_UDP_135<|>TCP_UDP_135_1'}->srcPort eq '0-65535'
        and $parser->elements->{service}{'TCP_UDP_135'}->metas->{'TCP_UDP_135<|>TCP_UDP_135_1'}->dstPort eq '135-135'
        and $parser->elements->{service}{'TCP_UDP_135'}->metas->{'TCP_UDP_135<|>TCP_UDP_135_1'}->protocol eq 'udp'
        and $parser->elements->{service}{'TCP_UDP_135'}->metas->{'TCP_UDP_135<|>TCP_UDP_135_1'}->timeout eq '10800'
        and $parser->elements->{service}{'ms-rpc-uuid-any-tcp'}->metas->{'ms-rpc-uuid-any-tcp<|> '}->uuid eq
        'ffffffff-ffff-ffff-ffff-ffffffffffff'
        and $parser->elements->{service}{'TCP_20523'}->metas->{'TCP_20523<|> '}->protocol eq 'tcp'
        and $parser->elements->{service}{'TCP_20523'}->metas->{'TCP_20523<|> '}->srcPort eq '0-65535'
        and $parser->elements->{service}{'TCP_20523'}->metas->{'TCP_20523<|> '}->dstPort eq '20523-20523'
        and $parser->elements->{service}{'TCP_UDP_135'}->srvName eq 'TCP_UDP_135'
        and $parser->getService( 'TCP_UDP_135', 'TCP_UDP_135_1' )
        and $parser->getPreDefinedService('junos-rsh')
        and not $parser->getPreDefinedService('TCP_UDP_135');
    },
    ' parseService 方法'
  );
}

testServiceGroup: {
  my $string = qq{set applications application-set GuiZe_1_3 application TCP_1-19\n};
  ok(
    do {
      $parser->isServiceGroup($string) == 1 ? 1 : 0;
    },
    ' isServiceGroup 方法'
  );

  $string = <<_STRING_;
set applications application-set GuiZe_1_3 application TCP_1-19
set applications application-set GuiZe_1_3 application TCP_2050-3388
set applications application-set GuiZe_1_3 application UDP_1-65535
_STRING_

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Srx'
        );
        my $service = Firewall::Config::Element::Service::Srx->new(
          fwId     => 1,
          srvName  => 'TCP_1-19',
          protocol => 'tcp',
          srcPort  => '0-65535',
          dstPort  => '1-19',
          term     => 'z'
        );
        $service->addMeta(
          Firewall::Config::Element::ServiceMeta::Srx->new(
            fwId     => 1,
            srvName  => 'TCP_1-19',
            protocol => 'udp',
            srcPort  => '0-65535',
            dstPort  => '1-19',
            term     => 'y'
          )
        );
        $parser->elements->{service}{ $service->sign } = $service;
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseServiceGroup($lala);
      }
            exists $parser->elements->{serviceGroup}{'GuiZe_1_3'}->srvGroupMembers->{'TCP_1-19'}
        and exists $parser->elements->{serviceGroup}{'GuiZe_1_3'}->srvGroupMembers->{'UDP_1-65535'}
        and $parser->elements->{serviceGroup}{'GuiZe_1_3'}->srvGroupName eq 'GuiZe_1_3'
        and $parser->elements->{serviceGroup}{'GuiZe_1_3'}->dstPortRangeMap->{'tcp'}->min == 1
        and $parser->elements->{serviceGroup}{'GuiZe_1_3'}->dstPortRangeMap->{'tcp'}->max == 19
        and $parser->getServiceGroup('GuiZe_1_3');
    },
    ' parseServiceGroup 方法'
  );
}

testSchedule: {
  my $string = qq{set schedulers scheduler S_20130924 start-date 2013-09-24.00:00 stop-date 2013-10-23.23:59\n"};
  ok(
    do {
      $parser->isSchedule($string) ? 1 : 0;
    },
    ' isSchedule 方法'
  );

  $string = <<_STRING_;
set schedulers scheduler S_20130924 start-date 2013-09-24.00:00 stop-date 2013-10-23.23:59
_STRING_

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Srx'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseSchedule($lala);
      }
            $parser->elements->{schedule}{'S_20130924'}->startDate eq '2013-09-24.00:00'
        and $parser->elements->{schedule}{'S_20130924'}->endDate eq '2013-10-23.23:59'
        and $parser->elements->{schedule}{'S_20130924'}->schName eq 'S_20130924'
        and $parser->getSchedule('S_20130924');
    },
    ' parseSchedule 方法'
  );

}

testRule: {
  my $string =
    qq{set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match source-address net_10.0.0.0\n};
  ok(
    do {
      $parser->isRule($string) == 1 ? 1 : 0;
    },
    ' isRule 方法'
  );
  $string = <<_STRING_;
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match source-address net_10.0.0.0
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match source-address net_192.168.10.0
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match destination-address net_10.33.120.0/22
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match destination-address net_10.12.120.0/22
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match application junos-http
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match application junos-https
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match application tcp_8080
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 then permit
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 scheduler-name S_20130924
set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 then log session-init
deactivate security policies from-zone l2-untrust to-zone l2-trust policy 000000-07
_STRING_
  ok(
    do {
      eval {
        $parser->{rule} = {};
        $config = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Srx'
        );
      };
      warn $@ if $@;
      while ( my $lala = $config->nextUnParsedLine ) {
        $parser->parseRule( $lala, $config );
      }
            $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->action eq 'permit'
        and $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->content eq $string
        and $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->ruleName eq '000000-07'
        and $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->fromZone eq 'l2-untrust'
        and $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->toZone eq 'l2-trust'
        and $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->schName eq 'S_20130924'
        and $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->hasLog eq 'log session-init'
        and exists $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->srcAddressMembers->{'net_10.0.0.0'}
        and exists $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->srcAddressMembers->{'net_192.168.10.0'}
        and exists $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->dstAddressMembers->{'net_10.33.120.0/22'}
        and exists $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->dstAddressMembers->{'net_10.12.120.0/22'}
        and exists $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->serviceMembers->{'junos-http'}
        and exists $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->serviceMembers->{'junos-https'}
        and exists $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->serviceMembers->{'tcp_8080'}
        and $parser->elements->{rule}{'l2-untrust<|>l2-trust<|>000000-07'}->ruleName eq '000000-07'
        and $parser->getRule( 'l2-untrust', 'l2-trust', '000000-07' );
    },
    ' parseRule 方法'
  );
}

