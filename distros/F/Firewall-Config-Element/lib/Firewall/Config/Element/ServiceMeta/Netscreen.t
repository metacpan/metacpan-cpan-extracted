#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 3;
use Mojo::Util qw(dumper);

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

has timeout => (
    is => 'ro',
    isa => 'Undef|Str',
    default => undef,
    writer => 'setTimeout',
);
=cut

my $serviceMeta;

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if $@;
    ref($serviceMeta) eq 'Firewall::Config::Element::ServiceMeta::Netscreen' ? 1 : 0;
  },
  ' 生成 Firewall::Config::Element::ServiceMeta::Netscreen 对象'
);

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if $@;
    $serviceMeta->sign eq 'a<|>b<|>c<|>1525-1559';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $serviceMeta = Firewall::Config::Element::ServiceMeta::Netscreen->new(
        fwId     => 1,
        srvName  => 'a',
        protocol => 'b',
        srcPort  => 'c',
        dstPort  => '1525-1559'
      );
    };
    warn $@ if $@;
    $serviceMeta->dstPortRange->min == 1525
      and $serviceMeta->dstPortRange->max == 1559;
  },
  ' 自动生成dstPortRange'
);

#print dumper($serviceMeta);
