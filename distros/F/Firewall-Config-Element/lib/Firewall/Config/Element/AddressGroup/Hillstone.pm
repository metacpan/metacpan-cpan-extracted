package Firewall::Config::Element::AddressGroup::Hillstone;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Config::Element::Address::Hillstone;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::AddressGroup::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::AddressGroup::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::AddressGroup::H3c 通用属性
#------------------------------------------------------------------------------
has zone => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildSign 方法，
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->addrGroupName );
}

__PACKAGE__->meta->make_immutable;
1;
