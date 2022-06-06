package Firewall::Config::Element::Rule::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role 通用属性
#------------------------------------------------------------------------------
has action => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has isDisable => (
  is      => 'ro',
  isa     => 'Str',
  default => 'enable',
  writer  => 'setIsDisable',
);

has hasLog => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has schName => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has content => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
  writer   => 'setContent',
);

has srcAddressGroup => (
  is      => 'ro',
  does    => 'Firewall::Config::Element::AddressGroup::Role',
  lazy    => 1,
  builder => '_buildSrcAddressGroup',
);

has dstAddressGroup => (
  is      => 'ro',
  does    => 'Firewall::Config::Element::AddressGroup::Role',
  lazy    => 1,
  builder => '_buildDstAddressGroup',
);

has serviceGroup => (
  is      => 'ro',
  does    => 'Firewall::Config::Element::ServiceGroup::Role',
  lazy    => 1,
  builder => '_buildServiceGroup',
);

has schedule => (
  is        => 'ro',
  does      => 'Firewall::Config::Element::Schedule::Role',
  predicate => 'hasSchedule',
  writer    => 'setSchedule',
);

has ruleNum => (
  is       => 'ro',
  isa      => 'Int',
  required => 0,
);

#------------------------------------------------------------------------------
# does 对象 requires 需要实现的方法
# https://metacpan.org/pod/Moose::Role
#------------------------------------------------------------------------------
requires 'ignore';
requires '_buildSrcAddressGroup';
requires '_buildDstAddressGroup';
requires '_buildServiceGroup';

#------------------------------------------------------------------------------
# 源地址成员
#------------------------------------------------------------------------------
sub srcAddressMembers {
  my $self = shift;
  return $self->srcAddressGroup->addrGroupMembers;
}

#------------------------------------------------------------------------------
# 目的地址成员
#------------------------------------------------------------------------------
sub dstAddressMembers {
  my $self = shift;
  return $self->dstAddressGroup->addrGroupMembers;
}

#------------------------------------------------------------------------------
# 服务端口成员
#------------------------------------------------------------------------------
sub serviceMembers {
  my $self = shift;
  return $self->serviceGroup->srvGroupMembers;
}

#------------------------------------------------------------------------------
# 新增源地址成员
#------------------------------------------------------------------------------
sub addSrcAddressMembers {
  my ( $self, $srcAddressMemberName, $obj ) = @_;
  $self->srcAddressGroup->addAddrGroupMember( $srcAddressMemberName, $obj );
}

#------------------------------------------------------------------------------
# 新增目的地址成员
#------------------------------------------------------------------------------
sub addDstAddressMembers {
  my ( $self, $dstAddressMemberName, $obj ) = @_;
  $self->dstAddressGroup->addAddrGroupMember( $dstAddressMemberName, $obj );
}

#------------------------------------------------------------------------------
# 新增服务端口成员
#------------------------------------------------------------------------------
sub addServiceMembers {
  my ( $self, $serviceMemberName, $obj ) = @_;
  $self->serviceGroup->addSrvGroupMember( $serviceMemberName, $obj );
}

#------------------------------------------------------------------------------
# 新增策略规则内容
#------------------------------------------------------------------------------
sub addContent {
  my ( $self, $content ) = @_;
  my $conf = $self->content;

  # 去除变量首尾空白
  chomp $conf;
  chomp $content;
  $conf .= "\n" . $content;
  $self->setContent($conf);
}

1;
