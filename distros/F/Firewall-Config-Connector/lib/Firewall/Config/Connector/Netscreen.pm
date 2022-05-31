package Firewall::Config::Connector::Netscreen;

use 5.018;
use warnings;
use Carp;
use namespace::autoclean;
use Firewall::Config::Connector::Device::Netscreen;

#------------------------------------------------------------------------------
# Netscreen telnet 函数入口
#------------------------------------------------------------------------------
sub telnet {
  my ( $self, %param ) = @_;
  my ( $host, $user, $password ) = @{param}{qw/ host user password /};
  my $conn = Firewall::Config::Connector::Device::Netscreen->new(
    host     => $host,
    username => $user,
    password => $password,
    proto    => 'telnet'
  );
  my $config = $conn->getconfig();
  if ( $config->{"success"} ) {
    return $config->{"config"};
  }
  else {
    confess $config->{"reason"};
  }
}

#------------------------------------------------------------------------------
# Netscreen ssh 函数入口
#------------------------------------------------------------------------------
sub ssh {
  my ( $self, %param ) = @_;
  my ( $host, $user, $password ) = @{param}{qw/ host user password /};
  my $conn = Firewall::Config::Connector::Device::Netscreen->new(
    host     => $host,
    username => $user,
    password => $password,
    proto    => 'ssh'
  );
  my $config = $conn->getconfig();
  if ( $config->{"success"} ) {
    return $config->{"config"};
  }
  else {
    confess $config->{"reason"};
  }
}

__PACKAGE__->meta->make_immutable;
1;
