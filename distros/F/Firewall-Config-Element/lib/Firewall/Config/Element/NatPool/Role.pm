package Firewall::Config::Element::NatPool::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::NatPool::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::NatPool::Rool 通用属性
#------------------------------------------------------------------------------
has poolIp => ( is => 'ro', isa => 'Str', required => 1, );

# _buildRange 需要具体实现
has poolRange => ( is => 'ro', isa => 'Firewall::Utils::Set', lazy => 1, builder => '_buildRange' );

has poolName => ( is => 'ro', isa => 'Str', required => 1, );

1;
