package Firewall::Config::Element::Interface::Srx;

use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Interface::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Interface::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Interface::Srx 通用属性
#------------------------------------------------------------------------------
has routeInstance => (
  is      => 'ro',
  isa     => 'Str',
  default => 'default',
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->name );
}

__PACKAGE__->meta->make_immutable;
1;
