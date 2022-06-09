package Firewall::Config::Element::Route::Srx;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Route::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Route::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Route::Srx 通用属性
#------------------------------------------------------------------------------
has routeInstance => ( is => 'ro', isa => 'Str', required => 1, default => 'default' );

has type => ( is => 'ro', isa => 'Str', default => 'static', );

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#-------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->routeInstance, $self->network, $self->mask );
}

__PACKAGE__->meta->make_immutable;
1;
