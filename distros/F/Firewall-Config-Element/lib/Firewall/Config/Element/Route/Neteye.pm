package Firewall::Config::Element::Route::Neteye;

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
# Firewall::Config::Element::Route::Neteye 通用属性
#------------------------------------------------------------------------------
has '+network' => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has '+mask' => (
  is       => 'ro',
  isa      => 'Int',
  required => 0,
);

has type => (
  is      => 'ro',
  isa     => 'Str',
  default => 'static',
);

has srcInterface => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

has srcRange => (
  is       => 'ro',
  required => 0,
  isa      => 'Firewall::Utils::Set|Undef',
);

has dstInterface => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  if ( $self->type eq 'static' ) {
    return $self->createSign( $self->type, $self->network, $self->mask );
  }
  else {
    return $self->createSign( $self->type, $self->srcIpmask );
  }
}

__PACKAGE__->meta->make_immutable;
1;
