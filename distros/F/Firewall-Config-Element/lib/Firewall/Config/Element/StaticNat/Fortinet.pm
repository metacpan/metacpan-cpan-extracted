package Firewall::Config::Element::StaticNat::Fortinet;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Utils::Ip;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::StaticNat::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::StaticNat::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::StaticNat::Fortinet 通用属性
#------------------------------------------------------------------------------
has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has realIp => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has realIpRange => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  lazy    => 1,
  builder => '_buildRealIpRange',
);

has natIp => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has natIpRange => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  lazy    => 1,
  builder => '_buildNatIpRange',
);

has natInterface => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has natZone => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has realZone => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->name );
}

#------------------------------------------------------------------------------
# 生成 _buildRealIpRange 对象
#------------------------------------------------------------------------------
sub _buildRealIpRange {
  my $self = shift;
  my $ip   = '\d+\.\d+\.\d+\.\d+';
  my $range;
  if ( $self->realIp =~ /$ip-$ip/ ) {
    my ( $ipmin, $ipmax ) = split( '-', $self->realIp );
    $ipmax = $ipmin if not defined $ipmin;
    $range = Firewall::Utils::Ip->new->getRangeFromIpRange( $ipmin, $ipmax );
  }
  elsif ( $self->realIp =~ /$ip(\/\d+)?/ ) {
    my ( $ip, $mask ) = split( '/', $self->realIp );
    $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );

  }
  return ($range);
}

#------------------------------------------------------------------------------
# 生成 _buildNatIpRange 对象
#------------------------------------------------------------------------------
sub _buildNatIpRange {
  my $self = shift;
  my ( $ipmin, $ipmax ) = split( '-', $self->natIp );
  $ipmax = $ipmin if not defined $ipmax;
  my $range = Firewall::Utils::Ip->new->getRangeFromIpRange( $ipmin, $ipmax );
  return ($range);
}

__PACKAGE__->meta->make_immutable;
1;
