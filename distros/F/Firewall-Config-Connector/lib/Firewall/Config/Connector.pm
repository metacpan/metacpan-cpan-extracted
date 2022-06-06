package Firewall::Config::Connector;
# ABSTRACT: turns baubles into trinkets

use Carp;
use POSIX;
use Moose;
use namespace::autoclean;
use Time::HiRes;
use Data::Dumper;

use Firewall::Config::Dao::Parser;
use Firewall::Config::Content::Static;
use Firewall::Utils::Date;

$Data::dumper::Sortkeys = 1;

has dbi => (
  is   => 'ro',
  does => 'Firewall::DBI::Role',
);

sub update {
  my ( $self, %param ) = @_;
  my ( $fwType, @process, $conf, %processForFw, $numOfProcesses, $fwIds );
  my $fwInfo = $self->getFwInfo;
  if (@{$param{fwIds}}) {
    $fwIds = $param{fwIds};
  }
  else {
    $fwIds = [ keys %{$fwInfo} ];
  }
  $numOfProcesses =
    ( defined $param{numOfProcessesInput} and $param{numOfProcessesInput} > 0 )
      ? $param{numOfProcessesInput}
      : 10;
  $numOfProcesses = ( @{$fwIds} > $numOfProcesses ) ? $numOfProcesses : scalar(@{$fwIds});

  my $i = 0;
  foreach my $fwIdNum (@{$fwIds}) {
    push @{$process[ $i % $numOfProcesses ]}, $fwIdNum;
    $i++;
  }
  my $func = "getConfById";
  my %childPids;
  my $home = $ENV{firewall_manager_home};
  if (not defined($home) or $home =~ /^\s*$/) {
    print("ERROR: 获取home目录失败: $@\n");
    exit();
  }
  my $logPath = $home . '/log/' . POSIX::strftime("%Y%m%d", localtime());
  mkdir($logPath, 0755) or confess("ERROR: mkdir( $logPath, 0755 ) failed: $!") if not -d $logPath;
  for (my $j = 0; $j < $numOfProcesses; $j++) {
    if (my $pid = fork) {
      $childPids{$pid} = undef;
      $processForFw{$pid} = $process[$j];
    }
    else {
      foreach my $fwId (@{$process[$j]}) {
        my $logName = sprintf('%04d', $fwId) . '_' . $fwInfo->{$fwId}{fwName};
        if (open(STDERR, q{>>}, "$logPath/$logName")) {
          print STDERR '<'
                       . Firewall::Utils::Date->new->getFormatedDate
                       . "> $fwId:$fwInfo->{$fwId}{fwName} start in proc $$\n";

          $fwType = $fwInfo->{$fwId}->{fwType};
          eval {$conf = $self->getConfById($fwInfo->{$fwId})};

          if (!!$@) {
            open(my $failedList, q{>>}, "$logPath/failedList")
            or confess("ERROR: open file $logPath/failedList failed: $!");
            print $failedList $fwId . ",";
            print STDERR $@;
          }
          else {
            eval {$self->saveconfig({ fwId => $fwId, type => $fwType, conf => $conf })};
            print STDERR $@ if !!$@;
            print STDERR '<' . Firewall::Utils::Date->new->getFormatedDate . "> $fwId:$fwInfo->{$fwId}{fwName} end\n";
          }
        }
        else {
          warn(qq{ERROR: open( STDERR, ">>$logPath/$logName" ) failed: $!});
        }
      } ## end foreach my $fwId ( @{$process...})
      exit;
    } ## end else [ if ( my $pid = fork ) ]
  }   ## end for ( my $i = 0; $i < $numOfProcesses...)
  open(my $parentLog, q{>>}, "$logPath/parentLog") or confess("ERROR: open file $logPath/parentLog failed: $!");
  print $parentLog dumper(\%processForFw);
  close $parentLog;

  my $exitPid;
  while (keys(%childPids)) {
    while (( $exitPid = waitpid(-1, WNOHANG) ) > 0) {
      delete($childPids{$exitPid});
      sleep(0.25);
    }
  }
} ## end sub update

sub saveconfig() {
  my ( $self, $param ) = @_;
  my ( $fwId, $type, $conf ) = @{$param}{qw/fwId type conf/};
  my $sonDbi = $self->dbi->clone;
  my $predefinedService;
  eval
  "use Firewall::Config::Dao::PredefinedService::$type; \$predefinedService = Firewall::Config::Dao::PredefinedService::$type->new( dbi => \$sonDbi )";
  confess $@ if !!$@;

  $predefinedService = $predefinedService->load($fwId);
  use Firewall::Config::Dao::Config;
  my $daoConf = Firewall::Config::Dao::Config->new(
    dbi  => $sonDbi,
    conf => $conf
  );
  my $isConfigChanged = $daoConf->save;
  return unless $isConfigChanged or $ENV{firewall_manager_force_parse};
  my $daoLock;
  use Firewall::Config::Dao::Lock;
  $daoLock = Firewall::Config::Dao::Lock->new(
    dbi  => $sonDbi,
    fwId => $fwId
  );
  $daoLock->lock;
  my $parser;
  eval
  "use Firewall::Config::Parser::$type; \$parser = Firewall::Config::Parser::$type->new(config => \$conf, preDefinedService => \$predefinedService);";
  confess $@ if !!$@;
  $parser->parse();
  my $dao = Firewall::Config::Dao::Parser->new(
    dbi    => $sonDbi,
    parser => $parser
  );
  $dao->save;
  $daoLock->unLock;
} ## end sub saveconfig

sub getConfById {
  my ( $self, $fwInfoEachId ) = @_;
  my ( $fwId, $manageIp, $username, $passwd, $fwType, $connectionType, $fwName )
    = @{$fwInfoEachId}{qw/fwId manageIp username passwd fwType connectionType fwName/};
  my $className = "Firewall::Config::Connector::$fwType";
  my ( $config, $conn );
  eval "use $className;\$conn = \$className->new();";
  confess $@ if $@;
  my $configStr;
  my $num = 0;
  do {
    eval {$configStr = $conn->$connectionType(host => $manageIp, user => $username, password => $passwd)};
    $num++;
    sleep 5;
  } while ($num < 8 and $@);
  confess $@ if $@;
  $config = [ split(/(?<=\n)/, $configStr) ];
  my $conf = Firewall::Config::Content::Static->new(
    fwId   => $fwId,
    fwName => $fwName,
    config => $config,
    fwType => $fwType
  );
  return $conf;
} ## end sub getConfById

sub getFwInfo {
  my $self = shift;
  my $fwInfo = $self->dbi->execute(
    "select i.fw_id,i.fw_name,
        (select b.basekey_name from fw_basekey b where b.basekey_id = i.connection_type) as connection_type,
        (select b.basekey_name from fw_basekey b where b.basekey_id = i.fw_type) as fw_type,
        i.username,i.passwd,i.state,i.manage_ip,i.device_idfrom FW_INFO iwhere i.state = 1"
  )->all;
  $self->dbi->disconnect;

  my %fwInfoIdAsKey;
  foreach (@{$fwInfo}) {
    @{$fwInfoIdAsKey{$_->{'fw_id'}}}{qw/fwId fwName connectionType fwType username passwd state manageIp/}
      = @{$_}{qw/fw_id fw_name connection_type fw_type username passwd state manage_ip/};
    $fwInfoIdAsKey{$_->{'fw_id'}}{fwType} = ucfirst lc $fwInfoIdAsKey{$_->{'fw_id'}}{fwType};
  }
  return \%fwInfoIdAsKey;
}

__PACKAGE__->meta->make_immutable;
1;
