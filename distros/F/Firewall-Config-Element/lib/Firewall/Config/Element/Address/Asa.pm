package Firewall::Config::Element::Address::Asa;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Address::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Address::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Address::Asa 通用属性
#------------------------------------------------------------------------------
# 改写 addrName 属性
has '+addrName' => ( required => 0, );

# 新增 iprange 属性
has iprange => ( is => 'ro', isa => 'Str', required => 0, );

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildSign 方法，
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  if ( defined $self->{iprange} ) {
    return $self->createSign( $self->{iprange} );
  }
  else {
    return $self->createSign( $self->ip, $self->mask );
  }
}

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Address::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self = shift;
  my $range;
  if ( defined $self->{iprange} ) {
    my ( $ipmin, $ipmax ) = split( '-', $self->{iprange} );
    $range = Firewall::Utils::Ip->new->getRangeFromIpRange( $ipmin, $ipmax );
  }
  else {
    $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $self->ip, $self->mask );
  }

  # 返回计算结果
  return ($range);
}

__PACKAGE__->meta->make_immutable;
1;
