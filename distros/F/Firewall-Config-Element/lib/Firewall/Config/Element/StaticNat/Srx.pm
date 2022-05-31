package Firewall::Config::Element::StaticNat::Srx;

use Moose;
use namespace::autoclean;
use Firewall::Utils::Set;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::StaticNat::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::StaticNat::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::StaticNat::Srx 通用属性
#------------------------------------------------------------------------------
has natZone => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has realZone => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

has dstIpRange => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  default => sub { Firewall::Utils::Set->new( 0, 4294967295 ) },
);

has realIp => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

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

has natIp => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has ruleName => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has ruleSet => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->ruleSet, $self->ruleName );
}

__PACKAGE__->meta->make_immutable;
1;
