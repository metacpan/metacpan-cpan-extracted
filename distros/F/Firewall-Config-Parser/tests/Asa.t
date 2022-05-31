#!/usr/bin/env perl
use strict;
use warnings;
use 5.018;
use Test::Simple tests => 11;
use Mojo::Util qw(dumper);

use Firewall::Config::Content::Static;
use Firewall::Config::Parser::Asa;
use Digest::MD5;

my $preDefinedService = {
  'ssh' => Firewall::Config::Element::Service::Asa->new(
    fwId     => 1,
    srvName  => 'ssh',
    srcPort  => '1-65535',
    dstPort  => '22',
    protocol => 'tcp'
  ),
  'https' => Firewall::Config::Element::Service::Asa->new(
    fwId     => 1,
    srvName  => 'https',
    srcPort  => '1-65535',
    dstPort  => '443',
    protocol => 'tcp'
  ),
};

my $parser = Firewall::Config::Parser::Asa->new(
  config => Firewall::Config::Content::Static->new(
    config => [],
    fwId   => 1,
    fwName => 'lala',
    fwType => 'Asa'
  ),
  preDefinedService => $preDefinedService,
);

my $config;

testParse: {
  ok(
    do {
      my ( $fwId1, $fwId2 ) = ( 4, 7 );
      $parser = Firewall::Config::Parser::Asa->new(
        config => Firewall::Config::Content::Static->new(
          config => [],
          fwId   => $fwId1,
          fwName => 'lala',
          fwType => 'Asa'
        ),
        preDefinedService => $preDefinedService
      );
      my $oldFwId = $parser->fwId;
      $parser->parse(
        Firewall::Config::Content::Static->new(
          config => ["lala"],
          fwId   => $fwId2,
          fwName => 'lala',
          fwType => 'Asa'
        )
      );
      my $newFwId = $parser->fwId;
      $oldFwId == $fwId1 and $newFwId == $fwId2;
    },
    ' parse 方法'
  );
}

testAddressGroup: {
  my $string = qq{object-group network P_88_src\n};
  ok(
    do {
      $parser->isAddressGroup($string) == 1 ? 1 : 0;
    },
    ' isAddressGroup 方法'
  );
  $string = <<_STRING_;
object-group network P_88_src
 network-object host 10.12.102.157
 network-object 10.16.0.0 255.255.0.0
 group-object G_openview_mg
_STRING_
  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Asa'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseAddressGroup($lala);
      }
            exists $parser->elements->{addressGroup}{'P_88_src'}->addrGroupMembers->{"host 10.12.102.157"}
        and exists $parser->elements->{addressGroup}{'P_88_src'}->addrGroupMembers->{"10.16.0.0 255.255.0.0"}
        and exists $parser->elements->{addressGroup}{'P_88_src'}->addrGroupMembers->{"G_openview_mg"}
        and $parser->elements->{addressGroup}{'P_88_src'}->range->mins->[0] == 168584861
        and $parser->elements->{addressGroup}{'P_88_src'}->range->mins->[1] == 168820736
        and $parser->elements->{addressGroup}{'P_88_src'}->range->maxs->[0] == 168584861
        and $parser->elements->{addressGroup}{'P_88_src'}->range->maxs->[1] == 168886271
        and $parser->elements->{addressGroup}{'P_88_src'}->addrGroupName eq 'P_88_src'
        and $parser->getAddressGroup('P_88_src');
    },
    ' parseAddressGroup 方法'
  );

}

testServiceGroup: {
  my $string = qq{object-group service P_Scan_service tcp\n};
  ok(
    do {
      $parser->isServiceGroup($string) == 1 ? 1 : 0;
    },
    ' isServiceGroup 方法'
  );

  $string = <<_STRING_;
object-group service P_Scan_service tcp
 port-object eq 1433
 port-object eq https
 port-object range 40000 40050
 group-object tcpabc
object-group service unix_basic_service
 service-object tcp eq ssh
 service-object tcp eq domain
 service-object udp eq domain
 service-object tcp eq 383
 service-object tcp range ssh 383
_STRING_

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'srx'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseServiceGroup($lala);
      }
      $parser->elements->{serviceGroup}{'P_Scan_service'}->srvGroupMembers->{"eq 1433"}
        ->isa('Firewall::Config::Element::Service::Asa')
        and $parser->elements->{serviceGroup}{'P_Scan_service'}->srvGroupMembers->{"eq https"}
        ->isa('Firewall::Config::Element::Service::Asa')
        and exists $parser->elements->{serviceGroup}{'P_Scan_service'}->srvGroupMembers->{"tcpabc"}
        and $parser->elements->{serviceGroup}{'P_Scan_service'}->dstPortRangeMap->{'tcp'}->mins->[0] == 443
        and $parser->elements->{serviceGroup}{'P_Scan_service'}->dstPortRangeMap->{'tcp'}->maxs->[0] == 443
        and $parser->elements->{serviceGroup}{'P_Scan_service'}->dstPortRangeMap->{'tcp'}->mins->[1] == 1433
        and $parser->elements->{serviceGroup}{'P_Scan_service'}->dstPortRangeMap->{'tcp'}->maxs->[1] == 1433
        and $parser->elements->{serviceGroup}{'P_Scan_service'}->dstPortRangeMap->{'tcp'}->mins->[2] == 40000
        and $parser->elements->{serviceGroup}{'P_Scan_service'}->dstPortRangeMap->{'tcp'}->maxs->[2] == 40050
        and $parser->elements->{serviceGroup}{'P_Scan_service'}->srvGroupName eq 'P_Scan_service'
        and $parser->elements->{serviceGroup}{'unix_basic_service'}->srvGroupMembers->{"tcp eq ssh"}
        ->isa('Firewall::Config::Element::Service::Asa')
        and exists $parser->elements->{serviceGroup}{'unix_basic_service'}->srvGroupMembers->{"tcp eq domain"}
        and exists $parser->elements->{serviceGroup}{'unix_basic_service'}->srvGroupMembers->{"udp eq domain"}
        and $parser->elements->{serviceGroup}{'unix_basic_service'}->srvGroupMembers->{"tcp eq 383"}
        ->isa('Firewall::Config::Element::Service::Asa')
        and $parser->elements->{serviceGroup}{'unix_basic_service'}->srvGroupMembers->{"tcp range ssh 383"}
        ->isa('Firewall::Config::Element::Service::Asa')
        and $parser->elements->{serviceGroup}{'unix_basic_service'}->dstPortRangeMap->{'tcp'}->min == 22
        and $parser->elements->{serviceGroup}{'unix_basic_service'}->dstPortRangeMap->{'tcp'}->max == 383
        and $parser->getServiceGroup('unix_basic_service')
        and $parser->getPreDefinedService('ssh');
    },
    ' parseServiceGroup 方法'
  );
}

testProtocolGroup: {
  my $string = qq{object-group protocol TCP_UDP\n};
  ok(
    do {
      $parser->isProtocolGroup($string) == 1 ? 1 : 0;
    },
    ' isProtocolGroup 方法'
  );

  $string = <<_STRING_;
object-group protocol TCP_UDP
 protocol-object tcp
 protocol-object udp
 group-object pa123
_STRING_

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Asa'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseProtocolGroup($lala);
      }
      $parser->elements->{protocolGroup}{'TCP_UDP'}->proGroupMembers->{"tcp"}->isa('Firewall::Config::Element::Protocol::Asa')
        and $parser->elements->{protocolGroup}{'TCP_UDP'}->protocols->{'tcp'}->protocol eq 'tcp'
        and $parser->elements->{protocolGroup}{'TCP_UDP'}->proGroupMembers->{"udp"}
        ->isa('Firewall::Config::Element::Protocol::Asa')
        and $parser->elements->{protocolGroup}{'TCP_UDP'}->protocols->{'udp'}->protocol eq 'udp'
        and exists $parser->elements->{protocolGroup}{'TCP_UDP'}->proGroupMembers->{"pa123"}
        and $parser->getProtocolGroup('TCP_UDP');
    },
    ' parseProtocolGroup 方法'
  );
}

testSchedule: {
  my $string = qq{time-range S_20091130\n};
  ok(
    do {
      $parser->isSchedule($string) ? 1 : 0;
    },
    ' isSchedule 方法'
  );

  $string = <<_STRING_;
time-range S_20091130
 absolute start 00:00 01 November 2009 end 23:59 30 November 2009
time-range S_20091131
 periodic daily 11:00 to 14:00 
time-range S_20091132
 periodic monday tuesday 11:30 to 14:00 
time-range S_20091133 
 periodic weekdays 11:00 to 14:00
time-range S_20091134 
 periodic weekend 11:00 to 14:00
_STRING_

  ok(
    do {
      eval {
        $parser->{elements} = new Firewall::Config::Parser::Elements;
        $parser->{config}   = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Asa'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->parseSchedule($lala);
      }
            $parser->elements->{schedule}{'S_20091130'}->schType eq 'absolute'
        and $parser->elements->{schedule}{'S_20091130'}->startDate eq '00:00 01 November 2009'
        and $parser->elements->{schedule}{'S_20091130'}->endDate eq '23:59 30 November 2009'
        and $parser->elements->{schedule}{'S_20091131'}->schType eq 'periodic'
        and $parser->elements->{schedule}{'S_20091131'}->periodic eq 'daily'
        and $parser->elements->{schedule}{'S_20091131'}->startTime eq '11:00'
        and $parser->elements->{schedule}{'S_20091131'}->endTime eq '14:00'
        and $parser->elements->{schedule}{'S_20091132'}->periodic eq 'monday tuesday';
    },
    ' parseSchedule 方法'
  );

}

testRule: {
  my $string = qq{access-list inbond extended permit tcp 10.50.0.0 255.255.0.0 host 10.11.100.252 eq 1234 log\n};
  ok(
    do {
      $parser->isRule($string) == 1 ? 1 : 0;
    },
    ' isRule 方法'
  );
  $string = <<_STRING_;
access-list inbond extended permit tcp 10.50.0.0 255.255.0.0 host 10.11.100.252 eq 1234 log
access-list inbond extended permit tcp object-group G_Tech_Terminal_Svr host 10.11.100.53 eq 3389 log 
access-list inbond extended permit tcp host 10.12.104.57 object-group yun_ying_monitor eq 39564 
access-list inbond extended permit object-group TCP_UDP host 10.35.174.115 host 10.11.100.37 object-group Monitor_fw log 
access-list inbond extended permit tcp object-group P_137_net host 10.11.100.37 range 40050 41000
access-list inbond extended permit udp object-group G_New_Solarwinds_Svr any eq snmp
access-list inbond extended permit tcp any host 10.11.108.217 range ssh telnet
access-list inbond extended permit ip host 10.33.30.102 host 10.11.100.37 time-range S_20100418
access-list inbond extended permit tcp any host 202.69.21.97 object-group IMC_tcp inactive 
access-list inbond extended permit tcp 10.50.0.0 255.255.0.0 host 10.11.100.252 log
_STRING_
  ok(
    do {
      eval {
        $parser->{elements}       = new Firewall::Config::Parser::Elements;
        $parser->{aclLineNumbers} = {};
        $parser->{config}         = Firewall::Config::Content::Static->new(
          config => [ map { "$_\n" } split( /\n/, $string ) ],
          fwId   => 1,
          fwName => 'lala',
          fwType => 'Asa'
        );
      };
      warn $@ if $@;
      while ( my $lala = $parser->nextUnParsedLine ) {
        $parser->isRule($lala);
        $parser->parseRule($lala);
      }

            $parser->elements->{rule}{'inbond<|>1'}->action eq 'permit'
        and $parser->elements->{rule}{'inbond<|>1'}->zone eq 'inbond'
        and $parser->elements->{rule}{'inbond<|>1'}->aclName eq 'inbond'
        and $parser->elements->{rule}{'inbond<|>1'}->aclLineNumber == 1
        and $parser->elements->{rule}{'inbond<|>1'}->hasLog eq 'log'
        and $parser->elements->{rule}{'inbond<|>1'}->srcAddressGroup->range->min == 171048960
        and $parser->elements->{rule}{'inbond<|>1'}->srcAddressGroup->range->max == 171114495
        and $parser->elements->{rule}{'inbond<|>1'}->dstAddressGroup->range->min == 168518908
        and $parser->elements->{rule}{'inbond<|>1'}->dstAddressGroup->range->max == 168518908
        and $parser->elements->{rule}{'inbond<|>1'}->serviceGroup->dstPortRangeMap->{'tcp'}->min == 1234
        and $parser->elements->{rule}{'inbond<|>1'}->serviceGroup->dstPortRangeMap->{'tcp'}->max == 1234
        and $parser->elements->{rule}{'inbond<|>1'}->protocolMembers->{'tcp'}->protocol eq 'tcp'
        and $parser->elements->{rule}{'inbond<|>1'}->srcAddressMembers->{'10.50.0.0 255.255.0.0'}->range->min == 171048960
        and $parser->elements->{rule}{'inbond<|>1'}->srcAddressMembers->{'10.50.0.0 255.255.0.0'}->range->max == 171114495
        and $parser->elements->{rule}{'inbond<|>1'}->dstAddressMembers->{'host 10.11.100.252'}
        ->isa('Firewall::Config::Element::Address::Asa')
        and $parser->elements->{rule}{'inbond<|>1'}->serviceMembers->{'eq 1234'}
        ->isa('Firewall::Config::Element::ServiceGroup::Asa')
        and exists $parser->elements->{rule}{'inbond<|>2'}->srcAddressMembers->{'G_Tech_Terminal_Svr'}
        and exists $parser->elements->{rule}{'inbond<|>3'}->dstAddressMembers->{'yun_ying_monitor'}
        and exists $parser->elements->{rule}{'inbond<|>4'}->protocolMembers->{'TCP_UDP'}
        and $parser->elements->{rule}{'inbond<|>5'}->serviceMembers->{'range 40050 41000'}
        ->isa('Firewall::Config::Element::ServiceGroup::Asa')
        and
        $parser->elements->{rule}{'inbond<|>6'}->dstAddressMembers->{'any'}->isa('Firewall::Config::Element::Address::Asa')
        and
        $parser->elements->{rule}{'inbond<|>7'}->srcAddressMembers->{'any'}->isa('Firewall::Config::Element::Address::Asa')
        and $parser->elements->{rule}{'inbond<|>8'}->schName eq 'S_20100418'
        and $parser->elements->{rule}{'inbond<|>9'}->isDisable eq 'inactive'
        and $parser->elements->{rule}{'inbond<|>9'}->ignore
        and $parser->elements->{rule}{'inbond<|>10'}->serviceGroup->dstPortRangeMap->{'tcp'}->min == 0
        and $parser->elements->{rule}{'inbond<|>10'}->serviceGroup->dstPortRangeMap->{'tcp'}->max == 65535;
    },
    ' parseRule 方法'
  );
}

