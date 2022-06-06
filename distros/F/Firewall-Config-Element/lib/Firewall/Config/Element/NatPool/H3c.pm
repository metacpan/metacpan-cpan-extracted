package Firewall::Config::Element::NatPool::H3c;

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
# Firewall::Config::Element::NatPool::H3c 通用属性
#------------------------------------------------------------------------------
has '+poolIp' => (
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 1,
);

has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

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
  my $set  = Firewall::Utils::Set->new();
  for my $addrange ( @{$self->poolIp} ) {
    my ( $minip, $maxip ) = split( /\s+/, $addrange );
    $set->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpRange( $minip, $maxip ) );
  }
  return $set;
}

__PACKAGE__->meta->make_immutable;
1;
