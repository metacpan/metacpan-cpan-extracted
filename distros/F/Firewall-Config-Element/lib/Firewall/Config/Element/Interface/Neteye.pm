package Firewall::Config::Element::Interface::Neteye;

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
# Firewall::Config::Element::Interface::Neteye 通用属性
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# 新增接口 vlan 方法
#------------------------------------------------------------------------------
sub addVlan {
  my ( $self, $vlanInt ) = @_;
  push @{$self->accessVlan}, $vlanInt->{name};
  $self->range->mergeToSet( $vlanInt->range );
}

__PACKAGE__->meta->make_immutable;
1;
