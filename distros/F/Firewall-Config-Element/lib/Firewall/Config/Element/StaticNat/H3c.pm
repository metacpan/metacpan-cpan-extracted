package Firewall::Config::Element::StaticNat::H3c;

use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::StaticNat::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::StaticNat::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::StaticNat::H3c 通用属性
#------------------------------------------------------------------------------
has realIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set',
  required => 1,
);

has natIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set',
  required => 1,
);

has aclName => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has aclNum => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has realIp => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has natIp => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->natIp );
}

__PACKAGE__->meta->make_immutable;
1;
