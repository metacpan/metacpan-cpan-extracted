#!/usr/bin/env perl
use strict;
use warnings;
use 5.016;
use Test::Simple tests => 1;
use Mojo::Util qw(dumper);

use Firewall::Policy::Element::Service;

=lala
has fwId => (
    is => 'ro',
    isa => 'Int',
    required => 1,
);

has ruleSign => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);


has ranges => (
    is => 'ro',
    isa => 'Firewall::Utils::Set',
    builder => '_buildRanges',
);

has protocol => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

=cut

my $service;

ok(
  do {
    eval { $service = Firewall::Policy::Element::Service->new( ruleSign => 3, fwId => 5, protocol => 'tcp' ); };
    warn $@ if $@;
    $service->isa('Firewall::Policy::Element::Service');
  },
  ' 生成 Firewall::Policy::Element::Service 对象'
);
