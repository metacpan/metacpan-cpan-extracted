#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 4;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::ServiceMeta::Srx;

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

has term => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has timeout => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);

has uuid => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
);
=cut

my $serviceMeta;

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        term     => 'd',
        protocol => 'tcp',
        srcPort  => '1000-1024',
        dstPort  => '135-135'
      );
    };
    warn $@ if $@;
    $serviceMeta->isa('Firewall::Config::Element::ServiceMeta::Srx');
  },
  ' 生成 Firewall::Config::Element::ServiceMeta::Srx 对象'
);

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        term     => 'd',
        protocol => 'tcp',
        srcPort  => '0-65535',
        dstPort  => '135-135'
      );
    };
    warn $@ if $@;
    $serviceMeta->sign eq 'a<|>d';
  },
  ' lazy生成 sign(有 term)'
);

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'tcp',
        srcPort  => '0-65535',
        dstPort  => '135-135'
      );
    };
    warn $@ if $@;
    $serviceMeta->sign eq 'a<|> ';
  },
  ' lazy生成 sign(没有 term)'
);

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Srx->new(
        fwId     => 1,
        srvName  => 'a',
        term     => 'd',
        protocol => 'tcp',
        srcPort  => '0-65535',
        dstPort  => '135-135'
      );
    };
    warn $@ if $@;
    $serviceMeta->dstPortRange->min == 135
      and $serviceMeta->dstPortRange->max == 135;
  },
  ' 自动生成dstPortRange'
);
