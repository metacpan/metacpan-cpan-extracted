package Firewall::Policy::Element::Service;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 继承 Firewall::Policy::Element::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Policy::Element::Role';

#------------------------------------------------------------------------------
# 定义 Firewall::Policy::Element::Service 方法属性
#------------------------------------------------------------------------------
has protocol => ( is => 'ro', isa => 'Str', required => 1, );

has dstPort => ( is => 'ro', isa => 'Str', required => 0, );

__PACKAGE__->meta->make_immutable;
1;
