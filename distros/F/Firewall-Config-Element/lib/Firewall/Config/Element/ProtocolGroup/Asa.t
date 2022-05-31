#!/usr/bin/env perl
use strict;
use warnings;

use Test::Simple tests => 3;
use Mojo::Util qw(dumper);

use Firewall::Config::Element::ProtocolGroup::Asa;

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

has proGroupName => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has proGroupMembers => (
    is => 'ro',
    does => 'HashRef[ Firewall::Config::Element::Protocol::Role | Firewall::Config::Element::ProtocolGroup::Role | Undef ]',
    default => sub { {} },
);

has protocols => (
    is => 'ro',
    does => 'HashRef[Firewall::Config::Element::Protocol::Role]',
    default => sub { {} },
);
=cut

my $protocolGroup;

ok(
  do {
    eval { $protocolGroup = Firewall::Config::Element::ProtocolGroup::Asa->new( fwId => 1, proGroupName => 'a' ) };
    warn $@ if $@;
    $protocolGroup->isa('Firewall::Config::Element::ProtocolGroup::Asa');
  },
  ' 生成 Firewall::Config::Element::ProtocolGroup::Asa 对象'
);

ok(
  do {
    eval { $protocolGroup = Firewall::Config::Element::ProtocolGroup::Asa->new( fwId => 1, proGroupName => 'a' ) };
    warn $@ if $@;
    $protocolGroup->sign eq 'a';
  },
  ' lazy生成 sign'
);

ok(
  do {
    eval {
      $protocolGroup = Firewall::Config::Element::ProtocolGroup::Asa->new(
        fwId         => 1,
        proGroupName => 'a'
      );
      my $protocol = Firewall::Config::Element::Protocol::Asa->new(
        fwId     => 1,
        protocol => 'd'
      );
      my $protocol1 = Firewall::Config::Element::Protocol::Asa->new(
        fwId     => 1,
        protocol => 'c'
      );
      my $protocolGroup1 = Firewall::Config::Element::ProtocolGroup::Asa->new(
        fwId         => 1,
        proGroupName => 'b'
      );
      $protocolGroup1->addProGroupMember( 'la', $protocol1 );
      $protocolGroup->addProGroupMember('abc');
      $protocolGroup->addProGroupMember( 'def', $protocol );
      $protocolGroup->addProGroupMember( 'ghi', $protocolGroup1 );
    };
    warn $@ if $@;
    exists $protocolGroup->proGroupMembers->{'abc'}
      and not defined $protocolGroup->proGroupMembers->{'abc'}
      and $protocolGroup->proGroupMembers->{'def'}->isa('Firewall::Config::Element::Protocol::Asa')
      and $protocolGroup->proGroupMembers->{'ghi'}->isa('Firewall::Config::Element::ProtocolGroup::Asa')
      and $protocolGroup->protocols->{'c'}->protocol eq 'c'
      and $protocolGroup->protocols->{'d'}->protocol eq 'd';
  },
  " addProGroupMember"
);
