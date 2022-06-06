package Firewall::Config::Element::Rule::H3c;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Firewall::Config::Element::AddressGroup::H3c;
use Firewall::Config::Element::ServiceGroup::H3c;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element::Rule::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Rule::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::H3c 通用属性
#------------------------------------------------------------------------------
#rule type ACL or object-policy(obj)
has ruleType => (
  is      => 'ro',
  isa     => 'Str',
  default => 'obj'
);

has objName => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has aclName => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has aclRuleNum => (
  is       => 'ro',
  isa      => 'Int',
  required => 0,
);

has aclType => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has policyId => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has fromZone => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

has toZone => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

has fromInterface => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has toInterface => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has '+action' => (
  is      => 'ro',
  isa     => 'Str',
  default => 'permit',
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  if ( $self->ruleType eq 'obj' ) {
    return $self->createSign( $self->objName, $self->policyId );
  }
  else {
    return $self->createSign( $self->aclName, $self->aclRuleNum );
  }
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildSrcAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildSrcAddressGroup {
  my $self = shift;
  return Firewall::Config::Element::AddressGroup::H3c->new( addrGroupName => '^' );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildDstAddressGroup 具体实现
#------------------------------------------------------------------------------
sub _buildDstAddressGroup {
  my $self = shift;
  return Firewall::Config::Element::AddressGroup::H3c->new( addrGroupName => '^' );
}

#------------------------------------------------------------------------------
# Firewall::Config::Element::Rule::Role _buildServiceGroup 具体实现
#------------------------------------------------------------------------------
sub _buildServiceGroup {
  my $self = shift;
  return Firewall::Config::Element::ServiceGroup::H3c->new( srvGroupName => '^' );
}

sub ignore {
  my $self = shift;
  return (
    defined $self->isDisable and $self->isDisable eq 'disable'
      or $self->hasSchedule  and $self->schedule->isExpired
  );
}

__PACKAGE__->meta->make_immutable;
1;
