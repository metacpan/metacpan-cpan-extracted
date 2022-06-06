package Firewall::Config::Element::Interface::Topsec;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Interface::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Interface::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Interface::Topsec 通用属性
#------------------------------------------------------------------------------
has accessMode => (
  is      => 'rw',
  isa     => 'Str',
  default => 'access',
);

has accessVlan => (
  is      => 'rw',
  isa     => 'ArrayRef',
  default => sub { [] },
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
