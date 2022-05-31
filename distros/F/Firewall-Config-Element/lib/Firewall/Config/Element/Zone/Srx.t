#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 2;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::Interface::Srx;
use Firewall::Config::Element::Zone::Srx;
use Firewall::Config::Element::Route::Srx;

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

has routeInstance => (
    is => 'ro',
    isa => 'Str',
    require => 1,
);

has name => (
    is => 'Str',
    require => 1,
);


has interfaces => (
    is =>'hashRef[Str]',
    require => 0,
    
);



=cut

my $zone;

ok(
  do {
    eval {
      $zone = Firewall::Config::Element::Zone::Srx->new(
        fwId => 1,
        name => 'trust'
      );
      my $interface = Firewall::Config::Element::Interface::Srx->new(
        fwId          => 1,
        name          => 'reth0.0',
        interfaceType => 'layer3',
        ipAddress     => '10.15.254.38',
        mask          => '29'
      );
      my $route = Firewall::Config::Element::Route::Srx->new(
        fwId    => $interface->fwId,
        network => $interface->ipAddress,
        mask    => $interface->mask
      );
      $interface->addRoute($route);
      $zone->addInterface($interface);
      say dumper $zone;
    };
    warn $@ if $@;
    $zone->isa('Firewall::Config::Element::Zone::Srx');
  },
  ' 生成 Firewall::Config::Element::Zone::Srx 对象'
);

ok(
  do {
    eval {
      $zone = Firewall::Config::Element::Interface::Srx->new(
        fwId => 1,
        name => 'trust'
      );

    };
    warn $@ if $@;
    $zone->sign eq 'trust';
  },
  ' lazy生成 sign'
);

