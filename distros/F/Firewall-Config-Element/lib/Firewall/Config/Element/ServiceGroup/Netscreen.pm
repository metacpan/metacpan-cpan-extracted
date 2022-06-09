package Firewall::Config::Element::ServiceGroup::Netscreen;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Config::Element::Service::Netscreen;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::ServiceGroup::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::ServiceGroup::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::ServiceGroup::Netscreen 通用属性
#------------------------------------------------------------------------------
has description => ( is => 'ro', isa => 'Undef|Str', default => undef, );

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->srvGroupName );
}

__PACKAGE__->meta->make_immutable;
1;
