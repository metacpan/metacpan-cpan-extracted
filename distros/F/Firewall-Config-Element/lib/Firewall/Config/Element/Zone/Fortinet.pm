package Firewall::Config::Element::Zone::Fortinet;

use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Zone::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Zone::Role';

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->name );
}

__PACKAGE__->meta->make_immutable;
1;
