package Firewall::Policy::Element::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.016;
use Moose::Role;
use Firewall::Utils::Set;

#------------------------------------------------------------------------------
# 定义 Firewall::Config::Element::Role 方法属性
# Moose lazy 懒加载属性，需要配置缺省值
#------------------------------------------------------------------------------
has policyId => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_buildPolicyId',
);

has fwId => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);

has ruleSign => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has ranges => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  default => sub { Firewall::Utils::Set->new },
);

#------------------------------------------------------------------------------
# 具体实现_buildPolicyId，返回策略签名 | 需要等待 ruleSign 生成
#------------------------------------------------------------------------------
sub _buildPolicyId {
  my $self = shift;
  return $self->ruleSign;
}

1;
