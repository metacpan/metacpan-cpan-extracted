package Firewall::Config::Element::ProtocolGroup::Asa;

use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::ProtocolGroup::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::ProtocolGroup::Role';

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->proGroupName );
}

__PACKAGE__->meta->make_immutable;
1;
