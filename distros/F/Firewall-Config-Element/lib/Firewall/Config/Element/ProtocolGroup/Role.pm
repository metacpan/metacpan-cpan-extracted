package Firewall::Config::Element::ProtocolGroup::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::ProtocolGroup::Role 通用属性
#------------------------------------------------------------------------------
has proGroupName => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has proGroupMembers => (
  is   => 'ro',
  does =>
    'HashRef[ Firewall::Config::Element::Protocol::Role | Firewall::Config::Element::ProtocolGroup::Role | Undef ]',
  default => sub { {} },
);

has protocols => (
  is      => 'ro',
  does    => 'HashRef[Firewall::Config::Element::Protocol::Role]',
  default => sub { {} },
);

#------------------------------------------------------------------------------
# 新增协议对象成员方法
#------------------------------------------------------------------------------
sub addProGroupMember {
  my ( $self, $proGroupMemberName, $obj ) = @_;
  confess "ERROR: proGroupMemberName must defined" if not defined $proGroupMemberName;
  unless ( not defined $obj
    or $obj->does('Firewall::Config::Element::Protocol::Role')
    or $obj->does('Firewall::Config::Element::ProtocolGroup::Role') )
  {
    confess
      "ERROR: 参数 obj 只能是 Firewall::Config::Element::Protocol::Role or Firewall::Config::Element::ProtocolGroup::Role or Undef";
  }
  $self->{proGroupMembers}{$proGroupMemberName} = $obj;
  if ( defined $obj ) {
    if ( $obj->does('Firewall::Config::Element::Protocol::Role') ) {
      $self->protocols->{$obj->protocol} = $obj;
    }
    elsif ( $obj->does('Firewall::Config::Element::ProtocolGroup::Role') ) {
      for my $protocol ( keys %{$obj->protocols} ) {
        $self->protocols->{$protocol} = $obj->protocols->{$protocol};
      }
    }
  }
} ## end sub addProGroupMember

1;
