package Firewall::Config::Element::DynamicNat::Fortinet;

use Moose;
use namespace::autoclean;
use Firewall::Utils::Set;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::DynamicNat::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::DynamicNat::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::DynamicNat::Fortinet 通用属性
#------------------------------------------------------------------------------
has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has fromZone => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has toZone => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has srcIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set',
  required => 0,
);

has dstIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set',
  required => 0,
);

has dstPort => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has natDstPort => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has natSrcPool => (
  is       => 'ro',
  isa      => 'Firewall::Config::Element::NatPool::Fortinet | Undef',
  required => 0,
);

has natSrcIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set | Undef',
  required => 0,
);

has natDstIp => (
  is       => 'ro',
  isa      => 'Str | Undef',
  required => 0,
);

has natDstIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set | Undef',
  required => 0,
);

has policyId => (
  is       => 'ro',
  isa      => 'Int',
  required => 0,
);

has natDirection => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has proto => (
  is      => 'ro',
  isa     => 'Str',
  default => 'tcp',
);

has natInterface => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Address::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->name // $self->policyId );

}

__PACKAGE__->meta->make_immutable;
1;
