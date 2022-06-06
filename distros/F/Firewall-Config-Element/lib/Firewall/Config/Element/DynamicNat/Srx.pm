package Firewall::Config::Element::DynamicNat::Srx;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#-----------------------------------------------------------------------------
# 引用 Firewall::Config::Element::DynamicNat::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::DynamicNat::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::DynamicNat::Srx 通用属性
#------------------------------------------------------------------------------
has fromZone => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has toZone => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has srcIpRange => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  default => sub { Firewall::Utils::Set->new },
);

has dstIpRange => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  default => sub { Firewall::Utils::Set->new },
);

has natSrcPool => (
  is       => 'ro',
  isa      => 'Firewall::Config::Element::NatPool::Srx | Undef',
  required => 0,
);

has natSrcRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set | Undef',
  required => 0,
);

has natDstPool => (
  is       => 'ro',
  isa      => 'Firewall::Config::Element::NatPool::Srx | Undef',
  required => 0,
);

has natDstRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set | Undef',
  required => 0,
);

has natDstPort => (
  is       => 'ro',
  isa      => 'Int | Undef',
  required => 0,
);

has ruleName => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has ruleSet => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has natDirection => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->ruleSet, $self->ruleName );
}

__PACKAGE__->meta->make_immutable;
1;
