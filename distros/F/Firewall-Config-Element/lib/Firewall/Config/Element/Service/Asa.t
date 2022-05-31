#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 3;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::Service::Asa;

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

has dstPort => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
=cut

my $service;

ok(
  do {
    eval {
      $service = Firewall::Config::Element::Service::Asa->new(
        fwId     => 1,
        srvName  => 'a',
        dstPort  => '100',
        protocol => 'tcp'
      );
    };
    warn $@ if $@;
    $service->isa('Firewall::Config::Element::Service::Asa');
  },
  ' 生成 Firewall::Config::Element::Service::Asa 对象'
);

ok(
  do {
    eval {
      $service = Firewall::Config::Element::Service::Asa->new(
        fwId     => 1,
        srvName  => 'a',
        dstPort  => '100',
        protocol => 'tcp'
      );
    };
    warn $@ if $@;
    $service->sign eq 'a';
  },
  ' lazy生成 sign(有 srvName)'
);

ok(
  do {
    eval {
      $service = Firewall::Config::Element::Service::Asa->new(
        fwId     => 1,
        srvName  => 'a',
        dstPort  => '100',
        protocol => 'tcp'
      );
    };
    warn $@ if $@;
    $service->metas->{'100<|>tcp'}->sign eq '100<|>tcp'
      and $service->dstPortRangeMap->{'tcp'}->min == 100
      and $service->dstPortRangeMap->{'tcp'}->max == 100;
  },
  " new( fwId => 1, dstPort => '100', protocol => 'tcp' )"
);
