package Firewall::Config::Connector::Fortinet;

use 5.018;
use warnings;
use Carp;
use namespace::autoclean;
use Firewall::Config::Connector::Device::Fortinet;

#------------------------------------------------------------------------------
# Fortinet telnet 函数入口
#------------------------------------------------------------------------------
sub telnet {
  my ( $self, %param ) = @_;
  my ( $host, $user, $password ) = @{param}{qw/ host user password /};
  my $conn = Firewall::Config::Connector::Device::Fortinet->new(
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
# Fortinet ssh 函数入口
#------------------------------------------------------------------------------
sub ssh {
  my ( $self, %param ) = @_;
  my ( $host, $user, $password ) = @{param}{qw/ host user password /};
  my $conn = Firewall::Config::Connector::Device::Fortinet->new(
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

=old
sub telnet {
    my ($self, %param) = @_;
    my ($host, $user, $password) = @{param}{qw/host user password/};
    my $prompt = '/.+[>#] $/';
    my $cmd0 = "terminal pager 0";
    my $cmd1 = "show run";
    my $conn = new Net::Telnet(
        Max_buffer_length  => 2_098_1520,
        Timeout => 600,
    );
    $conn->open($host);
    $conn->waitfor('/username/i');
    $conn->print($user);
    $conn->waitfor('/password/i');
    $conn->print($password);
    $conn->waitfor($prompt);
    $conn->print('ena');
    $conn->waitfor('/password/i');
    $conn->print($password);
    $conn->waitfor($prompt);
    $conn->print($cmd0);
    $conn->waitfor($prompt);
    $conn->print($cmd1);
    my @output = $conn->waitfor($prompt);
    return $output[0];
}
sub ssh {
    my ($self, %param) = @_;
    my ($host, $user, $password) = @{param}{qw/host user password/};
    my $ssh = new Net::SSH::Expect(
        host => $host,
        user => $user,
        password => $password,
        raw_pty => 1
    );
    my $enaPasswd = $password;
    my $cmd0 = "terminal pager 0";
    my $cmd1 = "show run";
    $ssh->login();
    $ssh->send('ena');
    $ssh->waitfor('assword') or confess 'waiting for prompt "assword" failed';
    $ssh->send($enaPasswd);
    $ssh->waitfor('.+#\s*$') or confess 'failed to enter enable mode';
    $ssh->send($cmd0);
    my $config = $ssh->exec($cmd1);
    $ssh->send($cmd0);
    $ssh->waitfor('.+#\s*$', 60) or confess 'fetching config failed. Perhaps the usename doesn\'t have sufficient privileges';
    $ssh->close();
    if ( $config !~ /#\s*$|coldstart\s*$/i ) {
        confess "config may not be complete";
    }
    return $config;
}
=cut

__PACKAGE__->meta->make_immutable;
1;
