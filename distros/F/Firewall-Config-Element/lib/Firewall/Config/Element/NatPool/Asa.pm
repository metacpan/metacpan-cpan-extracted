package Firewall::Config::Element::NatPool::Asa;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Utils::Ip;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::NatPool::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::NatPool::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::NatPool::Asa 通用属性
#------------------------------------------------------------------------------
has zone => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->poolName );
}

#------------------------------------------------------------------------------
# 具体实现Firewall::Config::Element::NatPool::Role _buildRange 方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self = shift;
  if ( $self->poolIp =~ /^(?<minIp>[^-]+)-(?<maxIp>.+)$/ox ) {
    my ( $minIp, $minMask ) = split( '/', $+{minIp} );
    my ( $maxIp, $maxMask ) = split( '/', $+{maxIp} );
    my $min = Firewall::Utils::Ip->new->getRangeFromIpMask( $minIp, $minMask )->min;
    my $max = Firewall::Utils::Ip->new->getRangeFromIpMask( $maxIp, $maxMask )->max;
    return Firewall::Utils::Set->new( $min, $max );
  }
  elsif ( $self->poolIp =~ /^\d+\.\d+\.\d+\.\d+\/\d+\s*$/ox ) {
    my ( $ip, $mask ) = split( '/', $self->poolIp );
    return Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
  }
  else {
    print "$self->poolIp is wrong!\n";
    return Firewall::Utils::Set->new();
  }
}

__PACKAGE__->meta->make_immutable;
1;
