package Firewall::Config::Element::ServiceGroup::Huawei;

use Moose;
use namespace::autoclean;
use Firewall::Config::Element::Service::Huawei;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::ServiceGroup::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::ServiceGroup::Role';

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->srvGroupName );
}

__PACKAGE__->meta->make_immutable;
1;
