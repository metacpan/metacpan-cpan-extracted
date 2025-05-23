package Firewall::Config::Connector::Srx;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.018;
use warnings;
use Carp;
use namespace::autoclean;
use Firewall::Config::Connector::Device::Srx;

#------------------------------------------------------------------------------
# Srx telnet 函数入口
#------------------------------------------------------------------------------
sub telnet {
  my ( $self, %param ) = @_;
  my ( $host, $user, $password ) = @{param}{qw/ host user password /};
  my $conn = Firewall::Config::Connector::Device::Srx->new(
    host     => $host,
    username => $user,
    password => $password,
    proto    => 'telnet'
  );
  my $config = $conn->getconfig();
  if ( $config->{success} ) {
    return $config->{config};
  }
  else {
    confess $config->{reason};
  }
}

#------------------------------------------------------------------------------
# Srx ssh 函数入口
#------------------------------------------------------------------------------
sub ssh {
  my ( $self, %param ) = @_;
  my ( $host, $user, $password ) = @{param}{qw/ host user password /};
  my $conn = Firewall::Config::Connector::Device::Srx->new(
    host     => $host,
    username => $user,
    password => $password,
    proto    => 'ssh'
  );
  my $config = $conn->getconfig();
  if ( $config->{success} ) {
    return $config->{config};
  }
  else {
    confess $config->{reason};
  }
}

__PACKAGE__->meta->make_immutable;
1;
