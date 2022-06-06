package Firewall::Config::Element::Protocol::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Protocol::Role 通用方法
#------------------------------------------------------------------------------
has protocol => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
# https://metacpan.org/pod/Moose::Manual::Construction
# https://metacpan.org/pod/Moose::Object
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  # 接收传递进来的遍历
  my %params = @_;
  $params{protocol} = lc( $params{protocol} ) if defined $params{protocol};
  return $class->$orig(@_);
};

1;
