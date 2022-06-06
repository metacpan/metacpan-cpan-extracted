package Firewall::Config::Element::ServiceMeta::Netscreen;

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
# Firewall::Config::Element::ServiceMeta::Netscreen 通用属性
#------------------------------------------------------------------------------
has timeout => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
  writer  => 'setTimeout',
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->srvName, $self->protocol, $self->srcPort, $self->dstPort );
}

__PACKAGE__->meta->make_immutable;
1;
