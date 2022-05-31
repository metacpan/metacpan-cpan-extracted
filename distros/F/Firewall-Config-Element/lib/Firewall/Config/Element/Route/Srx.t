#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 2;
use Mojo::Util qw(dumper);

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

has network => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has networkMask => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has routeInstance => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
=cut

my $route;

ok(
  do {
    eval { $route = Firewall::Config::Element::Route::Srx->new( fwId => 1, network => '10.0.0.0', mask => '8' ) };
    warn $@ if $@;
    $route->isa('Firewall::Config::Element::Route::Srx');

  },
  ' 生成 Firewall::Config::Element::Route::Srx 对象'
);

ok(
  do {
    eval { $route = Firewall::Config::Element::Route::Srx->new( fwId => 1, network => '10.0.0.0', mask => '8' ) };
    warn $@ if $@;
    $route->sign eq 'default<|>10.0.0.0<|>8';
  },
  ' lazy生成 sign'
);

