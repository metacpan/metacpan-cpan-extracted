package Firewall::Config::Element::Rule::Netscreen;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Config::Element::AddressGroup::Netscreen;
use Firewall::Config::Element::ServiceGroup::Netscreen;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element::Rule::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Rule::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Netscreen 通用属性
#------------------------------------------------------------------------------
has policyId => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

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

has hasApplicationCheck => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
  writer  => 'setHasApplicationCheck',
);

has alias => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has priority => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->policyId );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildSrcAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildSrcAddressGroup {
  my $self = shift;
  return Firewall::Config::Element::AddressGroup::Netscreen->new(
    fwId          => $self->fwId,
    addrGroupName => '^',
    zone          => '^'
  );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildDstAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildDstAddressGroup {
  my $self = shift;
  return Firewall::Config::Element::AddressGroup::Netscreen->new(
    fwId          => $self->fwId,
    addrGroupName => '^',
    zone          => '^'
  );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildServiceGroup 具体实现
#------------------------------------------------------------------------------
sub _buildServiceGroup {
  my $self = shift;
  return Firewall::Config::Element::ServiceGroup::Netscreen->new(
    fwId         => $self->fwId,
    srvGroupName => '^'
  );
}

#------------------------------------------------------------------------------
# 忽略 disable 状态的策略
#------------------------------------------------------------------------------
sub ignore {
  my $self = shift;
  return (
    defined $self->isDisable and $self->isDisable eq 'disable'
      or $self->hasSchedule  and $self->schedule->isExpired
  );
}

__PACKAGE__->meta->make_immutable;
1;
