package Firewall::Config::Element::StaticNat::Neteye;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Utils::Set;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::StaticNat::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::StaticNat::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::StaticNat::Neteye 通用属性
#------------------------------------------------------------------------------
has id => ( is => 'ro', isa => 'Str', required => 1, );

has realIp => ( is => 'ro', isa => 'Str', required => 1, );

has realIpRange => ( is => 'ro', isa => 'Firewall::Utils::Set', default => sub { Firewall::Utils::Set->new }, );

has natIp => ( is => 'ro', isa => 'Str', required => 1, );

has natIpRange =>
  ( is => 'ro', isa => 'Firewall::Utils::Set', lazy => 1, default => sub { Firewall::Utils::Set->new }, );

has natInterface => ( is => 'ro', isa => 'Str', required => 0, );

has natZone => ( is => 'ro', isa => 'Str', required => 0, );

has realZone => ( is => 'ro', isa => 'Str', required => 0, );

has matchRule => ( is => 'ro', isa => 'Firewall::Config::Element::Rule::Role', required => 0, );

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->id );
}

__PACKAGE__->meta->make_immutable;
1;
