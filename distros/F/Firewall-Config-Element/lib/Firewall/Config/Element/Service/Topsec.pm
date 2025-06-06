package Firewall::Config::Element::Service::Topsec;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Config::Element::ServiceMeta::Topsec;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::Service::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Service::Role';

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->srvName );
}

__PACKAGE__->meta->make_immutable;
1;
