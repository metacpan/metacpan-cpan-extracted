package Firewall::Config::Element::Address::Huawei;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use Carp;
use Mojo::Util qw(dumper);
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Address::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Address::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Address::Huawei 通用属性
#------------------------------------------------------------------------------
has '+ip' => (
  required => 0,
);

has '+mask' => (
  required => 0,
);

has members => (
  is      => 'rw',
  isa     => 'ArrayRef',
  default => sub { [] },
);

# 是否为 vpn-instance 实例
has vpn => (
  is      => 'ro',
  isa     => 'Str',
  default => 'default',
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
  my $self = shift;
  if ( not defined $self->{range} ) {
    return Firewall::Utils::Set->new;
  }
  else {
    $self->range;
  }
}

#------------------------------------------------------------------------------
# 新增地址组成员方法
#------------------------------------------------------------------------------
sub addMember {
  my ( $self, $member ) = @_;
  say dumper $member;

  push @{$self->{"members"}}, $member;
  for my $type ( keys %{$member} ) {
    if ( $type eq 'ipmask' ) {
      my ( $ip, $mask ) = split( '/', $member->{$type} );
      my $ipSet = Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask );
      $self->range->mergeToSet($ipSet);
    }
    elsif ( $type eq 'range' ) {
      my ( $ipmin, $ipmax ) = split( '\s+|-', $member->{$type} );
      my $ipSet = Firewall::Utils::Ip->getRangeFromIpRange( $ipmin, $ipmax );
      $self->range->mergeToSet($ipSet);
    }
    elsif ( $type eq 'obj' ) {
      $self->range->mergeToSet( $member->{$type}->range );
    }
  }

} ## end sub addMember

__PACKAGE__->meta->make_immutable;
1;

