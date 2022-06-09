package Firewall::FireFlow::FWDeploy;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use POSIX;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::DBI::Pg;
use Firewall::Config::Initialize;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
has dbi => ( is => 'ro', does => 'Firewall::DBI::Role', );

#------------------------------------------------------------------------------
# 脚本下发函数入口
#------------------------------------------------------------------------------
sub deploy {
  my ( $self, $taskId ) = @_;
  return unless defined $taskId;

  # 查询 SQL
  my $sql = "SELECT ft.taskid,ft.manage_ip,ft.fw_type,ft.config,fi.username,fi.passwd,fi.fw_id,
    (SELECT basekey_name FROM fw_basekey WHERE basekey_id=fi.connection_type) AS proto
    FROM firewall_task ft,fw_info fi WHERE ft.fw_id=fi.fw_id AND ft.taskid = $taskId";
  my $task = $self->dbi->execute($sql)->one;

  # 初始化变量
  my $fwType    = ucfirst lc $task->{fw_type};
  my @commands  = split( '\n', $task->{config} );
  my $username  = $task->{username};
  my $password  = $task->{passwd};
  my $proto     = $task->{proto};
  my $classname = "Firewall::FireFlow::Config::" . $fwType;
  my $fwc;

  # 设置防火墙会话开始时间
  $sql
    = "UPDATE firewall_task SET deploy_date = now(), deploy_state = :deployState, deploy_result= :deployResult WHERE taskid = :taskid";

  # 尝试登录设备并执行脚本
  eval
    "use $classname; \$fwc = $classname->new(host => '$task->{manage_ip}', username => '$username', password => '$password', proto => '$proto')";
  if ( !!$@ ) {
    $@ =~ /^(?<error>.+?)(\s+at\s+)?/;
    my $error = $+{error};
    $self->dbi->execute( $sql, {deployState => 0, deployResult => $error, taskid => $taskId} );
    return {success => 0, reason => $@};
  }
  my $execResult = $fwc->execCommands(@commands);
  if ( $execResult->{success} == 1 ) {
    $self->dbi->execute( $sql, {deployState => 1, deployResult => $execResult->{result}, taskid => $taskId} );

    # 执行完毕重新初始化防火墙
    my $InitFW = Firewall::Config::Initialize->new( dbi => $self->dbi );
    my $param;
    $param->{fwId}     = $task->{fw_id};
    $param->{initType} = 'connect';
    $InitFW->initFirewall($param);
    return {success => 1};
  }
  else {
    $self->dbi->execute( $sql, {deployState => 0, deployResult => $execResult->{result}, taskid => $taskId} );
    return $execResult;
  }
}

__PACKAGE__->meta->make_immutable;
1;

