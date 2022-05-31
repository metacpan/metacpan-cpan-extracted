package Firewall::Config::Element::Address::Srx;

use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Address::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Address::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Address::Srx 通用属性
#------------------------------------------------------------------------------
has zone => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildSign 方法，
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->zone, $self->addrName );
}

__PACKAGE__->meta->make_immutable;
1;
