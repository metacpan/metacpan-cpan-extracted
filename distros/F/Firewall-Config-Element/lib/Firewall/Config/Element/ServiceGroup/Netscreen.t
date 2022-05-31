#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 3;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::Service::Netscreen;
use Firewall::Config::Element::ServiceGroup::Netscreen;

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

has dstPortRange => (
    is => 'ro',
    isa => 'Firewall::Utils::Set',
    default => sub { new Firewall::Utils::Set },
);

has description => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

=cut

my $serviceGroup;

ok(
  do {
    eval { $serviceGroup = Firewall::Config::Element::ServiceGroup::Netscreen->new( fwId => 1, srvGroupName => 'a' ) };
    warn $@ if $@;
    $serviceGroup->isa('Firewall::Config::Element::ServiceGroup::Netscreen');
  },
  ' 生成 Firewall::Config::Element::ServiceGroup::Netscreen 对象'
);

ok(
  do {
    eval { $serviceGroup = Firewall::Config::Element::ServiceGroup::Netscreen->new( fwId => 1, srvGroupName => 'a' ) };
    warn $@ if $@;
    $serviceGroup->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceGroup = Firewall::Config::Element::ServiceGroup::Netscreen->new(
        fwId         => 1,
        srvGroupName => 'a'
      );
      my $service = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
      my $service1 = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'e',
        srcPort  => 'c',
        dstPort  => '2525-2559'
      );
      my $serviceGroup1 = Firewall::Config::Element::ServiceGroup::Netscreen->new(
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
      and $serviceGroup->srvGroupMembers->{'def'}->isa('Firewall::Config::Element::Service::Netscreen')
      and $serviceGroup->srvGroupMembers->{'ghi'}->isa('Firewall::Config::Element::ServiceGroup::Netscreen')
      and $serviceGroup->dstPortRangeMap->{'b'}->min == 1525
      and $serviceGroup->dstPortRangeMap->{'b'}->max == 1559
      and $serviceGroup->dstPortRangeMap->{'e'}->min == 2525
      and $serviceGroup->dstPortRangeMap->{'e'}->max == 2559;
  },
  " addSrvGroupMember"
);
