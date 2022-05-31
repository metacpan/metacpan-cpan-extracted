package Firewall::Config::Element::ServiceMeta::Srx;

use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引入 Firewall::Config::Element::ServiceMeta::Role 角色
#------------------------------------------------------------------------------
with 'Firewall::Config::Element::ServiceMeta::Role';

#------------------------------------------------------------------------------
# Firewall::Config::Element::ServiceMeta::Srx 通用属性
#------------------------------------------------------------------------------
has term => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has timeout => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

has uuid => (
  is      => 'ro',
  isa     => 'Undef|Str',
  default => undef,
);

#------------------------------------------------------------------------------
# Moose BUILDARGS 在实例创建之前生效，可以接收哈希和哈希的引用
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig   = shift;
  my $class  = shift;
  my %params = @_;
  $params{term}    = $params{term} // ' ';
  $params{srcPort} = '0-65535' if not defined $params{srcPort};
  if ( defined $params{uuid} ) {
    $params{protocol} = 'ms-rpc-' . $params{protocol};
  }
  if ( defined $params{protocol} and $params{protocol} !~ /^(tcp|udp)$/io ) {
    $params{dstPort} = '0-65535' if not defined $params{dstPort};
  }
  return $class->$orig(%params);
};

#------------------------------------------------------------------------------
# 重写 Firewall::Config::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign( $self->srvName, $self->term );
}

__PACKAGE__->meta->make_immutable;
1;
