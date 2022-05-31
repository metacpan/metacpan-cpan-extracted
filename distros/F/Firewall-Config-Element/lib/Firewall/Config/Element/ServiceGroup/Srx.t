#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 3;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::Service::Srx;
use Firewall::Config::Element::ServiceGroup::Srx;

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
=cut

my $serviceGroup;

ok(
  do {
    eval { $serviceGroup = Firewall::Config::Element::ServiceGroup::Srx->new( fwId => 1, srvGroupName => 'a' ) };
    warn $@ if $@;
    $serviceGroup->isa('Firewall::Config::Element::ServiceGroup::Srx');
  },
  ' 生成 Firewall::Config::Element::ServiceGroup::Srx 对象'
);

ok(
  do {
    eval { $serviceGroup = Firewall::Config::Element::ServiceGroup::Srx->new( fwId => 1, srvGroupName => 'a' ) };
    warn $@ if $@;
    $serviceGroup->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceGroup = Firewall::Config::Element::ServiceGroup::Srx->new(
        fwId         => 1,
        srvGroupName => 'a'
      );
      my $service = Firewall::Config::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559',
        term     => 'z'
      );
      my $service1 = Firewall::Config::Element::Service::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'e',
        srcPort  => 'c',
        dstPort  => '2525-2559',
        term     => 'z'
      );
      my $serviceGroup1 = Firewall::Config::Element::ServiceGroup::Srx->new(
        fwId         => 1,
        srvGroupName => 'b'
      );
      $serviceGroup1->addSrvGroupMember( 'la', $service1 );
      $serviceGroup->addSrvGroupMember('abc');
      $serviceGroup->addSrvGroupMember( 'def', $service );
      $serviceGroup->addSrvGroupMember( 'ghi', $serviceGroup1 );
    };
    warn $@ if $@;
    exists $serviceGroup->srvGroupMembers->{'abc'}
      and not defined $serviceGroup->srvGroupMembers->{'abc'}
      and $serviceGroup->srvGroupMembers->{'def'}->isa('Firewall::Config::Element::Service::Srx')
      and $serviceGroup->srvGroupMembers->{'ghi'}->isa('Firewall::Config::Element::ServiceGroup::Srx')
      and $serviceGroup->dstPortRangeMap->{'b'}->min == 1525
      and $serviceGroup->dstPortRangeMap->{'b'}->max == 1559
      and $serviceGroup->dstPortRangeMap->{'e'}->min == 2525
      and $serviceGroup->dstPortRangeMap->{'e'}->max == 2559;
  },
  " addSrvGroupMember"
);
