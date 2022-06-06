package Firewall::Config::Element::DynamicNat::Netscreen;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::DynamicNat::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::DynamicNat::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::DynamicNat::Netscreen 通用属性
#------------------------------------------------------------------------------
has fromZone => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has toZone => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
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

has srv => (
  is       => 'ro',
  isa      => 'Firewall::Config::Element::Service::Netscreen | Undef',
  required => 0,
);

has natSrcPool => (
  is       => 'ro',
  isa      => 'Firewall::Config::Element::NatPool::Netscreen | Undef',
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
  required => 1,
);

has natDstPort => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has srvRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set | Undef',
  required => 0,
);

has natSrvRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set | Undef',
  required => 0,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  if ( defined $self->{policyId} ) {
    return $self->createSign( $self->policyId );
  }
  else {
    if ( defined $self->{natDstIp} and defined $self->{natDstPort} ) {
      return $self->createSign( $self->{natDstIp}, $self->{natDstPort} );
    }
  }
}

__PACKAGE__->meta->make_immutable;
1;
