package Firewall::Config::Element::Route::Role;

use Moose::Role;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::Role 角色
#-------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Route::Role 通用属性
#-------------------------------------------------------------------------------
has network => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has mask => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);

has nextHop => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

has range => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  lazy    => 1,
  builder => '_buildRange',
);

has zoneName => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has distance => (
  is      => 'ro',
  isa     => 'Int',
  default => 10,
);

has priority => (
  is      => 'ro',
  isa     => 'Int',
  default => 0,
);

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
# https://metacpan.org/pod/Moose::Manual::Construction
# https://metacpan.org/pod/Moose::Object
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  my %param = @_;
  $param{network} = Firewall::Utils::Ip->new->getNetIpFromIpMask( $param{network}, $param{mask} );

  # 返回计算结果
  return $class->$orig(@_);
};

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self = shift;
  return Firewall::Utils::Ip->new->getRangeFromIpMask( $self->network, $self->mask );
}

1;
