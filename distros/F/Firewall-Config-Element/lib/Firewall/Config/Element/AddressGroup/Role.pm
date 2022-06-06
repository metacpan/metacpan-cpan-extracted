package Firewall::Config::Element::AddressGroup::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use Firewall::Utils::Set;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::AddressGroup::Role 通用属性
#------------------------------------------------------------------------------
has addrGroupName => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has addrGroupMembers => (
  is   => 'ro',
  does => 'HashRef[ Firewall::Config::Element::Address::Role | Firewall::Config::Element::AddressGroup::Role | Undef ]',
  default => sub { {} },
);

has range => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  default => sub { Firewall::Utils::Set->new },
);

has refnum => (
  is      => 'ro',
  isa     => 'Int',
  default => 0
);

#------------------------------------------------------------------------------
# 新增地址组成员方法
#------------------------------------------------------------------------------
sub addAddrGroupMember {
  my ( $self, $addrGroupMemberName, $obj ) = @_;
  confess "ERROR: addrGroupMemberName must defined" unless ( defined $addrGroupMemberName );
  unless ( not defined $obj
    or $obj->does('Firewall::Config::Element::Address::Role')
    or $obj->does('Firewall::Config::Element::AddressGroup::Role') )
  {
    confess
      "ERROR: 参数 obj 只能是 Firewall::Config::Element::Address::Role or Firewall::Config::Element::AddressGroup::Role or Undef";
  }
  $self->{addrGroupMembers}{$addrGroupMemberName} = $obj;
  if ( defined $obj ) {
    $self->range->mergeToSet( $obj->range );
  }
}

1;
