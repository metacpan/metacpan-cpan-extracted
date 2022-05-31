package Firewall::Config::Parser::Elements;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Carp;
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element 各属性角色，实现属性校验
#------------------------------------------------------------------------------
use Firewall::Config::Element::Address::Role;
use Firewall::Config::Element::AddressGroup::Role;
use Firewall::Config::Element::DynamicNat::Role;
use Firewall::Config::Element::Interface::Role;
use Firewall::Config::Element::NatPool::Role;
use Firewall::Config::Element::Protocol::Role;
use Firewall::Config::Element::ProtocolGroup::Role;
use Firewall::Config::Element::Route::Role;
use Firewall::Config::Element::Rule::Role;
use Firewall::Config::Element::Schedule::Role;
use Firewall::Config::Element::Service::Role;
use Firewall::Config::Element::ServiceGroup::Role;
use Firewall::Config::Element::ServiceMeta::Role;
use Firewall::Config::Element::StaticNat::Role;
use Firewall::Config::Element::Zone::Role;

#------------------------------------------------------------------------------
# Firewall::Config::Parser::Elements 通用属性
#------------------------------------------------------------------------------
has natPool => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::NatPool::Role]',
  default => sub { {} },
);

has zone => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::Zone::Role]',
  default => sub { {} },
);

has interface => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::Interface::Role]',
  default => sub { {} },
);

has route => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::Route::Role]',
  default => sub { {} },
);

has staticNat => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::StaticNat::Role]',
  default => sub { {} },
);

has dynamicNat => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::DynamicNat::Role]',
  default => sub { {} },
);

has address => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::Address::Role]',
  default => sub { {} },
);

has addressGroup => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::AddressGroup::Role]',
  default => sub { {} },
);

has protocolGroup => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::ProtocolGroup::Role]',
  default => sub { {} },
);

has schedule => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::Schedule::Role]',
  default => sub { {} },
);

has service => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::Service::Role]',
  default => sub { {} },
);

has serviceGroup => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::ServiceGroup::Role]',
  default => sub { {} },
);

has rule => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::Rule::Role]',
  default => sub { {} },
);

#------------------------------------------------------------------------------
# addElement 新增解析对象元素类型
#------------------------------------------------------------------------------
sub addElement {
  my ( $self, $obj ) = @_;

  #say dumper $obj;
  my $className = ref($obj);
  if ( $className =~ /^Firewall::Config::Element::(?<elementType>\w+)::\w+$/o ) {
    my $elementType = lcfirst $+{elementType};
    $self->setElement( $elementType, $obj->sign, $obj );
  }
  else {
    confess "ERROR: obj must be an object of Firewall::Config::Element::xxxx";
  }
}

#------------------------------------------------------------------------------
# setElement 设置解析对象元素类型
# https://metacpan.org/pod/distribution/Moose/lib/Moose/Manual/Roles.pod
#------------------------------------------------------------------------------
sub setElement {
  my ( $self, $elementType, $sign, $obj ) = @_;
  confess "ERROR: elementType can't be Undef" unless defined $elementType;
  confess "ERROR: sign can't be Undef"        unless defined $sign;
  $elementType = lcfirst $elementType;

  # 判断实例化对象 obj 是否 does(roleName)
  my $roleName = 'Firewall::Config::Element::' . ucfirst($elementType) . '::Role';
  confess "ERROR: obj must implement Role $roleName" unless $obj->does($roleName);
  $self->{$elementType}{$sign} = $obj;
}

#------------------------------------------------------------------------------
# getElement 获取对象哈希标记
#------------------------------------------------------------------------------
sub getElement {
  my ( $self, $elementType, $sign ) = @_;
  confess "ERROR: elementType can't be Undef" unless defined $elementType;
  confess "ERROR: sign can't be Undef"        unless defined $sign;
  $elementType = lcfirst $elementType;
  return $self->$elementType->{$sign};
}

__PACKAGE__->meta->make_immutable;
1;
