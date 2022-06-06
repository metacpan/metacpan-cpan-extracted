package Firewall::Config::Element::Address::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use Firewall::Utils::Ip;
use Firewall::Utils::Set;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Address::Role 通用属性
#------------------------------------------------------------------------------
has addrName => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has ip => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has mask => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has range => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  lazy    => 1,
  builder => '_buildRange',
);

has type => (
  is      => 'ro',
  isa     => 'Str',
  default => 'subnet'
);

has refnum => (
  is      => 'ro',
  isa     => 'Int',
  default => 0
);

#------------------------------------------------------------------------------
# builder => _buildRange 将 ip 转换为 range 格式
#------------------------------------------------------------------------------
sub _buildRange {
  my $self  = shift;
  my $range = Firewall::Utils::Ip->getRangeFromIpMask( $self->{"ip"}, $self->{"mask"} );

  # 这里返回的匿名数组
  return ($range);
}

1;
