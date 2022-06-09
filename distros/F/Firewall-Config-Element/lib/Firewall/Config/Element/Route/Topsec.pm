package Firewall::Config::Element::Route::Topsec;

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
# Firewall::Config::Element::Route::Topsec 通用属性
#------------------------------------------------------------------------------
has routeId => ( is => 'ro', isa => 'Str', required => 0, );

has type => ( is => 'ro', isa => 'Str', default => 'static', );

has srcInterface => ( is => 'ro', isa => 'Str|Undef', required => 0, );

has srcIpmask => ( is => 'ro', isa => 'Str|Undef', required => 0, );

has dstInterface => ( is => 'ro', isa => 'Str|Undef', required => 0, );

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#-------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->type, $self->network, $self->routeId );
}

__PACKAGE__->meta->make_immutable;
1;
