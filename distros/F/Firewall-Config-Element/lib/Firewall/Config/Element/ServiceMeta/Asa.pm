package Firewall::Config::Element::ServiceMeta::Asa;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::ServiceMeta::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::ServiceMeta::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::ServiceMeta::Asa 常用属性
#------------------------------------------------------------------------------
has '+srvName' => ( required => 0, );

has '+srcPort' => ( required => 0, );

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->dstPort, $self->protocol );
}

__PACKAGE__->meta->make_immutable;
1;
