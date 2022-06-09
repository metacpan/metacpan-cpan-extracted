package Firewall::Config::Element::Zone::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use Firewall::Config::Element::Interface::Role;
use Firewall::Utils::Set;
use Firewall::Utils::Ip;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Zone::Role 通用属性
#------------------------------------------------------------------------------
has name => ( is => 'ro', isa => 'Str', required => 1, );

has interfaces => ( is => 'ro', does => 'HashRef[Firewall::Config::Element::Interface::Role]', default => sub { {} }, );

has range => ( is => 'ro', isa => 'Firewall::Utils::Set', lazy => 1, default => sub { Firewall::Utils::Set->new() } );

#------------------------------------------------------------------------------
# 安全区添加接口
#------------------------------------------------------------------------------
sub addInterface {
  my ( $self, $interface ) = @_;
  $self->interfaces->{$interface->sign} = $interface;
  $self->range->mergeToSet( $interface->range );
}

#------------------------------------------------------------------------------
# 完全区添加地址段
#------------------------------------------------------------------------------
sub addrIpRange {
  my $self            = shift;
  my $addrIpRangeARef = [];
  my $ipObj           = Firewall::Utils::Ip->new;
  for ( my $i = 0; $i < $self->range->length; $i++ ) {
    my $ipMin   = $ipObj->changeIntToIp( $self->range->mins->[$i] );
    my $ipMax   = $ipObj->changeIntToIp( $self->range->maxs->[$i] );
    my $ipRange = $ipMin . '-' . $ipMax;
    push @{$addrIpRangeARef}, $ipRange;
  }
  return $addrIpRangeARef;
}

#------------------------------------------------------------------------------
# 安全区地址段 - 最小地址结合
#------------------------------------------------------------------------------
sub mins {
  my $self = shift;
  return $self->range->mins;
}

#------------------------------------------------------------------------------
# 安全区地址段 - 最大地址结合
#------------------------------------------------------------------------------
sub maxs {
  my $self = shift;
  return $self->range->maxs;
}

1;
