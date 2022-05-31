package Firewall::Config::Element::DynamicNat::Topsec;

use Moose;
use namespace::autoclean;

#-----------------------------------------------------------------------------
# 引用 Firewall::Config::Element::DynamicNat::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::DynamicNat::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::DynamicNat::Topsec 通用属性
#------------------------------------------------------------------------------
has id => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);

has fromZone => (
  is       => 'ro',
  isa      => 'Str | Undef',
  required => 0,
);

has toZone => (
  is       => 'ro',
  isa      => 'Str | Undef',
  required => 0,
);

has srcIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set',
  required => 0,
);

has dstIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set',
  required => 0,
);

has srvRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set',
  required => 0,
);

has natSrcIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set | Undef',
  required => 0,
);

has natDstIp => (
  is       => 'ro',
  isa      => 'Str | Undef',
  required => 0,
);

has natDstIpRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set | Undef',
  required => 0,
);

has natSrvRange => (
  is       => 'ro',
  isa      => 'Firewall::Utils::Set | Undef',
  required => 0,
);

# source|destination
has natDirection => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has proto => (
  is      => 'ro',
  isa     => 'Str',
  default => 'tcp',
);

has natInterface => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->id, $self->fromZone, $self->toZone );
}

__PACKAGE__->meta->make_immutable;
1;
