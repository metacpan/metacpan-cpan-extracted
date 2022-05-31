package Firewall::Config::Element::AddressGroup::Asa;

use Moose;
use namespace::autoclean;
use Firewall::Config::Element::Address::Asa;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::AddressGroup::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::AddressGroup::Role';

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildSign 方法，
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->addrGroupName );
}

__PACKAGE__->meta->make_immutable;
1;
