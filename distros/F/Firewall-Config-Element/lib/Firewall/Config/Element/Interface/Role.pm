package Firewall::Config::Element::Interface::Role;

use Carp;
use Moose::Role;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Interface::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Route::Role 通用属性
#------------------------------------------------------------------------------
has name => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has ipAddress => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has mask => (
  is       => 'ro',
  isa      => 'Int',
  required => 0,
);

# 接口类型是二层还是三层
has interfaceType => (
  is      => 'ro',
  isa     => 'Str',
  default => 'layer2',
);

has range => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  default => sub { Firewall::Utils::Set->new() }
);

# 接口路由
has routes => (
  is      => 'ro',
  isa     => 'HashRef',
  lazy    => 1,
  default => sub { {} },
);

# 接口安全区
has zoneName => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

#------------------------------------------------------------------------------
# Moose BUILD 用于对象创建后，进行属性检查逻辑
# https://metacpan.org/pod/Moose::Manual::Construction
#------------------------------------------------------------------------------
sub BUILD {
  my $self = shift;
  my @ERROR;
  if ( $self->interfaceType ne 'layer2' and $self->interfaceType ne 'layer3' ) {
    push @ERROR, "Attribute (interfaceType) 's value must be 'layer2' or 'layer3' at constructor " . __PACKAGE__;
  }
  if ( @ERROR > 0 ) {
    confess join( ', ', @ERROR );
  }
}

#------------------------------------------------------------------------------
# 新增接口路由函数
#------------------------------------------------------------------------------
sub addRoute {
  my ( $self, $route ) = @_;
  $self->routes->{$route->sign} = $route;
  $self->range->mergeToSet( $route->range );
}

1;
