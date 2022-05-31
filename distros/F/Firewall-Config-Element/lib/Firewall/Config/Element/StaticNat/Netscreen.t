#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 2;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::StaticNat::Netscreen;

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

has natZone => (
    is => 'ro',
    isa => 'Str',
    required => 0,
);
  
has realZone => (
    is => 'ro',
    isa => 'Str',
    required => 0,
);

has realIp => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has natIp => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has mask => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
=cut

my $staticNat;

ok(
  do {
    eval {
      $staticNat = Firewall::Config::Element::StaticNat::Netscreen->new(
        fwId     => 1,
        realZone => 'dmz',
        natZone  => 'trust',
        natIp    => '10.37.172.25',
        realIp   => '192.168.184.25',
        mask     => '32'
      );
    };
    warn $@ if $@;
    $staticNat->isa('Firewall::Config::Element::StaticNat::Netscreen');
  },
  ' 生成 Firewall::Config::Element::StaticNat::Netscreen 对象'
);

ok(
  do {
    eval {
      $staticNat = Firewall::Config::Element::StaticNat::Netscreen->new(
        fwId     => 1,
        realZone => 'dmz',
        natZone  => 'trust',
        natIp    => '10.37.172.25',
        realIp   => '192.168.184.25',
        mask     => '32'
      );
    };
    warn $@ if $@;
    $staticNat->sign eq '10.37.172.25';
  },
  ' lazy生成 sign'
);
