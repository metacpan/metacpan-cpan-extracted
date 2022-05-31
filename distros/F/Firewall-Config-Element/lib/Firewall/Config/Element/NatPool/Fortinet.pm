package Firewall::Config::Element::NatPool::Fortinet;

use Moose;
use namespace::autoclean;
use Firewall::Utils::Ip;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::NatPool::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::NatPool::Role';

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildSign 方法，
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
    return Firewall::Utils::Ip->new->getRangeFromIpRange( $+{minIp}, $+{maxIp} );
  }
  elsif ( $self->poolIp =~ /^\d+\.\d+\.\d+\.\d+(\/\d+)?\s*$/ox ) {
    my ( $ip, $mask ) = split( '/', $self->poolIp );
    $mask = 32 if not defined $mask;
    return Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
  }
  else {
    print "$self->poolIp is wrong!\n";
    return Firewall::Utils::Set->new();
  }
}

__PACKAGE__->meta->make_immutable;
1;
