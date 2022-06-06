package Firewall::Config::Element::Service::Netscreen;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Config::Element::ServiceMeta::Netscreen;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::Service::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Service::Role';

#------------------------------------------------------------------------------
# timeout 具体实现功能推敲
#------------------------------------------------------------------------------
sub timeout {
  my $self = shift;
  my $timeout;
  for my $serviceMeta ( values %{$self->metas} ) {
    $timeout = $serviceMeta->timeout;
    last;
  }
  return $timeout;
}

#------------------------------------------------------------------------------
# setTimeout 具体实现功能推敲
#------------------------------------------------------------------------------
sub setTimeout {
  my ( $self, $timeout ) = @_;
  for my $serviceMeta ( values %{$self->metas} ) {
    $serviceMeta->setTimeout($timeout);
  }
}

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->srvName );
}

__PACKAGE__->meta->make_immutable;
1;
