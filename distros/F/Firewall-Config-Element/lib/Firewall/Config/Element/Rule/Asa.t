#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 11;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::Rule::Asa;
use Time::Local;
use Firewall::Config::Element::Schedule::Asa;

=lala
#设备Id
has fwId => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

#在同一个设备中描述一个对象的唯一性特征
has sign => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    builder => '_buildSign',
);

has action => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has isDisable => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
    writer => 'setIsDisable',
);

has hasLog => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has schName => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has content => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    writer => 'setContent',
);

has srcAddressGroup => (
    is => 'ro',
    does => 'Firewall::Config::Element::AddressGroup::Role',
    lazy => 1,
    builder => '_buildSrcAddressGroup',
);

has dstAddressGroup => (
    is => 'ro',
    does => 'Firewall::Config::Element::AddressGroup::Role',
    lazy => 1,
    builder => '_buildDstAddressGroup',
);

has serviceGroup => (
    is => 'ro',
    does => 'Firewall::Config::Element::ServiceGroup::Role',
    lazy => 1,
    builder => '_buildServiceGroup',
);

has schedule => (
    is => 'ro',
    does => 'Firewall::Config::Element::Schedule::Role',
    predicate => 'hasSchedule',
    writer => 'setSchedule',
);

has zone => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);


has aclName => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has aclLineNumber => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has protocolGroup => (
    is => 'ro',
    does => 'Firewall::Config::Element::ProtocolGroup::Role',
    lazy => 1,
    builder => '_buildProtocolGroup',
);
=cut

my $rule;

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
    };
    warn $@ if $@;
    $rule->isa('Firewall::Config::Element::Rule::Asa');
  },
  ' 生成 Firewall::Config::Element::Rule::Asa 对象'
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
    };
    warn $@ if $@;
    $rule->sign eq 'la<|>1';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      $rule->setContent('lele');
    };
    warn $@ if $@;
    $rule->content eq 'lele';
  },
  " setContent('lele')"
);

ok(
  do {
    my $content = 'lele';
    my $add     = 'lala';
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => $content
      );
      $rule->addContent($add);
    };
    warn $@ if $@;
    $rule->content eq $content . $add ? 1 : 0;
  },
  " addContent('lelelala')"
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      my $address = Firewall::Config::Element::Address::Asa->new(
        fwId => 1,
        ip   => '10.11.77.41',
        mask => '255.255.252.0'
      );
      my $addressGroup = Firewall::Config::Element::AddressGroup::Asa->new(
        fwId          => 1,
        addrGroupName => 'ghi'
      );
      $rule->addSrcAddressMembers('abc');
      $rule->addSrcAddressMembers( 'def', $address );
      $rule->addSrcAddressMembers( 'ghi', $addressGroup );
    };
    warn $@ if $@;
    exists $rule->srcAddressMembers->{'abc'}
      and not defined $rule->srcAddressMembers->{'abc'}
      and $rule->srcAddressMembers->{'def'}->isa('Firewall::Config::Element::Address::Asa')
      and $rule->srcAddressMembers->{'ghi'}->isa('Firewall::Config::Element::AddressGroup::Asa');
  },
  " addSrcAddressMembers"
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      my $address = Firewall::Config::Element::Address::Asa->new(
        fwId => 1,
        ip   => '10.11.77.41',
        mask => '255.255.252.0'
      );
      my $addressGroup = Firewall::Config::Element::AddressGroup::Asa->new(
        fwId          => 1,
        addrGroupName => 'ghi'
      );
      $rule->addDstAddressMembers('abc');
      $rule->addDstAddressMembers( 'def', $address );
      $rule->addDstAddressMembers( 'ghi', $addressGroup );
    };
    warn $@ if $@;
    exists $rule->dstAddressMembers->{'abc'}
      and not defined $rule->dstAddressMembers->{'abc'}
      and $rule->dstAddressMembers->{'def'}->isa('Firewall::Config::Element::Address::Asa')
      and $rule->dstAddressMembers->{'ghi'}->isa('Firewall::Config::Element::AddressGroup::Asa');
  },
  " addDstAddressMembers"
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      my $service = Firewall::Config::Element::Service::Asa->new(
        fwId     => 1,
        srvName  => 'la',
        dstPort  => '100',
        protocol => 'tcp'
      );
      my $serviceGroup = Firewall::Config::Element::ServiceGroup::Asa->new(
        fwId         => 1,
        srvGroupName => 'a',
        protocol     => 't'
      );
      $rule->addServiceMembers('abc');
      $rule->addServiceMembers( 'def', $service );
      $rule->addServiceMembers( 'ghi', $serviceGroup );
    };
    warn $@ if $@;
    exists $rule->serviceMembers->{'abc'}
      and not defined $rule->serviceMembers->{'abc'}
      and $rule->serviceMembers->{'def'}->isa('Firewall::Config::Element::Service::Asa')
      and $rule->serviceMembers->{'ghi'}->isa('Firewall::Config::Element::ServiceGroup::Asa');
  },
  " addServiceMembers"
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
      my $protocol = Firewall::Config::Element::Protocol::Asa->new(
        fwId     => 1,
        protocol => 'd'
      );
      my $protocolGroup = Firewall::Config::Element::ProtocolGroup::Asa->new(
        fwId         => 1,
        proGroupName => 'a'
      );
      $rule->addProtocolMembers('abc');
      $rule->addProtocolMembers( 'def', $protocol );
      $rule->addProtocolMembers( 'ghi', $protocolGroup );
    };
    warn $@ if $@;
    exists $rule->protocolMembers->{'abc'}
      and not defined $rule->protocolMembers->{'abc'}
      and $rule->protocolMembers->{'def'}->isa('Firewall::Config::Element::Protocol::Asa')
      and $rule->protocolMembers->{'ghi'}->isa('Firewall::Config::Element::ProtocolGroup::Asa');
  },
  " addProtocolMembers"
);

ok(
  do {
    my $time;
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      my $date = '2013-12-07 10:45:00 周六';
      my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
      $time = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
      my $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'absolute',
        startDate => '00:00 01 November 2009',
        endDate   => '23:59 30 November 2012'
      );
      $rule->setSchedule($schedule);
    };
    warn $@ if $@;
    $rule->hasSchedule and $rule->schedule->isExpired($time);
  },
  " hasSchedule and setSchedule"
);

ok(
  do {
    my ( $rule1, $rule2, $rule3 );
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      $rule1 = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      my $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'absolute',
        startDate => '00:00 01 November 2009',
        endDate   => '23:59 30 November 2013'
      );
      $rule1->setSchedule($schedule);
      $rule2 = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      $rule2->setIsDisable('inactive');
      $rule3 = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala',
        schname       => 'a'
      );
      $rule3->setSchedule($schedule);
      $rule3->setIsDisable('inactive');
    };
    warn $@ if $@;
    not $rule->ignore
      and $rule1->ignore
      and $rule2->ignore
      and $rule3->ignore;
  },
  " ignore"
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Asa->new(
        fwId          => 1,
        zone          => 'a',
        aclName       => 'la',
        aclLineNumber => 1,
        action        => 'b',
        content       => 'lala'
      );
    };
    warn $@ if $@;
          $rule->srcAddressGroup->isa('Firewall::Config::Element::AddressGroup::Asa')
      and $rule->srcAddressGroup->addrGroupName eq '^'
      and $rule->dstAddressGroup->isa('Firewall::Config::Element::AddressGroup::Asa')
      and $rule->dstAddressGroup->addrGroupName eq '^'
      and $rule->serviceGroup->isa('Firewall::Config::Element::ServiceGroup::Asa')
      and $rule->serviceGroup->srvGroupName eq '^'
      and $rule->protocolGroup->isa('Firewall::Config::Element::ProtocolGroup::Asa')
      and $rule->protocolGroup->proGroupName eq '^';
  },
  " lazy 生成 srcAddressGroup dstAddressGroup serviceGroup protocolGroup"
);
