#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 3;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::ServiceMeta::Asa;

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

has protocol => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has srcPort => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has dstPort => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);


has dstPortRange => (
    is => 'ro',
    isa => 'Firewall::Utils::Set',
    lazy => 1,
    builder => '_buildDstPortRange',
);

has '+srvName' => (
    required => 0,
);

has '+srcPort' => (
    required => 0,
);
=cut

my $serviceMeta;

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Asa->new(
        fwId     => 1,
        dstPort  => '100',
        protocol => 'tcp'
      );
    };
    warn $@ if $@;
    $serviceMeta->isa('Firewall::Config::Element::ServiceMeta::Asa');
  },
  ' 生成 Firewall::Config::Element::ServiceMeta::Asa 对象'
);

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Asa->new(
        fwId     => 1,
        dstPort  => '100',
        protocol => 'tcp'
      );
    };
    warn $@ if $@;
    $serviceMeta->sign eq '100<|>tcp';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Asa->new(
        fwId     => 1,
        dstPort  => '40000 40050',
        protocol => 'tcp'
      );
    };
    warn $@ if $@;
    $serviceMeta->dstPortRange->min == 40000
      and $serviceMeta->dstPortRange->max == 40050;
  },
  ' 自动生成dstPortRange'
);
