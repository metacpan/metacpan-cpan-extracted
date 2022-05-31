#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 3;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::ServiceGroup::Asa;

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

has srvGroupName => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has srvGroupMembers => (
    is => 'ro',
    does => 'HashRef[ Firewall::Config::Element::Service::Role | Firewall::Config::Element::ServiceGroup::Role | Undef ]',
    default => sub { {} },
);

has dstPortRangeMap => (
    is => 'ro',
    isa => 'HashRef[Firewall::Utils::Set]',
    default => sub { {} },
);

has protocol => (
    is => 'ro',
    isa => 'Undef|Str',
    required => 0,
    default => undef,
);
=cut

my $serviceGroup;

ok(
  do {
    eval {
      $serviceGroup = Firewall::Config::Element::ServiceGroup::Asa->new(
        fwId         => 1,
        srvGroupName => 'a',
        protocol     => 't'
      );
    };
    warn $@ if $@;
    $serviceGroup->isa('Firewall::Config::Element::ServiceGroup::Asa');
  },
  ' 生成 Firewall::Config::Element::ServiceGroup::Asa 对象'
);

ok(
  do {
    eval {
      $serviceGroup = Firewall::Config::Element::ServiceGroup::Asa->new(
        fwId         => 1,
        srvGroupName => 'a',
        protocol     => 't'
      );
    };
    warn $@ if $@;
    $serviceGroup->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceGroup = Firewall::Config::Element::ServiceGroup::Asa->new(
        fwId         => 1,
        srvGroupName => 'a',
        protocol     => 't'
      );
      my $service = Firewall::Config::Element::Service::Asa->new(
        fwId     => 1,
        srvName  => 'b',
        dstPort  => '100',
        protocol => 'u'
      );
      my $service1 = Firewall::Config::Element::Service::Asa->new(
        fwId     => 1,
        srvName  => 'c',
        dstPort  => '200',
        protocol => 'v'
      );
      my $serviceGroup1 = Firewall::Config::Element::ServiceGroup::Asa->new(
        fwId         => 1,
        srvGroupName => 'b',
        protocol     => 't'
      );
      $serviceGroup1->addSrvGroupMember( 'la', $service1 );
      $serviceGroup->addSrvGroupMember('abc');
      $serviceGroup->addSrvGroupMember( 'def', $service );
      $serviceGroup->addSrvGroupMember( 'ghi', $serviceGroup1 );
    };
    warn $@ if $@;
    exists $serviceGroup->srvGroupMembers->{'abc'}
      and not defined $serviceGroup->srvGroupMembers->{'abc'}
      and $serviceGroup->srvGroupMembers->{'def'}->isa('Firewall::Config::Element::Service::Asa')
      and $serviceGroup->srvGroupMembers->{'ghi'}->isa('Firewall::Config::Element::ServiceGroup::Asa')
      and $serviceGroup->dstPortRangeMap->{'u'}->mins->[0] == 100
      and $serviceGroup->dstPortRangeMap->{'u'}->maxs->[0] == 100
      and $serviceGroup->dstPortRangeMap->{'v'}->mins->[0] == 200
      and $serviceGroup->dstPortRangeMap->{'v'}->maxs->[0] == 200;
  },
  " addSrvGroupMember"
);
