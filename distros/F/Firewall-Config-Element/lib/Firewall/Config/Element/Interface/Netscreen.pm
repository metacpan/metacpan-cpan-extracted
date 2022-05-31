package Firewall::Config::Element::Interface::Netscreen;

use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Interface::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Interface::Role';

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Address::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->name );
}

__PACKAGE__->meta->make_immutable;
1;
