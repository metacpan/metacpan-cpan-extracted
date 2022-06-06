package Firewall::Config::Element::Address::Fortinet;

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
# Firewall::Config::Element::Address::Fortinet 通用属性
#------------------------------------------------------------------------------
# 改写 ip mask 属性 => 非必须
has '+ip' => (
  required => 0,
);

has '+mask' => (
  required => 0,
);

has zone => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has startIp => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has endIp => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildSign 方法，
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->addrName );
}

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Address::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self  = shift;
  my $range = Firewall::Utils::Set->new;
  $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $self->ip, $self->mask )        if $self->type eq 'subnet';
  $range = Firewall::Utils::Ip->new->getRangeFromIpRange( $self->startIp, $self->endIp ) if $self->type eq 'iprange';

  # 返回计算结果
  return ($range);
}

__PACKAGE__->meta->make_immutable;
1;
