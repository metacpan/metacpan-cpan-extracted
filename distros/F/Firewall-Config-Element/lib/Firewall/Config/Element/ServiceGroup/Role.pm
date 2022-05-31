package Firewall::Config::Element::ServiceGroup::Role;

use Moose::Role;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::ServiceGroup::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::ServiceGroup::Role 通用属性
#------------------------------------------------------------------------------
has srvGroupName => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has srvGroupMembers => (
  is   => 'ro',
  does => 'HashRef[ Firewall::Config::Element::Service::Role | Firewall::Config::Element::ServiceGroup::Role | Undef ]',
  default => sub { {} },
);

has dstPortRangeMap => (
  is      => 'ro',
  isa     => 'HashRef[Firewall::Utils::Set]',
  default => sub { {} },
);

has refnum => (
  is      => 'ro',
  isa     => 'Int',
  default => 0
);

has range => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  lazy    => 1,
  builder => '_buildRange',
);

#------------------------------------------------------------------------------
# addSrvGroupMember 添加服务端口组成员
#------------------------------------------------------------------------------
sub addSrvGroupMember {
  my ( $self, $srvGroupMemberName, $obj ) = @_;
  confess "ERROR: srvGroupMemberName must defined" if not defined $srvGroupMemberName;
  unless ( not defined $obj
    or $obj->does('Firewall::Config::Element::Service::Role')
    or $obj->does('Firewall::Config::Element::ServiceGroup::Role') )
  {
    confess
      "ERROR: 参数 obj 只能是 Firewall::Config::Element::Service::Role or Firewall::Config::Element::ServiceGroup::Role or Undef";
  }
  $self->{srvGroupMembers}{$srvGroupMemberName} = $obj;
  if ( defined $obj ) {
    for my $protocol ( keys %{$obj->dstPortRangeMap} ) {
      if ( not defined $self->dstPortRangeMap->{$protocol} ) {
        $self->dstPortRangeMap->{$protocol} = Firewall::Utils::Set->new;
      }
      $self->dstPortRangeMap->{$protocol}->mergeToSet( $obj->dstPortRangeMap->{$protocol} );
    }
  }
} ## end sub addSrvGroupMember

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildRange {
  my $self  = shift;
  my $range = Firewall::Utils::Set->new;
  for my $service ( values %{$self->srvGroupMembers} ) {
    $range->mergeToSet( $service->range );
  }
  return $range;
}

1;
