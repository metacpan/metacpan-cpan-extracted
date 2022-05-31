package Firewall::Config::Element::Route::H3c;

use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::Route::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Route::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::Route::H3c 通用属性
#------------------------------------------------------------------------------
has '+network' => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

# 改写 mask 属性
has '+mask' => (
  is       => 'ro',
  isa      => 'Int',
  required => 0,
);

has type => (
  is      => 'ro',
  isa     => 'Str',
  default => 'static',
);

has srcInterface => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

has srcIpmask => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

has srcRange => (
  is       => 'ro',
  required => 0,
  isa      => 'Firewall::Utils::Set',
  lazy     => 1,
  builder  => '_buildSrcRange',
);

has dstInterface => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

has vpn => (
  is       => 'ro',
  isa      => 'Str|Undef',
  required => 0,
);

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  if ( $self->type eq 'static' ) {
    return $self->createSign( $self->type, $self->network, $self->mask );
  }
  else {
    return $self->createSign( $self->type, $self->srcIpmask );
  }
}

#------------------------------------------------------------------------------
# srcRange => _buildSrcRange 具体实现方法
#------------------------------------------------------------------------------
sub _buildSrcRange {
  my $self = shift;
  if ( $self->type eq 'policy' ) {
    if ( defined $self->{srcIpmask} ) {
      my ( $ip, $mask ) = split( '/', $self->srcIpmask );
      return Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
    }
    else {
      return Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', 0 );
    }
  }
  else {
    return Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', 0 );
  }
}

__PACKAGE__->meta->make_immutable;
1;
