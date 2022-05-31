#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 12;
use Time::Local;

use Firewall::Config::Element::Rule::Netscreen;
use Firewall::Config::Element::Schedule::Netscreen;

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

has policyId => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has fromZone => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has toZone => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has hasApplicationCheck => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
    writer => 'setHasApplicationCheck',
);

has alias => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has priority => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);
=cut

my $rule;

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
    };
    warn $@ if $@;
    $rule->isa('Firewall::Config::Element::Rule::Netscreen');
  },
  ' 生成 Firewall::Config::Element::Rule::Netscreen 对象'
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
    };
    warn $@ if $@;
    $rule->sign eq '2';
  },
  ' lazy生成 sign'
);

for my $attr (qw/ hasApplicationCheck isDisable content /) {
  my $func   = "set" . ucfirst($attr);
  my $string = 'abcdefg';
  my $code   = <<_CODE_;
ok(
    do {
        eval {
            \$rule->$func('$string');
        };
        warn \$@ if \$@;
        \$rule->$attr eq '$string' ? 1 : 0;
    },
    " $func('$string')");
_CODE_
  eval($code);
  die $@ if $@;
}

ok(
  do {
    my $schedule;
    my $time;
    eval {
      $rule = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234,
        schName  => 'a'
      );
      my $date = '2013-12-07 10:45:00 周六';
      my ( $year, $mon, $mday, $hour, $min, $sec ) = split( '[\- :]', $date );
      $time     = timelocal( $sec, $min, $hour, $mday, $mon - 1, $year - 1900 );
      $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'once',
        startDate => '10/10/2011 0:0',
        endDate   => '3/31/2022 23:59'
      );
      $rule->setSchedule($schedule);
    };
    warn $@ if $@;
    $rule->hasSchedule and not $rule->schedule->isExpired($time);
  },
  " hasSchedule and setSchedule"
);

ok(
  do {
    my ( $rule1, $rule2, $rule3 );
    eval {
      $rule = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234,
        schName  => 'a'
      );
      my $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
        fwId      => 1,
        schName   => 'a',
        schType   => 'once',
        startDate => '10/10/2011 0:0',
        endDate   => '3/31/2012 23:59'
      );
      $rule1 = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
      $rule1->setIsDisable('disable');
      $rule2 = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234,
        schName  => 'a'
      );
      $rule2->setSchedule($schedule);
      $rule3 = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234,
        schName  => 'a'
      );
      $rule3->setIsDisable('disable');
      $rule3->setSchedule($schedule);
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
    my $content = 'lele';
    my $add     = 'lala';
    eval {
      $rule = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => $content,
        priority => 234
      );
      $rule->addContent($add);
    };
    warn $@ if $@;
    $rule->content eq $content . $add;
  },
  " addContent('lelelala')"
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
      my $address = Firewall::Config::Element::Address::Netscreen->new(
        fwId     => 1,
        addrName => 'a',
        ip       => '10.11.77.41',
        mask     => '255.255.252.0',
        zone     => 'o'
      );
      my $addressGroup = Firewall::Config::Element::AddressGroup::Netscreen->new(
        fwId          => 1,
        addrGroupName => 'a',
        zone          => 'o'
      );
      $rule->addSrcAddressMembers('abc');
      $rule->addSrcAddressMembers( 'def', $address );
      $rule->addSrcAddressMembers( 'ghi', $addressGroup );
    };
    warn $@ if $@;
    exists $rule->srcAddressMembers->{'abc'}
      and not defined $rule->srcAddressMembers->{'abc'}
      and $rule->srcAddressMembers->{'def'}->isa('Firewall::Config::Element::Address::Netscreen')
      and $rule->srcAddressMembers->{'ghi'}->isa('Firewall::Config::Element::AddressGroup::Netscreen');
  },
  " addSrcAddressMembers"
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
      my $address = Firewall::Config::Element::Address::Netscreen->new(
        fwId     => 1,
        addrName => 'a',
        ip       => '10.11.77.41',
        mask     => '255.255.252.0',
        zone     => 'o'
      );
      my $addressGroup = Firewall::Config::Element::AddressGroup::Netscreen->new(
        fwId          => 1,
        addrGroupName => 'a',
        zone          => 'o'
      );
      $rule->addDstAddressMembers('abc');
      $rule->addDstAddressMembers( 'def', $address );
      $rule->addDstAddressMembers( 'ghi', $addressGroup );
    };
    warn $@ if $@;
    exists $rule->dstAddressMembers->{'abc'}
      and not defined $rule->dstAddressMembers->{'abc'}
      and $rule->dstAddressMembers->{'def'}->isa('Firewall::Config::Element::Address::Netscreen')
      and $rule->dstAddressMembers->{'ghi'}->isa('Firewall::Config::Element::AddressGroup::Netscreen');
  },
  " addDstAddressMembers"
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
      my $service = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
      my $serviceGroup = Firewall::Config::Element::ServiceGroup::Netscreen->new(
        fwId         => 1,
        srvGroupName => 'a'
      );
      $rule->addServiceMembers('abc');
      $rule->addServiceMembers( 'def', $service );
      $rule->addServiceMembers( 'ghi', $serviceGroup );
    };
    warn $@ if $@;
    exists $rule->serviceMembers->{'abc'}
      and not defined $rule->serviceMembers->{'abc'}
      and $rule->serviceMembers->{'def'}->isa('Firewall::Config::Element::Service::Netscreen')
      and $rule->serviceMembers->{'ghi'}->isa('Firewall::Config::Element::ServiceGroup::Netscreen');
  },
  " addServiceMembers"
);

ok(
  do {
    eval {
      $rule = Firewall::Config::Element::Rule::Netscreen->new(
        fwId     => 1,
        policyId => '2',
        fromZone => 'a',
        toZone   => 'b',
        action   => 'ok',
        content  => 'lala',
        priority => 234
      );
    };
    warn $@ if $@;
          $rule->srcAddressGroup->isa('Firewall::Config::Element::AddressGroup::Netscreen')
      and $rule->srcAddressGroup->addrGroupName eq '^'
      and $rule->srcAddressGroup->zone eq '^'
      and $rule->dstAddressGroup->isa('Firewall::Config::Element::AddressGroup::Netscreen')
      and $rule->dstAddressGroup->addrGroupName eq '^'
      and $rule->dstAddressGroup->zone eq '^'
      and $rule->serviceGroup->isa('Firewall::Config::Element::ServiceGroup::Netscreen')
      and $rule->serviceGroup->srvGroupName eq '^';
  },
  " lazy 生成 srcAddressGroup dstAddressGroup serviceGroup"
);
