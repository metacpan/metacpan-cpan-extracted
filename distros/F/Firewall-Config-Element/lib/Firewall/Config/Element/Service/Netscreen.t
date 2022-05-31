#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 6;

use Firewall::Config::Element::Service::Netscreen;
use Firewall::Config::Element::ServiceMeta::Netscreen;

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

has srvName => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);


has metas => (
    is => 'ro',
    does => 'HashRef[Firewall::Config::Element::ServiceMeta::Role]',
    default => sub { {} },
);

has dstPortRangeMap => (
    is => 'ro',
    isa => 'HashRef[Firewall::Utils::Set]',
    default => sub { {} },
);
=cut

my $service;

ok(
  do {
    eval {
      $service = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if $@;
    $service->isa('Firewall::Config::Element::Service::Netscreen');
  },
  ' 生成 Firewall::Config::Element::Service::Netscreen 对象'
);

ok(
  do {
    eval {
      $service = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if $@;
    $service->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $service = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if $@;
    $service->addMeta(
      fwId     => 1,
      srvName  => 'a',
      protocol => 'd',
      srcPort  => 'c',
      dstPort  => '1525-1559'
    );
    $service->metas->{'a<|>b<|>c<|>1525-1559'}->sign eq 'a<|>b<|>c<|>1525-1559'
      and $service->dstPortRangeMap->{'b'}->min == 1525
      and $service->dstPortRangeMap->{'b'}->max == 1559;
  },
  " addMeta( fwId => 1, srvName => 'a', protocol => 'd', srcPort => 'c', dstPort => '1525-1559' )"
);

ok(
  do {
    eval {
      $service = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if $@;
    $service->addMeta(
      Firewall::Config::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'd',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      )
    );
    $service->metas->{'a<|>d<|>c<|>1525-1559'}->sign eq 'a<|>d<|>c<|>1525-1559'
      and $service->dstPortRangeMap->{'d'}->min == 1525
      and $service->dstPortRangeMap->{'d'}->max == 1559;
  },
  " addMeta( Firewall::Config::Element::ServiceMeta::Netscreen )"
);

ok(
  do {
    eval {
      $service = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
      $service->addMeta(
        Firewall::Config::Element::ServiceMeta::Netscreen->new(
          fwId     => 1,
          srvName  => 'a',
          protocol => 'd',
          srcPort  => 'c',
          dstPort  => '1525-1559'
        )
      );
      my $anotherService = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1520-1523'
      );
      $anotherService->addMeta(
        Firewall::Config::Element::ServiceMeta::Netscreen->new(
          fwId     => 1,
          srvName  => 'a',
          protocol => 'f',
          srcPort  => 'c',
          dstPort  => '1525-1559'
        )
      );
      $service->addMeta($anotherService);
    };
    warn $@ if $@;
          $service->metas->{'a<|>f<|>c<|>1525-1559'}->sign eq 'a<|>f<|>c<|>1525-1559'
      and $service->dstPortRangeMap->{'b'}->mins->[0] == 1520
      and $service->dstPortRangeMap->{'b'}->maxs->[0] == 1523
      and $service->dstPortRangeMap->{'b'}->mins->[1] == 1525
      and $service->dstPortRangeMap->{'b'}->maxs->[1] == 1559;
  },
  " addMeta( Firewall::Config::Element::Service::Netscreen )"
);

ok(
  do {
    eval {
      $service = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
      $service->addMeta(
        Firewall::Config::Element::ServiceMeta::Netscreen->new(
          fwId     => 1,
          srvName  => 'a',
          protocol => 'd',
          srcPort  => 'c',
          dstPort  => '1525-1559'
        )
      );
      my $anotherService = Firewall::Config::Element::Service::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1520-1523'
      );
      $anotherService->addMeta(
        Firewall::Config::Element::ServiceMeta::Netscreen->new(
          fwId     => 1,
          srvName  => 'a',
          protocol => 'f',
          srcPort  => 'c',
          dstPort  => '1525-1559'
        )
      );
      $service->addMeta($anotherService);
    };
    warn $@ if $@;
    my $timeout = 10;
    $service->setTimeout($timeout);
          $service->timeout == $timeout
      and $service->metas->{'a<|>b<|>c<|>1525-1559'}->timeout == $timeout
      and $service->metas->{'a<|>d<|>c<|>1525-1559'}->timeout == $timeout
      and $service->metas->{'a<|>b<|>c<|>1520-1523'}->timeout == $timeout
      and $service->metas->{'a<|>f<|>c<|>1525-1559'}->timeout == $timeout;
  },
  " setTimeout and timeout"
);

#print dumper($service);
