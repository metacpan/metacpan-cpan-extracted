package Firewall::Config::Element::Rule::Srx;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Config::Element::AddressGroup::Srx;
use Firewall::Config::Element::ServiceGroup::Srx;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element::Rule::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Rule::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Netscreen 通用属性
#------------------------------------------------------------------------------
has ruleName => ( is => 'ro', isa => 'Str', required => 1, );

has fromZone => ( is => 'ro', isa => 'Str', required => 1, );

has toZone => ( is => 'ro', isa => 'Str', required => 1, );

has '+action' => ( required => 0, writer => 'setAction', );

has '+schName' => ( writer => 'setSchName', );

has '+hasLog' => ( writer => 'setHasLog', );

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->fromZone, $self->toZone, $self->ruleName );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildSrcAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildSrcAddressGroup {
  my $self = shift;
  return Firewall::Config::Element::AddressGroup::Srx->new( fwId => $self->fwId, addrGroupName => '^', zone => '^' );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildDstAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildDstAddressGroup {
  my $self = shift;
  return Firewall::Config::Element::AddressGroup::Srx->new( fwId => $self->fwId, addrGroupName => '^', zone => '^' );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildServiceGroup 具体实现
#------------------------------------------------------------------------------
sub _buildServiceGroup {
  my $self = shift;
  return Firewall::Config::Element::ServiceGroup::Srx->new( fwId => $self->fwId, srvGroupName => '^' );
}

#------------------------------------------------------------------------------
# 忽略 disable 状态的策略
#------------------------------------------------------------------------------
sub ignore {
  my $self = shift;
  return (
    defined $self->isDisable and $self->isDisable eq 'deactivate'
      or $self->hasSchedule  and $self->schedule->isExpired
  );
}

__PACKAGE__->meta->make_immutable;
1;
