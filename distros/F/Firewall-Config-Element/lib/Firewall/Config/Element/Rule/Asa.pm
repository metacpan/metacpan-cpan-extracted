package Firewall::Config::Element::Rule::Asa;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Config::Element::AddressGroup::Asa;
use Firewall::Config::Element::ServiceGroup::Asa;
use Firewall::Config::Element::ProtocolGroup::Asa;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element::Rule::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Rule::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Asa 通用属性
#------------------------------------------------------------------------------
has zone => ( is => 'ro', isa => 'Str', required => 1, );

has aclName => ( is => 'ro', isa => 'Str', required => 1, );

has aclLineNumber => ( is => 'ro', isa => 'Int', required => 1, );

has protocolGroup => (
  is      => 'ro',
  isa     => 'Firewall::Config::Element::ProtocolGroup::Asa',
  lazy    => 1,
  builder => '_buildProtocolGroup',
);

#------------------------------------------------------------------------------
# 协议栈协议对象
#------------------------------------------------------------------------------
sub protocolMembers {
  my $self = shift;
  return $self->protocolGroup->proGroupMembers;
}

#------------------------------------------------------------------------------
# 添加策略协议栈
#------------------------------------------------------------------------------
sub addProtocolMembers {
  my ( $self, $ProtocolMemberName, $obj ) = @_;
  $self->protocolGroup->addProGroupMember( $ProtocolMemberName, $obj );
}

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
# 由于asa配置文件本身所决定，如果在配置文件中插入一个rule，可能会导致其它rule的
# aclLineNumber发生变化，所以本sign不具备长时间有效性，只能即查即用，切记切记
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->aclName, $self->aclLineNumber );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildSrcAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildSrcAddressGroup {
  my $self = shift;
  return Firewall::Config::Element::AddressGroup::Asa->new( fwId => $self->fwId, addrGroupName => '^' );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildDstAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildDstAddressGroup {
  my $self = shift;
  return Firewall::Config::Element::AddressGroup::Asa->new( fwId => $self->fwId, addrGroupName => '^' );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildServiceGroup 具体实现
#------------------------------------------------------------------------------
sub _buildServiceGroup {
  my $self = shift;
  return Firewall::Config::Element::ServiceGroup::Asa->new( fwId => $self->fwId, srvGroupName => '^' );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildProtocolGroup 具体实现
#------------------------------------------------------------------------------
sub _buildProtocolGroup {
  my $self = shift;
  return Firewall::Config::Element::ProtocolGroup::Asa->new( fwId => $self->fwId, proGroupName => '^' );
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
