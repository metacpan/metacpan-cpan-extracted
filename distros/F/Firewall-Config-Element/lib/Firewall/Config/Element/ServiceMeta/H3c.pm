package Firewall::Config::Element::ServiceMeta::H3c;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::ServiceMeta::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::ServiceMeta::Role';

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig   = shift;
  my $class  = shift;
  my %params = @_;
  $params{srcPort} = '0-65535' if not defined $params{srcPort};
  if ( defined $params{protocol} and $params{protocol} !~ /^(tcp|udp)$/io ) {
    $params{dstPort} = '0-65535' if not defined $params{dstPort};
  }
  return $class->$orig(%params);
};

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->srvName, $self->protocol, $self->srcPort, $self->dstPort );
}

__PACKAGE__->meta->make_immutable;
1;
