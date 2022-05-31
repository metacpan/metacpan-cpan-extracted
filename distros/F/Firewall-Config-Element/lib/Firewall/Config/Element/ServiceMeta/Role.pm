package Firewall::Config::Element::ServiceMeta::Role;

use Moose::Role;
use Firewall::Utils::Set;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::Role';

has srvName => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has protocol => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has srcPort => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has dstPort => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has srcPortRange => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  default => sub { Firewall::Utils::Set->new( 0, 65535 ) }
);

has dstPortRange => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  lazy    => 1,
  builder => '_buildDstPortRange',
);

has range => (
  is      => 'ro',
  isa     => 'Firewall::Utils::Set',
  builder => '_buildRange',
);

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig      = shift;
  my $className = shift;
  my %params    = @_;
  $params{protocol}     = lc( $params{protocol} )                if defined $params{protocol};
  $params{srcPortRange} = &buildSrcPortRange( $params{srcPort} ) if defined $params{srcPort};
  return $className->$orig(%params);
};

#------------------------------------------------------------------------------
# _buildDstPortRange 具体实现
#------------------------------------------------------------------------------
sub _buildDstPortRange {
  my $self = shift;
  my ( $min, $max );
  my $dstPort = $self->dstPort;
  if ( $dstPort =~ /^\s*(\d+)\s*$/o ) {
    ( $min, $max ) = ( $1, $1 );
  }
  elsif ( $dstPort =~ /^\s*(\d+)[\s+\-](\d+)\s*$/o ) {
    ( $min, $max ) = ( $1, $2 );
  }
  else {
    confess "ERROR: Attribute (dstPort) 's value [$dstPort] 's format is wrong";
  }
  return ( Firewall::Utils::Set->new( $min, $max ) );
}

#------------------------------------------------------------------------------
# 生成源端区间集合
#------------------------------------------------------------------------------
sub buildSrcPortRange {
  my ( $min, $max );
  my $srcPort = shift;
  if ( $srcPort =~ /^\s*(\d+)\s*$/o ) {
    ( $min, $max ) = ( $1, $1 );
  }
  elsif ( $srcPort =~ /^\s*(\d+)[\s+\-](\d+)\s*$/o ) {
    ( $min, $max ) = ( $1, $2 );
  }
  else {
    return ( Firewall::Utils::Set->new( 0, 65535 ) );
  }
  return ( Firewall::Utils::Set->new( $min, $max ) );
}

#------------------------------------------------------------------------------
# _buildRange 具体实现
#------------------------------------------------------------------------------
sub _buildRange {
  my $self    = shift;
  my $service = $self->protocol . "/" . $self->dstPort;
  return Firewall::Utils::Ip->new->getRangeFromService($service);
}

1;
